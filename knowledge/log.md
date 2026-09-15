---
type: log
title: Knowledge change log
---
# Knowledge change log

<!-- YYYY-MM-DD — <type>/<concept> — thêm|sửa: mô tả -->

2026-09-10 — bundle created — adopt OKF: `index.md`, `log.md`, six category indexes.
2026-09-10 — convention/settings-symlink — added: repo file is the live `$DSH_HOME/settings.yaml`.
2026-09-10 — convention/skill-bundle-layout — added: top-level discovery + required frontmatter.
2026-09-10 — convention/secrets-never-committed — added: `apiKeyEnv` names, never values.
2026-09-10 — decision/adopt-harness-and-okf — added: state in files, knowledge in `knowledge/`.
2026-09-10 — decision/pin-dsh-version — added: exact pin + CVE-2026-82533 floor.
2026-09-10 — decision/init-stays-offline — added: split offline gate from machine readiness.
2026-09-10 — system/dsh-home-layout — added: what `$DSH_HOME` holds and who owns it.
2026-09-10 — api/opencode-go-route — added: full route contract with reasons.
2026-09-10 — service/credential-resolution — added: four-layer resolution order.
2026-09-10 — glossary/dsh-vocabulary — added: overloaded nouns (provider, preset, profile, skill).
2026-09-10 — runbook/new-machine-setup — added: clone → install → key → READY.
2026-09-10 — runbook/verify-change — added: `init.sh` vs `doctor.sh` vs harness audit.
2026-09-10 — runbook/add-model-or-provider — added: model/provider edit procedure.
2026-09-10 — gotcha/models-endpoint-not-authenticated — added: `/models` does not authenticate.
2026-09-10 — gotcha/missing-session-id — added: the required OpenCode Go header.
2026-09-10 — gotcha/compat-flags — added: developer role + max_tokens field.
2026-09-10 — gotcha/empty-yaml-value-refused — added: empty value fails the parse.
2026-09-10 — gotcha/hand-declared-models-text-only — added: images need `input: [text, image]`.
2026-09-10 — runbook/ci-verification — added: GitHub Actions runs `./init.sh`; the PyYAML step is load-bearing; `init.sh` now fails if the wiring is removed.
2026-09-10 — runbook/ci-verification — updated: action majors bumped to v7 (Node 24 runner runtime, clears the Node 20 deprecation annotation).
2026-09-10 — runbook/update-ponytail-skills — added: pinned upstream ref, drift check vs apply, and what is deliberately not synced (built `.openclaw` copy, plugin hooks).
2026-09-11 — gotcha/web-ui-exits-under-a-tty — added: `dsh web` exits 0 without serving when stdout is a TTY; supervise it non-interactively.
2026-09-11 — gotcha/dsh-diagram-incompatible-with-pinned-dsh — added: its client needs a `conversationEvents` service absent from dsh 0.1.5-rc.1, so the layer composes but the web boot dies.
2026-09-11 — runbook/dsh-plugins — updated: added the shell-side check that proves the *running* server serves a plugin (`?token=` → cookie, registry inline in `/`, `client.js` 200), because `--dump-config` only proves the host layer.
2026-09-11 — runbook/dsh-plugins — updated: the boot-killing failure mode (a client half built for another release) and the set actually declared here. `dsh-diagram` dropped from `plugins.json`.
2026-09-11 — runbook/dsh-plugins — added: `plugins.json` as the source of truth, apply/verify/restart, and the `prepare`/`allowBuilds` failure mode.
2026-09-11 — gotcha/dsh-mermaid-npm-name-collision — added: the npm name is held by MrmoLabs, not the AKS1st repo a plugin list links.
2026-09-11 — runbook/dsh-plugins — updated: added the pre-flight (`dsh.compatibility.dshReleases` + `dsh.client.inject` resolved against the pinned install) and its limits; the applier now blocks a rejected plugin.
2026-09-11 — script/plugin-preflight — added: the offline oracle is the pinned install under `$(npm root -g)/@deepseek-ai/dsh/node_modules`, and `npm view <spec> dsh --json` exposes the manifest without installing.
2026-09-11 — runbook/verify-change — updated: `doctor.sh --json` (one object, stable keys, identical verdict and exit code).
2026-09-11 — script/doctor — added: `--json` emits `{status, ok, warn, fail, checks[]}`; `compose` is absent when `dsh` is not on PATH.
2026-09-11 — script/check-node — added: Node 20 floor from `.nvmrc`, warn on a divergent major; `install.sh` runs it before creating anything.
2026-09-11 — plugin-set/expansion — updated: `plugins.json` now declares 5 web plugins (+ `dshmarket@1.45.1`, `dsh-find-plugin@0.3.7`, `@liustack/modsearch@5.10.2`, `@anionex/dsh-vision-toolkit@0.1.44`), each pre-flighted against 0.1.5-rc.1; installed and composed, not yet live (needs a `dsh web` restart).
2026-09-11 — gotcha/plugin-fit-vs-popularity — added: the list's ⭐/⬇ leaders in two categories are refused on 0.1.5-rc.1 (`@deepseek-ai/dsh-client-runtime` is gone), and `liustack/modsearch` publishes scoped — popularity ≠ fitness, and a list link is not an npm name.
2026-09-11 — runbook/dsh-plugins — added: how each plugin is actually driven — market UI + its drift from `plugins.json`, the `find_dsh_plugin` agent tool, modsearch's three tools and its per-machine engine table (`fetch`→`local` ready keyless; `web_search`→`firecrawl` refused 403 from this IP, needs a key; `x_search` needs the `grok` CLI), and the vision split between local (no upload) and remote tools with the `vision_toolkit_activate` bootstrap.
2026-09-11 — runbook/dsh-plugins — verified: `read_page` fetches keyless via the `local` engine, and the vision defaults authenticate and answer (200 /v1/models with the free literal key; a real image turn described correctly in ~7 s). Also noted: tools compose per session, and all five plugins are on the `web` profile only.
2026-09-11 — correction/evidence — retracted: an earlier claim that `web_search` was "verified working keyless through modsearch" was wrong — the call came from the omp harness tool, not the plugin. A session booted from another profile, or opened before the restart, does not carry modsearch at all.
2026-09-11 — runbook/dsh-plugins — verified: after `hub restart dsh-web` all four client halves are served (roster entry + `client.js` 200, distinct `rev` per plugin) and Settings renders the tabs they add — Plugin Market, Vision, Search engine (ModSearch); `dsh-find-plugin` stays host-only with no roster entry by design.
2026-09-11 — discovery/channel — referenced: `awesome-dsh-plugin/awesome-dsh-plugin` is a curated index (3.4k entries / 23 categories, `data/stars.json` + `data/downloads.json`, snapshot 2026-08-19), not a manager; `dshmarket` is the managing half.
2026-09-12 — gotcha/settings-symlink-drift — added: the live `~/.dsh/settings.yaml` was a regular file carrying an app-written `ui-onboarding` key, so repo edits reached nothing while `init.sh` and `doctor.sh` both passed. The extra key is the tell.
2026-09-12 — gotcha/hand-declared-models-text-only — updated: cause (absent `input` materialises as `[]`, which falls through to `[text]`), and the flag-is-not-the-capability split — the route passes images on `deepseek-flash` (200, `A blue square.`) but `deepseek-v4-pro` has no vision at all.
2026-09-12 — api/opencode-go-route — verified: image input end to end at the gateway, not just declared in config.
2026-09-12 — gotcha/init-sh-needs-dsh-home-write — added: the gate's `--dump-config` step writes `$DSH_HOME/profiles/<name>/cordis.yml`; under a workspace-write sandbox that is a bare Node `EPERM`, not the harness denial marker.
2026-09-12 — experiment/office-3d-poc — added: a one-file Three.js r160 scene plus `verify.mjs` (headless-Chromium CDP loop, no dependencies), proving the image→scene workflow runs on `deepseek-flash`. Five findings recorded in the experiment README; the sharpest is that `Matrix4.compose` with a default `Vector3()` scale silently deletes every `InstancedMesh` instance with no console warning.
2026-09-12 — api/opencode-go-route — measured: the real cost profile of one agent session (100 requests, 21 min, 13 images) — 11 055 232 cached vs 130 031 uncached input, 105 912 output, 98.84 % hit rate, ~$0.116 at list price. The same tokens at cache-miss prices would be $1.74, so the prefix cache, not the model choice, is what makes long contexts affordable. Also records where usage lives in the session log.
2026-09-14 — gotcha/diagram-plugins-er-and-flow — added: a full-namespace scan (4 449 npm `dsh-plugin` packages, 3 660 curated entries) finds zero ERD/DBML/PlantUML/BPMN plugins; `dsh-mermaid@0.4.0` already bundles mermaid 11.17.0, whose `erDiagram` and `flowchart` both render against the served runtime (verified: `<svg class="erDiagram">` 11 776 B, `<svg class="flowchart">` 17 675 B), while `dsh-drawio`, `dsh-flowchart`, `dsh-visualizer` and `@dsh-local/dsh-diagram` all inject `@deepseek-ai/dsh-client-runtime` and are refused. Also: `detectType` false-negatives before the first `render` because diagram implementations load lazily.
2026-09-15 — gotcha/diagram-plugins-er-and-flow — verified end to end: two prompts typed into the live `dsh web` composer rendered through `dsh-mermaid` — an `erDiagram` (KHACH_HANG/DON_HANG) and a `flowchart TD` with three approval branches, both in Vietnamese, both with the Diagram/Fullscreen/Download-SVG toolbar. Curated ranking data scanned too (`data/stars.json` 1 484, `data/downloads.json` 624): zero ERD/BPMN/DBML hits, so the gap is ecosystem-wide and not a keyword artefact.
