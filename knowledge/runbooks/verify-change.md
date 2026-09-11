---
type: runbook
title: Verify a change before claiming done
description: Which gate proves what, and what to record as evidence.
tags: [verification, runbook]
---
# Steps

1. `./init.sh` — offline gate. Green means the tracked config is self-consistent (scripts parse, feature list valid, `settings.yaml` parses and its default model resolves, skill frontmatter intact, shellcheck clean).
2. If the change touches a route, credential, or skills: `./scripts/doctor.sh` — machine gate, needs a live key, posts one real completion. Add `--json` for one object with stable keys (`status`, `ok`, `warn`, `fail`, `checks[]` of `id`/`status`/`message`) instead of parsing colour; the verdict and exit code are identical in both modes.
3. If a harness file changed: `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` — expect 100/100.
4. Record the command and its output in `feature_list.json` (`evidence`) or `progress.md`.

# Notes

- Never diagnose a credential with `GET /models` — see the gotcha.
- A green `init.sh` does **not** prove inference works; that is `doctor.sh`.

# Related

[../decisions/init-stays-offline.md](../decisions/init-stays-offline.md) · [../gotchas/models-endpoint-not-authenticated.md](../gotchas/models-endpoint-not-authenticated.md) · [../../AGENTS.md](../../AGENTS.md)
