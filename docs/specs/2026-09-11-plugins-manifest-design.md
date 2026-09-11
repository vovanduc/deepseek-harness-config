# Reproducible plugin set — design

- **Feature:** `feat-006` (Reproducible dsh plugin set; seeds `dsh-mermaid` + `dsh-diagram`)
- **Date:** 2026-09-11
- **Status:** approved (single maintainer)

## Problem

Dsh plugins install into a **profile** — `$DSH_HOME/profiles/<name>/` — which this repo
**gitignores** (`profiles/`). So today a plugin installed here exists only on this machine: clone
the repo on a second machine, run `./install.sh`, and the plugins are gone. The repo's promise
("a second machine starts in the same state as the first") currently covers `settings.yaml` and
`skills/` only.

## Facts established (2026-09-11, official docs + this machine)

- `dsh plugin --profile <name> <pnpm args>` forwards to **pnpm** in the profile directory, then
  **reconciles `dsh.profile.bundles`** against the installed state: a dependency whose manifest
  declares `dsh.bundle` joins the layer stack; removing the dependency removes the layer.
- Missing shipped profiles (`web`, `headless`, `sdk`, `sdk-minimal`, `acp`) **auto-initialize from
  the shipped template** on first use, so `dsh plugin --profile web add …` is safe on a fresh
  machine — it creates the correct `base + web-app` web profile, not a base-only one.
- A running profile keeps the bundle set from its start: **adding a plugin needs a profile restart**
  to take effect. Ordinary `cordis.patch.yml` edits hot-reload instead.
- `dsh --profile web --dump-config` / `--dump-default-config` compose and print the tree **without
  booting** — the way to verify a plugin layer without restarting a live server.
- Git-sourced plugins that ship sources build through `prepare`, which pnpm ≥10 blocks until the
  consumer adds an `allowBuilds` key to the profile's **machine-local** `pnpm-workspace.yaml`.
- This machine: pnpm 10.33.0, Node v22.22.2, dsh 0.1.5-rc.1, profiles `web` (base + web-app, live
  patches) and `headless`.

## The two seed plugins, and a name collision

| Plugin | Install spec (chosen) | Source | Licence |
|---|---|---|---|
| Mermaid fences → SVG | `dsh-mermaid@0.4.0` | [MrmoLabs/dsh-mermaid](https://github.com/MrmoLabs/dsh-mermaid) | MIT |
| Editable Excalidraw canvases | `dsh-diagram@0.4.0` | [hanzhangzzz/dsh-diagram](https://github.com/hanzhangzzz/dsh-diagram) | MIT |

**Collision:** `AKS1st/dsh-mermaid` (MIT, v0.5.0) declares the package name `dsh-mermaid` but is *not*
the npm publisher — npm's `dsh-mermaid` belongs to `MrmoLabs` (v0.4.0). Installing `dsh-mermaid` by
name therefore gets MrmoLabs, and the awesome-list entry points at AKS1st. The npm route is chosen
because it pins to an exact published version and needs **no `prepare` build** (hence no
machine-local `allowBuilds` edit, which would break reproducibility). The collision is recorded as a
gotcha and the alternative is documented.

## Goal

One manifest in git lists the plugins; `./install.sh` applies it; re-running reconciles. A second
machine ends up with the same plugins at the same versions, or a clear message saying what is missing.

## Non-goals

- **No vendoring** of plugin code or `node_modules` into the repo.
- **No auto-restart** of a running profile (restarting this repo's own web server would end the
  session that installed the plugin).
- No headless/multi-profile seeding beyond what the manifest states; no plugin for the `headless` profile.
- Not a general package manager: the script only replays names already pinned in the manifest.

## Design

| Artifact | Role |
|---|---|
| `plugins.json` | the manifest: `{plugins: [{profile, package, source?}]}`; `package` is a pinned `name@version` |
| `scripts/install-plugins.sh` | reads the manifest, compares with each profile's `package.json`, applies the difference with `dsh plugin … add`, prints a summary. `--dry-run` prints the plan and changes nothing |
| `install.sh` | calls the script after the skills step; a failure warns instead of aborting (same treatment as `doctor.sh`) |
| `scripts/doctor.sh` | **unchanged** — `install-plugins.sh` already reports drift, and doctor stays about the model route |
| `docs/plugins.md` | user-facing: the set, provenance, install/uninstall/verify, the restart requirement |
| `init.sh` | validates the manifest: every entry has `profile` + `package`, the spec is **pinned** (`@` + version, never `@latest`/bare), no duplicate profile+package, and `install.sh` still calls the applier |

Why JSON: `init.sh` and `install.sh` both already require Node, so the manifest parses with no
dependency (the repo's settings YAML needs PyYAML, which is optional here). Why a separate script:
it is independently runnable — "re-apply the plugin set without reinstalling everything" — and
testable in `--dry-run`.

Idempotency rule: if the profile's `dependencies[name]` already equals the requested version, skip;
otherwise run `add` (which also covers a version bump).

## Decisions and trade-offs

| Decision | Why | Accepted cost |
|---|---|---|
| Manifest in git, profile stays machine-local | the profile is dsh runtime state; the manifest is the reproducible source of truth | one extra file, and `install.sh` must run to apply |
| Pin exact npm versions | `@latest` is not reproducible, and the npm name here is contested | a bump is a deliberate edit |
| npm over `github:` for `dsh-mermaid` | no `prepare` build, no machine-local `allowBuilds` edit | v0.4.0 instead of AKS1st's v0.5.0 |
| Warn, don't abort, on plugin failure | settings/skills are already applied by then; a network hiccup should not fail the whole setup | a failed install is a warning, so `install-plugins.sh` must be re-run |
| Verify with `--dump-config`, not a restart | restarting the profile would kill the running session | actual rendering is only proven after the user restarts |

## Acceptance criteria

1. `scripts/install-plugins.sh` (no flags; `--dry-run` only prints the plan) installs both plugins into the `web` profile; `dsh --profile web --dump-default-config` then contains a `# == dsh-mermaid` and a `# == dsh-diagram` layer.
2. Re-running the script reports both as already installed and changes nothing.
3. `./install.sh` applies the set; with `--no-install` it still applies when `dsh` is on PATH, and warns when it is not.
4. `init.sh` fails on an unpinned spec, a missing field, a duplicate entry, or a dropped `install.sh` call — and keeps passing on the real manifest.
5. `docs/plugins.md` + a `knowledge/` runbook and gotcha exist; links resolve.
6. `./init.sh` and CI stay green.

## Verification plan

- Run `--dry-run` (no side effects), then the real apply; assert the two dump-config layers.
- Re-run for idempotency; mutate the manifest to `@latest` and to a duplicate, and confirm `init.sh` fails each time, then restore.
- `./init.sh`, the harness audit, the knowledge link check, and the CI run after pushing.
- Not verifiable here: the rendered diagrams — that needs a web-profile restart, which would end this session.

## Process note

`superpowers:*` is not installed in this session, so the spec and plan are written by hand and the
tasks run inline (same note as the `feat-003` and `feat-004` specs).
