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
2026-09-11 — runbook/dsh-plugins — added: how each plugin is actually driven — market UI + its drift from `plugins.json`, the `find_dsh_plugin` agent tool, modsearch's three tools (`web_search` reroute, `read_page`, `x_search`) and where its route health shows, and the vision split between local (no upload) and remote tools with the `vision_toolkit_activate` bootstrap.
2026-09-11 — runbook/dsh-plugins — verified: `modsearch` answers a real `web_search` with zero keys, and the vision runtime (managed venv + bundled upstream CLI + vendor free service) returns a correct description.
2026-09-11 — runbook/dsh-plugins — verified: after `hub restart dsh-web` all four client halves are served (roster entry + `client.js` 200, distinct `rev` per plugin) and Settings renders the tabs they add — Plugin Market, Vision, Search engine (ModSearch); `dsh-find-plugin` stays host-only with no roster entry by design.
2026-09-11 — discovery/channel — referenced: `awesome-dsh-plugin/awesome-dsh-plugin` is a curated index (3.4k entries / 23 categories, `data/stars.json` + `data/downloads.json`, snapshot 2026-08-19), not a manager; `dshmarket` is the managing half.
