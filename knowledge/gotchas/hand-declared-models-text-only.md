---
type: gotcha
title: A hand-declared model is text-only until it says otherwise
description: Images are refused before sending, naming the model, and the attachment stays in the session log so the same request repeats until the session moves off that model.
tags: [models, images]
---
# Symptom

An image is refused before sending, and the model is named in the refusal.

# Cause

A model declared by hand infers nothing — including input modality. The config schema
materialises an absent `input` as `[]`, and `[]` means "ask the next level"; for a
hand-declared model there is no next level, so it resolves to `[text]`.

# Fix

Add `input: [text, image]` to that model. If a session already logged the attachment, move the
session off the model: the attachment stays in the log and will be retried.

No restart is needed — the adapter re-reads on the next request.

# The flag is not the capability

Declaring `image` does not make a model see, and omitting it does not mean the route cannot.
On the `opencode-go` route only `deepseek-flash` has vision; `deepseek-v4-pro` does not. Check
the model's own documentation, then prove the route:

```bash
set -a; . ~/.dsh/.env; set +a
# 200 `A blue square.` on deepseek-flash, 2026-09-12
```

An image-capable *route* with a text-only *model entry* is exactly this gotcha — which is why
the symptom ("refused before it is sent") is diagnostic: a refusal from the model would look
different.

# Related

[../runbooks/add-model-or-provider.md](../runbooks/add-model-or-provider.md) · [../../docs/models.md](../../docs/models.md)
