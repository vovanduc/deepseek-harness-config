# doctor.sh --json — plan

- **Feature:** `feat-005`
- **Spec:** [docs/specs/2026-09-11-doctor-json-design.md](../specs/2026-09-11-doctor-json-design.md)
- **REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` — **not installed**; tasks run inline.
- **Isolation:** direct on `main`.

## Task 1 — Record and emit

- [x] `record <status> <id> <message>`: counts, buffers, prints live only in human mode.
- [x] `finish`: human summary as today, or one JSON object via `node`; same exit code.
- [x] Every check call site gains an id (`cli`, `settings`, `compose`, `credential`, `inference`, `skills`); the early settings-missing return goes through `finish`.
- [x] Verify: `bash -n`, `shellcheck -S warning`.

## Task 2 — Prove both modes agree

- [x] Human run unchanged, exit 0.
- [x] `--json` → one object, `json.tool` accepts it, no ANSI, key set exact.
- [x] Counts/status/exit match the human run.
- [x] `DSH_HOME=/tmp/missing` → `NOT_READY` + exit 1 in both modes, JSON still complete.
- [x] `--help` exit 0; bad flag exit 2.

## Task 3 — Docs

- [x] `docs/troubleshooting.md` (or the runbook that mentions doctor): the `--json` contract.
- [x] `knowledge/runbooks/verify-change.md` + `knowledge/log.md`.
- [x] Link check.

## Task 4 — Definition of Done

- [x] `./init.sh` green, audit 100/100, `feature_list.json` + `progress.md` updated, commit and push, CI green.

## Definition of Done (from AGENTS.md)

Implemented · verified with real output · evidence recorded · `./init.sh` green · pinned runtime · knowledge written.
