---
type: convention
title: Real credentials never enter the repo
description: settings.yaml stores only the environment-variable NAME (apiKeyEnv); values live in ~/.dsh/.env, ~/.dsh/.credentials.yaml, or the launch environment — all outside git.
tags: [security, credentials]
---
# Rule

- `settings.yaml` records `apiKeyEnv: <NAME>`, never a value.
- `.gitignore` blocks `.env`, `.credentials.yaml`, `*.local.yaml`, `*.bak`.
- Uncommitted local notes go in `AGENTS.local.md` / `CLAUDE.local.md` (loaded as additive overlays).

# Why

The repo is public-shaped (GitHub) and now symlinked live on every machine: a leaked key would also be a working key everywhere, and rotating it would mean rotating every clone.

# Check before committing

`git diff --cached --name-only` must not list `.env`, and a staged diff must not contain `sk-`.

# Related

[../systems/credential-resolution.md](../systems/credential-resolution.md) · [../../.env.example](../../.env.example)
