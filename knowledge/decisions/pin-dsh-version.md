---
type: decision
title: Pin the exact dsh version in dsh.version
description: install.sh installs @deepseek-ai/dsh at exactly the version in dsh.version; doctor.sh warns on any mismatch. No caret ranges, no "latest".
tags: [dsh, versioning, security]
---
# Decision

- `dsh.version` holds one exact version (`0.1.5-rc.1`). `install.sh` installs that version; `doctor.sh` warns when PATH has another.
- Upgrading means: edit `dsh.version` → `./install.sh` → `./scripts/doctor.sh` → commit.

# Why

- **Reproducibility**: this repo has no dependencies and therefore no lockfile, so the pinned runtime version *is* the reproducibility guarantee (DoD item 5).
- **Security**: releases up to and including `0.1.1-rc.2` carry CVE-2026-82533 — a sandboxed agent could reach dsh's own local Web UI and switch the session to `danger-full-access` with no prompt. Fixed from `0.1.2-alpha.2`; `dsh.version` stays above that floor.

# Trade-off

A pinned pre-release needs manual bumps and can lag fixes. Accepted: a config repo changes rarely, and a surprise upgrade is worse than a stale one.

# Related

[../runbooks/new-machine-setup.md](../runbooks/new-machine-setup.md) · [adopt-harness-and-okf.md](adopt-harness-and-okf.md) · [../../docs/troubleshooting.md](../../docs/troubleshooting.md)
