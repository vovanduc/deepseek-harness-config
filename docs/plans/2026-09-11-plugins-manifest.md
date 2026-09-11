# Reproducible plugin set — plan

- **Feature:** `feat-006`
- **Spec:** [docs/specs/2026-09-11-plugins-manifest-design.md](../specs/2026-09-11-plugins-manifest-design.md)
- **REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` — **not installed in this session**; tasks run inline, each as implement → verify.
- **Isolation:** direct on `main` (repo convention is commit-then-publish).

## Task 1 — Manifest and applier

- [x] `plugins.json` with the two pinned entries and their `source`.
- [x] `scripts/install-plugins.sh`: parse via node, compare with each profile's `dependencies`, `dsh plugin --profile … add <spec>`, summary, `--dry-run`, exit non-zero when something failed.
- [x] Verify: `bash -n`, `shellcheck -S warning`, `--dry-run` output.

## Task 2 — Wire into install.sh

- [x] Call the applier after the skills step; `--no-install` semantics; warn (not abort) on failure.
- [x] Verify: `bash -n`, and a dry-run path that does not touch the real profiles.

## Task 3 — Guards in init.sh

- [x] Validate `plugins.json`: required fields, pinned specs only, no duplicates.
- [x] Keep the CI-wiring guard; assert `install.sh` still calls `scripts/install-plugins.sh`.
- [x] Verify positive (green) and negative (unpinned spec, duplicate, missing field → fail), then restore.

## Task 4 — Install and verify the two plugins

- [x] Apply the set; assert `dsh --profile web --dump-default-config` shows both bundle layers.
- [x] Re-run: both reported already installed (idempotency).
- [x] Record that rendering needs a profile restart — not performed, because it would end this session.

## Task 5 — Documentation

- [x] `docs/plugins.md`; README tree + "what is configured".
- [x] `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/dsh-mermaid-npm-name-collision.md`, index + log updates.
- [x] Verify: link check 0 broken.

## Task 6 — Definition of Done and ship

- [x] `./init.sh` green; harness audit 100/100.
- [x] `feature_list.json` `feat-006` → done with evidence; `progress.md` + `session-handoff.md` updated.
- [x] Commit, push, confirm the CI run is green.

## Definition of Done (from AGENTS.md)

Implemented · verified in this session with real output · evidence recorded · `./init.sh` green ·
runtime pinned · durable knowledge written.
