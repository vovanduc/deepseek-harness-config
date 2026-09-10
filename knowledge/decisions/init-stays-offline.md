---
type: decision
title: init.sh verifies offline; doctor.sh verifies the machine
description: The startup gate parses and cross-checks tracked files only — no credential, no network, no live model call — so a fresh clone always has a valid baseline. Live readiness stays in doctor.sh.
tags: [verification, harness]
---
# Decision

- `./init.sh` — `bash -n` on every script, `feature_list.json` shape + one-feature rule, `settings.yaml` parse + `agent-default-model` resolution, skill frontmatter, shellcheck. Fails fast.
- `./scripts/doctor.sh` (or `./init.sh --with-doctor`) — CLI version, settings symlink, credential (placeholder detection), one live completion.
- CI runs only the offline gate.

# Why

A baseline that needs a secret is red on every fresh machine and in CI, which trains everyone to ignore it. "Is the tracked config self-consistent?" and "is this machine ready to talk to the model?" are different questions; splitting them keeps the fast gate trustworthy.

# Consequences

`./init.sh` can be green while inference is broken. That is expected — it is exactly what `doctor.sh` is for, and `AGENTS.md` names both.

# Related

[../runbooks/verify-change.md](../runbooks/verify-change.md) · [../gotchas/models-endpoint-not-authenticated.md](../gotchas/models-endpoint-not-authenticated.md) · [adopt-harness-and-okf.md](adopt-harness-and-okf.md)
