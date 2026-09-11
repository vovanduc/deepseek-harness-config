# Node major check — design

- **Feature:** `feat-008` (a Node 18 machine must fail loudly, at install time)
- **Date:** 2026-09-11
- **Status:** approved (single maintainer)

## Problem

`install.sh` only asks whether `node` exists (`command -v node`). `.nvmrc` pins major 22 and CI
installs from it, but a machine running Node 18 passes that check, installs the pinned `dsh`, and
then fails somewhere later — a confusing failure far from its cause. The repo's whole promise is that
a second machine ends up in the same state; the runtime baseline should be checked, not assumed.

## Facts

- `dsh` requires Node 20+ (`install.sh` says so in its error message; CI uses `.nvmrc` = 22).
- `init.sh` and the plugin scripts hard-require `node`, so it is always present when they run.
- No other script reads `.nvmrc`.

## Goal

A single, standalone check that answers "is this machine's Node usable, and does it match the pin?"
— run by `install.sh` and available by hand.

## Non-goals

- Does not switch Node versions (no nvm/corenv invocation) and does not install anything.
- Does not fail on a *newer* major: the hard floor is 20; a divergence from `.nvmrc` is a warning.
- Not part of `init.sh`'s offline gate beyond a wiring guard — the gate must stay about tracked files,
  and it already requires a working node to run at all.

## Design

`scripts/check-node.sh` — exit `0` ok, `1` too old, `2` no node / usage.

| Situation | Result |
|---|---|
| major ≥ 20 and == `.nvmrc` major | `ok`, exit 0 |
| major ≥ 20 but ≠ `.nvmrc` major | `warn` (this config is verified against the pinned major), exit 0 |
| major < 20 | `FAIL`, names the floor and the pin, exit 1 |
| no `node` on PATH | `FAIL`, exit 1 (a caller that needs node exits 2 only on a bad flag) |

`install.sh` calls it in step 1, before anything is created, and `die`s on a non-zero exit. `init.sh`
gains a wiring guard (script exists, is executable, `install.sh` still calls it), alongside the
existing `install-plugins.sh` / pre-flight guards.

## Decisions and trade-offs

| Decision | Why | Accepted cost |
|---|---|---|
| A separate script, not four inline lines | every branch (old / divergent / fine) is testable by putting a fake `node` first on PATH, without running `install.sh` | one more file to wire |
| Warn on a newer major, fail only below 20 | a Node 24 machine is not broken; blocking it would be wrong | divergence from the pin is only a warning |
| `.nvmrc` is the pin | it is already what CI installs from | `.nvmrc` must stay a major-only file |

## Acceptance criteria

1. `./scripts/check-node.sh` on this machine → `ok`, exit 0 (node 22 = `.nvmrc` 22).
2. A fake `node` reporting `v18.20.0` first on PATH → `FAIL`, exit 1, message names both the floor and the pin.
3. A fake `node` reporting `v24.1.0` → `warn`, exit 0.
4. `install.sh` stops before creating anything when the check fails (no `~/.dsh` writes).
5. `init.sh` fails if the script is removed, loses `+x`, or `install.sh` stops calling it.
6. `./init.sh`, the audit and CI stay green.

## Verification plan

The three fixtures above plus the wiring negative tests, `./init.sh`, and the CI run after pushing.

## Process note

`superpowers:*` is not installed; spec and plan are written by hand and the tasks run inline.
