---
type: gotcha
title: "400 MissingSessionID — the session header is not optional"
description: The OpenCode Go gateway routes by client session and refuses any request without headers.x-opencode-session.
tags: [opencode-go, gateway]
---
# Symptom

Every request fails `400 ... MissingSessionID`.

# Cause

`llm-pi-ai.providers.opencode-go.headers.x-opencode-session` was removed or renamed. The value only identifies the client — any stable string works.

# Fix

Restore the header in the route, then `./init.sh`.

# Related

[../systems/opencode-go-route.md](../systems/opencode-go-route.md) · [../../docs/troubleshooting.md](../../docs/troubleshooting.md)
