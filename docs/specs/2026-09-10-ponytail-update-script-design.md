# Ponytail skill update script — design

- **Feature:** `feat-004` (Script the ponytail skill update)
- **Date:** 2026-09-10
- **Status:** approved (single maintainer)

## Problem

`skills/README.md` tells the reader to "copy `skills/*/SKILL.md` from a newer upstream release over
these directories" — by hand, across a repo boundary. Two failure modes:

- A half-completed update (five of six files copied) looks exactly like a complete one.
- Nothing records which upstream ref the local copy came from, so "is this current?" needs the upstream repo opened and compared by eye.

## Facts established (2026-09-10)

- Upstream is [`DietrichGebert/ponytail`](https://github.com/DietrichGebert/ponytail), MIT, latest release `v4.9.0`; the source layout is `skills/<name>/SKILL.md`. The repo also carries `.openclaw/skills/...`, which is a *built* copy — not the source to sync from.
- All six local `skills/ponytail*/SKILL.md` **and** `skills/LICENSE-ponytail-upstream` are byte-identical to upstream `v4.9.0`.
- A tag tarball downloads from `https://codeload.github.com/<repo>/tar.gz/refs/tags/<ref>` (~1 MB, single top directory `ponytail-4.9.0/`).
- `v4.8.4` differs from the local copy in two files (`ponytail`, 2 lines; `ponytail-help`, 6 lines), so it is a usable drift fixture.
- Note: upstream ships plugin hooks for other agents; only the `SKILL.md` layer is carried here, so the sync set is exactly `skills/*/SKILL.md` plus `LICENSE`.

## Goal

One command that reports which local files differ from a pinned upstream ref, and applies the
upstream files when explicitly asked.

## Non-goals

- Not a general dependency updater — it knows about ponytail only.
- It does not run in CI: it needs network, and this repo's CI stays offline by decision.
- It does not rewrite its own pin, and it does not touch `install.sh` or the skill symlinks.

## Design

`scripts/update-ponytail.sh`:

| Invocation | Behaviour |
|---|---|
| `./scripts/update-ponytail.sh` | download the pin, report per skill `identical` / `DIFFERS` / `missing`, plus LICENSE; exit 0 when in sync, 1 on drift |
| `./scripts/update-ponytail.sh --apply` | copy the upstream `SKILL.md` files (and LICENSE) over the local ones; exit 0 |
| `./scripts/update-ponytail.sh --ref <ref>` | check or apply another tag/branch without changing the pin |
| `./scripts/update-ponytail.sh --help` | usage |

- `UPSTREAM_REPO` and `UPSTREAM_REF` sit at the top of the script — the pin's single source of truth. `skills/README.md` therefore stops hardcoding a version that can drift.
- The tarball is downloaded to a `mktemp -d` directory, extracted, and the single top directory is derived; a `trap` removes it on exit.
- Comparison uses `cmp -s`; a differing file also reports its changed-line count from `diff`.
- Local `ponytail*` skills with no upstream counterpart are reported as `orphan`.
- Exit 2 for usage errors, a missing `curl`/`tar`, or a failed download.

## Decisions and trade-offs

| Decision | Why | Accepted cost |
|---|---|---|
| Tarball + `curl`/`tar`, not `git`/`gh` | no auth and no clone; works on a bare machine and in a container | ~1 MB download per run |
| Diff-only by default | running it never mutates the tree, so it doubles as a drift check | applying takes a second invocation |
| Pin inside the script | one source of truth; the README can stop repeating a version number | bumping the pin means editing the script |
| `--apply` leaves the pin alone | the script never rewrites itself | it prints a reminder to update `UPSTREAM_REF` |
| `git` is the undo, not a `*.bak` copy | the files are tracked, so `git diff`/`checkout` is stronger and self-documenting | no backup outside git |

## Acceptance criteria

1. `./scripts/update-ponytail.sh` at the pin exits 0 and reports all six skills plus LICENSE `identical`.
2. `--ref v4.8.4` reports drift for `ponytail` and `ponytail-help` and exits 1; `--apply --ref v4.8.4` really rewrites those files (checked, then reverted with `git checkout`).
3. An unknown ref exits 2 with a readable message and does not touch the tree.
4. `bash -n` and `shellcheck -S warning` are clean (also enforced by `./init.sh`, which globs `scripts/*.sh`).
5. `skills/README.md` documents the script; a `knowledge/` runbook records the procedure and the verbatim-copy rule.

## Verification plan

- Local: the three invocations above (pin, drift, apply-then-revert), an unknown ref, `./init.sh`, shellcheck, and the knowledge link check.
- No remote/CI verification: by design this script stays out of CI.

## Process note

`superpowers:*` is not installed in this session, so the spec and plan are written by hand and the
tasks are executed inline (same note as the `feat-003` spec).
