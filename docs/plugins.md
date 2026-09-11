# Plugins

Dsh installs a plugin into a **profile** — `$DSH_HOME/profiles/<name>/` — which is machine state this
repo deliberately does not track. So the plugin set is declared in
[`plugins.json`](../plugins.json) and applied by
[`scripts/install-plugins.sh`](../scripts/install-plugins.sh), which `install.sh` calls. A second
machine that clones this repo and runs `./install.sh` ends up with the same plugins at the same
pinned versions.

## The set

| Profile | Package | What it does | Source |
|---|---|---|---|
| `web` | `dsh-mermaid@0.4.0` | renders ` ```mermaid ` fences as theme-aware SVG diagrams in chat | [MrmoLabs/dsh-mermaid](https://github.com/MrmoLabs/dsh-mermaid) |
| `web` | `dshmarket@1.45.1` | the plugin market inside Settings: browse, search, install, update, switch themes | [dsh-market/dsh-market](https://github.com/dsh-market/dsh-market) |
| `web` | `dsh-find-plugin@0.3.7` | host-only tool: the agent searches the curated registry and hands back a ready `dsh plugin add` line | [awesome-dsh-plugin/dsh-find-plugin](https://github.com/awesome-dsh-plugin/dsh-find-plugin) |
| `web` | `@liustack/modsearch@5.10.2` | web search + page fetch returning cited JSON, standing in for the credential-less built-in `web_search` | [liustack/modsearch](https://github.com/liustack/modsearch) |
| `web` | `@anionex/dsh-vision-toolkit@0.1.44` | vision tools for text-only routes: image Q&A, comparison, OCR, crops, pixel diff | [Anionex/dsh-vision-toolkit](https://github.com/Anionex/dsh-vision-toolkit) |

Every entry publishes a `dsh.bundle` patch, except `dsh-find-plugin`, which is host-only. Versions are
pinned exactly; `./init.sh` rejects `latest`, `*`, `^`, `~`, a missing field, or a duplicate entry.

## How to use them

**`dshmarket` — Settings → *Plugin Market*.** No CLI needed. Browse/search the community catalog
(2 300+ entries, category filters, star counts), one-click install with live progress, a *Themes* tab
(install → active immediately, one click to switch), per-plugin update checks, uninstall, and hot
disable/enable that writes a `disabled:` row into the profile's `cordis.patch.yml` (HMR re-composes in
~1 s, no restart). *Diagnostics* shows the load order and conflicts; *Backup & restore* exports the
plugin list as JSON. The market manages itself from **Settings → Plugins → Plugin configuration**.
Reproducibility caveat: see the market/`plugins.json` rule below.

**`dsh-find-plugin` — ask the agent.** It registers the `find_dsh_plugin` tool: a live GitHub search
over the public `dsh-plugin` topic, ranked by stars, enriched with the curated list's descriptions. It
returns ready-to-run `dsh plugin add` lines. Prompt shape: *"find me a dsh plugin for X"* /
*"có plugin dsh nào làm Y không?"*. Host-only: it needs no profile client. (The reference catalogue is
also reachable as a plain HTTP fetch — `web_fetch`/`read_page`, no key.)

**`modsearch` — three agent tools; page fetch works keyless, web search needs one engine key here.**
The layer above reroutes the `web` row's `searchProvider` to `modsearch`, so the built-in
credential-less DeepSeek engine is bypassed. It registers `web_search` (the ordinary search tool),
`read_page` (one specific URL) and `x_search` (X/Twitter).

The engine set is resolved per machine — check it before promising a search:

```bash
npx @liustack/modsearch doctor          # from the profile dir; no quota, no network
```

Measured on this machine (2026-09-11):

| Source | Resolved | State |
|---|---|---|
| fetch (→ `read_page`) | `local` | **READY keyless** — verified: `example.com` → 200, content + links + uncertainty |
| search (→ `web_search`) | `firecrawl` | keyless **refused from this IP** (`403`, "your IP address looks suspicious"); needs a key |
| social (→ `x_search`) | none | needs the `grok` CLI signed in |

So a working search needs **one** of: a free Firecrawl key (`modsearch config set firecrawl.apiKey <k>`,
1 000 credits/month), `TAVILY_API_KEY`, `EXA_API_KEY`, or the Antigravity CLI
(`curl -fsSL https://antigravity.google/cli/install.sh \| bash && agy`). The same keys can be set in
**Settings → Plugins → Plugin configuration → Search engine (ModSearch)**, which POSTs to
`/modsearch/config`; route health reads back from the same URL with the session cookie. `fetch` keeps
working with nothing set.

**`dsh-vision-toolkit` — Settings → *Vision*, and it works with zero configuration.** Pick the
protocol (OpenAI Chat Completions or Anthropic Messages), base URL, model, API key. The default is the
vendor's free service — `https://vision.anionex.me/v1`, model `gemini-3.7-flash`, and the API key is
the literal string `https://agent-vision.anionex.me` (`lib/defaults.js`:
`BUILT_IN_FREE_VISION_BASE_URL` / `BUILT_IN_FREE_VISION_KEY`). Verified against that endpoint:
`GET /v1/models` → 200, and a real image call returned a correct description in ~7 s. The endpoint is
vision-only (`400` *"At least one user image_url is required"* for a text-only turn) and sits behind
Cloudflare, which serves `403` to non-browser user agents — the packaged client sends a browser UA by
default, so this only matters if you call it by hand. Tools:

| Local (never uploads the image) | Remote (sends the image bytes to the configured API) |
|---|---|
| `vision_crop`, `vision_trace`, `vision_pixel_diff`, `vision_dominant_colors`, `vision_extract_foreground`, `vision_html_screenshot` | `vision_glance`, `vision_ground`, `vision_detect`, `vision_long_screenshot_ocr` |

Loading the `vision-skills` Skill activates them; if the visual tools are still missing in a session,
call `vision_toolkit_activate` once — it disappears after success. Inputs must resolve inside the
session workspace, the platform temp dir, or an `allowedDirs` entry; outputs stay in the
plugin-managed output directory. The managed runtime is a Python venv at
`$DSH_HOME/cache/dsh-vision-toolkit/python/<hash>` (pillow, numpy, vtracer); if it is absent the first
use prepares it (up to 10 minutes, needs network + `uv`).

> **Tools appear per agent session.** A session that was already open before the restart runs the old
> plugin set: `read_page`, `find_dsh_plugin` and the `vision_*` tools are simply not in it. Open a new
> session (or reload the page) after a plugin change.

> **All five live on the `web` profile only.** `plugins.json` declares nothing for `headless`, `sdk`,
> `sdk-minimal` or `acp`, so a session booted from those profiles gets the dead built-in `web_search`
> and none of these tools.

> **The market is for browsing; `plugins.json` is the source of truth.** Anything installed through
> the Plugin Market UI writes to the machine-local profile (`~/.dsh/profiles/web`) and nowhere else, so
> it is absent on a second machine and `./init.sh` will not notice — it validates the manifest, not
> installed state. Any keeper therefore goes through the documented path: `./scripts/plugin-preflight.sh
> <spec>`, add the entry to `plugins.json`, `./scripts/install-plugins.sh`, commit. The applier is
> add-only and will not fight or uninstall what the market added.

> **Why these four were added (2026-09-11).** Three gaps in ordinary use: no in-harness way to
> discover a plugin, a built-in `web_search` that fails with *"no API key for `DEEPSEEK_API_KEY`"*, and
> hand-declared routes (`deepseek-flash`, `deepseek-v4-pro`, `glm-5.3`) that accept **text only**.
> `dshmarket` + `dsh-find-plugin` close the first, `modsearch` the second, `dsh-vision-toolkit` the
> third. All five entries passed `./scripts/plugin-preflight.sh`; only `dsh-vision-toolkit` *declares*
> `dsh.compatibility.dshReleases["0.1.5-rc.1"] = compatible` — for the others the pre-flight reports
> `note: no dsh.compatibility declared`, which is a filter, not a guarantee.
>
> `modsearch` needs no key for its default engines and `dsh-vision-toolkit` ships a free default
> service; this repo installs both but configures neither, so they run on those vendor defaults.
> `pnpm` prints missing-peer warnings (`@deepseek-ai/cordis`, `@deepseek-ai/dsh-tools`, `react`, …)
> for every one of them — the host supplies those, so they are warnings, not failures.

> **Refused by the pre-flight, 2026-09-11.** `dsh-vision-router@2.1.5` (⭐775),
> `dsh-web-search-pro@0.1.11` and `dsh-free-search@0.4.24` (⬇2 141) all inject
> `@deepseek-ai/dsh-client-runtime`, which dsh `0.1.5-rc.1` does not provide — `exit 1`, not installed.
> They are the *most popular* entries in their categories. Popularity is not compatibility; see
> `knowledge/gotchas/plugin-fit-vs-popularity.md`. `@liustack/modlens@3.26.1` (⭐3152) does pass and is
> the richer vision alternative if `dsh-vision-toolkit` disappoints.

> **`dsh-diagram` is deliberately not in the set.** Its client bundle injects a `conversationEvents`
> service that does not exist in the pinned dsh (`0.1.5-rc.1`; its own compatibility list stops at
> `0.1.1-rc.2`), so the layer composes but its client entry never activates and the web UI dies at
> boot with `Failed to load plugins`. Verified 2026-09-11: `dsh-diagram@0.4.0` installed → boot
> failed; removed → boot clean and `dsh-mermaid` rendered. Re-add it only when a release lists dsh
> 0.1.5 in `dsh.compatibility.dshReleases`. See
> `knowledge/gotchas/dsh-diagram-incompatible-with-pinned-dsh.md`.


> **Name collision.** `AKS1st/dsh-mermaid` (v0.5.0) also calls its package `dsh-mermaid`, but the npm
> name belongs to `MrmoLabs`. `dsh plugin add dsh-mermaid` therefore installs MrmoLabs's v0.4.0. The
> npm route was chosen because it needs no `prepare` build — a git-sourced install would require a
> machine-local `allowBuilds` edit in the profile's `pnpm-workspace.yaml`, which would break
> reproducibility. The same trap appeared with `modsearch`: the unscoped npm name is an unrelated
> package, and the list's plugin publishes as `@liustack/modsearch`. Check `npm view <spec>
> repository.url` before pinning. See `knowledge/gotchas/dsh-mermaid-npm-name-collision.md` to switch.

## Where candidates come from

[`awesome-dsh-plugin/awesome-dsh-plugin`](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)
(⬇ CC0, 23 categories, ~3.4k entries) is a **curated index, not a manager**: it never installs
anything. Its `data/stars.json` and `data/downloads.json` are useful for ranking, with two caveats —
they cover 1 488 and 624 entries respectively, and both are snapshots (2026-08-19 at the time of
writing). The managing half is `dshmarket` (in the set above) or `dsh plugin … add` directly.

## Apply and check

```bash
./scripts/install-plugins.sh --dry-run   # print the plan, change nothing
./scripts/install-plugins.sh             # install what is missing or off-version
./scripts/install-plugins.sh             # re-run: reports "already installed" when in sync
dsh plugin --profile web list            # what the profile actually carries
```

`install.sh` runs this automatically; a failure warns instead of aborting, so re-run the script.

## Pre-flight

A correct version pin is not a compatible one — that is what `dsh-diagram` proved. So before anything
touches a profile, each plugin is checked against the pinned dsh by
[`scripts/plugin-preflight.sh`](../scripts/plugin-preflight.sh), from its published manifest only:

| Check | Rule |
|---|---|
| `dsh.compatibility.dshReleases` | when the plugin declares the map, the pinned release must be listed as `compatible` |
| `dsh.client.inject` | every id must exist in the pinned install — a directory, or a literal string under its `@deepseek-ai/` |

```bash
./scripts/plugin-preflight.sh dsh-mermaid@0.4.0                  # 0 = ok
./scripts/plugin-preflight.sh dsh-diagram@0.4.0                  # 1, names the missing release
./scripts/plugin-preflight.sh <spec> --dsh-version 0.1.1-rc.2    # check against another release
```

`install-plugins.sh` skips a rejected plugin, counts it as *blocked*, and exits non-zero;
`--skip-preflight` is the deliberate override. The pre-flight reads metadata and never executes plugin
code, so it **cannot** see a bare service name that lives only in compiled client code: a pass is a
filter, not a guarantee, and the browser after a restart remains the final gate.

## Adding or bumping a plugin

1. Resolve the real npm spec and confirm `npm view <spec> repository.url` matches the repo you mean.
2. Add or edit one entry in `plugins.json`: `{ "profile": …, "package": "name@x.y.z", "source": … }`.
3. `./scripts/plugin-preflight.sh <name>@<x.y.z>` — never install past a rejection.
4. `./scripts/install-plugins.sh` to apply, then `./init.sh` to validate the manifest.
5. Commit `plugins.json` — that is what makes the change reproducible elsewhere.

## Restart requirement

A running profile keeps the bundle set it started with. After adding, removing, or updating a plugin,
**restart that profile** (`dsh web`). Restart it non-interactively: `dsh web` exits immediately when
stdout is a TTY (see `knowledge/gotchas/web-ui-exits-under-a-tty.md`). Ordinary `cordis.patch.yml`
edits hot-reload instead — only bundle membership needs the restart.

**Live since the 2026-09-11 restart.** All four new bundles run in the server on `:4319`: the served
roster carries a client entry for `dsh-mermaid`, `dshmarket`, `@liustack/modsearch` and
`@anionex/dsh-vision-toolkit` (each `client.js` → 200), the boot log is clean, and Settings renders
the tabs they contribute — *Plugin Market*, *Vision*, and *Search engine (ModSearch)*. `dsh-find-plugin`
is host-only and publishes no client bundle, so it appears in the composed tree and never in the roster;
its activation is the error-free boot.

## Verify the restart actually took

`dsh --profile web --dump-default-config` only proves the **host** layer composes. It happily printed
`# == dsh-diagram` for a plugin whose client half then killed the boot. To prove the server is
serving a plugin:

```bash
# token = the one-time URL from the startup log; an existing cookie works too
curl -s -c /tmp/j -o /dev/null "http://127.0.0.1:4319/?token=$TOKEN"
curl -s -b /tmp/j http://127.0.0.1:4319/ | grep -oE '\{"id":"[^"]*","url":"[^"]*"'   # served roster
curl -s -b /tmp/j -o /dev/null -w '%{http_code}\n' \
  "http://127.0.0.1:4319/plugins/??dsh-mermaid/client.js&rev=<rev>"                 # 200 = client served
```

Grepping `"id":"dsh-` alone reports **false negatives** for every scoped plugin
(`@liustack/modsearch`, `@anionex/dsh-vision-toolkit`) — match the individual name, not the prefix.

The served page carries the plugin registry inline (each entry has `url` and `inject`), so a plugin
missing from that list, or a `client.js` that 404s, is caught without a browser. Full proof of a
plugin that renders is still the browser.

Each entry's `url` carries **its own** `rev` — the tail differs per plugin (`…-44`, `…-45`, `…-50`,
`…-55` in the 2026-09-11 run). Copy the `url` verbatim; reusing one plugin's `rev` on another gives a
404 that looks like a missing bundle.

## Removing

`plugins.json` is a desired-state list that the script only ever adds to. To remove a plugin, drop its
entry **and** uninstall it:

```bash
dsh plugin --profile web remove dsh-mermaid
```

`dsh plugin` removes both the dependency and its layer.

## Trust

These are third-party plugins running inside a harness that holds a shell. Pin versions, read the
source, and remember the sandbox confines **writes only** — reads and network access are not confined.
A slot in a curated list is not a security review.
