---
type: system
title: The ACP automation surface
description: What `dsh --profile acp` exposes on stdio at 0.1.5-rc.1 — standard ACP v1 calls, what is deliberately omitted, and how to build a per-bot ACP profile.
tags: [dsh, acp, automation, multi-bot]
---
# What it is

`@deepseek-ai/dsh-acp` + `@deepseek-ai/dsh-acp-app` implement [Agent Client Protocol](https://agentclientprotocol.com) v1 over stdio JSON-RPC: an **automation-only** transport for trusted controllers (supervisors, test runners, out-of-process subagents). Stdout carries only protocol traffic. One connection runs several independent sessions.

The `acp` app bundle also patches `system-prompt` (sets `personaPrefix`/`personaSuffix`), disables `session-title-llm`, and inserts `acp` with default config `provider: deepseek-official, model: deepseek-v4-flash` — **defaults only**; clients pick per session (below).

# Calls a client can make (verified against installed README, 0.1.5-rc.1)

| Call | Behaviour |
|---|---|
| `initialize` | ACP v1 + `session/list`, `session/resume`, `session/close`, Streamable HTTP MCP |
| `authenticate` | immediate success — no auth on stdio |
| `session/new` | persistent agent; absolute workspace + MCP entries validated before publication |
| `session/list` | newest-first pages of persisted resumable sessions; optional `cwd` filter (physical-dir identity) |
| `session/resume` | restores a persisted inactive session (workspace re-verified), no replay of old updates |
| `session/close` | quiescent teardown: cancel → drain updates → dispose descendants → flush persistence |
| `session/set_config_option` | switch `model` or `reasoning_effort` from the live LLM catalog; applies to next turn |
| `session/prompt` | text + resource links + images (when route supports); **one in-flight prompt per session**; route pinned for the whole turn |
| `session/cancel` / `$/cancel_request` | cancels the in-flight prompt, or autonomous work |
| `session/update` | committed messages/thoughts, generic tool lifecycle, config changes, context usage |
| `session/request_permission` | **approvals reach the client** — one-shot allow/reject |

Deliberately absent: `session/load`, session deletion, fork, additional directories, terminals, plans, modes, commands, elicitation, SSE/ACP-transport MCP, and every DSH-specific presentation element (cards, titles, todos, terminal views). Anything Grok-Bot-like beyond this list needs a side channel.

# Building a per-bot ACP profile

```bash
dsh --profile bot-<name> --from-default-profile acp   # copies [dsh-base, dsh-acp-app]
```

Then edit `profiles/bot-<name>/cordis.patch.yml`: persona via the `system-prompt` plugin (`personaPrefix`/`personaSuffix`), default route via the `acp` entry (`provider`/`model`), providers via `llm-pi-ai` (same shape as `settings.yaml`). Runtime model switching works per session through `set_config_option`, so per-bot patches are for identity and policy, not required for model choice.

# Security posture

ACP clients are **trusted controllers**: stdio MCP entries authorize their absolute commands+env, HTTP entries their URLs+headers. The supervisor holds the same trust as the web UI — treat the spawn boundary as the security boundary.

# Related

[profiles-and-bundles.md](profiles-and-bundles.md) · [../gotchas/sessions-keyed-by-workspace.md](../gotchas/sessions-keyed-by-workspace.md) · [../decisions/dsh-as-teammates-engine.md](../decisions/dsh-as-teammates-engine.md)
