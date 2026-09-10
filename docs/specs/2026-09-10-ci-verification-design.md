# CI verification gate — design

- **Feature:** `feat-003` (CI runs the verification gate on push)
- **Date:** 2026-09-10
- **Status:** approved (single maintainer; see note on process below)

## Problem

`./init.sh` is the baseline gate for this repo, but it only runs when a human or agent remembers to
run it. The failure modes it catches are all silent ones:

- `settings.yaml` fails to parse, or `agent-default-model` points at a provider/model that no longer exists (the composer then blocks every new session).
- A `skills/*/SKILL.md` loses `name` or `description` and the skill quietly disappears.
- A shell script gains a syntax error that breaks `install.sh` on a fresh machine.
- `feature_list.json` becomes invalid JSON or acquires two `in-progress` features.

None of these announce themselves on the machine where the edit was made. They surface on the second
machine — exactly what this repo exists to prevent.

## Goal

Every push and pull request runs the same offline gate automatically and reports red/green, with no
credential involved.

## Non-goals

- **No live inference in CI.** That needs a real key; it belongs to `scripts/doctor.sh` on a machine.
- **No `dsh` install in CI.** Keeps the job fast and offline; `dsh --dump-config` stays a machine check.
- **No dependency caching.** There is no `package.json`, and `actions/setup-node` with `cache: npm` errors without a lock file.
- **Not the harness audit.** `validate-harness.mjs` needs the local `harness-creator` install, which a runner does not have.

## Design

One workflow, one job: `.github/workflows/verify.yml`, triggered by `push` and `pull_request`.

| Step | Action | Why |
|---|---|---|
| 1 | `actions/checkout@v7` | get the repo |
| 2 | `actions/setup-node@v7` with `node-version-file: .nvmrc` | `init.sh` hard-requires Node (`dsh` needs Node 20+); `.nvmrc` pins 22 |
| 3 | `actions/setup-python@v7` (3.12) | the YAML cross-check is Python |
| 4 | `python3 -m pip install pyyaml` | see "the silent-skip trap" below |
| 5 | `./init.sh` | the gate itself |

### The silent-skip trap

`init.sh`'s most valuable check — parse `settings.yaml` *and* verify `agent-default-model` resolves
to a declared provider/model — is skipped with a message when `python3` + PyYAML is missing. The
GitHub Ubuntu image does not guarantee `python3-yaml`, so without step 4 CI would go green having
never run that check. CI therefore installs PyYAML explicitly, and `init.sh` gains a guard asserting
the workflow keeps installing it.

`dsh` is absent on the runner, so `init.sh` skips the `dsh --dump-config` step by its existing
guard; `shellcheck` is present on the Ubuntu image, and `init.sh` skips it gracefully elsewhere.

## Decisions and trade-offs

| Decision | Why | Accepted cost |
|---|---|---|
| Work directly on `main` | one-file additive change; this repo's convention is commit-then-publish on `main`; the workflow is itself unverified until the first push | no PR isolation for this change |
| Action refs by major tag (`@v7`) | readable, universally used; `v7` tracks the Node-24 runner runtime (the `v4`/`v5` majors still target Node 20 and now draw a deprecation annotation) | not SHA-pinned against tag retargeting |
| Python 3.12 pinned in the workflow | deterministic | one more version to bump |
| `init.sh` also checks the workflow | removing `run: ./init.sh` or the PyYAML step becomes a local failure instead of an invisible gap | a little coupling between the gate and its CI wiring |

## Acceptance criteria

1. `.github/workflows/verify.yml` parses as YAML and triggers on both `push` and `pull_request`.
2. The job installs PyYAML and then runs `./init.sh` on `ubuntu-latest`; `.nvmrc` pins Node 22.
3. The workflow references no credential (no `secrets.` anywhere).
4. `./init.sh` stays green locally, and now fails if the workflow stops invoking the gate or stops installing PyYAML.
5. A push to `main` produces a green run (`gh run list --workflow=verify.yml`); README carries the status badge.

## Verification plan

- **Local:** `./init.sh` (green), a YAML parse plus structural assertions on the workflow, a negative test (temporarily remove the `./init.sh` step → the gate must fail), and the knowledge link check.
- **Remote:** push, then `gh run list` / `gh run watch` to confirm the workflow actually runs and passes.

## Process note

The design path normally uses `superpowers:brainstorming` and `superpowers:writing-plans`. Those
skills are not installed in this session (checked in all three skill roots), so the spec and plan are
written by hand in the same shape and the workflow proceeds without them, per the `dcnet-workflow`
rule for absent sources.
