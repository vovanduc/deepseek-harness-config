---
type: convention
title: settings.yaml is symlinked into $DSH_HOME, never copied
description: install.sh links the repo file as $DSH_HOME/settings.yaml so the server READS this repo's file. The write path is the opposite — a UI settings change replaces the link with a standalone file, and that file never reaches the repo.
tags: [dsh, install, settings]
timestamp: 2026-09-10T08:37:00Z
---
# Rule

- `install.sh` symlinks `settings.yaml` to `$DSH_HOME/settings.yaml`; it never copies it (`DSH_HOME` defaults to `~/.dsh`).
- **The direction is one-way.** The server *reads* the repo file through the link, so a repo edit is live on the next request, no restart. UI writes do **not** travel back: dsh persists with `writeFile` + `rename`, and `rename` replaces the link, so the UI's changes land in a plain `~/.dsh/settings.yaml` and are never committed.
- Therefore: edit the repo file, and after using UI settings panels run `./scripts/doctor.sh` — it fails on a regular file and names the fix.
- To keep a UI-made change (a model pick, a new ack key), read it out of `~/.dsh/settings.yaml` and write it into the repo by hand, then relink. Do not `cp` the live file over the repo one: it also carries app state, and a `vision-toolkit-*` provider id is only valid on the profile that registers it.

# Why

The read direction is the point of the link: one file, live without a restart. The write direction was assumed to mirror it and does not — the app's atomic write is what unlinks it
([../gotchas/settings-symlink-drift.md](../gotchas/settings-symlink-drift.md)). Treat the repo file as the source of truth for *configuration* only; the app also uses it for *state* (`ui-onboarding`, the last model pick), which is why a naive copy-back is wrong.

# Notes

- A pre-existing regular file is moved aside to `*.bak-<timestamp>` before the link is made.
- **The app breaks this link by itself.** Any UI settings write — a model pick, a font size, even dismissing the welcome notice — leaves a regular file behind. Expect to relink; `doctor.sh` requires the arrow and reports whether the drifted file has merely not been used yet or has already diverged.
- The welcome notice is ack'd by writing `ui-onboarding: {welcomeNoticeVersion: <version>}`. It is committed here so the notice does not reappear after every relink; bump it when dsh bumps `WELCOME_NOTICE_VERSION` (`dsh-client-ui-settings-models`).
- `dsh --profile headless --dump-config` composes whatever `$DSH_HOME/settings.yaml` resolves to.

# Related

[../systems/dsh-home-layout.md](../systems/dsh-home-layout.md) · [../runbooks/new-machine-setup.md](../runbooks/new-machine-setup.md)
