---
type: system
title: Profiles, bundles, and patch layers
description: What a dsh profile physically is, the shipped profile templates, and the CLI flags that compose them — verified on 0.1.5-rc.1.
tags: [dsh, profiles, cordis, bundles]
---
# Anatomy

A profile is a directory `$DSH_HOME/profiles/<name>/` holding four small files:

- `package.json` — `dsh.profile.bundles` is the ordered bundle list; `dsh.profile.patchReload` is `live` or `startup`.
- `cordis.patch.yml` — the profile's own patch layer (top-level YAML array of loader entries: id-targeted config overrides, `disabled`, `insert` lists; `!!js` expressions allowed).
- `cordis.yml` — empty root, **rewritten every boot**; exists only to anchor `baseUrl`. Never edit.
- `pnpm-workspace.yaml` — `packages: [.]` + `nodeLinker: hoisted`.

Composition order: each bundle's `cordis.patch.yml` in bundle order → profile `cordis.patch.yml` → `--patch` overlays. Bundles resolve from the install anchor (`$DSH_HOME/profiles/node_modules` mirrors the installation's deps), so a custom profile needs **no pnpm install** to boot shipped bundles.

# Shipped templates (`--from-default-profile`)

| Template | Bundles | patchReload |
|---|---|---|
| `acp` | `dsh-base` + `dsh-acp-app` | startup |
| `web` | `dsh-base` + `dsh-web-app` | live |
| `headless` | `dsh-base` + `dsh-headless` | startup |
| `sdk` | `dsh-base` + `dsh-sdk-app` | startup |
| `sdk-minimal` | `dsh-sdk-minimal` | startup |

A name absent from this table gets `DEFAULT_PROFILE_BUNDLES = [dsh-base]` and `patchReload: live` when created via `dsh plugin --profile <name>` init.

# CLI surface

- `dsh --profile <name> --from-default-profile <template>` — creates the profile: copies **only** the template's bundle list and reload policy (no inheritance metadata); shipped names are reserved; an existing directory is refused.
- `--patch <path>` — repeatable extra overlay applied after the profile layer. Lets one profile serve several boot-time variants without new profiles.
- `--dump-config` / `--dump-default-config` — print the composed tree (with / without user patch + overlays) and exit. The verification tool for any composition question.
- `dsh plugin --profile <name> add <pkg>` — forwards to pnpm inside the profile dir; this is how a profile gets a distinct plugin set.

# Desktop app

The official desktop app (`/Applications/DeepSeek Harness.app`, downloads on deepseek.com/en/harness — macOS arm64 + Windows x64 only as of 2026-10) runs profile `desktop` with bundles `[dsh-base, dsh-web-app]`: the desktop shell embeds the web app bundle and ships its own Node/pnpm runtime. It shares `$DSH_HOME` with CLI profiles — same settings.yaml, credentials, sessions, storages.

# Verified

2026-10-07 on `0.1.5-rc.1`: `dsh --profile probe-bot --from-default-profile acp --dump-default-config` produced a 348-line composed tree (removed after). `--help` output and `PROFILE_TEMPLATES` read from `dsh-app-boot/lib/index.js`.

# Related

[acp-surface.md](acp-surface.md) · [dsh-home-layout.md](dsh-home-layout.md) · [../gotchas/sessions-keyed-by-workspace.md](../gotchas/sessions-keyed-by-workspace.md) · [../gotchas/profile-not-a-boundary.md](../gotchas/profile-not-a-boundary.md)
