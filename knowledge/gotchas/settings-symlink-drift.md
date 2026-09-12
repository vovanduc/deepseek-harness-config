---
type: gotcha
title: $DSH_HOME/settings.yaml can silently stop being a symlink
description: If the running config is a regular file instead of the link install.sh creates, every repo edit is invisible to the server while init.sh and doctor.sh still pass.
tags: [dsh, install, settings]
---
# Symptom

You edit `settings.yaml` in the repo, `./init.sh` passes, `doctor.sh` says READY — and the
running server still behaves as before. Nothing reports a problem, because nothing is broken:
the repo file is valid, it is simply not the file the server reads.

# How to see it

```bash
ls -la ~/.dsh/settings.yaml         # expect: lrwxr-xr-x ... -> <repo>/settings.yaml
diff ~/.dsh/settings.yaml settings.yaml
```

Found on 2026-09-12: `~/.dsh/settings.yaml` was a regular 2543-byte file (mode 600) carrying an
extra `ui-onboarding` key that the repo file did not have. The app had written its own state to
it — which is exactly what a symlink would have redirected into the repo. That difference is the
tell.

# Cause

The link is only created by `install.sh`. Anything that recreates the file afterwards — a
restore from backup, `cp` instead of `ln -s`, an install step skipped — leaves a regular file
that the app then happily keeps updating.

# Fix

```bash
./install.sh --no-install      # moves the file to settings.yaml.bak-<stamp>, then links
ls -la ~/.dsh/settings.yaml    # confirm the arrow
```

`install.sh` is idempotent and reports `settings.yaml already linked` on a healthy machine, so
running it is safe as a check. Treat the presence of the arrow as part of the baseline, not an
assumption — [../conventions/settings-symlink.md](../conventions/settings-symlink.md) states the
rule, and this is what breaking it looks like.

# Related

[../conventions/settings-symlink.md](../conventions/settings-symlink.md) · [../runbooks/new-machine-setup.md](../runbooks/new-machine-setup.md) · [../systems/dsh-home-layout.md](../systems/dsh-home-layout.md)
