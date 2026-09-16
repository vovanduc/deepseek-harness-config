---
type: gotcha
title: Every dsh UI settings write replaces the settings.yaml symlink with a regular file
description: dsh persists settings atomically (write a temp file, rename it over the target), and rename() replaces a symlink instead of following it — so picking a model or changing the font size silently unpicks the link, and every later repo edit stops reaching the server while the file itself still looks valid.
tags: [dsh, install, settings, atomic-write]
---
# Symptom

You edit `settings.yaml` in the repo, `./init.sh` passes, `doctor.sh` says READY — and the
running server still behaves as before. Nothing reports a problem, because nothing is broken:
the repo file is valid, it is simply not the file the server reads.

# Cause — confirmed in the dsh source, and reproduced

Two facts combine:

1. `dsh-settings-file` persists through `dsh-atomic-write`, which is
   `writeFile('<path>.<hex>.tmp')` followed by `rename(temp, path)`. There is no `realpath` step.
2. `rename()` operates on the **link**, not on what it points at. So the rename replaces
   `$DSH_HOME/settings.yaml` with a fresh regular file; the repo file is left untouched.

Reproduced 2026-09-16, deliberately: with the link restored, choosing a model in the web
picker drifted it inside 3 seconds. The live file then differed exactly as predicted —
`[ text, image ]` re-serialised, `agent-default-model` rewritten, a new `ui-onboarding` key.

So it is **not** a stray `cp`, a restore, or a skipped install step (the first version of this
note guessed that, wrongly). It is the app's normal write path. Any UI settings change causes
it. Four backup files tell the story:

```
settings.yaml.bak-20260910-153154   settings.yaml.bak-20260912-101238
settings.yaml.bak-20260915-144039   settings.yaml.bak-20260916-083653
```

# Why nothing caught it

`doctor.sh` used to accept `[ -L … ] || [ -f … ]` and record only "present" — which a regular
file satisfies. All four drifts stayed green, and one of them hid a whole missing provider route
(`omp-gateway`) for a day. `init.sh` reads the **repo** file, so it cannot see the drift either:
it was validating a file the server was not reading.

# Fix

```bash
./install.sh --no-install        # parks the file as settings.yaml.bak-<stamp>, then links
ls -la ~/.dsh/settings.yaml      # confirm the arrow
```

`doctor.sh` now requires the link, resolved into this repo, and fails with a message naming the
cause:

```
FAIL  ~/.dsh/settings.yaml is a regular file, not a symlink to <repo>/settings.yaml — a UI
      settings write replaced the link, so repo edits no longer reach the server; fix: ./install.sh
```

Run `doctor.sh` after using the UI to change anything. Because the link is the invariant, the
check is only meaningful on the live path — there is no way to make the app write through a link
without patching it, so expect to relink after UI edits and let the check catch you.

# A second trap in the same write

What the app persisted was `agent-default-model.provider: vision-toolkit-opencode-go` — an id
registered at **runtime** by `@anionex/dsh-vision-toolkit` (`VARIANT_PROVIDER_PREFIX =
'vision-toolkit-'`), and only on the profile that plugin is installed into (`web`). It is not in
`llm-pi-ai.providers`, so the shared default would name a provider that does not exist for
`headless` / `tui` / `sdk`. `init.sh` does assert this (`agent-default-model.provider … is not a
declared provider`, verified: exit 1 on the bad id, 0 on the good one) — but it reads the repo
file, so the guard only helps once the link is intact.

# Related

[../conventions/settings-symlink.md](../conventions/settings-symlink.md) · [../runbooks/new-machine-setup.md](../runbooks/new-machine-setup.md) · [../systems/dsh-home-layout.md](../systems/dsh-home-layout.md)
