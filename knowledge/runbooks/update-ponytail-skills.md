---
type: runbook
title: Update the ponytail skills from upstream
description: scripts/update-ponytail.sh reports drift against a pinned upstream ref and applies it. Local files are verbatim upstream; only skills/*/SKILL.md and LICENSE are carried.
tags: [skills, ponytail, runbook]
---
# The pin

`UPSTREAM_REPO` / `UPSTREAM_REF` at the top of `scripts/update-ponytail.sh` are the single source of
truth (currently `DietrichGebert/ponytail` @ `v4.9.0`). `skills/README.md` deliberately does not
repeat the version, so the two cannot drift apart.

# Check for drift

```bash
./scripts/update-ponytail.sh              # exit 0 in sync, 1 drift, 2 usage/download error
./scripts/update-ponytail.sh --ref v4.10.0
```

# Apply

```bash
./scripts/update-ponytail.sh --ref v4.10.0 --apply
git diff -- skills                        # review
# then set UPSTREAM_REF='v4.10.0' in the script and commit
```

`--apply` overwrites `skills/*/SKILL.md` and `skills/LICENSE-ponytail-upstream`. It never deletes a
local-only skill (reported as `orphan`) and never rewrites its own pin — it prints the reminder.

# What is deliberately not synced

- Upstream's `.openclaw/skills/` tree — a built copy, not the source.
- Upstream's plugin hooks for other agents (mode tracker, statusline, subagent re-injection): only
  the `SKILL.md` layer is carried here, which is why ponytail mode is not sticky.

# Notes

- No auth needed: the script downloads a codeload tarball (~1 MB). It stays out of CI (network).
- As of 2026-09-10 all six `SKILL.md` files and the LICENSE are byte-identical to `v4.9.0`.
  `v4.8.4` differs in `ponytail` (2 lines) and `ponytail-help` (6 lines) — the fixture used to test
  the drift and apply paths.

# Related

[../../skills/README.md](../../skills/README.md) · [../conventions/skill-bundle-layout.md](../conventions/skill-bundle-layout.md) · [../index.md](../index.md)
