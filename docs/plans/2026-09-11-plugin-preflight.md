# Plugin pre-flight compatibility — plan

- **Feature:** `feat-007`
- **Spec:** [docs/specs/2026-09-11-plugin-preflight-design.md](../specs/2026-09-11-plugin-preflight-design.md)
- **REQUIRED SUB-SKILL:** `superpowers:subagent-driven-development` — **not installed in this session**; tasks run inline, each as implement → verify.
- **Isolation:** direct on `main`. The working tree also carries the previous session's uncommitted `dsh-diagram` removal; that is committed first, separately, so this feature lands on a clean base.

## Task 1 — The pre-flight script

- [x] `scripts/plugin-preflight.sh`: pinned-spec check, `npm view … dsh` manifest, compatibility map lookup, client-inject resolution against the pinned install, `--dsh-version`, exit 0/1/2.
- [x] Verify: `bash -n`, `shellcheck -S warning`, `--help`.

## Task 2 — Prove it against the real regression

- [x] `dsh-mermaid@0.4.0` → exit 0.
- [x] `dsh-diagram@0.4.0` → exit 1 naming the missing release **and** the unresolved inject id.
- [x] `dsh-diagram@0.4.0 --dsh-version 0.1.1-rc.2` → exit 1 via check B alone.
- [x] unpinned spec → exit 2; unresolvable spec → exit 1.

## Task 3 — Wire it into the applier

- [x] `install-plugins.sh` pre-flights before `add`; a failure is skipped and counted; `--skip-preflight` overrides; `--dry-run` prints the verdict.
- [x] `init.sh` guard: script present + executable, and still called by `install-plugins.sh`.
- [x] Verify: positive run; negative tests (drop the call, drop the script) then restore.

## Task 4 — Documentation

- [x] `docs/plugins.md` + `knowledge/runbooks/dsh-plugins.md`: the pre-flight, what it cannot see, the override.
- [x] `knowledge/log.md` entry.
- [x] Verify: link check 0 broken.

## Task 5 — Definition of Done and ship

- [x] `./init.sh` green; harness audit 100/100.
- [x] `feature_list.json` `feat-007` → done with evidence; `progress.md` + `session-handoff.md` updated.
- [x] Commit both changes together — the working tree already carried the previous session's uncommitted `dsh-diagram` removal, and the two are one story (installable *and* runnable); push; CI green.

## Definition of Done (from AGENTS.md)

Implemented · verified in this session with real output · evidence recorded · `./init.sh` green ·
runtime pinned · durable knowledge written.
