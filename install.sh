#!/usr/bin/env bash
# Put this repo's DeepSeek Harness configuration on a machine.
#
#   ./install.sh              # link settings, seed env, install skills, verify
#   ./install.sh --no-install # skip the global `dsh` install step
#
# Idempotent: running it twice changes nothing. Anything it would overwrite is
# moved aside with a .bak-<timestamp> suffix first.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
VERSION="$(tr -d '[:space:]' < "$REPO/dsh.version")"
SKIP_INSTALL=0
[ "${1:-}" = "--no-install" ] && SKIP_INSTALL=1

say() { printf '\033[1m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[33m[warn]\033[0m %s\n' "$*" >&2; }
die() { printf '\033[31m[error]\033[0m %s\n' "$*" >&2; exit 1; }

stamp() { date +%Y%m%d-%H%M%S; }

# --- 0. node ----------------------------------------------------------------
# Node below the floor used to pass `command -v node` and fail much later, far
# from the cause. This runs before anything is created.
if ! "$REPO/scripts/check-node.sh"; then
  die "Node is missing or too old for this dsh — fix the message above, then re-run"
fi

# --- 1. the dsh CLI ---------------------------------------------------------
if [ "$SKIP_INSTALL" -eq 0 ]; then
  current="$(dsh --version 2>/dev/null || echo none)"
  if [ "$current" != "$VERSION" ]; then
    say "installing @deepseek-ai/dsh@$VERSION (found: $current)"
    npm install -g "@deepseek-ai/dsh@$VERSION"
  else
    say "dsh $VERSION already installed"
  fi
else
  command -v dsh >/dev/null 2>&1 || warn "dsh is not on PATH; skipping the install check"
fi

# --- 2. harness home --------------------------------------------------------
mkdir -p "$DSH_HOME" "$DSH_HOME/skills"

# settings.yaml is symlinked, not copied: the running server then reads the repo
# file, and edits made in the web UI land in the repo ready to commit.
settings="$DSH_HOME/settings.yaml"
if [ -L "$settings" ]; then
  say "settings.yaml already linked"
elif [ -e "$settings" ]; then
  mv "$settings" "$settings.bak-$(stamp)"
  ln -s "$REPO/settings.yaml" "$settings"
  say "settings.yaml linked (old file kept as $(basename "$settings").bak-$(stamp))"
else
  ln -s "$REPO/settings.yaml" "$settings"
  say "settings.yaml linked"
fi

# --- 3. credentials ---------------------------------------------------------
env_file="$DSH_HOME/.env"
if [ ! -e "$env_file" ]; then
  cp "$REPO/.env.example" "$env_file"
  chmod 600 "$env_file"
  warn "created $env_file from .env.example — put your real keys in it"
else
  say "$env_file already exists (left untouched)"
  chmod 600 "$env_file" 2>/dev/null || true
fi

# --- 4. skills --------------------------------------------------------------
if [ -d "$REPO/skills" ]; then
  count=0
  for dir in "$REPO"/skills/*/; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    target="$DSH_HOME/skills/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      rm -rf "$target"
    fi
    ln -sfn "$dir" "$target"
    count=$((count + 1))
  done
  say "linked $count skill(s) into $DSH_HOME/skills"
fi

# --- 4b. plugins ------------------------------------------------------------
# Dsh installs a plugin into $DSH_HOME/profiles/<name> — machine state this repo
# does not track — so plugins.json in git is what makes a second machine match.
# A failure warns rather than aborts: settings and skills are already in place.
if [ -f "$REPO/plugins.json" ]; then
  if command -v dsh >/dev/null 2>&1; then
    say "applying the plugin set from plugins.json"
    if ! "$REPO/scripts/install-plugins.sh"; then
      warn "the plugin set is incomplete — re-run scripts/install-plugins.sh"
    fi
  else
    warn "dsh is not on PATH; skipping plugins — re-run scripts/install-plugins.sh after install"
  fi
fi

# --- 5. verify --------------------------------------------------------------
say "verifying"
if ! "$REPO/scripts/doctor.sh"; then
  warn "doctor reported issues. On a fresh machine that is usually just the key:"
  warn "  \$EDITOR ~/.dsh/.env   # then re-run scripts/doctor.sh"
fi
