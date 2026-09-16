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
note guessed that, wrongly). It is the app's normal settings write path. Every **explicit settings
write** causes it: a model pick, a font size, and acknowledging the welcome notice — `acknowledge()`
has exactly one caller, the modal's Continue button (`dsh-client-ui-settings-models`), and it
persists the same way. All three are the *same* mechanism, not three mechanisms.

What does **not** drift it, measured: opening the UI, switching workspace, starting a session. Those
read settings without writing them. So the trigger is a settings change, not "using the UI". Four
backup files tell the story:

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

`doctor.sh` now requires the link, resolved into this repo, and distinguishes how bad the drift
already is — a latent one has not cost you anything yet, a diverged one means the server is already
running something else:

```
FAIL  ~/.dsh/settings.yaml is a regular file, not a symlink to <repo>/settings.yaml — dsh replaced
      the link when it last wrote settings, and content still matches the repo, so nothing is wrong
      yet — the next repo edit is what will not apply; fix: ./install.sh --no-install

FAIL  ~/.dsh/settings.yaml is a regular file, not a symlink to <repo>/settings.yaml — dsh replaced
      the link when it last wrote settings, and the live file has also DIVERGED from the repo, so the
      server is running settings this repo does not describe; fix: ./install.sh --no-install
```

Check after any explicit settings change. Opening the UI, switching workspace or starting a session
does **not** write settings and leaves the link intact (measured); the drifts come from settings
writes.

# One of the three triggers is now cured, not mitigated

Acknowledging the welcome notice was the most common drift here — five dismissals, each one
re-breaking a link that had just been restored. It is fixed rather than documented away: the repo
`settings.yaml` now carries the ack,

```yaml
ui-onboarding:
  welcomeNoticeVersion: 2026-08-13.1
```

so `state.acknowledged` is already true on load and the modal returns `null` before rendering — there
is no Continue button left to click, therefore no write. The value is
`WELCOME_NOTICE_ACK_FIELD`/`WELCOME_NOTICE_VERSION` from `dsh-client-ui-settings-models`; a stale
value is harmless beyond bringing the notice back. Verified: the notice no longer appears on a fresh
UI load and the link survives it intact.

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
