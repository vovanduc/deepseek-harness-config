# CI verification gate — plan

- **Feature:** `feat-003`
- **Spec:** [docs/specs/2026-09-10-ci-verification-design.md](../specs/2026-09-10-ci-verification-design.md)
- **REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` — **not installed in this session**; tasks are executed inline, each as implement → verify. Same for `verification-before-completion` (its content is mirrored by the Definition of Done in `AGENTS.md`).
- **Isolation:** direct on `main` (see the spec's decision table); the repo has no branch/PR convention and the change is one additive workflow.

## Task 1 — Pin Node

- [ ] Add `.nvmrc` containing `22`.
- [ ] Verify: `node --version` major matches, and `actions/setup-node` will read the file.

## Task 2 — The workflow

- [ ] Add `.github/workflows/verify.yml`: `push` + `pull_request`, one `ubuntu-latest` job, steps checkout → setup-node (`node-version-file`) → setup-python 3.12 → `pip install pyyaml` → `./init.sh`.
- [ ] Verify: parse as YAML; assert triggers, the run step, and that `secrets.` never appears.

## Task 3 — Close the gap in the gate

- [ ] Add a step to `init.sh`: the workflow exists, invokes `./init.sh`, installs PyYAML, references no `secrets.`, and parses as YAML when a parser is available.
- [ ] Verify positive: `./init.sh` green.
- [ ] Verify negative: temporarily replace the workflow (no `./init.sh` step, then no PyYAML step) → the gate must fail each time; restore after.

## Task 4 — README

- [ ] Add the workflow badge and the `.github/workflows/verify.yml` line to the layout tree.
- [ ] Verify: badge path matches the workflow file name.

## Task 5 — Knowledge (OKF)

- [ ] Add `knowledge/runbooks/ci-verification.md`; link from `runbooks/index.md` and `knowledge/index.md`; append to `knowledge/log.md`.
- [ ] Verify: link check reports 0 broken.

## Task 6 — Definition of Done and ship

- [ ] Record evidence in `feature_list.json` (`feat-003` → done), update `progress.md` and `session-handoff.md`.
- [ ] Commit and push.
- [ ] Verify remotely: `gh run list --workflow=verify.yml` shows a green run for this commit.

## Definition of Done (from AGENTS.md)

Implemented · verified in this session with real output · evidence recorded · `./init.sh` green ·
runtime pinned (`.nvmrc` + `dsh.version`) · durable knowledge written.
