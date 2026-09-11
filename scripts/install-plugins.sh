#!/usr/bin/env bash
# Apply the plugin set declared in plugins.json to this machine's dsh profiles.
#
#   ./scripts/install-plugins.sh            install anything missing or off-version
#   ./scripts/install-plugins.sh --dry-run  print the plan, change nothing
#
# Dsh installs a plugin into the profile directory ($DSH_HOME/profiles/<name>),
# which this repo gitignores — so plugins.json in git is what makes a second
# machine end up with the same set. A running profile keeps the bundle set it
# started with, so restart it (dsh web) after a change. See docs/plugins.md.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
MANIFEST='plugins.json'
dry_run=0
skip_preflight=0

usage() {
  cat <<'EOF'
Usage: scripts/install-plugins.sh [--dry-run] [--skip-preflight]

  (no flags)        install every plugin in plugins.json that is missing or at another version
  --dry-run         print what would be installed, change nothing
  --skip-preflight  install even when the pre-flight cannot verify the plugin
  --help            this text

Each plugin is pre-flighted against the pinned dsh first (scripts/plugin-preflight.sh):
a client half built for another dsh release composes fine and then kills the web boot.

Forwarded to dsh: dsh plugin --profile <profile> add <package@version>.
Exit codes: 0 applied (or nothing to do), 1 something failed or was blocked, 2 usage error.
EOF
}

warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
fail() { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; exit 2; }

while [ $# -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1 ;;
    --skip-preflight) skip_preflight=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

command -v node >/dev/null 2>&1 || fail 'node is required'
[ -f "$MANIFEST" ] || fail "$MANIFEST not found (run from the repo, or call $0 by path)"
if [ "$dry_run" -eq 0 ]; then
  command -v dsh >/dev/null 2>&1 || fail 'dsh is not on PATH — install it first (./install.sh)'
fi

# "profile<TAB>package" per line.
plan="$(node -e '
const { readFileSync } = require("node:fs");
const { plugins } = JSON.parse(readFileSync("plugins.json", "utf8"));
if (!Array.isArray(plugins) || plugins.length === 0) throw new Error("plugins[] missing");
for (const p of plugins) {
  if (typeof p.profile !== "string" || typeof p.package !== "string") {
    throw new Error("every plugin entry needs string profile + package");
  }
  console.log(`${p.profile}\t${p.package}`);
}
')" || fail "$MANIFEST is not a valid plugin manifest"

installed_version() {  # <profile> <name> -> version recorded by pnpm, or empty
  node -e '
const { readFileSync } = require("node:fs");
const [file, name] = process.argv.slice(1);
try {
  const manifest = JSON.parse(readFileSync(file, "utf8"));
  process.stdout.write((manifest.dependencies ?? {})[name] ?? "");
} catch {}
' "$DSH_HOME/profiles/$1/package.json" "$2"
}

applied=0
current=0
failed=0
blocked=0

while IFS=$'\t' read -r profile spec; do
  [ -n "$profile" ] || continue
  name="${spec%@*}"
  version="${spec##*@}"
  have="$(installed_version "$profile" "$name")"

  case "$have" in
    "$version"|"^$version"|"~$version")
      printf '  ok        %s/%s %s already installed\n' "$profile" "$name" "$version"
      current=$((current + 1))
      continue
      ;;
  esac

  if [ "$skip_preflight" -eq 0 ]; then
    if ! "$REPO/scripts/plugin-preflight.sh" "$spec"; then
      warn "pre-flight rejected $profile/$name@$version — not installed (override with --skip-preflight)"
      blocked=$((blocked + 1))
      continue
    fi
  fi

  if [ "$dry_run" -eq 1 ]; then
    printf '  would add %s/%s@%s\n' "$profile" "$name" "$version"
    applied=$((applied + 1))
    continue
  fi

  printf '  adding    %s/%s@%s\n' "$profile" "$name" "$version"
  if dsh plugin --profile "$profile" add "$spec"; then
    applied=$((applied + 1))
  else
    warn "failed to add $profile/$name@$version"
    failed=$((failed + 1))
  fi
done <<< "$plan"

echo
if [ "$dry_run" -eq 1 ]; then
  echo "dry run: $applied to add, $current already installed, $blocked blocked by pre-flight"
  exit 0
fi

echo "plugins: $applied added, $current already installed, $failed failed, $blocked blocked by pre-flight"
if [ "$failed" -ne 0 ] || [ "$blocked" -ne 0 ]; then
  warn "not every plugin in $MANIFEST was applied — review the output above"
  exit 1
fi
if [ "$applied" -gt 0 ]; then
  echo "restart the profile (dsh web) for the new bundles to load"
fi
