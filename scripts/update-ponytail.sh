#!/usr/bin/env bash
# Keep this repo's ponytail skills in step with upstream.
#
# Only the SKILL.md layer is carried over — upstream's plugin hooks for other
# agents are deliberately not synced. The pinned ref is UPSTREAM_REF below, the
# single source of truth; skills/README.md points here instead of repeating a
# version. git is the undo: the files are tracked, so `git diff` shows an apply
# and `git checkout -- skills` reverts one.
set -euo pipefail

UPSTREAM_REPO='DietrichGebert/ponytail'
UPSTREAM_REF='v4.9.0'

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO"

usage() {
  cat <<'EOF'
Usage: scripts/update-ponytail.sh [--apply] [--ref <tag-or-branch>]

  (no flags)   report drift in skills/ against the pinned upstream ref
  --apply      copy the upstream SKILL.md files and LICENSE over the local ones
  --ref <ref>  check or apply another tag/branch without changing the pin
  --help       this text

Exit codes: 0 in sync or applied, 1 drift found, 2 usage or download error.
EOF
}

apply=0
ref="$UPSTREAM_REF"
while [ $# -gt 0 ]; do
  case "$1" in
    --apply) apply=1 ;;
    --ref)
      shift
      [ $# -gt 0 ] || { echo 'error: --ref needs a value' >&2; exit 2; }
      ref="$1" ;;
    --help|-h) usage; exit 0 ;;
    *) echo "error: unknown argument: $1" >&2; usage >&2; exit 2 ;;
  esac
  shift
done

for tool in curl tar cmp diff find; do
  command -v "$tool" >/dev/null 2>&1 || { echo "error: $tool is required" >&2; exit 2; }
done

tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

if [ "$ref" = "$UPSTREAM_REF" ]; then
  echo "upstream: $UPSTREAM_REPO @ $ref (pinned)"
else
  echo "upstream: $UPSTREAM_REPO @ $ref (pin in this script: $UPSTREAM_REF)"
fi

if ! curl -fsSL -m 120 "https://codeload.github.com/$UPSTREAM_REPO/tar.gz/$ref" -o "$tmp/upstream.tgz"; then
  echo "error: could not download $UPSTREAM_REPO @ $ref" >&2
  exit 2
fi
tar xzf "$tmp/upstream.tgz" -C "$tmp"
src="$(find "$tmp" -mindepth 1 -maxdepth 1 -type d | head -1)"
if [ -z "$src" ] || [ ! -d "$src/skills" ]; then
  echo 'error: unexpected upstream layout (no skills/ directory)' >&2
  exit 2
fi

drift=0

# One skill: report the comparison, and copy when --apply was given.
handle_skill() {
  local name="$1" up="$2" local_file="skills/$1/SKILL.md" changed=''
  if [ ! -f "$local_file" ]; then
    if [ "$apply" -eq 1 ]; then
      mkdir -p "skills/$name"
      cp "$up" "$local_file"
      printf '  added       %s\n' "$name"
    else
      printf '  missing     %s (upstream has it, local does not)\n' "$name"
      drift=1
    fi
    return
  fi
  if cmp -s "$local_file" "$up"; then
    if [ "$apply" -eq 1 ]; then printf '  unchanged   %s\n' "$name"; else printf '  identical   %s\n' "$name"; fi
    return
  fi
  changed="$(diff "$local_file" "$up" | grep -c '^[<>]' || true)"
  if [ "$apply" -eq 1 ]; then
    cp "$up" "$local_file"
    printf '  updated     %s (%s changed lines)\n' "$name" "$changed"
  else
    printf '  DIFFERS     %s (%s changed lines)\n' "$name" "$changed"
    drift=1
  fi
}

while IFS= read -r up; do
  handle_skill "$(basename "$(dirname "$up")")" "$up"
done < <(find "$src/skills" -mindepth 2 -maxdepth 2 -name SKILL.md | sort)

# Skills that exist locally but not upstream. Never deleted automatically.
while IFS= read -r local_file; do
  name="$(basename "$(dirname "$local_file")")"
  if [ ! -f "$src/skills/$name/SKILL.md" ]; then
    printf '  orphan      %s (local only; remove by hand if upstream dropped it)\n' "$name"
    drift=1
  fi
done < <(find skills -mindepth 2 -maxdepth 2 -name SKILL.md -path 'skills/ponytail*' | sort)

if cmp -s skills/LICENSE-ponytail-upstream "$src/LICENSE"; then
  if [ "$apply" -eq 1 ]; then echo '  unchanged   LICENSE'; else echo '  identical   LICENSE'; fi
else
  if [ "$apply" -eq 1 ]; then
    cp "$src/LICENSE" skills/LICENSE-ponytail-upstream
    echo '  updated     LICENSE'
  else
    echo '  DIFFERS     LICENSE'
    drift=1
  fi
fi

echo
if [ "$apply" -eq 1 ]; then
  echo "applied $ref"
  if [ "$ref" != "$UPSTREAM_REF" ]; then
    echo "pin unchanged — set UPSTREAM_REF='$ref' in this script to make it the new pin"
  fi
  echo "review with: git diff --stat -- skills"
  exit 0
fi

if [ "$drift" -eq 0 ]; then
  echo "in sync with $UPSTREAM_REF"
  exit 0
fi

echo "drift against $ref"
if [ "$ref" = "$UPSTREAM_REF" ]; then
  echo "apply with: $0 --apply"
else
  echo "apply with: $0 --apply --ref $ref"
fi
exit 1
