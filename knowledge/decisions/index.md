---
type: index
title: Decisions (ADR)
---
# Decisions

- [Adopt the DCNET harness and an OKF knowledge bundle](adopt-harness-and-okf.md) — state in files, durable facts in `knowledge/`.
- [Pin the exact dsh version](pin-dsh-version.md) — `dsh.version`, no caret ranges; CVE-2026-82533 floor.
- [`init.sh` stays offline](init-stays-offline.md) — config correctness in the gate, machine readiness in `doctor.sh`.
- [dsh as the teammates-product engine](dsh-as-teammates-engine.md) — per-bot ACP profile + container + own `DSH_HOME`; pi.dev as curriculum, rakazo/OpenMausBot as product references.
- [This repo hosts the product, not only config](repo-hosts-teammates-product.md) — scope expanded 2026-10-07; revisit splitting if product code outweighs config.
