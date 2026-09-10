---
type: runbook
title: Add a model or a provider
description: Edit settings.yaml, declare the key name, verify with init.sh (and doctor.sh for a live check).
tags: [provider, runbook]
---
# Add a model to an existing route

1. Append to that route's `models`: `- id: <wire-id>` plus `name:`. A hand-declared model infers no capacities, so also state `contextWindow` and `maxTokens`.
2. Hand-declared models are text-only — add `input: [text, image]` if it accepts images.
3. No Effort menu until `reasoningEfforts` is declared. A model that thinks unless told otherwise also needs `compat.thinkingFormat: deepseek` for `off` to do anything.
4. `./init.sh`, then `./scripts/doctor.sh`. To make the probe exercise the new model, point `agent-default-model` at it.

# Add a provider

1. Copy the template in `docs/models.md` → "Adding another provider"; `defaultContextWindow` / `defaultMaxTokens` cover entries that state neither.
2. Put the value in `~/.dsh/.env` under the exact name `apiKeyEnv` declares.
3. `./init.sh` + `./scripts/doctor.sh`. `MISSING_CREDENTIAL` means the two names disagree.

# Related

[../../docs/models.md](../../docs/models.md) · [../systems/credential-resolution.md](../systems/credential-resolution.md) · [../gotchas/hand-declared-models-text-only.md](../gotchas/hand-declared-models-text-only.md)
