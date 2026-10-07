---
type: gotcha
title: Sessions and storages live at $DSH_HOME, keyed by workspace — not by profile
description: Every profile under one DSH_HOME shares one session store and one storage root; sessions are partitioned by the encoded cwd. Per-bot isolation needs a separate DSH_HOME or a separate workspace.
tags: [dsh, sessions, isolation, multi-bot]
---
# Fact

`session-persistence-jsonl` config is `root: dshHomePath('sessions')` and `storage-json` is `dshHomePath('storages')` — both **per-`DSH_HOME`**, with no profile component. On disk:

```
~/.dsh/sessions/--Users-vovanduc-Code-deepseek-harness-config--/session-<uuid>/
```

Sessions are namespaced by the **workspace directory** the agent was launched in, shared by every profile booted under that home. `session/list` over ACP accepts a `cwd` filter for exactly this reason.

# Rule

- Two profiles, same `DSH_HOME`, same workspace → they see each other's sessions.
- Two profiles, different workspaces → natural partition (the `cwd` filter resolves physical-directory identity).
- Real per-bot isolation → **`DSH_HOME` per bot** (env var; `install.sh`/`doctor.sh` honour it). Cheap: it also separates `credentials`, `settings`, and `storages`.

# Verified

2026-10-07, `0.1.5-rc.1`: dump-config shows the two roots above; `ls ~/.dsh/sessions` shows workspace-keyed directories only.

# Related

[../systems/dsh-home-layout.md](../systems/dsh-home-layout.md) · [../systems/acp-surface.md](../systems/acp-surface.md)
