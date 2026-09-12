---
type: gotcha
title: ./init.sh needs write access outside the workspace
description: Under a workspace-write file sandbox the gate dies with EPERM on $DSH_HOME/profiles/headless/cordis.yml, which looks like a broken repo and is not one.
tags: [sandbox, verification, init]
---
# Symptom

`./init.sh` gets through bash syntax, `feature_list.json` and the settings parse, then dies:

```
Error: EPERM: operation not permitted, open '/Users/<you>/.dsh/profiles/headless/cordis.yml'
    at prepareProfile (.../dsh/lib/profile-boot-*.js)
  code: 'EPERM'
```

Exit code 1. Every check before it passed.

# Cause

The gate ends with `dsh --profile headless --dump-config`, and composing a profile writes
`$DSH_HOME/profiles/<name>/cordis.yml`. `$DSH_HOME` defaults to `~/.dsh`, which is outside the
session workspace. A `workspace-write` file policy blocks that write, so the *environment*, not
the config, produces the failure.

This is not the harness's own `[sandbox: file access denied ...]` marker — the denial surfaces as
a raw Node `EPERM`. Do not read it as a repo defect.

# What to do

- Run the gate where `$DSH_HOME` is writable (a normal shell, or a session with
  `danger-full-access`).
- If you cannot, treat everything up to the compose step as the result, and say so explicitly
  instead of claiming the gate passed.
- Pointing `DSH_HOME` at a writable directory also works for a one-off check, but then the gate
  validates a *different* config than the running one — say which.

# Related

[../runbooks/verify-change.md](../runbooks/verify-change.md) · [../runbooks/ci-verification.md](../runbooks/ci-verification.md)
