---
type: convention
title: settings.yaml is symlinked into $DSH_HOME, never copied
description: install.sh links the repo file as $DSH_HOME/settings.yaml, so the running server reads and writes this repo's file.
tags: [dsh, install, settings]
timestamp: 2026-09-10T08:37:00Z
---
# Rule

- `install.sh` symlinks `settings.yaml` to `$DSH_HOME/settings.yaml`; it never copies it (`DSH_HOME` defaults to `~/.dsh`).
- Treat the repo file as the live config: edits made in the Web UI land here and are ready to `git commit`.
- Edit the repo file, not `~/.dsh/settings.yaml` — they are the same inode.

# Why

The running server reads the symlink target, so a repo edit applies to the next request without a restart, and settings changed in the UI are captured by git instead of drifting on one machine.

# Notes

- A pre-existing regular file is moved aside to `*.bak-<timestamp>` before the link is made.
- `dsh --profile headless --dump-config` composes whatever `$DSH_HOME/settings.yaml` resolves to.

# Related

[../systems/dsh-home-layout.md](../systems/dsh-home-layout.md) · [../runbooks/new-machine-setup.md](../runbooks/new-machine-setup.md)
