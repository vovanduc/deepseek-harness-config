#!/usr/bin/env bash
# Check that DeepSeek Harness is installed and that this machine can reach the
# configured model. Read-only: it never writes configuration.
#
#   ./scripts/doctor.sh          human-readable report: coloured, printed live
#   ./scripts/doctor.sh --json   one JSON object on stdout — status/ok/warn/fail/checks[]
#   ./scripts/doctor.sh --help
#
# Exit: 0 ready, 1 not ready, 2 usage error — identical in both modes.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
VERSION="$(tr -d '[:space:]' < "$REPO/dsh.version")"
pass=0; fail=0; warn=0
json=0
results=()

usage() {
  cat <<'EOF'
Usage: scripts/doctor.sh [--json]

  (no flags)  coloured report, printed as each check runs
  --json      one JSON object on stdout: {status, ok, warn, fail, checks:[{id,status,message}]}
  --help      this text

Check ids: cli, settings, compose, credential, inference, skills.
`compose` is absent when `dsh` is not on PATH; every other id is always present.
Exit codes: 0 ready, 1 not ready, 2 usage error.
EOF
}

for arg in "$@"; do
  case "$arg" in
    --json) json=1 ;;
    --help|-h) usage; exit 0 ;;
    *) echo "error: unknown argument: $arg" >&2; usage >&2; exit 2 ;;
  esac
done

record() {  # <ok|warn|fail> <check-id> <message>
  local status="$1" id="$2" message="$3"
  case "$status" in
    ok)   pass=$((pass + 1)) ;;
    warn) warn=$((warn + 1)) ;;
    fail) fail=$((fail + 1)) ;;
  esac
  results+=("$status|$id|$message")
  [ "$json" -eq 1 ] && return 0
  case "$status" in
    ok)   printf '  \033[32mok\033[0m    %s\n' "$message" ;;
    warn) printf '  \033[33mwarn\033[0m  %s\n' "$message" ;;
    fail) printf '  \033[31mFAIL\033[0m  %s\n' "$message" ;;
  esac
}

finish() {
  if [ "$json" -eq 1 ]; then
    printf '%s\n' "${results[@]}" | node -e '
const { readFileSync } = require("node:fs");
const checks = readFileSync(0, "utf8").split("\n").filter(Boolean).map((line) => {
  const [status, id, ...rest] = line.split("|");
  return { id, status, message: rest.join("|") };
});
const tally = (s) => checks.filter((c) => c.status === s).length;
const report = {
  status: tally("fail") === 0 ? "READY" : "NOT_READY",
  ok: tally("ok"),
  warn: tally("warn"),
  fail: tally("fail"),
  checks,
};
process.stdout.write(`${JSON.stringify(report, null, 2)}\n`);
'
    [ "$fail" -eq 0 ] || exit 1
    return 0
  fi
  echo
  if [ "$fail" -eq 0 ]; then
    printf 'status: \033[32mREADY\033[0m (%d ok, %d warn)\n' "$pass" "$warn"
  else
    printf 'status: \033[31mNOT READY\033[0m (%d ok, %d warn, %d fail)\n' "$pass" "$warn" "$fail"
    exit 1
  fi
}

[ "$json" -eq 1 ] || echo "dsh doctor — repo $REPO"

# --- CLI --------------------------------------------------------------------
if command -v dsh >/dev/null 2>&1; then
  have="$(dsh --version 2>/dev/null | tr -d '[:space:]')"
  if [ "$have" = "$VERSION" ]; then record ok cli "dsh $have on PATH"
  else record warn cli "dsh $have on PATH, repo pins $VERSION"; fi
else
  record fail cli "dsh not on PATH — npm install -g @deepseek-ai/dsh@$VERSION"
fi

# --- settings ---------------------------------------------------------------
# The symlink IS the invariant, not the file's presence. dsh writes settings by
# writeFileAtomic — write `<path>.<hex>.tmp`, then rename() over the target — and rename
# replaces the link itself with a regular file. So any UI settings write (picking a model,
# changing the font size) silently unpicks it, and from then on repo edits still look
# committed while never reaching the server, with every other check green. Requiring the
# link, resolved into this repo, turns the next silent drift into a red check.
settings="$DSH_HOME/settings.yaml"
if [ ! -e "$settings" ]; then
  record fail settings "$settings missing — run ./install.sh"
  finish
elif [ ! -L "$settings" ]; then
  record fail settings "$settings is a regular file, not a symlink to $REPO/settings.yaml — a UI settings write replaced the link, so repo edits no longer reach the server; fix: ./install.sh"
else
  target="$(readlink "$settings")"
  case "$target" in
    /*) resolved="$target" ;;
    *)  resolved="$(dirname "$settings")/$target" ;;
  esac
  if [ "$(cd "$(dirname "$resolved")" 2>/dev/null && pwd)/$(basename "$resolved")" = "$REPO/settings.yaml" ]; then
    record ok settings "$settings → $REPO/settings.yaml"
  else
    record fail settings "$settings points at $target, not $REPO/settings.yaml — fix: ./install.sh"
  fi
fi

# The composed tree is the only real parse check: a bad key fails here.
if command -v dsh >/dev/null 2>&1; then
  if dsh --profile headless --dump-config >/dev/null 2>&1; then
    record ok compose "settings compose (dsh --profile headless --dump-config)"
  else
    record fail compose "settings do not compose — run the command above to see the error"
  fi
fi

# --- credential -------------------------------------------------------------
key_env="$(grep -E '^\s+apiKeyEnv:' "$DSH_HOME/settings.yaml" | head -1 | awk '{print $2}')"
key_env="${key_env:-OPENCODE_GO_API_KEY}"
placeholder_re='^(sk-replace-me|changeme|your-.*key.*|xxx+)$'
if [ -n "${!key_env:-}" ]; then
  if [[ "${!key_env:-}" =~ $placeholder_re ]]; then
    record fail credential "$key_env is set but still the placeholder value"
  else
    record ok credential "$key_env set in the current environment"
  fi
elif [ -s "$DSH_HOME/.env" ] && grep -qE "^${key_env}=..*" "$DSH_HOME/.env"; then
  value="$(grep -E "^${key_env}=" "$DSH_HOME/.env" | head -1 | cut -d= -f2-)"
  if [[ "$value" =~ $placeholder_re ]]; then
    record fail credential "$key_env in $DSH_HOME/.env is still the placeholder — put the real key in"
  else
    record ok credential "$key_env present in $DSH_HOME/.env"
  fi
else
  record fail credential "$key_env missing — add it to $DSH_HOME/.env (see .env.example)"
fi

# --- live model call --------------------------------------------------------
# One real completion, not a model listing: this gateway answers GET /models with
# 200 even for a bogus key, so only an inference request proves anything.
if command -v curl >/dev/null 2>&1; then
  key="${!key_env:-}"
  if [ -z "$key" ] && [ -s "$DSH_HOME/.env" ]; then
    key="$(grep -E "^${key_env}=" "$DSH_HOME/.env" | head -1 | cut -d= -f2-)"
  fi
  base="$(grep -E '^\s+baseURL:' "$DSH_HOME/settings.yaml" | head -1 | awk '{print $2}')"
  base="${base:-https://opencode.ai/zen/go/v1}"
  model="$(grep -E '^\s+- id:' "$DSH_HOME/settings.yaml" | head -1 | awk '{print $3}')"
  model="${model:-deepseek-flash}"
  sess="$(grep -E '^\s+x-opencode-session:' "$DSH_HOME/settings.yaml" | head -1 | awk '{print $2}')"

  if [ -z "$key" ] || [[ "$key" =~ $placeholder_re ]]; then
    record warn inference "skipping the live call: no usable key"
  else
    out="$(mktemp)"
    args=(-s -o "$out" -w '%{http_code}' -m 45 "$base/chat/completions"
          -H "Authorization: Bearer $key" -H 'Content-Type: application/json')
    [ -n "$sess" ] && args+=(-H "x-opencode-session: $sess")
    code="$(curl "${args[@]}" \
      -d "{\"model\":\"$model\",\"messages\":[{\"role\":\"user\",\"content\":\"ping\"}],\"max_tokens\":1}")"
    case "$code" in
      200)
        if grep -q '"choices"' "$out"; then record ok inference "inference on $model -> 200"
        else record warn inference "inference on $model -> 200 but an unexpected body"; fi ;;
      400) record fail inference "inference -> 400 ($(head -c 120 "$out"))" ;;
      401|403) record fail inference "inference -> $code (key rejected or out of quota)" ;;
      000) record warn inference "inference -> no response (offline?)" ;;
      *) record warn inference "inference -> $code" ;;
    esac
    rm -f "$out"
  fi
else
  record warn inference "curl not available; skipping the live call"
fi

# --- skills -----------------------------------------------------------------
if [ -d "$DSH_HOME/skills" ]; then
  n="$(find -L "$DSH_HOME/skills" -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  record ok skills "$n skill(s) in $DSH_HOME/skills"
else
  record warn skills "no $DSH_HOME/skills directory"
fi

finish
