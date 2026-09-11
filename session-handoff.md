# Session Handoff

## Current Objective

- Goal: finish the backlog — machine-readable readiness (`feat-005`) and a Node baseline check (`feat-008`) — then close the session.
- Current status: complete. **The backlog is empty**: `feat-001` … `feat-008` are all `done`; repo clean and pushed.
- Branch / commit: `main` @ this turn's feature commit, with the evidence commit on top.

## Completed This Session

- [x] `feat-005` — `scripts/doctor.sh --json`: one object (`status`, `ok`, `warn`, `fail`, `checks[]` of `id`/`status`/`message`), identical verdict and exit code to the coloured report.
- [x] `feat-008` — `scripts/check-node.sh`: Node 20 floor from `.nvmrc`, warn on a divergent major, called by `install.sh` before it creates anything.
- [x] `init.sh` guards both wirings (script present, executable, still called).
- [x] `docs/troubleshooting.md`, `knowledge/runbooks/verify-change.md`, `knowledge/runbooks/new-machine-setup.md`, `README.md`, `knowledge/log.md` updated.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Offline gate | `./init.sh` | exit 0 | 7 scripts, 8 features, 1 plugin pinned, pre-flight + Node + CI wiring, shellcheck |
| doctor human | `./scripts/doctor.sh` | exit 0, `READY (6 ok, 0 warn)` | output unchanged |
| doctor JSON | `./scripts/doctor.sh --json` | exit 0, one object | 0 ANSI escapes; key set exact; per-check `id`/`status`/`message` |
| doctor negative | `DSH_HOME=/tmp/no-such ./scripts/doctor.sh [--json]` | exit 1, `NOT_READY` | complete object (`cli` ok, `settings` fail) |
| Node real | `./scripts/check-node.sh` | exit 0 | node 22.22.2 matches `.nvmrc` 22 |
| Node old | fake `node` `v18.20.0` first on PATH | exit 1 | names the Node 20 floor and the pin |
| Node newer | fake `node` `v24.1.0` | exit 0, warn | diverges from the pin but is not broken |
| install.sh guard | v18 fake + `DSH_HOME=/tmp/checknode-dsh`, `./install.sh --no-install` | exit 1 | **nothing created** — step 0 precedes every write |
| Wiring guards | drop the call / drop `+x`, run `./init.sh` | exit 1 (×2) | restored byte-identical |
| Harness audit | `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` | 100/100 | bottleneck: none |
| Machine check | `./scripts/doctor.sh` | `status: READY (6 ok, 0 warn)` | live inference `deepseek-flash -> 200` |
| Knowledge links | link check over `knowledge/**` + docs | 0 broken | |

## Files Changed

- `scripts/doctor.sh`, `scripts/check-node.sh`
- `install.sh`, `init.sh`
- `docs/troubleshooting.md`
- `docs/specs/2026-09-11-doctor-json-design.md`, `docs/plans/2026-09-11-doctor-json.md`
- `docs/specs/2026-09-11-node-major-check-design.md`, `docs/plans/2026-09-11-node-major-check.md`
- `knowledge/runbooks/verify-change.md`, `knowledge/runbooks/new-machine-setup.md`, `knowledge/log.md`
- `README.md`, `feature_list.json`, `progress.md`, `session-handoff.md`

## Decisions Made

- `doctor.sh --json` buffers instead of printing live, so the human report stays byte-identical while `--json` stays pipeable → `docs/specs/2026-09-11-doctor-json-design.md`
- The check ids (`cli`, `settings`, `compose`, `credential`, `inference`, `skills`) are a small public contract; `compose` is absent when `dsh` is not on PATH
- A newer Node warns rather than fails — the hard floor is 20, `.nvmrc` is the verified major → `docs/specs/2026-09-11-node-major-check-design.md`
- The Node check lives in its own script so every branch is testable with a fake `node`, without running `install.sh`

## Blockers / Risks

- None blocking, and no open features.
- `dsh-diagram` stays out until a release lists dsh 0.1.5 in `dsh.compatibility.dshReleases`; there is no `/`-menu `canvas-diagram` entry today.
- The pre-flight is a metadata filter, not a proof; after any plugin change, still check the browser (the running-server recipe is in `docs/plugins.md`).
- `scripts/install-plugins.sh` only adds: removing an entry from `plugins.json` does not uninstall it, so removal is two steps.
- Third-party plugin code is not audited here; pins and provenance are, and the sandbox confines writes only.
- `superpowers:*` skills are still not installed, so specs/plans are written by hand (noted in each spec).

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `feature_list.json` and `progress.md`.
3. Review this handoff.
4. Run `./init.sh` before editing — CI runs the same gate on push.

## Recommended Next Step

- No feature is queued. The candidates worth taking first are in `progress.md` → What's Next: (1) consume `doctor.sh --json` from a script or an `init.sh` passthrough, (2) a mock-boot check for the compiled-only plugin failures the pre-flight admits it cannot see, (3) one of the official host-only subagent bundles, which needs a preset tool row.
