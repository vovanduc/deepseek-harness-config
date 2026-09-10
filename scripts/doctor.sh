#!/usr/bin/env bash
# Check that DeepSeek Harness is installed and that this machine can reach the
# configured model. Read-only: it never writes configuration.
set -uo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
VERSION="$(tr -d '[:space:]' < "$REPO/dsh.version")"
pass=0; fail=0; warn=0

ok()   { printf '  \033[32mok\033[0m    %s\n' "$*"; pass=$((pass+1)); }
bad()  { printf '  \033[31mFAIL\033[0m  %s\n' "$*"; fail=$((fail+1)); }
meh()  { printf '  \033[33mwarn\033[0m  %s\n' "$*"; warn=$((warn+1)); }

echo "dsh doctor — repo $REPO"

# --- CLI --------------------------------------------------------------------
if command -v dsh >/dev/null 2>&1; then
  have="$(dsh --version 2>/dev/null | tr -d '[:space:]')"
  if [ "$have" = "$VERSION" ]; then ok "dsh $have on PATH"
  else meh "dsh $have on PATH, repo pins $VERSION"; fi
else
  bad "dsh not on PATH — npm install -g @deepseek-ai/dsh@$VERSION"
fi

# --- settings ---------------------------------------------------------------
if [ -L "$DSH_HOME/settings.yaml" ] || [ -f "$DSH_HOME/settings.yaml" ]; then
  ok "$DSH_HOME/settings.yaml present"
else
  bad "$DSH_HOME/settings.yaml missing — run ./install.sh"
  echo; echo "summary: $pass ok, $warn warn, $fail fail"; exit 1
fi

# The composed tree is the only real parse check: a bad key fails here.
if command -v dsh >/dev/null 2>&1; then
  if dsh --profile headless --dump-config >/dev/null 2>&1; then
    ok "settings compose (dsh --profile headless --dump-config)"
  else
    bad "settings do not compose — run the command above to see the error"
  fi
fi

# --- credential -------------------------------------------------------------
key_env="$(grep -E '^\s+apiKeyEnv:' "$DSH_HOME/settings.yaml" | head -1 | awk '{print $2}')"
key_env="${key_env:-OPENCODE_GO_API_KEY}"
if [ -n "${!key_env:-}" ]; then
  ok "$key_env set in the current environment"
elif [ -s "$DSH_HOME/.env" ] && grep -qE "^${key_env}=..*" "$DSH_HOME/.env"; then
  ok "$key_env present in $DSH_HOME/.env"
else
  bad "$key_env missing — add it to $DSH_HOME/.env (see .env.example)"
fi

# --- live model reachability ------------------------------------------------
if command -v curl >/dev/null 2>&1; then
  key="${!key_env:-}"
  if [ -z "$key" ] && [ -s "$DSH_HOME/.env" ]; then
    key="$(grep -E "^${key_env}=" "$DSH_HOME/.env" | head -1 | cut -d= -f2-)"
  fi
  base="$(grep -E '^\s+baseURL:' "$DSH_HOME/settings.yaml" | head -1 | awk '{print $2}')"
  base="${base:-https://opencode.ai/zen/go/v1}"
  if [ -z "$key" ]; then
    meh "skipping the live call: no key on hand"
  else
    code="$(curl -s -o /dev/null -w '%{http_code}' -m 30 "$base/models" \
      -H "Authorization: Bearer $key")"
    case "$code" in
      200) ok "GET $base/models -> 200" ;;
      401|403) bad "GET $base/models -> $code (key rejected or out of quota)" ;;
      000) meh "GET $base/models -> no response (offline?)" ;;
      *) meh "GET $base/models -> $code" ;;
    esac
  fi
else
  meh "curl not available; skipping the live call"
fi

# --- skills -----------------------------------------------------------------
if [ -d "$DSH_HOME/skills" ]; then
  n="$(find -L "$DSH_HOME/skills" -maxdepth 2 -name SKILL.md 2>/dev/null | wc -l | tr -d ' ')"
  ok "$n skill(s) in $DSH_HOME/skills"
else
  meh "no $DSH_HOME/skills directory"
fi

echo
if [ "$fail" -eq 0 ]; then
  printf 'status: \033[32mREADY\033[0m (%d ok, %d warn)\n' "$pass" "$warn"
else
  printf 'status: \033[31mNOT READY\033[0m (%d ok, %d warn, %d fail)\n' "$pass" "$warn" "$fail"
  exit 1
fi
