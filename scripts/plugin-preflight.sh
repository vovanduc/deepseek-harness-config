#!/usr/bin/env bash
# Pre-flight a dsh plugin against the pinned dsh, before it touches a profile.
#
#   ./scripts/plugin-preflight.sh dsh-mermaid@0.4.0
#   ./scripts/plugin-preflight.sh dsh-diagram@0.4.0 --dsh-version 0.1.1-rc.2
#
# Why: `dsh --profile <p> --dump-config` proves the HOST layer only. A client half
# built for another dsh release composes cleanly and then kills the whole web boot
# ("Failed to load plugins"). This reads the published manifest and refuses what
# cannot work: dsh.compatibility.dshReleases must list the pinned release, and every
# dsh.client.inject id must exist in the pinned install.
#
# It cannot see a bare service name that lives only in compiled client code, so a
# pass is a filter, not a guarantee — the browser after a restart is still the gate.
#
# Exit: 0 ok, 1 incompatible or unverifiable, 2 usage error.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

target="$(tr -d '[:space:]' < dsh.version)"
spec=''

usage() {
  cat <<'EOF'
Usage: scripts/plugin-preflight.sh <name>@<version> [--dsh-version <v>]

  <name>@<version>   the pinned package spec, exactly as in plugins.json
  --dsh-version <v>  check against another dsh release (default: dsh.version)
  --help             this text

Exit codes: 0 compatible, 1 incompatible or unverifiable, 2 usage error.
EOF
}

fail() { printf '  FAIL     %s\n' "$*"; }
note() { printf '  note     %s\n' "$*"; }
ok()   { printf '  ok       %s\n' "$*"; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dsh-version)
      shift
      [ $# -gt 0 ] || { echo 'error: --dsh-version needs a value' >&2; exit 2; }
      target="$1" ;;
    --help|-h) usage; exit 0 ;;
    -*) echo "error: unknown option: $1" >&2; exit 2 ;;
    *)
      [ -z "$spec" ] || { echo 'error: one package spec at a time' >&2; exit 2; }
      spec="$1" ;;
  esac
  shift
done

[ -n "$spec" ] || { usage >&2; exit 2; }

version="${spec##*@}"
if [ -z "$version" ] || [ "$version" = "$spec" ]; then
  fail "$spec: pin an exact version (name@x.y.z) before pre-flighting"
  exit 2
fi

echo "pre-flight: $spec against dsh $target"

command -v npm >/dev/null 2>&1 || { note 'npm is not available — cannot pre-flight'; exit 0; }

if ! manifest="$(npm view "$spec" dsh --json 2>/dev/null)" || [ -z "$manifest" ] || [ "$manifest" = 'null' ]; then
  fail "$spec: not resolvable on npm, or it publishes no dsh manifest — cannot verify (--skip-preflight overrides)"
  exit 1
fi

# --- A. declared compatibility ----------------------------------------------
verdict="$(printf '%s' "$manifest" | node -e '
const { readFileSync } = require("node:fs");
const dsh = JSON.parse(readFileSync(0, "utf8")) ?? {};
const map = dsh.compatibility?.dshReleases;
if (!map) { console.log("nodeclared|"); process.exit(0); }
const status = map[process.argv[1]];
console.log(`${status ? String(status) : "missing"}|${Object.keys(map).join(" ")}`);
' "$target")"
compat="${verdict%%|*}"
declared="${verdict#*|}"

case "$compat" in
  nodeclared) note 'no dsh.compatibility declared by the plugin' ;;
  compatible|Compatible) ok "declared compatible with dsh $target" ;;
  missing)
    fail "declares compatibility for [$declared] but not for dsh $target"
    exit 1 ;;
  *)
    fail "dsh.compatibility.dshReleases[$target] = $compat"
    exit 1 ;;
esac

# --- B. client services the plugin needs -------------------------------------
injects="$(printf '%s' "$manifest" | node -e '
const { readFileSync } = require("node:fs");
const dsh = JSON.parse(readFileSync(0, "utf8")) ?? {};
const client = dsh.client;
if (!client) { console.log("HOSTONLY"); process.exit(0); }
const list = Array.isArray(client.inject) ? client.inject : [];
if (list.length === 0) { console.log("NOINJECT"); process.exit(0); }
for (const id of list) console.log(id);
')"

if [ "$injects" = 'HOSTONLY' ]; then
  ok 'host-only plugin (no web client) — cannot kill the web boot this way'
  exit 0
fi
if [ "$injects" = 'NOINJECT' ]; then
  ok "web client injects nothing (platform: $(printf '%s' "$manifest" | node -e 'const{readFileSync}=require("node:fs");const d=JSON.parse(readFileSync(0,"utf8"))??{};process.stdout.write(String(d.client?.platform??"?"))'))"
  exit 0
fi

dsh_pkg="$(npm root -g 2>/dev/null)/@deepseek-ai/dsh"
if [ ! -d "$dsh_pkg/node_modules/@deepseek-ai" ]; then
  note "cannot locate the pinned dsh install at $dsh_pkg — client inject not checked"
  echo "pre-flight: inconclusive (install dsh, then re-run)"
  exit 0
fi

missing=0
while IFS= read -r id; do
  [ -n "$id" ] || continue
  if [ -d "$dsh_pkg/node_modules/$id" ] \
    || grep -rIl --fixed-strings "$id" "$dsh_pkg/node_modules/@deepseek-ai" >/dev/null 2>&1; then
    ok "client inject $id"
  else
    fail "client inject $id is not provided by dsh $target"
    missing=$((missing + 1))
  fi
done <<< "$injects"

if [ "$missing" -ne 0 ]; then
  echo "pre-flight: INCOMPATIBLE — $missing unmet client service(s)"
  exit 1
fi

echo "pre-flight: ok"
