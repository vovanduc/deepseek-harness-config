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
is the only safe way to check a plugin on a machine whose profile is already running.

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

# Related

[../../docs/plugins.md](../../docs/plugins.md) · [../gotchas/dsh-mermaid-npm-name-collision.md](../gotchas/dsh-mermaid-npm-name-collision.md) · [../index.md](../index.md)
