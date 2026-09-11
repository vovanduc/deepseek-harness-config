# Session Handoff

## Current Objective

- Goal: make the dsh plugin set reproducible from git, then stop an incompatible plugin from ever reaching a profile.
- Current status: complete — `feat-001` … `feat-004`, `feat-006` and `feat-007` are `done`; repo clean and pushed.
- Branch / commit: `main` @ `295a655` (feat-007), with the evidence commit on top.

## Completed This Session

- [x] `plugins.json` — the plugin set, version-pinned, with `source` provenance.
- [x] `scripts/install-plugins.sh` — reconciles each profile against the manifest; `--dry-run`, `--skip-preflight`.
- [x] `scripts/plugin-preflight.sh` — refuses a plugin the pinned dsh cannot run, from its published manifest.
- [x] `install.sh` calls the applier after the skills step; `init.sh` guards the manifest and the whole wiring chain.
- [x] `dsh-mermaid@0.4.0` installed and **verified in the browser** (SVG, Code/Diagram toggle, fullscreen, Download SVG).
- [x] `dsh-diagram@0.4.0` removed after the restart proved it kills the web boot; the trap is recorded and now caught by the pre-flight.
- [x] `docs/plugins.md` + `knowledge/runbooks/dsh-plugins.md` + the two plugin gotchas.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Offline gate | `./init.sh` | exit 0 | 6 scripts, 7 features, 1 plugin pinned, pre-flight + CI wiring, shellcheck |
| Manifest guards | mutate `plugins.json` / `install.sh`, run `./init.sh` | exit 1 (×5) | `@latest`, `^range`, duplicate, missing field, dropped call |
| Pre-flight fixtures | `./scripts/plugin-preflight.sh …` | 0 / 1 / 1 | mermaid ok; diagram names the omitted release; `--dsh-version 0.1.1-rc.2` fails on inject alone |
| Pre-flight end-to-end | `dsh-diagram` temporarily back in `plugins.json`, run the applier | exit 1, profile untouched | `dependencies` still `['dsh-mermaid']`; no `node_modules/dsh-diagram` |
| Escape hatch | `./scripts/install-plugins.sh --dry-run --skip-preflight` | `would add` | deliberate override works |
| Pre-flight guards | drop the call / remove `+x`, run `./init.sh` | exit 1 (×2) | restored byte-identical |
| Harness audit | `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` | 100/100 | bottleneck: none |
| Machine check | `./scripts/doctor.sh` | `status: READY (6 ok, 0 warn)` | live inference `deepseek-flash -> 200` |
| Knowledge links | link check over `knowledge/**` + docs | 0 broken | |

**Verified in the browser earlier this session** (after the restart this handoff previously asked for):
`dsh-mermaid` rendered a ```mermaid fence — SVG with 3 nodes and 7 labels, Code/Diagram toggle
round-trips, Fullscreen (zoom 285% / Fit / Close), Download SVG → `mermaid-flowchart.svg` (13,379 B).

## Files Changed

- `plugins.json`, `scripts/install-plugins.sh`, `scripts/plugin-preflight.sh`
- `install.sh`, `init.sh`
- `docs/plugins.md`
- `docs/specs/2026-09-11-plugins-manifest-design.md`, `docs/plans/2026-09-11-plugins-manifest.md`
- `docs/specs/2026-09-11-plugin-preflight-design.md`, `docs/plans/2026-09-11-plugin-preflight.md`
- `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/dsh-mermaid-npm-name-collision.md`, `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md`, `knowledge/index.md`, `knowledge/log.md`, category indexes
- `README.md`, `feature_list.json`, `progress.md`, `session-handoff.md`

## Decisions Made

- Plugins are declared in `plugins.json`; the profile directory is machine-local and never committed → `knowledge/runbooks/dsh-plugins.md`
- A version pin is not a compatibility guarantee: the pre-flight blocks, and the browser confirms → `docs/specs/2026-09-11-plugin-preflight-design.md`
- Fail closed on an unverifiable source (a git spec cannot be pre-flighted) with `--skip-preflight` as the explicit override
- The pre-flight reads metadata only and never executes plugin code; it cannot see a bare service name that lives in compiled client code
- npm `dsh-mermaid@0.4.0` (MrmoLabs) over `AKS1st/dsh-mermaid` v0.5.0 → `knowledge/gotchas/dsh-mermaid-npm-name-collision.md`
- `./init.sh` stays offline; plugin, pre-flight and ponytail syncs need network and stay out of CI

## Blockers / Risks

- None blocking.
- `dsh-diagram` stays out until a release lists dsh 0.1.5 in `dsh.compatibility.dshReleases`; there is no `/`-menu `canvas-diagram` entry today.
- `scripts/install-plugins.sh` only adds: removing an entry from `plugins.json` does not uninstall it, so removal is two steps (`dsh plugin … remove` plus the manifest edit).
- The pre-flight is a filter, not a proof; after any plugin change, still check the browser (the running-server recipe is in `docs/plugins.md`).
- Third-party plugin code is not audited here; pins and provenance are, and the sandbox confines writes only.
- `superpowers:*` skills are still not installed, so specs/plans are written by hand (noted in each spec).
- `feat-005` remains queued; `install.sh` still does not check the Node major (a candidate feature).

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `feature_list.json` and `progress.md`.
3. Review this handoff.
4. Run `./init.sh` before editing — CI runs the same gate on push.

## Recommended Next Step

- Take `feat-005`: give `scripts/doctor.sh` a `--json` mode with stable keys so `init.sh`, CI, or a setup script can consume readiness instead of parsing coloured text.
