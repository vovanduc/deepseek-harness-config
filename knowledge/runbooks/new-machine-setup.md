---
type: runbook
title: New machine setup
description: Clone → init.sh → install.sh → real key in ~/.dsh/.env → doctor.sh READY.
tags: [setup, runbook]
---
# Steps

```bash
git clone https://github.com/vovanduc/deepseek-harness-config ~/Code/deepseek-harness-config
cd ~/Code/deepseek-harness-config
./init.sh              # offline baseline — must be green before anything else
./scripts/check-node.sh # node ≥ 20 and matching .nvmrc (install.sh runs this itself, first)
./install.sh           # pinned dsh, settings symlink, ~/.dsh/.env seed, skill links, plugins
$EDITOR ~/.dsh/.env    # OPENCODE_GO_API_KEY=<real key>
./scripts/doctor.sh    # expect: status: READY  (add --json for one machine-readable object)
```

`install.sh --no-install` skips the global npm step. It is idempotent and moves anything it would overwrite to `*.bak-<timestamp>`. It runs `scripts/check-node.sh` before creating anything: a Node below 20 stops it there, and a major that differs from `.nvmrc` only warns.

# Expected

`doctor.sh` ends `status: READY (n ok, 0 warn)`. A `warn` on the live call usually means offline; a `FAIL` names the layer to fix.

# Related

[verify-change.md](verify-change.md) · [../conventions/settings-symlink.md](../conventions/settings-symlink.md) · [../gotchas/models-endpoint-not-authenticated.md](../gotchas/models-endpoint-not-authenticated.md)
