# Session Handoff

## Current Objective

- Goal: make the dsh **plugin set** reproducible from git, seeded with `dsh-mermaid` (and, until the first UI restart proved otherwise, `dsh-diagram`).
- Current status: complete — `feat-001` … `feat-004` and `feat-006` are `done`; the plugin set was amended after its first restart; repo clean and pushed.
- Branch / commit: `main` @ `afd7cea` (feat-006), with the evidence commit on top.

## Completed This Session

- [x] `plugins.json` — the plugin set, version-pinned, with `source` provenance.
- [x] `scripts/install-plugins.sh` — compares each profile's `dependencies` and applies the difference via `dsh plugin … add`; `--dry-run` plans only.
- [x] `install.sh` calls the applier after the skills step (a failure warns, it does not abort).
- [x] `init.sh` guards the manifest (exact pins, no duplicates, required fields) and the `install.sh` wiring.
- [x] Installed `dsh-mermaid@0.4.0` into the `web` profile; verified the layer with `--dump-default-config`.
- [x] Restarted the `web` profile non-interactively and checked the browser: `dsh-mermaid` renders (SVG, Diagram/Code toggle, fullscreen, Download SVG).
- [x] `dsh-diagram@0.4.0` removed after that restart — its client half needs a `conversationEvents` service the pinned dsh does not have, and it killed the whole web boot. Entry dropped from `plugins.json`, trap recorded.
- [x] `docs/plugins.md` + `knowledge/runbooks/dsh-plugins.md` + `knowledge/gotchas/dsh-mermaid-npm-name-collision.md` + `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md`.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Offline gate | `./init.sh` | exit 0 | 5 scripts, 6 features, 1 plugin pinned, CI wiring, shellcheck |
| Manifest guards | mutate `plugins.json` / `install.sh`, run `./init.sh` | exit 1 (×5) | `@latest`, `^range`, duplicate, missing field, dropped call |
| Plugin install | `./scripts/install-plugins.sh` | exit 0, `2 added` | both plugins went in; `dsh-diagram` was removed again after the restart below |
| Plugin layers | `dsh --profile web --dump-default-config` | `# == dsh-mermaid` | the dump proved the layer, not that it loads |
| Idempotency | `./scripts/install-plugins.sh` (re-run) | `0 added, 1 already installed` | pins exact, so a bump re-applies |
| Harness audit | `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` | 100/100 | bottleneck: none |
| Machine check | `./scripts/doctor.sh` | `status: READY (6 ok, 0 warn)` | live inference `deepseek-flash -> 200` |
| Knowledge links | link check over `knowledge/**` + docs | 0 broken | |

**Now verified** (2026-09-11, after the restart this handoff asked for):

- `dsh-mermaid`: a ```mermaid fence rendered in the browser — SVG with 3 nodes (Tải đơn → Duyệt →
  Gửi hàng) and 7 labels, Code/Diagram toggle round-trips, Fullscreen (zoom 285% / Fit / Close),
  Download SVG → `mermaid-flowchart.svg` (13,379 B).
- `dsh-diagram`: **cannot run**. Its layer composed, but the client entry never activated
  (`dsh-diagram: pending (waiting for service: conversationEvents)`) and the UI died with
  `Failed to load plugins`. `conversationEvents` does not exist in dsh 0.1.5-rc.1. Removed from the
  profile and from `plugins.json`; there is no `/`-menu `canvas-diagram` entry.
- The restart did **not** end the session (it ran in an `omp` session, not inside `dsh web`).

## Files Changed

- `plugins.json`, `scripts/install-plugins.sh`
- `install.sh`, `init.sh`
- `docs/plugins.md`, `docs/specs/2026-09-11-plugins-manifest-design.md`, `docs/plans/2026-09-11-plugins-manifest.md`
- `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/dsh-mermaid-npm-name-collision.md`, `knowledge/index.md`, `knowledge/log.md`, category indexes
- `README.md`, `feature_list.json`, `progress.md`, `session-handoff.md`

## Decisions Made

- Plugins are declared in `plugins.json`; the profile directory is machine-local and never committed → `knowledge/runbooks/dsh-plugins.md`
- npm `dsh-mermaid@0.4.0` (MrmoLabs) over `AKS1st/dsh-mermaid` v0.5.0 — no `prepare` build, so no machine-local `allowBuilds` edit → `knowledge/gotchas/dsh-mermaid-npm-name-collision.md`
- The applier warns rather than aborts in `install.sh`, matching how the doctor is treated
- `./init.sh` stays offline; plugin and ponytail syncs need network and stay out of CI

## Blockers / Risks

- None blocking.
- The plugins are on disk but **not live** until the `web` profile restarts.
- `scripts/install-plugins.sh` only adds: removing an entry from `plugins.json` does not uninstall it, so removal is two steps (`dsh plugin … remove` plus the manifest edit).
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
