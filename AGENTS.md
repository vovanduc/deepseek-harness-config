# AGENTS.md — deepseek-harness-config

This repo is my **DeepSeek Harness (`dsh`) configuration**, kept in git so a second machine starts
in the same state as the first. There is no application code: the deliverable is `settings.yaml`,
`skills/`, `install.sh`, `scripts/doctor.sh`, and the harness files below.

The delivery workflow is the `dcnet-workflow` skill — **superpowers** for the design path
(brainstorm → plan → implement → verify → ship) and the files below for state. Facts that outlive a
session go to `knowledge/` (OKF), never only into chat.

## Startup Workflow

Before writing code or config:

1. `pwd` — confirm the repo root.
2. Read this file.
3. Read `feature_list.json` (the `in-progress` feature) and `progress.md` (cross-session context); read `session-handoff.md` if a larger task is open.
4. Read `knowledge/index.md`, then only the concepts the current task touches.
5. Run `./init.sh` — offline verification. If the baseline fails, repair it before adding scope.
6. `git log --oneline -5`.

## Working Rules

- **One feature at a time**: pick exactly one `not-started` feature from `feature_list.json`, set it `in-progress`; never two.
- **Stay in scope**: change only what the active feature needs; an unrelated fix becomes its own feature entry.
- **Verification required**: no "done" claim without running the verification in this session.
- **State lives in files, never only in chat**: `feature_list.json`, `progress.md`, `session-handoff.md`.
- **Leave clean state**: the next session must be able to run `./init.sh` immediately.

## Required Artifacts

- `feature_list.json` — feature state (source of truth)
- `progress.md` — session continuity log
- `init.sh` — standard startup + verification path
- `session-handoff.md` — handoff for larger sessions
- `knowledge/` — OKF knowledge bundle; `knowledge/index.md` is the entry point
- `docs/specs/` and `docs/plans/` — design intent for a single feature

## Definition of Done

A feature is done only when ALL of these are true:

- [ ] The target behavior is implemented.
- [ ] Verification actually ran in this session (real command + output).
- [ ] Evidence is recorded in `feature_list.json` and/or `progress.md`.
- [ ] `./init.sh` still passes from a clean checkout.
- [ ] The environment stays reproducible: `dsh` is pinned in `dsh.version`, and nothing depends on local machine state.
- [ ] Durable knowledge is in `knowledge/`, or `knowledge/log.md` records that there was none.

## Verification Commands

```bash
./init.sh                      # offline gate: bash -n, JSON, YAML, skills, shellcheck
./init.sh --with-doctor        # adds scripts/doctor.sh (needs a live credential)
./scripts/doctor.sh            # machine check: CLI, settings, key, live inference
node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .   # harness audit
```

`./init.sh` is the fast gate and must pass with no credential and no network. `doctor.sh` is the
machine-level check for the model route.

## End of Session

Before ending a session:

1. Update `progress.md` (Current State, What's Done, What's Next, blockers).
2. Update `feature_list.json`: status plus `evidence`.
3. Knowledge Flush: walk the `knowledge/` checklist, write concepts, or record "no new knowledge" in `knowledge/log.md`.
4. Write `session-handoff.md` when the task is large or unfinished.
5. Commit in a safe state and push, so the repo restarts from `./init.sh` on any machine.

## Escalation

- Architecture or route changes → read `knowledge/decisions/` first, then ask.
- Ambiguous scope → re-read the feature entry and `docs/specs/` · `docs/plans/`.
- Repeated verification failures → update `progress.md` and flag for human review.
- Never commit a real key: credentials live outside the repo (see `knowledge/conventions/secrets-never-committed.md`).
