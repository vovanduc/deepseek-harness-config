# Session Progress Log

## Current State

**Last Updated:** 2026-09-11 11:00 (+07)
**Active Feature:** none — `feat-006` completed and amended after its first UI restart; next session picks `feat-005`
**Repo:** `deepseek-harness-config` @ `main`
**Harness:** adopted 2026-09-10 (`AGENTS.md`, `feature_list.json`, `progress.md`, `init.sh`, `session-handoff.md`, `docs/specs|plans`, `knowledge/`)

## Status

### What's Done

- [x] Adopted the DCNET harness: state files, `docs/specs/` + `docs/plans/`, and `AGENTS.md` as the routing pointer.
- [x] `init.sh` — offline gate (`bash -n`, feature-list shape, `settings.yaml` parse + default-model resolution, skill frontmatter, plugin manifest, CI wiring, shellcheck).
- [x] OKF `knowledge/` bundle: index + log + six category indexes + 24 concepts.
- [x] `feat-003`: `.github/workflows/verify.yml` runs `./init.sh` on push and pull request; `.nvmrc` pins Node 22; README badge.
- [x] `feat-004`: `scripts/update-ponytail.sh` — drift check and `--apply` against a pinned upstream ref.
- [x] `feat-006`: `plugins.json` + `scripts/install-plugins.sh` make the plugin set reproducible; `dsh-mermaid@0.4.0` is installed **and live** on the `web` profile.
- [x] `feat-006` amended after the first restart: `dsh-diagram@0.4.0` killed the web boot, so it is out of the profile and out of `plugins.json`; documented in `docs/plugins.md`, `knowledge/runbooks/dsh-plugins.md` and its gotcha.
- [x] `dsh-mermaid` verified in the real UI: a ```mermaid fence rendered as an SVG with Diagram/Code toggle, fullscreen viewer and Download SVG.
- [x] `./init.sh` passes; harness audit at full score; CI green on `main`.

### What's In Progress

- [ ] Nothing — session closed cleanly.

### What's Next

1. Pick `feat-005` (`doctor.sh --json` for automation) from `feature_list.json`.
2. Candidate not in the list: `install.sh` never checks the Node **major**, so a Node 18 machine passes its check and fails later; `.nvmrc` already pins 22.
3. First action of the next session: `./init.sh`.

## Blockers / Risks

- [x] ~~No CI yet~~ — closed by `feat-003`.
- [x] ~~The plugins installed on 2026-09-11 are on disk but not live~~ — closed: the `web` profile was restarted and `dsh-mermaid` renders. Restart it non-interactively — under a TTY `dsh web` exits 0 without serving (`knowledge/gotchas/web-ui-exits-under-a-tty.md`).
- [ ] `dsh-diagram` is unusable on the pinned dsh: its client needs a `conversationEvents` service that 0.1.5-rc.1 does not provide, and the failure is total (the web UI will not boot). Out of the manifest until a compatible release exists — `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md`.
- [ ] A `--dump-config` check does **not** prove a plugin's client half loads; only the browser does. Worth remembering before the next plugin bump.
- [ ] Live inference is deliberately not part of `init.sh` or CI; `./scripts/doctor.sh` covers it on a real machine.
- [ ] `danger-full-access` remains available as a preset; the repo documents the risk but cannot enforce it.
- [ ] `scripts/update-ponytail.sh` and `scripts/install-plugins.sh` need network, so they stay out of CI and their drift is only noticed when someone runs them.
- [ ] Third-party plugins run inside a harness holding a shell. Pins and provenance are recorded, but the code is not audited here.

## Decisions Made

- **Adopt harness + OKF in this repo** — state in files, durable facts in `knowledge/`.
  - Record: `knowledge/decisions/adopt-harness-and-okf.md`.
- **Pin the exact dsh version** — reproducibility without a lockfile, and a floor above CVE-2026-82533.
  - Record: `knowledge/decisions/pin-dsh-version.md`.
- **`init.sh` stays offline** — config correctness and machine readiness are split.
  - Record: `knowledge/decisions/init-stays-offline.md`.
- **`feat-003` and `feat-006` shipped directly on `main`** — repo convention is commit-then-publish; cost accepted is no PR isolation.
- **Ponytail skills stay byte-identical upstream; the pin lives in the script** — `--apply` is explicit, `git` is the undo.
  - Record: `knowledge/runbooks/update-ponytail-skills.md`.
- **Plugins are declared in `plugins.json`, never installed ad hoc** — the profile directory is machine-local and gitignored, so the manifest is what makes a second machine match; versions are pinned exactly, and npm is preferred over a git source so no machine-local `allowBuilds` edit is needed.
  - Record: `docs/specs/2026-09-11-plugins-manifest-design.md`, `knowledge/runbooks/dsh-plugins.md`.

## Files Modified This Session

- `plugins.json` — new: the plugin set (one pinned package for `web`).
- `scripts/install-plugins.sh` — new: applies/reconciles the manifest, `--dry-run`.
- `install.sh` — calls the applier after the skills step; a failure warns.
- `init.sh` — validates `plugins.json` (pin required, no duplicates) and that `install.sh` still calls the applier.
- `docs/plugins.md` — new: the set, provenance, apply/verify/restart/remove, trust.
- `docs/specs/2026-09-11-plugins-manifest-design.md`, `docs/plans/2026-09-11-plugins-manifest.md` — `feat-006` spec + plan.
- `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/dsh-mermaid-npm-name-collision.md` — new concepts + index/log.
- `README.md` — layout entries, plugin row, pointer to `docs/plugins.md`.
- `feature_list.json`, `progress.md`, `session-handoff.md` — harness state.
- Out-of-session before this turn: commit `87d9cf3` added `knowledge/gotchas/web-ui-exits-under-a-tty.md`.
- This turn (plugin restart + reconciliation): `plugins.json` (diagram entry dropped), `docs/plugins.md` (set + why-not note), `docs/specs/2026-09-11-plugins-manifest-design.md` (Outcome section amending criterion 1), `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md` + `knowledge/gotchas/index.md`, `knowledge/runbooks/dsh-plugins.md` (failure mode + the set), `knowledge/log.md`, `feature_list.json`, `progress.md`, `session-handoff.md`.
- Unchanged: `settings.yaml`, `.env.example`, `dsh.version`, `scripts/doctor.sh`, `skills/**`, `docs/models.md`, `docs/modes.md`, `docs/troubleshooting.md`.

## Evidence of Completion

- [x] `./init.sh` → `exit 0`: 5 scripts parse; 6 features, none in-progress; `settings.yaml` default `opencode-go/deepseek-flash`; 6 skill bundles; 1 plugin pinned for `web`; CI workflow parses; shellcheck clean.
- [x] `feat-006` manifest guards: `@latest`, `^0.4.0`, a duplicate entry, a missing field, and a dropped `install.sh` call each make `./init.sh` exit 1 with a `FAIL` line; restored byte-identical afterwards.
- [x] `feat-006` first UI restart (2026-09-11): boot failed — `Failed to load plugins / dsh-diagram: pending (waiting for service: conversationEvents)`, page rendered nothing. `grep -r conversationEvents` over the global dsh 0.1.5-rc.1 install → 0 hits; the plugin's `dsh.compatibility.dshReleases` stops at `0.1.1-rc.2`. Removed with `dsh plugin --profile web remove dsh-diagram` (dependency + layer), entry deleted from `plugins.json`.
- [x] After the removal, `dsh web` (pid 45565) boots clean and `dsh-mermaid@0.4.0` was verified **in the browser**, not by config dump: prompt → ```mermaid fence → SVG with 3 nodes ("Tải đơn → Duyệt → Gửi hàng"), 7 node/edge labels; Code/Diagram toggle round-trips (diagram hidden / code shown and back); Fullscreen opens with zoom 285% / Fit / Close; Download SVG saved `mermaid-flowchart.svg` (13,379 B, `aria-roledescription="flowchart-v2"`).
- [x] `GET /` answers `401` without the one-time token from the startup log — expected, not a fault.
- [x] `./scripts/doctor.sh` → `status: READY (6 ok, 0 warn)`, inference on `deepseek-flash` → 200.
- [x] `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` → `Overall: 100/100`, bottleneck none.
- [x] Knowledge links: 0 broken.
- [x] GitHub Actions runs green on `main`: `e548d0e` and [34554756467](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34554756467) (`afd7cea`, feat-006).

## Notes for Next Session

The route is `AGENTS.md` → `./init.sh` → `feature_list.json` → `progress.md` → `knowledge/index.md`.
Reproducibility now rests on four pins: `dsh.version` (dsh), `.nvmrc` (Node major), `plugins.json`
(plugins), and the ponytail `UPSTREAM_REF` in `scripts/update-ponytail.sh`.
