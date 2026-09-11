# Session Progress Log

## Current State

**Last Updated:** 2026-09-11 11:25 (+07)
**Active Feature:** none — `feat-007` completed; next session picks `feat-005`
**Repo:** `deepseek-harness-config` @ `main`
**Harness:** adopted 2026-09-10 (`AGENTS.md`, `feature_list.json`, `progress.md`, `init.sh`, `session-handoff.md`, `docs/specs|plans`, `knowledge/`)

## Status

### What's Done

- [x] Adopted the DCNET harness: state files, `docs/specs/` + `docs/plans/`, and `AGENTS.md` as the routing pointer.
- [x] `init.sh` — offline gate (`bash -n`, feature-list shape, `settings.yaml` parse + default-model resolution, skill frontmatter, plugin manifest, pre-flight wiring, CI wiring, shellcheck).
- [x] OKF `knowledge/` bundle: index + log + six category indexes + 26 concepts.
- [x] `feat-003`: `.github/workflows/verify.yml` runs `./init.sh` on push and pull request; `.nvmrc` pins Node 22; README badge.
- [x] `feat-004`: `scripts/update-ponytail.sh` — drift check and `--apply` against a pinned upstream ref.
- [x] `feat-006`: `plugins.json` + `scripts/install-plugins.sh` make the plugin set reproducible; `dsh-mermaid@0.4.0` is installed **and live** on the `web` profile.
- [x] `feat-006` amended after the first restart: `dsh-diagram@0.4.0` killed the web boot, so it is out of the profile and out of `plugins.json`.
- [x] `dsh-mermaid` verified in the real UI: a ```mermaid fence rendered as an SVG with Diagram/Code toggle, fullscreen viewer and Download SVG.
- [x] `feat-007`: `scripts/plugin-preflight.sh` refuses a plugin the pinned dsh cannot run — `dsh.compatibility.dshReleases` plus every `dsh.client.inject` id resolved against the pinned install — and `install-plugins.sh` blocks on it before touching a profile.
- [x] `./init.sh` passes; harness audit at full score; CI green on `main`.

### What's In Progress

- [ ] Nothing — session closed cleanly.

### What's Next

1. Pick `feat-005` (`doctor.sh --json` for automation) from `feature_list.json`.
2. Run `./scripts/plugin-preflight.sh <name>@<version>` before adding any plugin — and still check the browser after a restart, because the pre-flight cannot see a bare service name that lives only in compiled client code.
3. Candidate not in the list: `install.sh` never checks the Node **major**, so a Node 18 machine passes its check and fails later; `.nvmrc` already pins 22.
4. First action of the next session: `./init.sh`.

## Blockers / Risks

- [x] ~~No CI yet~~ — closed by `feat-003`.
- [x] ~~The plugins installed on 2026-09-11 are on disk but not live~~ — closed: the `web` profile was restarted and `dsh-mermaid` renders.
- [ ] `dsh-diagram` is unusable on the pinned dsh: its client needs a `conversationEvents` service that 0.1.5-rc.1 does not provide, and the failure is total (the web UI will not boot). Out of the manifest until a compatible release exists — `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md`.
- [ ] The pre-flight reads metadata only: it refuses what the manifest makes provable, but a bare service name that exists only in compiled `client.js` still needs the browser. `dsh-diagram` was caught twice over (its compatibility map omits 0.1.5, and `@deepseek-ai/dsh-client-runtime` is unresolved), which is why the net holds for it — not a guarantee for every plugin.
- [ ] Live inference is deliberately not part of `init.sh` or CI; `./scripts/doctor.sh` covers it on a real machine.
- [ ] `danger-full-access` remains available as a preset; the repo documents the risk but cannot enforce it.
- [ ] `scripts/update-ponytail.sh`, `scripts/install-plugins.sh` and `scripts/plugin-preflight.sh` need network, so they stay out of CI and their drift is only noticed when someone runs them.
- [ ] Third-party plugins run inside a harness holding a shell. Pins and provenance are recorded, but the code is not audited here.

## Decisions Made

- **Adopt harness + OKF in this repo** — state in files, durable facts in `knowledge/`.
  - Record: `knowledge/decisions/adopt-harness-and-okf.md`.
- **Pin the exact dsh version** — reproducibility without a lockfile, and a floor above CVE-2026-82533.
  - Record: `knowledge/decisions/pin-dsh-version.md`.
- **`init.sh` stays offline** — config correctness and machine readiness are split.
  - Record: `knowledge/decisions/init-stays-offline.md`.
- **`feat-003`, `feat-006` and `feat-007` shipped directly on `main`** — repo convention is commit-then-publish; cost accepted is no PR isolation.
- **Ponytail skills stay byte-identical upstream; the pin lives in the script** — `--apply` is explicit, `git` is the undo.
  - Record: `knowledge/runbooks/update-ponytail-skills.md`.
- **Plugins are declared in `plugins.json`, never installed ad hoc** — the profile directory is machine-local and gitignored, so the manifest is what makes a second machine match; versions are pinned exactly, and npm is preferred over a git source so no machine-local `allowBuilds` edit is needed.
  - Record: `docs/specs/2026-09-11-plugins-manifest-design.md`, `knowledge/runbooks/dsh-plugins.md`.
- **A pin is not a compatibility guarantee: pre-flight blocks, the browser confirms** — the pre-flight fails closed on an unverifiable source (a git spec) and needs `--skip-preflight` to override; it never executes plugin code.
  - Record: `docs/specs/2026-09-11-plugin-preflight-design.md`, `knowledge/runbooks/dsh-plugins.md`.

## Files Modified This Session

- `plugins.json` — the plugin set (one pinned package for `web`).
- `scripts/install-plugins.sh` — applies/reconciles the manifest; now pre-flights each plugin and counts a rejection as *blocked*; `--dry-run`, `--skip-preflight`.
- `scripts/plugin-preflight.sh` — new: compatibility map + client-inject resolution against the pinned install.
- `install.sh` — calls the applier after the skills step; a failure warns.
- `init.sh` — validates `plugins.json`, and guards the `install.sh` → applier → pre-flight wiring.
- `docs/plugins.md` — the set, provenance, pre-flight, apply/verify/restart/remove, trust.
- `docs/specs/2026-09-11-plugins-manifest-design.md`, `docs/plans/2026-09-11-plugins-manifest.md` — `feat-006`.
- `docs/specs/2026-09-11-plugin-preflight-design.md`, `docs/plans/2026-09-11-plugin-preflight.md` — `feat-007`.
- `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/dsh-mermaid-npm-name-collision.md`, `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md` — concepts + index/log.
- `README.md` — layout entries, plugin row, pointer to `docs/plugins.md`.
- `feature_list.json`, `progress.md`, `session-handoff.md` — harness state.
- Out-of-session before this turn: commit `87d9cf3` added `knowledge/gotchas/web-ui-exits-under-a-tty.md`.
- Unchanged: `settings.yaml`, `.env.example`, `dsh.version`, `scripts/doctor.sh`, `skills/**`, `docs/models.md`, `docs/modes.md`, `docs/troubleshooting.md`.

## Evidence of Completion

- [x] `./init.sh` → `exit 0`: 6 scripts parse; 7 features, none in-progress; `settings.yaml` default `opencode-go/deepseek-flash`; 6 skill bundles; 1 plugin pinned for `web`; pre-flight wired; CI workflow parses; shellcheck clean.
- [x] `feat-006` manifest guards: `@latest`, `^0.4.0`, a duplicate, a missing field, and a dropped `install.sh` call each make `./init.sh` exit 1; restored byte-identical.
- [x] `feat-006` first UI restart (2026-09-11): boot failed — `Failed to load plugins / dsh-diagram: pending (waiting for service: conversationEvents)`. `grep -r conversationEvents` over the global dsh 0.1.5-rc.1 install → 0 hits; the plugin's `dsh.compatibility.dshReleases` stops at `0.1.1-rc.2`. Removed with `dsh plugin --profile web remove dsh-diagram`, entry deleted from `plugins.json`.
- [x] `dsh-mermaid@0.4.0` verified **in the browser**: ```mermaid fence → SVG, 3 nodes / 7 labels, Code↔Diagram toggle, Fullscreen (zoom 285%), Download SVG → `mermaid-flowchart.svg` (13,379 B).
- [x] `feat-007` pre-flight fixtures: `dsh-mermaid@0.4.0` → exit 0; `dsh-diagram@0.4.0` → exit 1 naming `[0.1.0-rc.6 0.1.0-rc.8 0.1.1-rc.1 0.1.1-rc.2]` vs pinned `0.1.5-rc.1`; the same spec with `--dsh-version 0.1.1-rc.2` → exit 1 via check B alone (`@deepseek-ai/dsh-client-runtime` unresolved), proving the two checks are independent; unpinned spec → exit 2; git/unresolvable spec → exit 1.
- [x] `feat-007` end-to-end regression: with `dsh-diagram@0.4.0` temporarily back in `plugins.json`, `./scripts/install-plugins.sh` exited 1 with `pre-flight rejected … blocked by pre-flight`, and the profile was **untouched** — `dependencies` still `['dsh-mermaid']`, bundles still base + web-app + dsh-mermaid, no `node_modules/dsh-diagram`. `--dry-run --skip-preflight` printed `would add`, so the escape hatch works.
- [x] `feat-007` guards: dropping the pre-flight call from `install-plugins.sh`, or removing the script's executable bit, each make `./init.sh` exit 1 with a `FAIL` line; restored byte-identical.
- [x] `./scripts/doctor.sh` → `status: READY (6 ok, 0 warn)`, inference on `deepseek-flash` → 200.
- [x] `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` → `Overall: 100/100`, bottleneck none.
- [x] Knowledge links: 0 broken.
- [x] GitHub Actions runs green on `main`: [34560695575](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34560695575) (`9a89eb9`, the dsh-diagram removal) and [34561029949](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34561029949) (`295a655`, feat-007).

## Notes for Next Session

The route is `AGENTS.md` → `./init.sh` → `feature_list.json` → `progress.md` → `knowledge/index.md`.
Reproducibility now rests on four pins: `dsh.version` (dsh), `.nvmrc` (Node major), `plugins.json`
(plugins), and the ponytail `UPSTREAM_REF` in `scripts/update-ponytail.sh` — and a pin is checked for
**compatibility** before it is applied, which is what the pre-flight adds.
