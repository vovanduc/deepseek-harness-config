---
type: runbook
title: What CI checks, and what it deliberately does not
description: .github/workflows/verify.yml runs ./init.sh on push and pull request — no credential, no live model call. Reproduce it locally with the same commands.
tags: [ci, verification]
---
# What runs

`.github/workflows/verify.yml` — one job on `ubuntu-latest`:

1. checkout → Node (version read from `.nvmrc`) → Python 3.12
2. `python3 -m pip install pyyaml`
3. `./init.sh`

# The PyYAML step is load-bearing

`init.sh` *skips* the `settings.yaml` cross-check (parse + `agent-default-model` resolution) when
PyYAML is missing, and the Ubuntu image does not guarantee `python3-yaml`. CI installs it explicitly,
and `init.sh` fails when the workflow stops installing it — so the gap cannot reopen silently.

# Deliberately not in CI

- A live inference call (`scripts/doctor.sh`) — needs the real key.
- `dsh` install / `dsh --dump-config` — absent on the runner; `init.sh` skips it by its own guard.
- The harness audit (`validate-harness.mjs`) — needs the local `harness-creator` install.

`shellcheck` is preinstalled on the Ubuntu image; where it is absent, `init.sh` skips lint.

# Reproduce locally

```bash
python3 -m pip install pyyaml   # only if your python lacks it
./init.sh
```

A red badge means: read `gh run view --log-failed`, or just run `./init.sh` locally — it is the same gate.

# Maintenance

Action majors track the runner runtime — currently `@v7`. The older `v4`/`v5` majors still target
Node 20, which GitHub force-runs on Node 24 and flags with a deprecation annotation on every run.
Bump all three actions together, then re-run the workflow to confirm the annotation is gone.

# Related

[../decisions/init-stays-offline.md](../decisions/init-stays-offline.md) · [verify-change.md](verify-change.md) · [../index.md](../index.md)
