---
type: system
title: What lives in $DSH_HOME (~/.dsh)
description: settings.yaml is a symlink into this repo; .env, .credentials.yaml, skills/, profiles/ and .agent-presets/ are machine-local state.
tags: [dsh, layout]
---
# Layout

| Path | Owner | Notes |
|---|---|---|
| `$DSH_HOME/settings.yaml` | this repo (symlink) | live config: the server reads the repo file through the link. One-way — a UI settings write replaces the link, so it does not come back here |
| `$DSH_HOME/.env` | the machine | seeded from `.env.example`, mode 600, gitignored |
| `$DSH_HOME/.credentials.yaml` | the Web UI Models page | written by dsh, outside the repo |
| `$DSH_HOME/skills/` | symlinks from `install.sh` | one entry per `skills/<name>/` |
| `$DSH_HOME/profiles/` | dsh runtime | per-profile bundles; delete one to let it re-initialize |
| `$DSH_HOME/.agent-presets/<id>/` | hand-authored presets | never edit a shipped preset — an upgrade overwrites it |

`DSH_HOME` overrides the `~/.dsh` default; `install.sh` and `doctor.sh` both honour it.

# Related

[../conventions/settings-symlink.md](../conventions/settings-symlink.md) · [credential-resolution.md](credential-resolution.md) · [../../docs/modes.md](../../docs/modes.md)
