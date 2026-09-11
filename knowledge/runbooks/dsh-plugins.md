---
type: runbook
title: Declare, apply and verify dsh plugins
description: Plugins live in $DSH_HOME/profiles/<name> — machine state this repo gitignores — so plugins.json in git is the source of truth; scripts/install-plugins.sh applies it and install.sh calls it.
tags: [plugins, dsh, runbook]
---
# Why a manifest exists

`dsh plugin --profile <name> add <package>` forwards to pnpm in `$DSH_HOME/profiles/<name>/` and then
reconciles `dsh.profile.bundles`. The profile directory is **not** in git, so `plugins.json` is what
makes a second machine match.

# Pre-flight (before anything touches a profile)

```bash
./scripts/plugin-preflight.sh <name>@<version> [--dsh-version <v>]
```

Reads the published manifest via `npm view <spec> dsh --json` and refuses a plugin that cannot work
on the pinned release: `dsh.compatibility.dshReleases` must list the target release as `compatible`,
and every `dsh.client.inject` id must exist in the pinned install (a directory under its
`node_modules`, or a literal string under its `@deepseek-ai/`). Missing install → inconclusive, not a
failure. `install-plugins.sh` runs it before every `add` and counts a rejection as *blocked*;
`--skip-preflight` overrides. A git source cannot be pre-flighted → rejected unless overridden.

It reads metadata only, so it cannot see a bare service name that exists only in compiled client
code — a pass is a filter, not a guarantee.

# Apply

```bash
./scripts/install-plugins.sh --dry-run   # plan only, changes nothing
./scripts/install-plugins.sh             # add what is missing or off-version
```

`install.sh` calls it after linking skills. Missing shipped profiles (`web`, `headless`, `sdk`,
`sdk-minimal`, `acp`) auto-initialize from the shipped template on first use, so `add` is safe on a
fresh machine — it does not create a broken base-only profile for a shipped name.

# Verify without booting

```bash
dsh --profile web --dump-default-config | grep -A2 '# == dsh-mermaid'
```

`--dump-config` / `--dump-default-config` compose and print the tree without starting the app, which
is the only safe way to check a plugin on a machine whose profile is already running. It proves the
**host** layer only — see the failure mode below.

# Verify the running server actually serves it

```bash
TOKEN=<one-time token from the startup log>   # an existing browser cookie works too
curl -s -c /tmp/j -o /dev/null "http://127.0.0.1:4319/?token=$TOKEN"
curl -s -b /tmp/j http://127.0.0.1:4319/ | grep -o '{"id":"dsh-[^"]*"'   # roster the client loads
curl -s -b /tmp/j -o /dev/null -w '%{http_code}\n' \
  "http://127.0.0.1:4319/plugins/??dsh-mermaid/client.js&rev=<rev>"       # 200
```

Every plugin's registry entry (`url`, `inject`) is inline in the served page, so a plugin that never
made it into the running bundle set — or a `client.js` that 404s — is visible from the shell. A
plugin's lazy assets sit under its own root too (e.g. `/dsh-mermaid/mermaid-runtime.js`, 3.4 MB).
Each entry's `url` carries its **own** `rev` tail — fetch it verbatim, since borrowing another
plugin's `rev` returns 404 for a bundle that is served fine.

Verified end to end on 2026-09-11: `dsh-mermaid` `…-44`, `@liustack/modsearch` `…-45`,
`dshmarket` `…-50`, `@anionex/dsh-vision-toolkit` `…-55`, all `200`.

# Restart

A running profile keeps the bundle set it started with — restart that profile (`dsh web`) after a
change. Only bundle membership needs this; `cordis.patch.yml` edits hot-reload.

# Remove

`dsh plugin --profile web remove <name>` and delete the entry from `plugins.json`. The applier only
ever adds — it never uninstalls.

# Failure modes seen

- `ERR_PNPM_GIT_DEP_PREPARE_NOT_ALLOWED` — a git-sourced plugin wants to run `prepare`, which pnpm ≥10
  blocks until `allowBuilds` is added to the profile's machine-local `pnpm-workspace.yaml`. Prefer a
  published npm tarball, which needs no allowance.
- A package without `dsh.bundle` installs as a plain dependency and activates no layer (dsh warns).
- **A client half built for another dsh release kills the whole web boot.** `dsh-diagram@0.4.0`
  injects a `conversationEvents` client service that dsh `0.1.5-rc.1` does not provide: the layer
  composes (`--dump-default-config` is happy), then the browser shows `Failed to load plugins` and
  renders nothing. The metadata-level cases are now refused before install by the pre-flight above; a
  bare service name that lives only in compiled client code still needs the browser after a restart.
  Details: [../gotchas/dsh-diagram-incompatible-with-pinned-dsh.md](../gotchas/dsh-diagram-incompatible-with-pinned-dsh.md).

# The set here

`plugins.json` declares five plugins for the `web` profile — `dsh-mermaid@0.4.0` (diagrams),
`dshmarket@1.45.1` (the market inside Settings), `dsh-find-plugin@0.3.7` (host-only registry search),
`@liustack/modsearch@5.10.2` (web search + fetch, because the built-in `web_search` has no key on this
route) and `@anionex/dsh-vision-toolkit@0.1.44` (vision for the text-only routes).
`dsh-diagram` is deliberately absent for the reason above.

# Finding candidates

[`awesome-dsh-plugin/awesome-dsh-plugin`](https://github.com/awesome-dsh-plugin/awesome-dsh-plugin) is
a curated **index**, not a manager — it never installs anything. Useful inputs: the 23 category
sections, and `data/stars.json` / `data/downloads.json` for ranking (coverage 1 488 / 624 entries,
snapshot-dated). The managing half is `dshmarket` itself, or `dsh plugin --profile <p> add <spec>`.

Two filters before trusting an entry, in this order:

```bash
npm view <spec> repository.url dsh --json      # the npm name must be the repo you read
./scripts/plugin-preflight.sh <name>@<x.y.z>   # and it must run on the pinned release
```

The 2026-09-11 survey found the *most popular* entries in two categories
(`dsh-vision-router@2.1.5` ⭐775, `dsh-free-search@0.4.24` ⬇2 141) blocked by the second filter —
both inject `@deepseek-ai/dsh-client-runtime`, absent from `0.1.5-rc.1`. Full list:
[../gotchas/plugin-fit-vs-popularity.md](../gotchas/plugin-fit-vs-popularity.md).



# Related

[../../docs/plugins.md](../../docs/plugins.md) · [../gotchas/dsh-mermaid-npm-name-collision.md](../gotchas/dsh-mermaid-npm-name-collision.md) · [../index.md](../index.md)
