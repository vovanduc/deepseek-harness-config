---
type: index
title: Knowledge base — deepseek-harness-config
description: Entry point for durable knowledge (OKF v0.1) about this dsh configuration repo. Read this before touching config.
tags: [okf, index]
---
# Knowledge base

Durable knowledge about this repo. Three layers, kept apart:

- **State** — "where are we": `feature_list.json`, `progress.md`, `session-handoff.md`.
- **Design intent** — "what we meant for one feature": `docs/specs/`, `docs/plans/`.
- **Knowledge** — "what the system is": this bundle.

## Start here

- New machine → [runbooks/new-machine-setup.md](runbooks/new-machine-setup.md)
- Change `settings.yaml` → [systems/opencode-go-route.md](systems/opencode-go-route.md) · [systems/credential-resolution.md](systems/credential-resolution.md)
- Add a model or provider → [runbooks/add-model-or-provider.md](runbooks/add-model-or-provider.md)
- Verify before claiming done → [runbooks/verify-change.md](runbooks/verify-change.md)
- CI is red, or wondering what CI covers → [runbooks/ci-verification.md](runbooks/ci-verification.md)
- Something is broken → [gotchas/](gotchas/index.md)
- Why is it built this way → [decisions/](decisions/index.md)

## Categories

- [conventions/](conventions/index.md) — rules this repo follows
- [decisions/](decisions/index.md) — ADRs: decision + reason + trade-off
- [systems/](systems/index.md) — routes, credential layers, `$DSH_HOME` layout
- [domain/](domain/index.md) — dsh vocabulary
- [runbooks/](runbooks/index.md) — operational procedures
- [gotchas/](gotchas/index.md) — non-obvious traps

Read/write rules: `AGENTS.md` → End of Session → Knowledge Flush. Change history: [log.md](log.md).
