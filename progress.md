# Session Progress Log

## Current State

**Last Updated:** 2026-09-11 09:35 (+07)
**Active Feature:** none — `feat-006` completed; next session picks `feat-005`
**Repo:** `deepseek-harness-config` @ `main`
**Harness:** adopted 2026-09-10 (`AGENTS.md`, `feature_list.json`, `progress.md`, `init.sh`, `session-handoff.md`, `docs/specs|plans`, `knowledge/`)

## Status

### What's Done

- [x] Adopted the DCNET harness: state files, `docs/specs/` + `docs/plans/`, and `AGENTS.md` as the routing pointer.
- [x] `init.sh` — offline gate (`bash -n`, feature-list shape, `settings.yaml` parse + default-model resolution, skill frontmatter, plugin manifest, CI wiring, shellcheck).
- [x] OKF `knowledge/` bundle: index + log + six category indexes + 22 concepts.
- [x] `feat-003`: `.github/workflows/verify.yml` runs `./init.sh` on push and pull request; `.nvmrc` pins Node 22; README badge.
- [x] `feat-004`: `scripts/update-ponytail.sh` — drift check and `--apply` against a pinned upstream ref.
- [x] `feat-006`: `plugins.json` + `scripts/install-plugins.sh` make the plugin set reproducible; `dsh-mermaid@0.4.0` and `dsh-diagram@0.4.0` are installed on the `web` profile.
- [x] `./init.sh` passes; harness audit at full score; CI green on `main`.

### What's In Progress

- [ ] Nothing — session closed cleanly.

### What's Next

1. Pick `feat-005` (`doctor.sh --json` for automation) from `feature_list.json`.
2. Candidate not in the list: `install.sh` never checks the Node **major**, so a Node 18 machine passes its check and fails later; `.nvmrc` already pins 22.
3. The two plugins are installed but **not loaded yet** — the `web` profile must restart (see Blockers).
4. First action of the next session: `./init.sh`.

## Blockers / Risks

- [x] ~~No CI yet~~ — closed by `feat-003`.
- [ ] The plugins installed on 2026-09-11 are on disk but not live: a running profile keeps the bundle set it started with, so `dsh web` must restart. Restart it non-interactively — under a TTY `dsh web` exits 0 without serving (`knowledge/gotchas/web-ui-exits-under-a-tty.md`).
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

- `plugins.json` — new: the plugin set (`web` + 2 pinned packages).
- `scripts/install-plugins.sh` — new: applies/reconciles the manifest, `--dry-run`.
- `install.sh` — calls the applier after the skills step; a failure warns.
- `init.sh` — validates `plugins.json` (pin required, no duplicates) and that `install.sh` still calls the applier.
- `docs/plugins.md` — new: the set, provenance, apply/verify/restart/remove, trust.
- `docs/specs/2026-09-11-plugins-manifest-design.md`, `docs/plans/2026-09-11-plugins-manifest.md` — `feat-006` spec + plan.
- `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/dsh-mermaid-npm-name-collision.md` — new concepts + index/log.
- `README.md` — layout entries, plugin row, pointer to `docs/plugins.md`.
- `feature_list.json`, `progress.md`, `session-handoff.md` — harness state.
- Out-of-session before this turn: commit `87d9cf3` added `knowledge/gotchas/web-ui-exits-under-a-tty.md`.
- Unchanged: `settings.yaml`, `.env.example`, `dsh.version`, `scripts/doctor.sh`, `skills/**`, `docs/models.md`, `docs/modes.md`, `docs/troubleshooting.md`.

## Evidence of Completion

- [x] `./init.sh` → `exit 0`: 5 scripts parse; 6 features, 1 in-progress; `settings.yaml` default `opencode-go/deepseek-flash`; 6 skill bundles; 2 plugins pinned for `web`; CI workflow parses; shellcheck clean.
- [x] `feat-006` manifest guards: `@latest`, `^0.4.0`, a duplicate entry, a missing field, and a dropped `install.sh` call each make `./init.sh` exit 1 with a `FAIL` line; restored byte-identical afterwards.
- [x] `feat-006` install: `./scripts/install-plugins.sh` → exit 0, `2 added`; profile now has `dependencies: {dsh-diagram 0.4.0, dsh-mermaid 0.4.0}` and both in `dsh.profile.bundles`; `dsh --profile web --dump-default-config` shows `# == dsh-mermaid` (line 540) and `# == dsh-diagram` (line 543); re-run → `0 added, 2 already installed`.
- [x] `./scripts/doctor.sh` → `status: READY (6 ok, 0 warn)`, inference on `deepseek-flash` → 200.
- [x] `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` → `Overall: 100/100`, bottleneck none.
- [x] Knowledge links: 0 broken.
- [x] CI: runs green on `main` through `e548d0e`; this session's run recorded in `session-handoff.md`.

## Notes for Next Session

The route is `AGENTS.md` → `./init.sh` → `feature_list.json` → `progress.md` → `knowledge/index.md`.
Reproducibility now rests on four pins: `dsh.version` (dsh), `.nvmrc` (Node major), `plugins.json`
(plugins), and the ponytail `UPSTREAM_REF` in `scripts/update-ponytail.sh`.
