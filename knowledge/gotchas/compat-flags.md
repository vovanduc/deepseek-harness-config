---
type: gotcha
title: Valid key, every request fails — the two compat flags
description: Most OpenAI-compatible gateways reject the developer role and the max_completion_tokens field; compat.supportsDeveloperRole=false and compat.maxTokensField=max_tokens fix both.
tags: [gateway, compat]
---
# Read the symptom, pick the flag

| Symptom | Cause | Fix |
|---|---|---|
| Only reasoning models fail | the system prompt arrives as `role: developer` | `compat.supportsDeveloperRole: false` |
| Any model with an output cap fails, key and URL are right | the cap arrives as `max_completion_tokens` | `compat.maxTokensField: max_tokens` |

Both are already set on the `opencode-go` route; a second gateway will usually need them too.

# Related

`off` in `reasoningEfforts` sends no reasoning field at all, so a model that thinks by default keeps thinking — pair it with `compat.thinkingFormat: deepseek`.

# Related

[../systems/opencode-go-route.md](../systems/opencode-go-route.md) · [../runbooks/add-model-or-provider.md](../runbooks/add-model-or-provider.md) · [../../docs/troubleshooting.md](../../docs/troubleshooting.md)
