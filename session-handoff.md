# Session Handoff

## Current Objective

- Goal: survey the curated dsh plugin index (`awesome-dsh-plugin/awesome-dsh-plugin`) category by
  category, decide what is worth using, and land the first bundle as a reproducible feature.
- Current status: complete. `feat-009` is `done`; **the backlog is empty**; repo clean and pushed.
- Branch / commit: `main` @ `8695a33` (`feat-009`), with the evidence commit on top.

## Completed This Session

- [x] Surveyed the index: 23 categories, 3 431 entries, joined `data/stars.json` (1 488 repos) and
  `data/downloads.json` (624) to rank per category. It is a curated **index**, not a plugin manager —
  the managing half is `dshmarket`, also on the list.
- [x] Pre-flighted eight candidates against dsh `0.1.5-rc.1` with `./scripts/plugin-preflight.sh`:
  5 pass, 3 blocked on the missing `@deepseek-ai/dsh-client-runtime` client service.
- [x] `feat-009` — `plugins.json` grew from 1 to 5 pinned web plugins: `dshmarket@1.45.1`,
  `dsh-find-plugin@0.3.7`, `@liustack/modsearch@5.10.2`, `@anionex/dsh-vision-toolkit@0.1.44`
  (alongside `dsh-mermaid@0.4.0`). Installed, composed, and **live** after the follow-up `dsh web`
  restart — verified from the shell (roster + `client.js` 200) and in the browser (`Settings` tabs).
- [x] New knowledge: `gotcha/plugin-fit-vs-popularity` + a discovery section in `runbook/dsh-plugins`;
  `docs/plugins.md`, `README.md`, `knowledge/log.md` updated.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Offline gate | `./init.sh` | exit 0 | 9 features / 0 in-progress, 5 plugins pinned, shellcheck clean |
| Pre-flight (pass) | `./scripts/plugin-preflight.sh <spec>` | exit 0 ×5 | `dshmarket`, `dsh-find-plugin`, `@liustack/modsearch`, `@liustack/modlens`, `@anionex/dsh-vision-toolkit` |
| Pre-flight (blocked) | same, 3 candidates | exit 1 ×3 | `dsh-vision-router@2.1.5`, `dsh-web-search-pro@0.1.11`, `dsh-free-search@0.4.24` — unmet inject `@deepseek-ai/dsh-client-runtime` |
| Apply | `./scripts/install-plugins.sh` | exit 0 | `4 added, 1 already installed, 0 failed, 0 blocked` |
| Idempotent re-run | `./scripts/install-plugins.sh` | exit 0 | `0 added, 5 already installed, 0 failed, 0 blocked` |
| Profile state | `dsh plugin --profile web list` | 5 packages | see the set in `docs/plugins.md` |
| Host layers | `dsh --profile web --dump-default-config \| grep '# =='` | 5 plugin layers | host layer only, not proof the client half lives |
| Restart | `hub restart dsh-web` | ready in 18 s, clean log | pid 15184; `dsh web --port 4319 --no-open` |
| Served roster | `curl -b /tmp/dsh-j2 http://127.0.0.1:4319/` | 200 | entries for `dsh-mermaid`, `dshmarket`, `@liustack/modsearch`, `@anionex/dsh-vision-toolkit`, each with its own `rev` |
| Client bundles | `curl` each registry `url` | 200 ×4 | 23 550 / 567 583 / 42 614 / 143 381 bytes |
| UI, headless Chromium | screenshot + `document.body.innerText` | renders, 0 console errors | Settings → *Plugin Market*, *Vision*, *Search engine (ModSearch)* |
| Harness audit | `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` | 100/100 | bottleneck: none |
| Knowledge links | link check over `knowledge/**` + docs + README | 129 checked, 0 broken | 57 files |
| CI | [run 34568962541](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34568962541) on `8695a33` | success | the same `./init.sh` gate the repo runs locally |

## Files Changed

- `plugins.json`, `README.md`, `docs/plugins.md`
- `docs/specs/2026-09-11-plugin-set-expansion-design.md`, `docs/plans/2026-09-11-plugin-set-expansion.md`
- `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/plugin-fit-vs-popularity.md`,
  `knowledge/gotchas/index.md`, `knowledge/log.md`
- `feature_list.json`, `progress.md`, `session-handoff.md`

## Decisions Made

- A curated list is a discovery channel, not a ranking of fitness: rank with the list's star/download
  data, then filter with `npm view <spec> repository.url` (identity) and the pre-flight (compatibility).
  → `knowledge/gotchas/plugin-fit-vs-popularity.md`
- `@anionex/dsh-vision-toolkit` over the far more popular `@liustack/modlens` for the vision slot —
  the only candidate declaring compatibility with the pinned rc; fail-closed beats feature-rich.
  → `docs/specs/2026-09-11-plugin-set-expansion-design.md`
- `dshmarket` installed even though it is a nested market: it is the manager the list recommends and
  the only way to browse/update plugins without hand-editing the manifest.
- No restart during `feat-009` itself — the user was talking to the agent through the running `web`
  server; the restart was done afterwards as a separate, explicit step (13:2x).

## Blockers / Risks

- `modsearch` runs on keyless CLI/local engines (verified with a real search); keyed engines need
  `TAVILY_API_KEY` / `EXA_API_KEY` / `FIRECRAWL_API_KEY`. `dsh-vision-toolkit` runs on the vendor's
  free default service (verified end-to-end through the bundled CLI + managed venv).
- Market installs land in the profile only — add the pin to `plugins.json` to make one reproducible.
- Two of the five entries declare no `dsh.compatibility` map at all — a pre-flight pass is a filter,
  and the restart is what actually settled them (all four client halves load).
- The `@deepseek-ai/dsh-client-runtime` family block (`plugin-fit-vs-popularity`) will need revisiting
  on a dsh bump; three popular plugins wait behind it.
- `scripts/install-plugins.sh` only adds: removing an entry from `plugins.json` does not uninstall it.
- Third-party plugin code is not audited here; pins and provenance are, and the sandbox confines writes only.
- `superpowers:*` skills are still not installed, so specs/plans are written by hand (noted in each spec).

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `feature_list.json` and `progress.md`.
3. Review this handoff.
4. Run `./init.sh` before editing — CI runs the same gate on push.

## Recommended Next Step

- **Exercise the agent-side tools from an ordinary session.** `find_dsh_plugin`, `read_page`,
  `x_search` and the `vision_*` set are registered and the vision runtime is ready; usage for each is
  written up in `docs/plugins.md` → *How to use them*. Deeper plugin decisions (Memory vs this repo's
  OKF, Skills/Workflow vs `dcnet-workflow`, Security, Runtime) are listed in `progress.md` → What's
  Next, with the ranked catalog at `/tmp/adp/report.md` until it is moved into `knowledge/`.
