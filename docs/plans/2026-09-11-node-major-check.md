# Node major check — plan

- **Feature:** `feat-008`
- **Spec:** [docs/specs/2026-09-11-node-major-check-design.md](../specs/2026-09-11-node-major-check-design.md)
- **REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` — **not installed**; tasks run inline.
- **Isolation:** direct on `main`.

## Task 1 — The check

- [x] `scripts/check-node.sh`: read `node --version` and `.nvmrc`, compare majors, exit 0/1/2.
- [x] Verify: `bash -n`, `shellcheck -S warning`, `./scripts/check-node.sh`.

## Task 2 — Prove the branches

- [x] Real node → `ok`, exit 0.
- [x] Fake `node` `v18.20.0` on PATH first → `FAIL`, exit 1, names the floor and the pin.
- [x] Fake `node` `v24.1.0` → `warn`, exit 0.
- [x] `install.sh` with the fake v18 node → dies before touching `$DSH_HOME` (assert nothing written).

## Task 3 — Wire it

- [x] `install.sh` calls it early and `die`s on failure.
- [x] `init.sh` wiring guard (exists, executable, still called).
- [x] Verify: positive `./init.sh`; negative tests (drop the call, drop `+x`) then restore.

## Task 4 — Docs and Definition of Done

- [x] README layout entry; `knowledge/runbooks/new-machine-setup.md` + `knowledge/log.md`.
- [x] `./init.sh` green, audit 100/100, `feature_list.json` + `progress.md` + `session-handoff.md` updated.
- [x] Commit, push, CI green, session closed.

## Definition of Done (from AGENTS.md)

Implemented · verified with real output · evidence recorded · `./init.sh` green · pinned runtime · knowledge written.
