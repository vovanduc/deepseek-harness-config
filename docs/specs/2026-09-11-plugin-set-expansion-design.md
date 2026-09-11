# Plugin set expansion — design

- **Feature:** `feat-009` (Expand the plugin set with the vetted web bundle)
- **Date:** 2026-09-11
- **Status:** approved (single maintainer)

## Problem

`plugins.json` declares exactly one plugin (`dsh-mermaid@0.4.0`), and three capability gaps showed up
in ordinary use:

1. **Discovery is manual.** There is no in-harness way to browse or install a plugin; every candidate
   has to be found on GitHub, then pre-flighted by hand.
2. **`web_search` is unusable here.** The built-in tool fails with *"DeepSeek search has no API key
   for `DEEPSEEK_API_KEY`"* — the route in use (`opencode-go`) never had one.
3. **The declared routes are text-only.** `deepseek-flash` / `deepseek-v4-pro` / `glm-5.3` are
   hand-declared without `input: [text, image]`, so an attached image cannot reach the model at all.

The obvious place to look is the curated list
[`awesome-dsh-plugin/awesome-dsh-plugin`](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin)
(15.2k★, 3.4k entries, 23 categories, CC0). It is **not** a plugin manager: it is an index plus a
website plus `data/stars.json` / `data/downloads.json` (⬇ coverage 624/3 431, checked 2026-08-19). The
manager it recommends is a separate plugin (`dshmarket`, itself on the list).

## Facts established (2026-09-11, this machine)

- Pinned dsh `0.1.5-rc.1` does **not** provide `@deepseek-ai/dsh-client-runtime`. Every plugin whose
  `dsh.client.inject` names it fails `./scripts/plugin-preflight.sh` with exit 1. That covers the
  three most popular candidates in two categories (`dsh-vision-router@2.1.5` ⭐775,
  `dsh-web-search-pro@0.1.11`, `dsh-free-search@0.4.24` ⬇2 141) — **stars and downloads say nothing
  about compatibility with a pinned release.**
- npm identity must be checked per candidate. The unscoped name `modsearch` is an unrelated package
  (`dsh.bundle` absent); the list's `liustack/modsearch` is published as `@liustack/modsearch`. `npm
  view <spec> repository.url` is the cheap proof.
- Of eight candidates pre-flighted, five pass and three are blocked by that one missing service. Only
  `@anionex/dsh-vision-toolkit@0.1.44` declares `dsh.compatibility.dshReleases["0.1.5-rc.1"] =
  compatible`; the other passes are `note: no dsh.compatibility declared`, which the pre-flight treats
  as a filter, not a guarantee.
- `pnpm` reports missing peer dependencies (`@deepseek-ai/cordis`, `@deepseek-ai/dsh-tools`) for these
  plugins. That is expected: the host provides them. They are warnings, not install failures.

## Candidates and verdicts

| Candidate | Spec | Pre-flight | Decision |
|---|---|---|---|
| dsh-market | `dshmarket@1.45.1` | ok (exit 0) | **install** — the market inside Settings |
| dsh-find-plugin | `dsh-find-plugin@0.3.7` | ok, host-only | **install** — agent-side discovery |
| modsearch | `@liustack/modsearch@5.10.2` | ok (injects nothing) | **install** — replaces the dead `web_search` |
| dsh-vision-toolkit | `@anionex/dsh-vision-toolkit@0.1.44` | ok, declares 0.1.5-rc.1 | **install** — vision bridge |
| modlens | `@liustack/modlens@3.26.1` | ok (injects nothing) | held — more capable, no compatibility declaration |
| dsh-vision-router | `dsh-vision-router@2.1.5` | INCOMPATIBLE | reject — needs `dsh-client-runtime` |
| dsh-web-search-pro | `dsh-web-search-pro@0.1.11` | INCOMPATIBLE | reject — same |
| dsh-free-search | `dsh-free-search@0.4.24` | INCOMPATIBLE | reject — same |

## Goal

One deliberate expansion of `plugins.json`: a way to discover and install plugins, a working web
search, and image input for text-only routes — each entry pre-flighted against the pinned dsh and
pinned to an exact published version, so a second machine reproduces the same set.

## Non-goals

- **No restart.** Adding a bundle needs a `dsh web` restart; that is the user's call, not this
  feature's, and the browser remains the final gate.
- No plugin installed outside `plugins.json`; no `--skip-preflight`.
- No credential provisioning for the new plugins. `modsearch` and `dsh-vision-toolkit` each have
  their own key/credential story; this feature installs them, it does not configure them.
- No mass install of the shortlist from the category review. Only the four vetted entries.

## Design

| Artifact | Role |
|---|---|
| `plugins.json` | four new pinned entries, `source` = the publishing repo (not the list's link, where they differ) |
| `scripts/install-plugins.sh` | **unchanged** — pre-flights each entry, then `dsh plugin --profile web add` |
| `docs/plugins.md` | the set table, plus why three popular candidates are refused |
| `knowledge/runbooks/dsh-plugins.md` | set updated; the list-as-discovery-source and the compatibility rule recorded |
| `knowledge/gotchas/plugin-fit-vs-popularity.md` | new: the two ways a list entry lies — npm identity and release compatibility |
| `init.sh` | **unchanged** — already validates pins, fields and duplicates |

## Decisions and trade-offs

| Decision | Why | Accepted cost |
|---|---|---|
| `dsh-vision-toolkit` over the far more popular `modlens` | the only candidate that *declares* compatibility with the pinned rc; the repo's rule is fail-closed | fewer features than modlens (⭐714 vs ⭐3152) |
| Install `dshmarket` even though it is a nested market | it is the manager the list itself recommends, and the only way to browse/update without hand-editing | one more third-party bundle in the boot path |
| Keep the rejected three in the docs/knowledge, not in the manifest | the incompatibility is one missing service name — a future release will fix it | documentation to revisit on a dsh bump |
| Do not restart the running profile | the user is talking to the agent through that server | the four plugins are installed but not live until a restart |

## Acceptance criteria

1. `plugins.json` lists five pinned entries (existing `dsh-mermaid@0.4.0` + four new), no duplicates.
2. `./scripts/install-plugins.sh` pre-flights each entry, installs the four, and re-runs as
   *already installed* with 0 blocked.
3. `dsh --profile web --dump-default-config` contains a layer for each installed plugin (host layer).
4. `./init.sh` exits 0 with 9 features, none in-progress once the feature closes.
5. `docs/plugins.md` + the knowledge concept and log describe the set, the refusals and the restart
   requirement.
6. Committed on `main` and pushed; CI green.

## Verification plan

- `./scripts/install-plugins.sh` (real run) and the summary line; then `dsh plugin --profile web list`.
- `dsh --profile web --dump-default-config | grep '# =='` for the four names.
- `./init.sh` exit 0; knowledge link check; harness audit.
- Post-push: the GitHub Actions run on the new commit.
- Not verifiable here: that the four client halves actually activate — that needs the web restart.

## Outcome

Filled in after the run: see `feature_list.json` → `feat-009` → `evidence`, and `progress.md`.
