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
| `web` | `dsh-diagram@0.4.0` | draws editable Excalidraw canvases with a live preview card in the conversation | [hanzhangzzz/dsh-diagram](https://github.com/hanzhangzzz/dsh-diagram) |

Both are MIT and publish a `dsh.bundle` patch. Versions are pinned exactly; `./init.sh` rejects
`latest`, `*`, `^`, `~`, a missing field, or a duplicate entry.

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

## Adding or bumping a plugin

1. Add or edit one entry in `plugins.json`: `{ "profile": …, "package": "name@x.y.z", "source": … }`.
2. `./scripts/install-plugins.sh` to apply, then `./init.sh` to validate the manifest.
3. Commit `plugins.json` — that is what makes the change reproducible elsewhere.

## Restart requirement

A running profile keeps the bundle set it started with. After adding, removing, or updating a plugin,
**restart that profile** (`dsh web`). Restart it non-interactively: `dsh web` exits immediately when
stdout is a TTY (see `knowledge/gotchas/web-ui-exits-under-a-tty.md`). Ordinary `cordis.patch.yml`
edits hot-reload instead — only bundle membership needs the restart. Verify a layer without booting
anything:

```bash
dsh --profile web --dump-default-config | grep -A2 '# == dsh-mermaid'
```

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
