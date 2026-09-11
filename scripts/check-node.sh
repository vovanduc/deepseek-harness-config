#!/usr/bin/env bash
# Is this machine's Node usable for the pinned dsh, and does it match .nvmrc?
#
#   ./scripts/check-node.sh
#
# install.sh calls this before it creates anything. A Node below the floor used to
# pass `command -v node` and fail much later, far from the cause; a newer major is
# not broken, but it is not what this config is verified against either.
#
# Exit: 0 ok (possibly with a warning), 1 too old or no node, 2 usage error.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

FLOOR=20

usage() {
  cat <<'EOF'
Usage: scripts/check-node.sh

Compares `node --version` with the Node 20 floor and with the major pinned in .nvmrc.
Exit codes: 0 ok or warning, 1 too old / node missing, 2 usage error.
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --help|-h) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
done

if ! command -v node >/dev/null 2>&1; then
  printf '  FAIL node is not on PATH — dsh needs Node %s+ (see .nvmrc)\n' "$FLOOR"
  exit 1
fi

have="$(node --version 2>/dev/null | sed 's/^v//' | tr -d '[:space:]')"
have_major="${have%%.*}"
case "$have_major" in
  ''|*[!0-9]*)
    printf '  FAIL cannot read a version from `node --version` (got %s)\n' "${have:-nothing}"
    exit 1 ;;
esac

pin=''
if [ -f .nvmrc ]; then
  pin="$(tr -d '[:space:]' < .nvmrc | sed 's/^v//')"
fi
pin_major="${pin%%.*}"

if [ "$have_major" -lt "$FLOOR" ]; then
  printf '  FAIL node %s is below the Node %s floor that dsh needs (this repo pins %s)\n' \
    "$have" "$FLOOR" "${pin:-?}"
  exit 1
fi

if [ -z "$pin_major" ]; then
  printf '  ok    node %s (no .nvmrc to compare)\n' "$have"
  exit 0
fi

if [ "$have_major" != "$pin_major" ]; then
  printf '  warn  node %s, but .nvmrc pins %s — this config is verified against %s\n' \
    "$have" "$pin" "$pin"
  exit 0
fi

printf '  ok    node %s (matches .nvmrc %s)\n' "$have" "$pin"
