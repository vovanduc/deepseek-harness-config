---
type: gotcha
title: A hand-declared model is text-only until it says otherwise
description: Images are refused before sending, naming the model, and the attachment stays in the session log so the same request repeats until the session moves off that model.
tags: [models, images]
---
# Symptom

An image is refused before sending, and the model is named in the refusal.

# Cause

A model declared by hand infers nothing — including input modality.

# Fix

Add `input: [text, image]` to that model. If a session already logged the attachment, move the session off the model: the attachment stays in the log and will be retried.

# Related

[../runbooks/add-model-or-provider.md](../runbooks/add-model-or-provider.md) · [../../docs/models.md](../../docs/models.md)
