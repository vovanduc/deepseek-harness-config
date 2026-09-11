# Session Progress Log

## Current State

**Last Updated:** 2026-09-11 11:50 (+07)
**Active Feature:** none — the backlog is empty (`feat-001` … `feat-008` are all `done`)
**Repo:** `deepseek-harness-config` @ `main`
**Harness:** adopted 2026-09-10 (`AGENTS.md`, `feature_list.json`, `progress.md`, `init.sh`, `session-handoff.md`, `docs/specs|plans`, `knowledge/`)

## Status

### What's Done

- [x] Adopted the DCNET harness: state files, `docs/specs/` + `docs/plans/`, and `AGENTS.md` as the routing pointer.
- [x] `init.sh` — offline gate: script syntax, feature-list shape, `settings.yaml` parse + default-model resolution, skill frontmatter, plugin manifest, and the wiring guards for CI, the plugin applier, the pre-flight and the Node check.
- [x] OKF `knowledge/` bundle: index + log + six category indexes + 28 concepts.
- [x] `feat-003`: CI runs `./init.sh` on push and pull request; `.nvmrc` pins Node 22.
- [x] `feat-004`: `scripts/update-ponytail.sh` — drift check and `--apply` against a pinned upstream ref.
- [x] `feat-006`: `plugins.json` + `scripts/install-plugins.sh` make the plugin set reproducible; `dsh-mermaid@0.4.0` is installed **and live** on the `web` profile.
- [x] `feat-007`: `scripts/plugin-preflight.sh` refuses a plugin the pinned dsh cannot run, and the applier blocks on it before touching a profile.
- [x] `feat-005`: `scripts/doctor.sh --json` — one machine-readable readiness object, identical verdict and exit code to the coloured report.
- [x] `feat-008`: `scripts/check-node.sh` — Node 20 floor from `.nvmrc`, run by `install.sh` before it creates anything.
- [x] `./init.sh` passes; harness audit at full score; CI green on `main`.

### What's In Progress

- [ ] Nothing — session closed cleanly.

### What's Next

**No open features.** Candidates, in the order they would pay off:

1. Consume `doctor.sh --json` somewhere: an `init.sh --with-doctor --json` passthrough, or a setup script that fails fast on `NOT_READY`.
2. Prompt-injection-safe plugin installs are still only metadata-checked — a mock boot of a throwaway profile would catch the compiled-only failures the pre-flight admits it cannot see.
3. The two official optional bundles (`@deepseek-ai/dsh-subagent-codex`, `@deepseek-ai/dsh-subagent-claude-code`) are installable and host-only; adding one needs a preset tool row, so it is its own feature.
4. Community plugins worth a pre-flight pass: `dsh-sysmon` (`inject: []`, the safest shape), `dsh-plugin-mindmap`, `dsh-hud`.

## Blockers / Risks

- [x] ~~No CI yet~~ — closed by `feat-003`.
- [x] ~~The plugins installed on 2026-09-11 are on disk but not live~~ — closed: the `web` profile was restarted and `dsh-mermaid` renders.
- [ ] `dsh-diagram` is unusable on the pinned dsh: its client needs a `conversationEvents` service that 0.1.5-rc.1 does not provide, and the failure is total (the web UI will not boot). Out of the manifest until a compatible release exists — `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md`.
- [ ] The pre-flight reads metadata only: a bare service name that exists only in compiled `client.js` still needs the browser. `dsh-diagram` was caught twice over, which is why the net holds for it — not a guarantee for every plugin.
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
- **Features ship directly on `main`** — repo convention is commit-then-publish; the accepted cost is no PR isolation.
- **Ponytail skills stay byte-identical upstream; the pin lives in the script** — `--apply` is explicit, `git` is the undo.
  - Record: `knowledge/runbooks/update-ponytail-skills.md`.
- **Plugins are declared in `plugins.json`, never installed ad hoc** — the profile directory is machine-local and gitignored.
  - Record: `docs/specs/2026-09-11-plugins-manifest-design.md`, `knowledge/runbooks/dsh-plugins.md`.
- **A pin is not a compatibility guarantee: pre-flight blocks, the browser confirms** — it fails closed on an unverifiable source and never executes plugin code.
  - Record: `docs/specs/2026-09-11-plugin-preflight-design.md`.
- **`doctor.sh --json` buffers instead of printing live** — the human report stays byte-identical while `--json` stays pipeable; the check ids become a small public contract.
  - Record: `docs/specs/2026-09-11-doctor-json-design.md`.
- **A newer Node is a warning, not a failure** — the hard floor is 20; diverging from `.nvmrc` is reported but does not block a machine that works.
  - Record: `docs/specs/2026-09-11-node-major-check-design.md`.

## Files Modified This Session

- `plugins.json`, `scripts/install-plugins.sh`, `scripts/plugin-preflight.sh`, `scripts/check-node.sh`
- `scripts/doctor.sh` — `--json`; `install.sh` — the Node check before anything is created
- `init.sh` — the plugin, pre-flight and Node wiring guards
- `docs/plugins.md`, `docs/troubleshooting.md`
- `docs/specs|plans/2026-09-11-{plugins-manifest,plugin-preflight,doctor-json,node-major-check}*`
- `knowledge/runbooks/{dsh-plugins,verify-change,new-machine-setup}.md`, `knowledge/gotchas/{dsh-mermaid-npm-name-collision,dsh-diagram-incompatible-with-pinned-dsh}.md`, `knowledge/log.md`, category indexes
- `README.md`, `feature_list.json`, `progress.md`, `session-handoff.md`
- Unchanged: `settings.yaml`, `.env.example`, `dsh.version`, `skills/**`, `docs/models.md`, `docs/modes.md`

## Evidence of Completion

- [x] `./init.sh` → `exit 0`: 7 scripts parse; 8 features, none in-progress; `settings.yaml` default `opencode-go/deepseek-flash`; 6 skill bundles; 1 plugin pinned; pre-flight + Node + CI wiring guards pass; shellcheck clean.
- [x] `feat-005`: the human `doctor.sh` report is unchanged and exits 0 (6 ok, READY); `--json` prints exactly one object with 0 ANSI escapes and the key set exactly `status`/`ok`/`warn`/`fail`/`checks`; counts, status and exit code match the human run; `DSH_HOME` pointed at a missing directory → both modes `NOT_READY` / exit 1 with a complete object (`cli` ok, `settings` fail); `--help` exit 0, unknown flag exit 2.
- [x] `feat-008`: real node 22.22.2 → `ok` exit 0; fake `node` reporting `v18.20.0` → `FAIL` exit 1 naming the Node 20 floor and the pin; fake `v24.1.0` → `warn` exit 0; `install.sh` with the v18 fake and `DSH_HOME=/tmp/checknode-dsh` exited 1 and **did not create** `DSH_HOME` — step 0 precedes every write; dropping the call or the script's `+x` makes `./init.sh` exit 1.
- [x] `feat-007` pre-flight: `dsh-mermaid@0.4.0` → 0; `dsh-diagram@0.4.0` → 1 naming the omitted releases; the same spec with `--dsh-version 0.1.1-rc.2` → 1 via the inject check alone; with `dsh-diagram` back in the manifest the applier exited 1 and left the profile untouched.
- [x] `feat-006`: `dsh-mermaid@0.4.0` verified **in the browser** — ```mermaid fence → SVG, 3 nodes / 7 labels, Code↔Diagram toggle, Fullscreen, Download SVG → `mermaid-flowchart.svg` (13,379 B).
- [x] `./scripts/doctor.sh` → `status: READY (6 ok, 0 warn)`, inference on `deepseek-flash` → 200.
- [x] `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` → `Overall: 100/100`, bottleneck none.
- [x] Knowledge links: 0 broken.
- [x] GitHub Actions green on `main` — runs recorded in `session-handoff.md`.

## Notes for Next Session

The route is `AGENTS.md` → `./init.sh` → `feature_list.json` → `progress.md` → `knowledge/index.md`.
Reproducibility rests on four pins — `dsh.version`, `.nvmrc`, `plugins.json`, and the ponytail
`UPSTREAM_REF` — and every one of them is now checked rather than assumed: Node by
`scripts/check-node.sh`, plugins by `scripts/plugin-preflight.sh`, dsh and the machine by
`scripts/doctor.sh` (human or `--json`), and the repo itself by `./init.sh` and CI.
