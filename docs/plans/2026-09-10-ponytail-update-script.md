# Ponytail skill update script — plan

- **Feature:** `feat-004`
- **Spec:** [docs/specs/2026-09-10-ponytail-update-script-design.md](../specs/2026-09-10-ponytail-update-script-design.md)
- **REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` — **not installed in this session**; tasks run inline, each as implement → verify.
- **Isolation:** direct on `main` (one new script; repo convention is commit-then-publish).

## Task 1 — The script

- [x] `scripts/update-ponytail.sh`: `UPSTREAM_REPO`/`UPSTREAM_REF` pin, `--apply`, `--ref`, `--help`, tarball download into a trap-cleaned temp dir, `cmp`-based report, exit 0/1/2.
- [x] Verify: `bash -n`, `shellcheck -S warning`.

## Task 2 — Prove it end to end

- [x] Plain run at the pin → all six skills + LICENSE identical, exit 0.
- [x] `--ref v4.8.4` → drift reported for `ponytail` and `ponytail-help`, exit 1.
- [x] `--apply --ref v4.8.4` → files really change; then `git checkout -- skills` to revert and confirm clean.
- [x] `--ref does-not-exist` → exit 2, tree untouched.

## Task 3 — Documentation

- [x] `skills/README.md`: replace the hand-copy instruction with the script, and stop hardcoding the version.
- [x] `knowledge/runbooks/update-ponytail-skills.md` + `runbooks/index.md` + `knowledge/log.md`.
- [x] Verify: link check 0 broken.

## Task 4 — Definition of Done and ship

- [x] `./init.sh` green (it lints the new script automatically).
- [x] `feature_list.json` `feat-004` → done with evidence; `progress.md` + `session-handoff.md` updated.
- [x] Commit and push; confirm the CI run for the commit is green.

## Definition of Done (from AGENTS.md)

Implemented · verified in this session with real output · evidence recorded · `./init.sh` green ·
runtime pinned · durable knowledge written.
