---
type: decision
title: Adopt the DCNET harness and an OKF knowledge bundle
description: This repo tracks delivery state in feature_list.json/progress.md/init.sh and durable knowledge in knowledge/ (OKF) instead of keeping process in chat or only in a global skill.
tags: [process, harness, okf]
timestamp: 2026-09-10T08:37:00Z
---
# Decision

- **State** — `feature_list.json` (status + evidence), `progress.md` (cross-session), `init.sh` (gate), `session-handoff.md` (large tasks).
- **Design intent** — `docs/specs/` and `docs/plans/`, deliberately not `docs/superpowers/`.
- **Knowledge** — `knowledge/` bundle, OKF v0.1 (markdown + `type` frontmatter, links as graph).
- **Routing** — `AGENTS.md`, which dsh injects automatically.

# Context

The repo is configuration, not application code. Its real risk is drift: a second machine that behaves differently, and a second session that re-derives decisions already made. The `dcnet-workflow` skill supplies the process but holds no repo state.

# Alternatives considered

- **Process only in the global skill** — rejected: every session starts greenfield and nothing records what was verified.
- **Knowledge inside `docs/`** — rejected: `docs/` is user-facing explanation; OKF keeps durable facts separate, typed, and progressively discoverable.

# Consequences

- Every feature ends by updating `feature_list.json` + `progress.md` and doing a Knowledge Flush.
- `./init.sh` is the baseline; a red baseline is repaired before new scope.
- DoD item 6 (knowledge recorded) is deliberately soft — it never blocks a merge.
- The cost is upkeep: these files are wrong the moment they are stale, so they are updated as part of DoD, not "later".

# Related

[../../AGENTS.md](../../AGENTS.md) · [pin-dsh-version.md](pin-dsh-version.md) · [init-stays-offline.md](init-stays-offline.md)
