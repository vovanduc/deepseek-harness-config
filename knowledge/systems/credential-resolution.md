---
type: service
title: Credential resolution order
description: Four layers, first hit wins — the launch environment, ~/.dsh/.credentials.yaml, <workspace>/.env, ~/.dsh/.env.
tags: [credentials, dsh]
---
# Order

| # | Source | Notes |
|---|---|---|
| 1 | the environment `dsh` was launched in | a snapshot: exporting the variable *after* launch is not seen; restart dsh |
| 2 | `~/.dsh/.credentials.yaml` | written by Web UI → Settings → Models |
| 3 | `<workspace>/.env` | per-project override |
| 4 | `~/.dsh/.env` | seeded by `install.sh`, mode 600 — the reliable layer for every launcher (systemd, cron, CI) |

The name `apiKeyEnv` points at must match the stored variable **exactly, including case**. Layers 2–4 take effect on the next request without a restart; layer 1 does not.

# Related

[../conventions/secrets-never-committed.md](../conventions/secrets-never-committed.md) · [../../docs/models.md](../../docs/models.md) · [../../.env.example](../../.env.example)
