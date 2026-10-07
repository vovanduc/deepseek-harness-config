---
type: gotcha
title: Neither a profile nor a sandbox mode is a compute boundary
description: A profile is composition config; SandboxMode governs file effects only. Giving an agent "its own computer" means replacing every *-local seam coherently — or running the whole dsh process inside the container.
tags: [dsh, sandbox, isolation, multi-bot]
---
# Fact

- A **profile** is a bundle list + patch layer. It carries no VM, network, credential, or filesystem boundary.
- `sandbox-policy` `mode` (`read-only` / `workspace-write` / `danger-full-access`, from `DSH_PERMISSION_MODE`) governs **file effects of subprocesses** with `workspaceRoot: process.cwd()`. Reads and network are never confined (see README security notes).
- Every side-effect seam in `dsh-base` ships a `-local` implementation: `subprocess-local`, `sandbox-local`, `bash-sandbox`/`pwsh-sandbox`, `fs-sandbox`, `shell-env`, `tool-fs`, `tool-bash`, `spill-local`. They are independent providers behind independent contracts.
- `dsh-base` has **no browser/desktop computer-use tool** — screen control is a plugin/MCP add-on (e.g. `@anionex/dsh-vision-toolkit` on the `web` profile).

# Rule

"Each bot has its own computer" cannot be done by patching one seam — a missed path leaves the agent acting on two filesystems at once. Two honest options:

1. **Whole dsh process per bot inside its container** (own `DSH_HOME` + workspace mount) — consistency is free; the cost is a full Node runtime and a credential question per container.
2. **dsh on host, all seams routed remote** — needs a `ComputerProvider` contract (provision/reconnect/exec/files/observe/checkpoint/destroy, à la rakazo's `SandboxProvider`) implemented for **every** seam listed above plus browser/desktop. That is the product-grade shape, not the first step.

# Verified

2026-10-07, `0.1.5-rc.1`: seam list and policy config from `--dump-default-config` of an ACP profile.

# Related

[sessions-keyed-by-workspace.md](sessions-keyed-by-workspace.md) · [../systems/acp-surface.md](../systems/acp-surface.md) · [../decisions/dsh-as-teammates-engine.md](../decisions/dsh-as-teammates-engine.md)
