---
type: api
title: The opencode-go route contract
description: Every field the OpenCode Go gateway needs — protocol, base URL, the mandatory session header, and the two compat flags — and why removing any of them breaks requests.
tags: [provider, opencode-go, gateway]
---
# Contract (`settings.yaml` → `llm-pi-ai.providers.opencode-go`)

| Field | Value | Why it is there |
|---|---|---|
| `api` | `openai-completions` | wire protocol; a route outside the shipped catalog must name one |
| `baseURL` | `https://opencode.ai/zen/go/v1` | OpenAI-compatible gateway |
| `apiKeyEnv` | `OPENCODE_GO_API_KEY` | a *name*; the value resolves per [credential-resolution](credential-resolution.md) |
| `headers.x-opencode-session` | any stable string | **required** — without it every request is `400 MissingSessionID` |
| `compat.supportsDeveloperRole` | `false` | the gateway rejects the `developer` role used for a reasoning model's system prompt |
| `compat.maxTokensField` | `max_tokens` | the gateway reads `max_tokens`, not `max_completion_tokens` |

Declared models: `deepseek-flash` (default), `deepseek-v4-pro`, `glm-5.3`. Only `deepseek-flash`
declares `input: [text, image]`; the other two are text-only, and `deepseek-v4-pro` has no vision
on DeepSeek's own model table either. A declared list *replaces* the catalog, so anything not
listed is `UNKNOWN_MODEL`. The provider id is permanent because sessions and defaults record it —
rename by adding a new route, then deleting the old one after re-pointing `agent-default-model`.

# Verified 2026-09-10

`./init.sh` resolves `agent-default-model` → `opencode-go/deepseek-flash` and `dsh --profile
headless --dump-config` composes; `./scripts/doctor.sh` posts one real completion for readiness.

# Verified 2026-09-12 — image input

Straight at the gateway (`Authorization: Bearer $OPENCODE_GO_API_KEY`, `x-opencode-session`
required): a text-only control returned `pong`; the same call carrying a 64×64 PNG of a blue
square on white, `detail: low`, returned `A blue square.` So the route itself passes images
through on `deepseek-flash`. In-harness `read_image` refuses until the model entry declares
`input: [text, image]` — see
[../gotchas/hand-declared-models-text-only.md](../gotchas/hand-declared-models-text-only.md).

# Related

[../../docs/models.md](../../docs/models.md) · [../gotchas/missing-session-id.md](../gotchas/missing-session-id.md) · [../gotchas/compat-flags.md](../gotchas/compat-flags.md) · [../runbooks/add-model-or-provider.md](../runbooks/add-model-or-provider.md)
