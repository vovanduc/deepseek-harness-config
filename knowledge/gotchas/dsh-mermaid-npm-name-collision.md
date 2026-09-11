---
type: gotcha
title: The npm name dsh-mermaid belongs to MrmoLabs, not AKS1st
description: Two unrelated projects use the package name dsh-mermaid. dsh plugin add dsh-mermaid installs MrmoLabs's v0.4.0; AKS1st/dsh-mermaid (v0.5.0) is only installable from git.
tags: [plugins, supply-chain, dsh]
---
# Symptom

A plugin list links `AKS1st/dsh-mermaid`, but `dsh plugin --profile web add dsh-mermaid` installs a
package whose `repository` is `MrmoLabs/dsh-mermaid` — a different author at a different version
(npm 0.4.0; the AKS1st repo is 0.5.0).

# Why

Both repos name their package `dsh-mermaid`, but only MrmoLabs published it to npm. An npm name is a
global namespace, so the name identifies the **publisher**, not the GitHub repo you read about.

# What this repo does

`plugins.json` pins `dsh-mermaid@0.4.0` and records `source` as MrmoLabs — the actual publisher. The
npm route also avoids a `prepare` build, which would otherwise need a machine-local `allowBuilds` edit
in the profile's `pnpm-workspace.yaml` and break reproducibility.

# To use AKS1st's version instead

```bash
dsh plugin --profile web remove dsh-mermaid
dsh plugin --profile web add github:AKS1st/dsh-mermaid#e009f8d570e74207bcbcf7a32310d6a90c8187bf
```

then update `plugins.json`. Expect pnpm to block the `prepare` build on the first attempt: copy the
key it prints into `~/.dsh/profiles/web/pnpm-workspace.yaml` under `allowBuilds` and re-run.

# Generalisation

Before adding a third-party plugin, check that the npm package's `repository` field matches the repo
you meant to install. Names are squattable and collide; a pin to `name@version` only pins the name.

# Related

[../runbooks/dsh-plugins.md](../runbooks/dsh-plugins.md) · [../../docs/plugins.md](../../docs/plugins.md) · [../index.md](../index.md)
