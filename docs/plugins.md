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

The plugin is MIT and publishes a `dsh.bundle` patch. Versions are pinned exactly; `./init.sh`
rejects `latest`, `*`, `^`, `~`, a missing field, or a duplicate entry.

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
> reproducibility. See `knowledge/gotchas/dsh-mermaid-npm-name-collision.md` to switch.

## Apply and check

```bash
./scripts/install-plugins.sh --dry-run   # print the plan, change nothing
./scripts/install-plugins.sh             # install what is missing or off-version
./scripts/install-plugins.sh             # re-run: reports "already installed" when in sync
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

1. Add or edit one entry in `plugins.json`: `{ "profile": …, "package": "name@x.y.z", "source": … }`.
2. `./scripts/install-plugins.sh` to apply, then `./init.sh` to validate the manifest.
3. Commit `plugins.json` — that is what makes the change reproducible elsewhere.

## Restart requirement

A running profile keeps the bundle set it started with. After adding, removing, or updating a plugin,
**restart that profile** (`dsh web`). Restart it non-interactively: `dsh web` exits immediately when
stdout is a TTY (see `knowledge/gotchas/web-ui-exits-under-a-tty.md`). Ordinary `cordis.patch.yml`
edits hot-reload instead — only bundle membership needs the restart.

## Verify the restart actually took

`dsh --profile web --dump-default-config` only proves the **host** layer composes. It happily printed
`# == dsh-diagram` for a plugin whose client half then killed the boot. To prove the server is
serving a plugin:

```bash
# token = the one-time URL from the startup log; an existing cookie works too
curl -s -c /tmp/j -o /dev/null "http://127.0.0.1:4319/?token=$TOKEN"
curl -s -b /tmp/j http://127.0.0.1:4319/ | grep -o '{"id":"dsh-[^"]*"'      # served roster
curl -s -b /tmp/j -o /dev/null -w '%{http_code}\n' \
  "http://127.0.0.1:4319/plugins/??dsh-mermaid/client.js&rev=<rev>"          # 200 = client served
```

The served page carries the plugin registry inline (each entry has `url` and `inject`), so a plugin
missing from that list, or a `client.js` that 404s, is caught without a browser. Full proof of a
plugin that renders is still the browser.

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
