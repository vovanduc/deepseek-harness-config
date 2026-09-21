# Session Progress Log

## Current State

**Last Updated:** 2026-09-21 (+07) — operational session: started `dsh web` (:4319) + omp-gateway (broker :8765 / gateway :4000, `swe-2 via gateway: OK`). Doctor caught settings-symlink **drift #5** (written 2026-09-18, diverged: a UI default-model change to `vision-toolkit-omp-gateway / devin/swe-2 / high` + cosmetic flow-style diff); relinked via `./install.sh --no-install`, user declined merging the UI change → repo keeps `opencode-go / deepseek-flash`. `doctor.sh` READY (6 ok).
**Active Feature:** none — `feat-010`…`feat-015` all closed; no open features
**Repo:** `deepseek-harness-config` @ `main`
**Harness:** adopted 2026-09-10 (`AGENTS.md`, `feature_list.json`, `progress.md`, `init.sh`, `session-handoff.md`, `docs/specs|plans`, `knowledge/`)

## Status

### What's Done

- [x] Adopted the DCNET harness: state files, `docs/specs/` + `docs/plans/`, and `AGENTS.md` as the routing pointer.
- [x] `init.sh` — offline gate: script syntax, feature-list shape, `settings.yaml` parse + default-model resolution, skill frontmatter, plugin manifest, and the wiring guards for CI, the plugin applier, the pre-flight and the Node check.
- [x] OKF `knowledge/` bundle: index + log + six category indexes + 31 concepts.
- [x] `feat-003`: CI runs `./init.sh` on push and pull request; `.nvmrc` pins Node 22.
- [x] `feat-004`: `scripts/update-ponytail.sh` — drift check and `--apply` against a pinned upstream ref.
- [x] `feat-005`: `scripts/doctor.sh --json` — one machine-readable readiness object.
- [x] `feat-006`: `plugins.json` + `scripts/install-plugins.sh` make the plugin set reproducible.
- [x] `feat-007`: `scripts/plugin-preflight.sh` refuses a plugin the pinned dsh cannot run.
- [x] `feat-008`: `scripts/check-node.sh` — Node 20 floor from `.nvmrc`, run before anything is created.
- [x] `feat-009`: plugin set expanded from 1 to 5 on the `web` profile after a pre-flight survey of the curated list — installed, composed, and **live** since the `dsh web` restart (roster + `client.js` 200 + Settings tabs).
- [x] `feat-010`: restored the `$DSH_HOME/settings.yaml` symlink — it had drifted to a regular file, so **no repo edit was reaching the server** while every check still passed.
- [x] `feat-011`: `input: [text, image]` on `deepseek-flash`, proven at the gateway first, then in-harness: `read_image` now returns real images.
- [x] `feat-012`: `experiments/office-3d-poc/` — a one-file Three.js office with a headless-Chromium verification loop, built and corrected over three render-and-look rounds.
- [x] `feat-014`: `omp-gateway` route — Devin SWE-2 (no public API) reaches dsh through omp's local auth-gateway; `scripts/omp-gateway.sh` brings broker + gateway up in the order the boot-time catalog needs. Measured at the gateway, then confirmed in the composer.
- [x] `./init.sh` passes; harness audit 100/100; knowledge links resolve.

### What's In Progress

- [ ] Nothing — session closed cleanly.

### What's Next

**No open features.** Candidates, in the order they would pay off:

1. **Raise the output ceiling if long single-file generations matter.** The route declares
   `maxTokens: 65536`; DeepSeek's own API allows 384 K. The PoC file is 37 KB (~11 K tokens) so it
   never came close, but the article's 3–4 k-line scenes would.
2. Give `modsearch` a search key (`TAVILY_API_KEY` / `EXA_API_KEY` / `firecrawl.apiKey`) — the fetch
   route is keyless, search is not, and `web_search` is the one tool still unusable.
3. Exercise `find_dsh_plugin`, `read_page`, `x_search` and `vision_*` from a **fresh** session —
   composition is per session, and this one was opened before the last restart.
4. Decide whether `experiments/` belongs in a repo whose `AGENTS.md` says the deliverable is
   `settings.yaml`, `skills/`, `install.sh` and `scripts/doctor.sh`. It is currently 700 KB of
   vendored Three.js plus a scene; if the answer is no, it moves out and only the README finding
   stays.
5. **Decide whether the BPMN path belongs in the repo.** Verified and written down
   (`knowledge/runbooks/draw-bpmn-workflow.md`) but living in `/tmp`: either route works — a ~200 KB
   vendored `bpmn-js` viewer page for interactive viewing, or `bpmn-to-image` for PNG/SVG artifacts
   (70 MB of deps). Promote to `experiments/` or leave it a recipe; the choice is about where the
   *diagrams* belong, not about feasibility.
6. The two official optional bundles (`@deepseek-ai/dsh-subagent-codex`,
   `@deepseek-ai/dsh-subagent-claude-code`) are installable and host-only; each needs a preset tool
   row, so it is its own feature.

## Blockers / Risks

- [x] ~~No CI yet~~ — closed by `feat-003`.
- [x] ~~The plugins installed on 2026-09-11 are on disk but not live~~ — closed twice: `dsh-mermaid`
  by the first restart, the other four by the 2026-09-11 13:2x restart (roster `client.js` → 200,
  Settings shows *Plugin Market*, *Vision*, *Search engine (ModSearch)*).
- [ ] `dsh-diagram` is unusable on the pinned dsh: its client needs a `conversationEvents` service
  that 0.1.5-rc.1 does not provide, and the failure is total (the web UI will not boot). Out of the
  manifest until a compatible release exists — `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md`.
- [ ] The same missing-service trap now has a **family**: `@deepseek-ai/dsh-client-runtime` is absent
  from 0.1.5-rc.1, which blocks `dsh-vision-router@2.1.5`, `dsh-web-search-pro@0.1.11` and
  `dsh-free-search@0.4.24` — the most popular entries in their categories. Recorded in
  `knowledge/gotchas/plugin-fit-vs-popularity.md`. A dsh bump may or may not restore the id.
- [ ] The pre-flight reads metadata only: a bare service name that exists only in compiled `client.js`
  still needs the browser. Two of the five installed plugins declare no compatibility map at all.
- [ ] `modsearch` **web search does not work on this machine without a key**: the keyless `firecrawl`
  route answers `403` for this IP, so `web_search` needs `TAVILY_API_KEY` / `EXA_API_KEY` /
  `firecrawl.apiKey` or the `agy` CLI; `read_page` works as-is via the `local` engine. `x_search` needs
  the `grok` CLI. `dsh-vision-toolkit` needs nothing (free default service verified).
- [ ] A session opened before the restart carries none of the new tools — the plugin set is composed
  per session.
- [ ] Live inference is deliberately not part of `init.sh` or CI; `./scripts/doctor.sh` covers it on a real machine.
- [ ] `danger-full-access` remains available as a preset; the repo documents the risk but cannot enforce it.
- [ ] `scripts/update-ponytail.sh`, `scripts/install-plugins.sh` and `scripts/plugin-preflight.sh` need network, so they stay out of CI and their drift is only noticed when someone runs them.
- [ ] Third-party plugins run inside a harness holding a shell. Pins and provenance are recorded, but the code is not audited here. A slot in a curated list is not a security review.

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
- **A pin is not a compatibility guarantee: pre-flight blocks, the browser confirms.**
  - Record: `docs/specs/2026-09-11-plugin-preflight-design.md`.
- **A curated list is a discovery channel, not a ranking of fitness** — rank with `data/stars.json` /
  `data/downloads.json`, then filter with `repository.url` + the pre-flight. Never one without the other.
  - Record: `knowledge/gotchas/plugin-fit-vs-popularity.md`, `docs/specs/2026-09-11-plugin-set-expansion-design.md`.
- **`dsh-vision-toolkit` over the far more popular `modlens` for the vision slot** — it is the only
  candidate that *declares* compatibility with `0.1.5-rc.1`; fail-closed beats feature-rich.
  - Record: `docs/specs/2026-09-11-plugin-set-expansion-design.md`.
- **`doctor.sh --json` buffers instead of printing live** — the human report stays byte-identical while `--json` stays pipeable.
  - Record: `docs/specs/2026-09-11-doctor-json-design.md`.
- **A newer Node is a warning, not a failure** — the hard floor is 20; diverging from `.nvmrc` is reported but does not block.
  - Record: `docs/specs/2026-09-11-node-major-check-design.md`.

## Files Modified This Session

- `plugins.json` — 4 new pinned entries (5 total on `web`)
- `README.md` — the configuration table's plugin row
- `docs/plugins.md` — the set table, the refusals, the discovery note, the live-status note, the
  per-plugin `rev` trap in the roster recipe
- `docs/specs/2026-09-11-plugin-set-expansion-design.md`, `docs/plans/2026-09-11-plugin-set-expansion.md`
- `knowledge/runbooks/dsh-plugins.md`, `knowledge/gotchas/plugin-fit-vs-popularity.md`,
  `knowledge/gotchas/index.md`, `knowledge/log.md`
- `feature_list.json`, `progress.md`, `session-handoff.md`
- Unchanged: `settings.yaml`, `.env.example`, `dsh.version`, `.nvmrc`, `skills/**`, `init.sh`,
  `install.sh`, `scripts/**`, `docs/models.md`, `docs/modes.md`

## Evidence of Completion

- [x] `./init.sh` → `exit 0`: 7 scripts parse; 9 features, 0 in-progress; `settings.yaml` default
  `opencode-go/deepseek-flash`; 6 skill bundles; **5 plugins pinned**; pre-flight + Node + CI wiring
  guards pass; shellcheck clean.
- [x] `feat-009` pre-flight survey (8 candidates, dsh `0.1.5-rc.1`): 5 ok — `dshmarket@1.45.1`,
  `dsh-find-plugin@0.3.7`, `@liustack/modsearch@5.10.2`, `@anionex/dsh-vision-toolkit@0.1.44`
  (the only one declaring `dshReleases["0.1.5-rc.1"] = compatible`), plus the existing
  `dsh-mermaid@0.4.0`; 3 blocked — `dsh-vision-router@2.1.5`, `dsh-web-search-pro@0.1.11`,
  `dsh-free-search@0.4.24`, each `exit 1` on unmet client inject `@deepseek-ai/dsh-client-runtime`.
- [x] `feat-009` apply: `./scripts/install-plugins.sh` → `plugins: 4 added, 1 already installed,
  0 failed, 0 blocked by pre-flight`, `exit 0`; re-run → `0 added, 5 already installed, 0 failed,
  0 blocked`.
- [x] `feat-009` profile state: `dsh plugin --profile web list` → 5 packages
  (`@anionex/dsh-vision-toolkit@0.1.44`, `@liustack/modsearch@5.10.2`, `dsh-find-plugin@0.3.7`,
  `dsh-mermaid@0.4.0`, `dshmarket@1.45.1`); `dsh --profile web --dump-default-config` prints a layer
  for each of the five.
- [x] Harness audit: `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .`
  → `Overall: 100/100`, bottleneck none.
- [x] Knowledge links: 129 checked across 57 markdown files, 0 broken.
- [x] GitHub Actions green on the new commit: [34568962541](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34568962541) (`8695a33`, `feat-009`).
- [x] **Restart + live check (2026-09-11 13:2x).** `hub restart dsh-web` (`dsh web --port 4319
  --no-open`, pid 15184, ready in 18 s, boot log clean — no plugin error). Served page HTTP 200 carries
  a registry entry with `url` for `dsh-mermaid` (`rev=…-44`), `@liustack/modsearch` (`…-45`),
  `dshmarket` (`…-50`) and `@anionex/dsh-vision-toolkit` (`…-55`); each `client.js` → `200`
  (23 550 / 42 614 / 567 583 / 143 381 bytes). `dsh-find-plugin` has no client bundle by design
  (host-only, patch `find-dsh-plugin`) — absent from the roster is correct, and the clean boot is its
  activation evidence.
- [x] **Screenshot (headless Chromium, `127.0.0.1:4319`).** UI renders normally — sidebar, workspaces,
  composer, model label — **0 console errors**, no `Failed to load plugins`. Settings panel shows the
  contributed tabs *Plugin Market* (dshmarket), *Vision* (dsh-vision-toolkit, reports a read-only key
  source) and, under *Plugins*, *Search engine (ModSearch)*. `--dump-config` alone would not have
  shown any of this.
- [x] **Second restart (2026-09-14 11:3x).** See the dated section at the foot of this file.
- [x] **`modsearch` engine state measured, not assumed (2026-09-11).** `npx @liustack/modsearch doctor`
  from the profile dir resolves: fetch → `local` READY keyless (**verified**: `read_page` route on
  `example.com` → 200 with content, links, uncertainty); search → `firecrawl` keyless **refused from
  this IP** (`403 your IP address looks suspicious`), so `web_search` needs one key
  (`TAVILY_API_KEY` / `EXA_API_KEY` / `firecrawl.apiKey`) or the Antigravity `agy` CLI; social →
  none (`grok` CLI absent). The `web` row's `searchProvider: modsearch` reroute is in `--dump-config`.
  **Correction:** an earlier note here called this "verified keyless" off a `web_search` call that
  actually came from the *omp* harness tool, not modsearch — this machine has never served a
  modsearch search without a key.
- [x] **`dsh-vision-toolkit` verified against the live endpoint, zero config (2026-09-11).**
  `GET https://vision.anionex.me/v1/models` with `Authorization: Bearer https://agent-vision.anionex.me`
  → **200** (`gemini-3.7-flash`); a real image turn with a screenshot → **correct description in ~7 s**.
  The endpoint is vision-only (`400` without an `image_url`) and Cloudflare-fronted (`403` to
  non-browser UAs; the packaged client sends a browser UA). Managed venv present at
  `$DSH_HOME/cache/dsh-vision-toolkit/python/*` (78 MB, py3.14, pillow 12.3.0 / numpy 2.4.6 /
  vtracer 0.6.15, `uv` manager, `runtime.json` pinning upstream `bc9803d`).
- [ ] Not yet exercised *through the harness* in a fresh session: `find_dsh_plugin`, `read_page`,
  `x_search`, `web_search` (blocked on the engine key above) and the `vision_*` set. A session opened
  before the restart does not carry them at all.

## 2026-09-12 — Image input, and a 3D scene built from a reference

Started from a Substack post (*"Dựng mô hình 3D văn phòng công ty bằng Three.js"*) and the question
"can DeepSeek do the same?". Answering it needed two things this repo did not have.

- [x] **Baseline failed, and not because of the repo.** `./init.sh` died with `EPERM` on
  `$DSH_HOME/profiles/headless/cordis.yml` under a `workspace-write` file policy. Recorded as
  [gotcha/init-sh-needs-dsh-home-write](knowledge/gotchas/init-sh-needs-dsh-home-write.md); the gate
  passes once `$DSH_HOME` is writable. A first-ever `./init.sh` run in an agent session will hit this.
- [x] **`feat-010` — the symlink had drifted.** `~/.dsh/settings.yaml` was a regular 2 543-byte file
  carrying an app-written `ui-onboarding` key, not the link `install.sh` creates. Every repo edit of
  `settings.yaml` had been a no-op for the server, and `init.sh` plus `doctor.sh` both passed anyway.
  `./install.sh --no-install` moved it to `settings.yaml.bak-20260912-101238` and linked the repo
  file; `doctor.sh` → READY (6 ok), 5 plugins already installed, 6 skills linked. New gotcha.
- [x] **`feat-011` — images work, and the flag was the only thing missing.** Proved the *route* first,
  straight at `https://opencode.ai/zen/go/v1`: text-only control → `pong`; a 64×64 PNG of a blue
  square at `detail: low` → **`A blue square.`** Then added `input: [text, image]` to the
  hand-declared `deepseek-flash` entry. `read_image` went from
  `model "deepseek-flash" does not declare image input` to describing a real 1600×1000 screenshot.
  No restart; the adapter re-reads per request. `deepseek-v4-pro` stays text-only — DeepSeek's model
  table marks vision unsupported there, so the whole image workflow runs on Flash.
- [x] **`feat-012` — the PoC, and what it caught.** `experiments/office-3d-poc/`: `index.html` (37 KB,
  one file, `file://`, no build), vendored Three.js r160 UMD (sha256 `170c6789…1d49fa`), and
  `verify.mjs` — a headless-Chromium CDP loop with **no npm dependencies** (Node 22 ships `fetch` and
  `WebSocket`). It fails the run on any console error or a missing `window.__poc`, so a clean log
  cannot pass for a working scene.
- [x] **The verification loop earned its keep.** The first run was clean — and wrong. Three rounds of
  *render it, look at it* fixed a ground floor that read as a black void, a roof railing that read as
  a black picture frame, and neighbour blocks filling the whole frame. When pixels stayed ambiguous,
  `verify.mjs --eval` queried the live scene and found the real bug: `instanced()` was composing
  `Matrix4` with the default `new THREE.Vector3()` **scale of (0,0,0)**, so every instance without an
  explicit `setScalar` was erased silently — fence pickets, stone pillars, roof posts, bamboo blinds,
  balcony flowers and the parked scooters all at once, with zero console output.
- [x] **Post-mortem on the source post is in the README.** Five transferable findings; the two worth
  repeating here: "console has no errors" is not verification, and the post's *single file* rule is
  unnecessary — a relative classic `<script src>` also runs offline from `file://`, which keeps the
  scene at 37 KB instead of ~700 KB. The post also pins Three.js **r128** (April 2021); r160 is the
  last UMD release and the right compromise while `file://` rules out ES modules.
- [x] `./init.sh` exit 0; `scripts/doctor.sh` READY; knowledge links resolve.

## 2026-09-14 — Restarting the web profile, and how to prove it came back

`dsh web` had exited on its own (`hub ps` → `exited exit=0`, uptime 1d1h), so the UI was down. Restart
is the `web` profile's real gate: the bundle set is composed at boot, so nothing about the plugins is
proven until the process is up again and the client halves are fetched.

- [x] Started it the way the profile needs — non-interactively, no TTY:

  ```bash
  hub start name=dsh-web application=dsh args=["web","--port","4319","--no-open"] pty=false
  ```

  Ready in **6.7 s** (pid 50166), log clean. `pty=false` matters: under a PTY, `dsh web` exits 0
  without serving (`knowledge/gotchas/web-ui-exits-under-a-tty.md`).

- [x] **The one-time token changed, and the old one is dead.** Read the new one from the startup log,
  then confirm it rather than assuming: new `?token=…` → `303` (sets the `dsh-auth-*` cookie), then
  `curl -b <jar> /` → **200**; the token from the previous boot → **401**. Capture the token
  immediately after the start — that is the only moment it is printed.

- [x] **Five plugins still live.** Roster (57 entries) under the new `rev 4dbf33d860c2e8bb` carries
  `dsh-mermaid`, `dshmarket`, `@liustack/modsearch` and `@anionex/dsh-vision-toolkit`; each
  `client.js` → **200** (23 550 / 42 614 / 567 583 / 143 381 bytes). `dsh-find-plugin` is host-only —
  no client bundle, so its absence is correct. Headless Chromium: UI renders, **0 console errors**,
  and the previous session list is intact.

- [x] `./init.sh` exit 0, `feat-009`…`feat-012` all `done`, harness audit 100/100, 129 links / 0 broken.

Note for next time: `curl -s ... | grep -o '{"id":"dsh-[^"]*'` **misses the scoped plugins** — use
`'{"id":"[^"]*","url":"[^"]*"'` and match names individually, or `@liustack/modsearch` and
`@anionex/dsh-vision-toolkit` will look missing when they are served fine.

## 2026-09-15 — ER and business-flow diagrams, and whether BPMN is usable here

Started from "is there a plugin for ER diagrams and business flows?" — answer: no plugin, and none is
needed for the first two. Then: "can BPMN draw workflows?" — yes, BPMN *is* the workflow notation, but
nothing in the ecosystem supports it, so the path had to be built and measured.

- [x] **The catalogue has no ERD or BPMN plugin at all.** Scanned the full npm `dsh-plugin` keyword
  (4 449 packages, paginated), the curated index (3 660 entries) and its ranking data
  (`data/stars.json` 1 484, `data/downloads.json` 624): **0 hits** for BPMN, DBML, PlantUML, ER /
  entity-relationship / schema diagram. The gap is ecosystem-wide, not a keyword artefact.
- [x] **ER and business flow already work — no install.** `dsh-mermaid@0.4.0` bundles mermaid 11.17.0;
  against its own served runtime, `erDiagram` → `<svg class="erDiagram">` (11 776 B) and `flowchart TD`
  → `<svg class="flowchart">` (17 675 B). Then proved it **through the live UI**: two prompts typed into
  the composer of the running `dsh web`, both answered and rendered by the plugin, Vietnamese labels
  and all. See `knowledge/gotchas/diagram-plugins-er-and-flow.md`.
- [x] **BPMN: mermaid cannot, and every renderer plugin is refused.** `render("bpmn\nA --> B")` →
  *No diagram type detected*. `dsh-drawio`, `dsh-flowchart`, `dsh-visualizer` and
  `@dsh-local/dsh-diagram` are all blocked by `./scripts/plugin-preflight.sh` on
  `@deepseek-ai/dsh-client-runtime`. Note the two failure families are different:
  `dsh-diagram@0.4.0` dies on `conversationEvents`, these four on `dsh-client-runtime`.
- [x] **The BPMN path works, and DI is the load-bearing part.** `bpmn-js@18.28.0`'s UMD
  navigated-viewer (194 KB) + its 3 CSS files render offline from `file://`: a hand-written
  purchase-approval process → 35 `.djs-element`, SVG 31 KB. The same XML **without**
  `bpmndi:BPMNDiagram` → `ERROR: no diagram to display`, so `bpmn-auto-layout@1.3.0`
  (bpmn-io, ⭐101) is mandatory, not optional.
- [x] **The model can author valid BPMN itself.** Asked the default route for the same process as BPMN
  XML with no DI: it produced 4 501 bytes with 8 tasks, 3 exclusive gateways and 14 sequence flows;
  `bpmn-auto-layout` resolved it to 28 shapes / 28 edges, and `bpmn-js` rendered it to a 36 KB SVG.
  Model → XML → auto-layout → viewer is a closed loop with no hand editing.
- [x] **MCP as the in-harness route is blocked at the plugin layer.** `dsh-mcp-adapter@0.6.3` fails the
  pre-flight on the same missing `dsh-client-runtime`; `dsh-mcp-proxy@0.1.0` and
  `dsh-mcp-lens@0.1.0-rc.9` are host-only and pass. The upstream BPMN MCP servers are tiny
  (`dattmavis/BPMN-MCP` ⭐12, `oisee/mcp-bpmn` ⭐9 — the `bpmn-js-mcp` repo the search engines cite
  returns 404), and no official `@deepseek-ai` MCP package is installed here.
- [x] **Artifact export needs no viewer page.** `bpmn-to-image@0.10.0` (bpmn-js + puppeteer, one
  command) turned both laid-out inputs into files in **6.5 s** — `purchase.png` 32 945 B, `gen.svg`
  36 417 B, Vietnamese labels intact. Cost: 70 MB `node_modules`, and it reused an existing
  `~/.cache/puppeteer` (1.5 GB, dated 2025-12-11) instead of downloading Chrome.
- [ ] Not done: no BPMN viewer is wired into the harness. Both verified routes live in `/tmp` today —
  a vendored `bpmn-js` viewer page, or `bpmn-to-image` for artifacts. Whether either belongs in this
  repo or in the project that needs the diagrams is an open choice, not a technical unknown.

## Notes for Next Session

The route is `AGENTS.md` → `./init.sh` → `feature_list.json` → `progress.md` → `knowledge/index.md`.
Reproducibility rests on four pins — `dsh.version`, `.nvmrc`, `plugins.json`, and the ponytail
`UPSTREAM_REF` — plus one invariant this session found by accident: **`~/.dsh/settings.yaml` must be
a symlink**, or nothing you write here reaches the running server. Check the arrow, not just the
file. The image route is now open on `deepseek-flash`, which makes the harness usable for any
screenshot-driven work, not just this PoC.

`./init.sh` needs write access to `$DSH_HOME`; under a `workspace-write` sandbox it stops at the
compose step with a bare Node `EPERM`. That is the sandbox, not the repo — say which one you hit
rather than reporting a red gate.

## 2026-09-15 (later) — BPMN inside the web UI: yes, without a plugin

The open question from the section above — "can this be shown *in* the harness?" — is answered, and
the answer is a workspace page rather than a plugin.

- [x] **`experiments/bpmn-viewer/`** — an 11 KB self-contained page rendering real BPMN 2.0 in the
  official document preview. 4 packed assets, **333 995 B** total (bpmn-js 18.28 UMD + 3 CSS +
  the laid-out XML inlined). No plugin, no build step, no network at runtime.
- [x] **The host's contract, read from the source and then obeyed.** The preview packs **only direct
  classic `<script src>` and `<link rel=stylesheet>`** into `blob:` URLs inside an
  opaque-origin `sandbox="allow-scripts"` iframe (4 MB/asset, 32 MB / 64 files). Hence: vendor the
  viewer and CSS locally, inline the XML (a runtime `fetch` is not in the packed set and the origin is
  opaque), and avoid CSS `url()` — `bpmn-embedded.css` carries its font as base64.
- [x] **Two traps that only appear in this host.** `canvas.zoom("fit-viewport")` **throws**
  `SVGMatrix.scale … non-finite` on a 0×0 container (the mount state) and silently leaves scale 1 on a
  hidden one — so the page fits declaratively with a `viewBox` pinned to the content bbox plus
  `preserveAspectRatio`, which makes every later resize automatic. And the page must **measure
  itself**: a parent cannot read a sandboxed frame's DOM (`SecurityError`, origin `"null"`), and a
  page global is not reliably visible across automation worlds, so the check is published into
  `<pre id="fit">`.
- [x] **Verified `pass: true` twice** — opened directly, and through `preview-sim.mjs`, which
  reproduces the host's pipeline byte for byte (opaque sandbox, blob-rewritten assets,
  `document.write` bootstrap): 38/38 elements painted, painted box 1348×195 inside 1365×768, i.e.
  fitted rather than left at scale 1. The dsh panel itself renders the diagram with its icons
  (`BPMN 2.0 · 38 elements`).
- [x] **Closing the loop on the real UI** (the simulator was not enough): with
  `experiments/bpmn-viewer/index.html` open from the Files panel, the frame is a
  `blob:http://127.0.0.1:4319/…` URL with `sandbox="allow-scripts"` and its own `#fit` reports
  **`pass:true`** in both the narrow panel (container 614×692, painted 606×88) and fullscreen
  (1365×692, 1348×195) — the viewBox fit refits by itself, and the packed `bpmn-embedded.css` font
  resolves inside the sandbox (user-task figures, service-task cogs, gateway ×, start/end circles).
- [x] **Measurement gotcha worth keeping:** read `#fit` in the *same* automation cell that forces a
  render. An idle tab is frozen between operations, and a frozen frame reports `clientWidth/Height 0`
  with rAF paused — so a later read republishes `container {w:0,h:0}`, a freeze artifact that looks
  exactly like a fit failure. An earlier read of mine said `pass:false` for that reason, not for a
  real reason.
- [ ] Still open: previewing a `.bpmn` **from a chat message**. The MCP route stays blocked at the
  plugin layer, and the upstream BPMN MCP servers are tiny (⭐12 / ⭐9; the widely-cited `bpmn-js-mcp`
  repo 404s).

## 2026-09-15 (later still) — does asking for BPMN in chat make this happen? No.

Tested by actually asking the running `dsh web`, not by reasoning about it.

- [x] **Nothing auto-triggers.** "Vẽ sơ đồ BPMN cho quy trình mua hàng" → 45 tool calls, 4 minutes,
  and the output was `diagrams/quy-trinh-mua-hang.{mmd,png,svg}`: a **mermaid `flowchart TD` with
  `subgraph` lanes, called BPMN**. Nothing rendered in the chat (0 mermaid fences, 0 images) — just
  file chips. The agent even said so itself: *"chọn mermaid vì nó render được trong chat"*, and that
  mermaid has no BPMN. A follow-up that named `experiments/bpmn-viewer/` and the runbook produced
  real BPMN (`*.source.bpmn` → `bpmn-auto-layout` → 44 shapes, PNG + SVG, `pass:true`) — so the path
  works, but only when someone says where it is.
- [x] **Why:** the viewer is a static workspace page and the runbook is workspace-local, so neither can
  fire on its own; an agent in another workspace sees neither. The only auto-surface is a **skill** in
  `~/.dsh/skills`, whose name+description `dsh-tool-skill` injects into every session's context.
- [x] **Added `skills/draw-bpmn/`** — notation decision table (mermaid vs BPMN), the four steps, five
  traps including lanes and label collisions. Linked to `~/.dsh/skills` (`doctor.sh` READY, 7 bundles,
  `init.sh` green). No restart needed: the catalog is recomputed per `agent/pre-step`, but a **new
  session** is required — plugins and skills compose per session.
- [x] **`inline.mjs`** — writing a fresh `.bpmn` next to `index.html` does **not** change what the
  viewer shows; the page was still rendering `Process_PurchaseRequest` while the agent's
  `Process_QuyTrinhMuaHang` sat beside it, and it looked fine. The script refuses XML without
  `bpmndi:BPMNDiagram` and prints the process id it inlined. Re-inlined: 44 shapes, 64 elements,
  `pass:true`.
- [ ] Honest limit: `bpmn-auto-layout` **drops lanes/pools** (0 lanes in the DI, no error). The agent
  hit this too. Roles must go in the task label or the lane DI must be hand-written.
- [ ] Housekeeping decided explicitly, not swept in: `diagrams/` is my test prompt's mermaid output
  (the very mislabel this skill exists to prevent) — left untracked; `.gitignore` now states *why*
  `.gstack/` is ignored (it holds `terminal-internal-token`, a credential).

## 2026-09-15 (evening) — a real leave-request BPMN, and why the DI is hand-placed

- [x] Ask: *"vẽ sơ đồ BPMN 2.0 cho quy trình xin nghỉ phép: nhân viên gửi đơn, quản lý duyệt, nếu
  nghỉ trên 3 ngày thì HR duyệt nữa, rồi cập nhật lịch."*
- [x] `diagrams/xin-nghi-phep.source.bpmn` — 13 flow nodes, 14 sequence flows, **no DI**. Main path
  on one row, HR approval on a second, a merge gateway and the reject row on a third. Roles are
  label prefixes (`[NV]` / `[QL]` / `[HR]` / `[HT]`) because `bpmn-auto-layout` drops `bpmn:Lane`.
- [x] `diagrams/make-bpmn.mjs` — injects the hand-placed DI into the DI-free source and **refuses to
  write if a shape/edge no longer matches a source element id**. Needed because auto-layout routed
  three flows down one channel (they render as one line) — see the runbook trap.
- [x] Rendered `xin-nghi-phep.png` (1107×472) + `.svg` with `bpmn-to-image@0.10.0`; inspected three
  zoomed crops — no edge-label/gateway collisions.
- [x] `diagrams/xin-nghi-phep.html` — offline bpmn-js viewer reusing
  `experiments/bpmn-viewer/vendor/*`; XML inlined. `preview-sim.mjs` packs 4 assets / 340 326 B, and
  a headless check reports `pass:true`, **39 elements, 0 console errors** on both `file://` and the
  simulated document-preview pipeline.
- [x] `./init.sh` exit 0 — but only with `DSH_HOME` pointed at a throwaway workspace dir; the default
  run dies `EPERM` on `$DSH_HOME/profiles/headless/cordis.yml`, the documented sandbox limit
  (`gotcha/init-sh-needs-dsh-home-write`), not a repo defect. Cleaned up after.
- [ ] Honest limits: no swimlanes (runbook trap: auto-layout cannot keep lanes, and lanes were not
  asked for); the files are still untracked — `git` in this sandbox carries `GIT_CONFIG_COUNT` with
  no matching `GIT_CONFIG_KEY_*`, so `git status`/`log` fail until those vars are unset.

### Closing check — the skill does trigger

A fresh headless session, asked only *"Vẽ cho tôi sơ đồ BPMN 2.0 cho quy trình xin nghỉ phép…"* with
**no mention of this repo**, produced real BPMN: `diagrams/xin-nghi-phep.{source.bpmn,bpmn,html,svg,png}`
+ a `make-bpmn.mjs` regeneration checker. It used this skill's vocabulary unprompted (`*.source.bpmn`
with no DI, `bpmn-to-image`, the `#fit` self-check it carried into its own viewer) and volunteered the
laneSet limitation before being asked. Verified from here: that viewer renders **39 elements,
`pass:true`** on `file://`.

It also improved on the skill: `bpmn-auto-layout` had put three distinct flows on one channel (the
HR-reject path running back 750 px, reading as a single line), so it hand-placed the DI and wrote a
checker that **refuses to write** when shape/edge ids drift from the source. Worth folding into the
skill next time.

`diagrams/` (both the mermaid lookalike from the first probe and this real BPMN set) is intentionally
**left untracked** — it is test output, not this repo's deliverable.

## 2026-09-15 (closing) — both diagram paths verified from chat

- [x] **mermaid, re-verified *after* the skill existed** (the earlier proof predated it, and the
  skill's description covers "vẽ sơ đồ … quy trình", so the mermaid half was not safe to assume).
  `dsh --profile headless "vẽ sơ đồ quy trình mua hàng bằng mermaid"` → a mermaid fence, and in the
  web chat **2 `flowchart` SVGs with "Mermaid diagram rendered" in 15 s**. The model read
  `draw-bpmn`'s description and correctly declined it — the skill says so explicitly: *"Do NOT use for
  a quick process sketch; a mermaid `flowchart TD` fence is better there."*
- [x] **BPMN from chat**, verified twice: a fresh headless session produced
  `xin-nghi-phep.{source.bpmn,bpmn,html,svg,png}` with no repo pointer, and a fresh web session
  (127 steps, 14 min) produced `travel-expense.*` — 5 tasks, 6 gateways, 12 flows, 20 DI shapes, never
  reaching for mermaid, viewer `pass:true` at 33 elements.
- [x] **`inline.mjs` now retitles the page** from the process `name` (falling back to the process id).
  Copying the viewer directory is how each diagram gets its page and the title lives outside the
  inlined XML, so a copy had shipped with the *previous* diagram's name in the tab. Verified both
  branches: `name` present → `BPMN — Quy trình mua hàng`; stripped → `BPMN — Process_QuyTrinhMuaHang`.
- [x] **`feat-013` recorded** — this session shipped a user-visible capability (a skill) with no
  feature entry, while `progress.md` still read "the backlog is empty". Its precedent `feat-012` had
  one. Feature list is now 13 / 0 in-progress and the header agrees.

## 2026-09-15 (evening) — Devin SWE-2 into dsh, without a proxy

Question: the omp harness had just moved its free lanes onto Devin SWE-2 (TokenRouter's free GLM
quota ran out); can dsh use the same model? SWE-2 has no public API — Cognition runs it only
inside Devin over Connect-RPC — and the community bridges (`cognition-claude-proxy`, a Python
shim behind CLIProxyAPI) are reverse-engineered, 0-star, and sanitize the system prompt.

- [x] **The bridge already existed.** omp ships `auth-broker` (credential vault) + `auth-gateway`
  (OpenAI Chat Completions / Anthropic Messages / Responses front over its own provider logic).
  Its `devin` provider is first-class. So dsh gets an ordinary `openai-completions` route at
  `http://127.0.0.1:4000/v1` with model `devin/swe-2` — nothing to install in dsh, no plugin.
- [x] **Measured at that endpoint (the exact wire dsh uses):** plain → `GW OK` in 7.4 s with
  `usage`; `stream: true` + `tools` → streamed `tool_calls` deltas with server-minted ids;
  `system` + `reasoning_effort` `medium`/`high`/`max` → answered, `reasoning_content` returned;
  no bearer → `{"error":"unauthorized"}`.
- [x] **Two traps, both written down** (`docs/models.md`, `knowledge/systems/omp-gateway-route.md`):
  the gateway builds `/v1/models` at boot from providers that already hold a credential, so a
  gateway started before `auth-broker migrate --include-env` uploads the Devin key answers
  `Unknown model: devin/swe-2` until restarted; and `max_tokens: 20` is eaten by reasoning
  (`finish_reason: length`, `content: null`). `scripts/omp-gateway.sh start|stop|status` encodes
  the order; `start` is idempotent (second run leaves 2 processes), `status` posts one real
  completion with the bearer.
- [x] `settings.yaml`: `omp-gateway` route added **after** `opencode-go`, so `doctor.sh`'s
  first-provider probe still targets `deepseek-flash` and the default model is unchanged.
  `.env.example` documents `OMP_GATEWAY_API_KEY` (the gateway's own token; `start` prints it).
- [ ] **Not exercised inside dsh.** `dsh` is not installed on this machine right now (`~/.dsh`
  absent, no global package), so neither `doctor.sh` nor the composer picker ran. First thing on
  a machine that has it: `./scripts/omp-gateway.sh status`, then one composer turn on
  *SWE-2 (Devin, via omp)*.
- [x] `./init.sh` → exit 0 (14 features, 0 in-progress; settings parse; default resolves).

Decision: **reuse omp's gateway, do not write a proxy or a dsh plugin.** A plugin would have
to reimplement Connect-RPC against an undocumented backend; the gateway is maintained upstream
and already carries the Devin quirks. Trade-off: two loopback processes and a dependency on
`omp >= 18.2` being installed — acceptable, it is the other harness on every machine here.
- [x] **Later the same evening — proven inside dsh.** `./install.sh` reinstalled `dsh 0.1.5-rc.1`
  (the machine had none), keys seeded into `~/.dsh/.env`, `doctor.sh` READY (6 ok), `dsh web`
  booted clean (4 client bundles served, 0 errors), and a composer session on
  *SWE-2 (Devin, via omp)* worked. Setup on another machine: `knowledge/runbooks/new-machine-setup.md`.

## 2026-09-16 — the settings symlink breaks itself, and doctor could not see it

Applying the config found the symlink drifted *again* — the fourth time — and the live file was
missing the whole `omp-gateway` route the repo declared. Chased it to the source.

- [x] **Root cause, code-confirmed then reproduced.** `dsh-settings-file` persists through
  `dsh-atomic-write`: `writeFile('<path>.<hex>.tmp')` then `rename(temp, path)`, with no
  `realpath`. `rename()` replaces the **link**, not its target. So *any* UI settings write breaks
  it — proven by restoring the link and picking a model in the picker: drifted within 3 s, and the
  live file showed exactly the predicted changes (`[ text, image ]` reserialised,
  `agent-default-model` rewritten, new `ui-onboarding` key). The first version of the gotcha blamed
  a stray `cp`/restore/skipped install; that guess was wrong and is corrected.
- [x] **Why four drifts stayed green:** `doctor.sh` accepted `[ -L … ] || [ -f … ]` and recorded
  "present" — a regular file satisfies it. One of those drifts hid the missing `omp-gateway` route
  for a day. `settings` now **requires the link, resolved into this repo**, and the failure names
  the cause and the fix. Verified: regular file → NOT READY; link to `/tmp` → NOT READY; correct
  link → READY (6 ok).
- [x] **A second trap in the same write.** The app had persisted
  `agent-default-model.provider: vision-toolkit-opencode-go` — an id registered at *runtime* by
  `@anionex/dsh-vision-toolkit` and only on the `web` profile, absent from `llm-pi-ai.providers`.
  Had that landed with the link intact, the shared default would name a provider that does not
  exist for `headless`/`tui`/`sdk`. `init.sh` **already** asserts this (negative-tested: exit 1 on
  the bad id, 0 restored) — but it reads the repo file, so it only helps once the link is intact.
  The two checks are complementary, not redundant.
- [x] Applying the config afterwards: `./install.sh --no-install` relinked, 7 skills linked, 5/5
  plugins already installed, `doctor.sh` READY. Broker + gateway started; `swe-2 via gateway: OK`;
  a real dsh turn on SWE-2 returned `GW OK` both headless (4.2 s) and in the UI (5 s, badge
  `SWE-2 (Devin, via omp)`).
- [ ] Standing caveat: **expect to relink after using the UI panels.** There is no way to make the
  app write through a link without patching it, so the check is the mitigation, not a fix. Run
  `./scripts/doctor.sh` after changing settings in the UI.

- [x] **Follow-up while verifying: ordinary UI use writes settings too.** Dismissing the onboarding
  notice drifted the link a fifth time (the app persists `ui-onboarding.welcomeNoticeVersion`), so
  this is not limited to deliberate setting changes. `doctor.sh` now distinguishes the two severities:
  *content still matches the repo* (latent — costs you the next edit) vs *the live file has DIVERGED*
  (the server is already running settings the repo does not describe — the case that hid
  `omp-gateway`). Both branches verified, with the wrong-target and correct-link branches.
- [x] Note on the model picker: it showed `GLM 5.3` in the panel because that **session** carries the
  model selected during the drift test, not because the default changed — the repo default
  (`opencode-go/deepseek-flash`) is what `init.sh` asserts and what `doctor.sh` exercises.

### Correction — the drift trigger is a settings *write*, not "using the UI"

An earlier bullet here said ordinary UI use writes settings and drift should be expected after any
session in the UI. That was wrong, and it contradicted my own check (opening a tab left the link
intact) plus the source: `acknowledge()` has exactly one caller — the welcome modal's Continue
button — and the only other path is an explicit settings write.

Accurate rule: **every explicit settings write drifts the link** (model pick, font size,
acknowledging the notice). Opening the UI, switching workspace and starting a session only *read*
settings and leave the link intact. Which also upgrades the `ui-onboarding` commit from cosmetic to
a cure: with the key present, `state.acknowledged` is true on load and the modal returns `null`
before rendering, so the most frequent drifting click no longer exists.

## 2026-09-17 — Machine re-applied, BPMN removed

- [x] `./init.sh` exit 0; `./install.sh` → dsh 0.1.5-rc.1 present, 5/5 plugins already installed,
  `doctor.sh` READY. **Symlink drift #5**: `~/.dsh/settings.yaml` was a regular file again (UI model pick
  → `vision-toolkit-omp-gateway/devin/swe-2`); relinked, backup `settings.yaml.bak-20260917-224203`,
  nothing merged (profile-local provider id).
- [x] Gateway was down after reboot → `omp-gateway.sh start` → `swe-2 via gateway: OK`. `dsh-web`
  restarted (`pty=false`, :4319): token 303, `/` 200, 4 plugin client bundles in the roster.
- [x] **BPMN removed from the repo on request**: `skills/draw-bpmn/`, `experiments/bpmn-viewer/`,
  `knowledge/runbooks/draw-bpmn-workflow.md`, the runbook index row, the handoff risk line, the README
  line; `~/.dsh/skills/draw-bpmn` unlinked. Mermaid (`dsh-mermaid`) remains the diagram path — ER and
  flowcharts. The dated 2026-09-15 sections above are history and stay as written.
