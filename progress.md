# Session Progress Log

## Current State

**Last Updated:** 2026-09-11 13:25 (+07) — `web` profile restarted, the five plugins are live
**Active Feature:** none — `feat-009` closed; the backlog is empty
**Repo:** `deepseek-harness-config` @ `main`
**Harness:** adopted 2026-09-10 (`AGENTS.md`, `feature_list.json`, `progress.md`, `init.sh`, `session-handoff.md`, `docs/specs|plans`, `knowledge/`)

## Status

### What's Done

- [x] Adopted the DCNET harness: state files, `docs/specs/` + `docs/plans/`, and `AGENTS.md` as the routing pointer.
- [x] `init.sh` — offline gate: script syntax, feature-list shape, `settings.yaml` parse + default-model resolution, skill frontmatter, plugin manifest, and the wiring guards for CI, the plugin applier, the pre-flight and the Node check.
- [x] OKF `knowledge/` bundle: index + log + six category indexes + 29 concepts.
- [x] `feat-003`: CI runs `./init.sh` on push and pull request; `.nvmrc` pins Node 22.
- [x] `feat-004`: `scripts/update-ponytail.sh` — drift check and `--apply` against a pinned upstream ref.
- [x] `feat-005`: `scripts/doctor.sh --json` — one machine-readable readiness object.
- [x] `feat-006`: `plugins.json` + `scripts/install-plugins.sh` make the plugin set reproducible.
- [x] `feat-007`: `scripts/plugin-preflight.sh` refuses a plugin the pinned dsh cannot run.
- [x] `feat-008`: `scripts/check-node.sh` — Node 20 floor from `.nvmrc`, run before anything is created.
- [x] `feat-009`: plugin set expanded from 1 to 5 on the `web` profile after a pre-flight survey of the curated list — installed, composed, and **live** since the `dsh web` restart (roster + `client.js` 200 + Settings tabs).
- [x] `./init.sh` passes; harness audit 100/100; knowledge links resolve.

### What's In Progress

- [ ] Nothing — session closed cleanly.

### What's Next

**No open features.** Candidates, in the order they would pay off:

1. **Restart the `web` profile** so the four new bundles actually load, then verify from the shell
   with the served-roster recipe in `docs/plugins.md` (registry inline in `/`, `client.js` → 200).
   Until then nothing proves the client halves activate — the pre-flight admits it cannot see that.
2. Configure the new plugins' credentials: `modsearch` (search route/keys) and
   `dsh-vision-toolkit` (vision model/key). They are installed but unconfigured.
3. Turn the 2026-09-11 category survey into a chosen shortlist. The ranked catalog (3 431 entries
   with stars/downloads per category) is at `/tmp/adp/report.md` — ephemeral; move anything worth
   keeping into `knowledge/`. Categories worth a real decision next: Memory (vs this repo's OKF),
   Skills/Workflow (vs `dcnet-workflow`), Security (`api-relay-audit` for the relay, permission
   rules), Development & Runtime (`dsh-undo-savepoint`, `dsh-context-doctor`).
4. A mock boot of a throwaway profile would catch the compiled-only client failures the pre-flight
   admits it cannot see.
5. The two official optional bundles (`@deepseek-ai/dsh-subagent-codex`,
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

## Notes for Next Session

The route is `AGENTS.md` → `./init.sh` → `feature_list.json` → `progress.md` → `knowledge/index.md`.
Reproducibility rests on four pins — `dsh.version`, `.nvmrc`, `plugins.json`, and the ponytail
`UPSTREAM_REF`. The plugin pin grew from 1 to 5 this session, and the two filters that guard it are
now written down: `npm view <spec> repository.url` for identity, `plugin-preflight.sh` for release
compatibility. The restart is done and the five bundles are live; `read_page` and the vision defaults
are the two paths verified end to end. The next concrete step is a search engine key for `modsearch`,
then exercising the tools from a **fresh** session (composition is per session) — usage for each is in
`docs/plugins.md` → *How to use them*.
