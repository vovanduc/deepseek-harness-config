---
type: gotcha
title: A plugin's popularity says nothing about whether it runs here
description: In the curated dsh plugin list the most-starred entries in two categories are refused by the pre-flight on dsh 0.1.5-rc.1, and one of them is published under a different npm name than the repo the list links.
tags: [plugins, compatibility, supply-chain, dsh]
---
# Symptom

Picking candidates by ⭐/⬇ from the curated list (`awesome-dsh-plugin/awesome-dsh-plugin`) and
installing them fails, or worse, installs and then kills the web boot:

```
./scripts/plugin-preflight.sh dsh-vision-router@2.1.5     # exit 1
  FAIL  client inject @deepseek-ai/dsh-client-runtime is not provided by dsh 0.1.5-rc.1
./scripts/plugin-preflight.sh dsh-web-search-pro@0.1.11   # exit 1, same id
./scripts/plugin-preflight.sh dsh-free-search@0.4.24      # exit 1, same id
```

`dsh-vision-router` is ⭐775, `dsh-free-search` ⬇2 141 — the top of their categories. The one that
actually declares compatibility with the pinned release is `@anionex/dsh-vision-toolkit@0.1.44`
(⭐714, `dsh.compatibility.dshReleases["0.1.5-rc.1"] = compatible`).

# Why

Two independent traps, both invisible from the list entry:

1. **Release compatibility.** The list records a repo, not a dsh release. `0.1.5-rc.1` dropped or
   renamed `@deepseek-ai/dsh-client-runtime`; every client bundle that injects it can never activate
   on this pin, and an unresolved injected service blocks the whole boot (same failure mode as
   `dsh-diagram`). Stars accumulate on repos built against older release lines.
2. **npm identity.** The list links a GitHub repo, but `dsh plugin add` resolves an npm **name**.
   `liustack/modsearch` publishes as `@liustack/modsearch`; the unscoped `modsearch` on npm is an
   unrelated package with no `dsh.bundle`. Installing the wrong one silently activates no layer.

# Fix

- Never install from a list entry directly. Resolve the npm spec, then prove both facts:

  ```bash
  npm view <spec> repository.url dsh --json     # repository must match the repo you read
  ./scripts/plugin-preflight.sh <name>@<x.y.z>  # 0 = may install, 1 = blocked
  ```

- Prefer a candidate that declares `dsh.compatibility.dshReleases` for the pinned release over one
  that merely has more stars.
- Treat `note: no dsh.compatibility declared` as *unverified*, not *safe*: the pre-flight reads
  metadata only, so the browser after a restart is still the gate.

# Generalisation

Popularity ranks adoption; it does not rank fitness for a pinned release, and it says nothing about
which npm name you are actually installing. Rank with `data/stars.json` / `data/downloads.json`, then
filter with the pre-flight and `repository.url` — never one without the other.

# Related

[../runbooks/dsh-plugins.md](../runbooks/dsh-plugins.md) · [dsh-diagram-incompatible-with-pinned-dsh.md](dsh-diagram-incompatible-with-pinned-dsh.md) · [dsh-mermaid-npm-name-collision.md](dsh-mermaid-npm-name-collision.md) · [../../docs/plugins.md](../../docs/plugins.md)
