---
type: decision
title: dsh as the engine for a per-bot-computer teammates product
description: For a Grok-Bot-inspired product (roster of agents, each with its own compute), dsh is the engine and study object; pi.dev is the curriculum; rakazo/OpenMausBot are product-layer references.
tags: [dsh, acp, multi-bot, product]
---
# Decision

Build the Grok-Bot-style product — multiple persistent bot identities, each with its own computer — on **dsh as the engine**:

- one bot = one `dsh --profile bot-<id> --from-default-profile acp` process, later inside its own container with its own `DSH_HOME`;
- a supervisor on loopback speaks standard ACP v1 (sessions, prompts, permission requests, per-session model switching);
- persona/policy per bot lives in the profile's `cordis.patch.yml` (`system-prompt`, `acp`, `llm-pi-ai` entries);
- models: `deepseek-flash` via `opencode-go` (already in `settings.yaml`), SWE-2 via `omp-gateway`, any custom OpenAI/Anthropic-protocol provider.

Study sources: **pi.dev** (`earendil-works/pi`, MIT) as the minimal-harness curriculum — 4 tools, ~1k-token prompt, everything else extensions; **rakazo** (Apache-2.0) for the `SandboxProvider` contract and persistent-workspace-vs-ephemeral-VM split; **OpenMausBot** (Apache-2.0 core, `enterprise/` separately licensed) for the local-first supervisor pattern (driver registry → event stream → UI). dsh's own `llm-pi-ai` already wraps `@earendil-works/pi-ai`, so the provider layer is shared vocabulary.

# Why

- The stated goal is *learn by porting*: dsh's "everything is a plugin" makes composition/service seams the organising principle — more to dissect than pi's deliberately minimal core.
- ACP already carries what a bot product needs (sessions, approvals, model switching) — verified at 0.1.5-rc.1.
- MIT licence; desktop/web/headless/acp/sdk profiles all coexist on one install.

# Trade-off

- dsh is public preview; the pin policy ([pin-dsh-version.md](pin-dsh-version.md)) is load-bearing — re-verify the ACP surface on every bump.
- Per-bot cost is a full dsh process (and later a container), heavier than embedding `pi-agent-core` in-process.
- ACP omits all presentation data — a "computer panel"/live screen needs a side channel from the container, not the protocol.
- Not yet proven on this machine: concurrent ACP profiles, E2E in Docker, throughput/cost. That is what the vertical slice exists to test.

# Source

External research brief (ChatGPT, 2026-10-07): [../../docs/research/dsh-grok-bot-brief-2026-10-07.md](../../docs/research/dsh-grok-bot-brief-2026-10-07.md) — critiqued against the installed `0.1.5-rc.1`; corrections recorded in the gotchas linked below.

# Related

[../systems/acp-surface.md](../systems/acp-surface.md) · [../systems/profiles-and-bundles.md](../systems/profiles-and-bundles.md) · [../gotchas/profile-not-a-boundary.md](../gotchas/profile-not-a-boundary.md) · [../gotchas/sessions-keyed-by-workspace.md](../gotchas/sessions-keyed-by-workspace.md) · [../gotchas/telemetry-on-by-default.md](../gotchas/telemetry-on-by-default.md)
