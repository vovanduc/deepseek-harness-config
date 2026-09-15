#!/usr/bin/env bash
# Devin SWE-2 for dsh. SWE-2 has no public API — it only speaks Devin's Connect-RPC —
# but omp (Oh My Pi) has a built-in `devin` provider and an `auth-gateway` that re-exposes
# every credential it holds as a local OpenAI-compatible endpoint. So: broker holds the
# Devin session token, gateway serves http://127.0.0.1:4000/v1, settings.yaml points the
# `omp-gateway` route at it. Needs omp >= 18.2 on PATH and one `devin auth login`.
#
#   ./scripts/omp-gateway.sh start    # broker + devin key upload + gateway, then print the .env line
#   ./scripts/omp-gateway.sh stop
#   ./scripts/omp-gateway.sh status   # exit 0 when a SWE-2 completion round-trips
set -euo pipefail

BROKER=127.0.0.1:8765
GATEWAY=127.0.0.1:4000
LOG="${TMPDIR:-/tmp}/omp-gateway"
CRED="$HOME/.local/share/devin/credentials.toml"

wait_for() {  # <url> — poll a healthz for up to 20 s
  for _ in $(seq 40); do curl -sf -m 2 "$1" >/dev/null 2>&1 && return 0; sleep 0.5; done
  echo "timeout waiting for $1" >&2; return 1
}

case "${1:-status}" in
start)
  command -v omp >/dev/null || { echo 'omp is not on PATH (brew install omp)' >&2; exit 1; }
  [ -f "$CRED" ] || { echo "$CRED missing — run: devin auth login" >&2; exit 1; }
  DEVIN_API_KEY="$(sed -nE 's/^windsurf_api_key = "(.*)"/\1/p' "$CRED")"
  export DEVIN_API_KEY
  pgrep -f 'omp auth-broker serve' >/dev/null \
    || (nohup omp auth-broker serve --bind="$BROKER" >"$LOG-broker.log" 2>&1 &)
  wait_for "http://$BROKER/v1/healthz"
  export OMP_AUTH_BROKER_URL="http://$BROKER"
  OMP_AUTH_BROKER_TOKEN="$(omp auth-broker token)"
  export OMP_AUTH_BROKER_TOKEN
  # Uploads the env-derived Devin key; idempotent. Must precede the gateway: its model
  # catalog is computed at boot from the providers that have a credential at that moment,
  # so an already-running gateway is restarted rather than reused (a stale one answers
  # `Unknown model: devin/swe-2` forever).
  omp auth-broker migrate --from-local --include-env >/dev/null
  pkill -f 'omp auth-gateway serve' 2>/dev/null && sleep 1 || true
  (nohup omp auth-gateway serve --bind="$GATEWAY" >"$LOG-gateway.log" 2>&1 &)
  wait_for "http://$GATEWAY/healthz"
  echo "gateway up: http://$GATEWAY/v1  (logs: $LOG-*.log)"
  echo "put this in ~/.dsh/.env:"
  echo "OMP_GATEWAY_API_KEY=$(omp auth-gateway token)"
  ;;
stop)
  pkill -f 'omp auth-gateway serve' || true
  pkill -f 'omp auth-broker serve' || true
  echo stopped
  ;;
status)
  tok="$(omp auth-gateway token 2>/dev/null || true)"
  out="$(curl -s -m 90 "http://$GATEWAY/v1/chat/completions" \
    -H "Authorization: Bearer $tok" -H 'Content-Type: application/json' \
    -d '{"model":"devin/swe-2","messages":[{"role":"user","content":"Reply with exactly: GW OK"}],"max_tokens":200}')"
  if printf '%s' "$out" | grep -q '"content":"GW OK"'; then echo "swe-2 via gateway: OK"; else echo "$out"; exit 1; fi
  ;;
*) echo "usage: $0 start|stop|status" >&2; exit 2 ;;
esac
