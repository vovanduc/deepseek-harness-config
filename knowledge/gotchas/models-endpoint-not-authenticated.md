---
type: gotcha
title: GET /models answers 200 even with a wrong key
description: This gateway lists models without validating the key. Only an inference request is authenticated, so never diagnose a credential with /models.
tags: [credentials, gateway, diagnosis]
---
# Symptom

`curl .../models` returns 200 while every real request is `401 Invalid API key`.

# Reality

Only `POST /chat/completions` is authenticated. A bogus or expired key is invisible on the listing.

# What to do

Run `./scripts/doctor.sh` — it posts one real completion (`max_tokens: 1`) for exactly this reason.

# Related

[../runbooks/verify-change.md](../runbooks/verify-change.md) · [../runbooks/new-machine-setup.md](../runbooks/new-machine-setup.md) · [../../docs/troubleshooting.md](../../docs/troubleshooting.md)
