---
type: decision
title: This repo hosts the teammates product, not only config
description: Scope expanded 2026-10-07 — the repo keeps its config deliverable AND carries the Grok-Bot-style product (bot supervisor, per-bot profiles) built on dsh.
tags: [repo, scope, product]
---
# Decision

The repo holds two scopes from `feat-016` onward:

- **Config** (the original deliverable): `settings.yaml`, `skills/`, `install.sh`, `scripts/doctor.sh`, pinned plugins — reproducible machine state.
- **Product**: the Grok-Bot-style teammates work — supervisor, per-bot ACP profiles, and later containers. Design intent in `docs/specs|plans`, research in `docs/research/`, ADR in [dsh-as-teammates-engine.md](dsh-as-teammates-engine.md).

# Why

Owner chose co-location (2026-10-07): the product *is* a dsh configuration problem at its core — per-bot `cordis.patch.yml`, provider routes, plugin sets — and the OKF bundle + harness here already serve it. Splitting early would duplicate the state machinery.

# Trade-off

`AGENTS.md` used to promise "no application code" — now false. If product code grows heavier than config (likely), revisit splitting `product/` into its own repo; the prior `experiments/` scope question in `progress.md` is the same boundary issue.

# Related

[dsh-as-teammates-engine.md](dsh-as-teammates-engine.md) · [../../AGENTS.md](../../AGENTS.md)
