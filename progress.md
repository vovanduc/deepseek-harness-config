# Session Progress Log

## Current State

**Last Updated:** 2026-09-10 16:05 (+07)
**Active Feature:** none — `feat-004` completed this session; next session picks `feat-005`
**Repo:** `deepseek-harness-config` @ `main`
**Harness:** adopted 2026-09-10 (`AGENTS.md`, `feature_list.json`, `progress.md`, `init.sh`, `session-handoff.md`, `docs/specs|plans`, `knowledge/`)

## Status

### What's Done

- [x] Adopted the DCNET harness: state files, `docs/specs/` + `docs/plans/`, and `AGENTS.md` as the routing pointer.
- [x] Added `init.sh` — offline verification gate (`bash -n`, feature-list shape, `settings.yaml` parse + default-model resolution, skill frontmatter, CI wiring, shellcheck).
- [x] Seeded the OKF `knowledge/` bundle: index + log + six category indexes + 20 concepts.
- [x] `feat-003`: `.github/workflows/verify.yml` runs `./init.sh` on push and pull request; `.nvmrc` pins Node 22; README badge added.
- [x] `init.sh` fails when CI stops invoking the gate, stops installing PyYAML, or references a secret.
- [x] `feat-004`: `scripts/update-ponytail.sh` — drift check and `--apply` against a pinned upstream ref, replacing the hand-copy step in `skills/README.md`.
- [x] `./init.sh` passes; harness audit at full score; CI green on `main`.

### What's In Progress

- [ ] Nothing — session closed cleanly.

### What's Next

1. Pick `feat-005` (`doctor.sh --json` for automation) from `feature_list.json`.
2. Candidate not yet in the list: `install.sh` never checks the Node **major**, so a Node 18 machine passes its check and fails later; `.nvmrc` already pins 22.
3. First action of the next session: `./init.sh`.

## Blockers / Risks

- [x] ~~No CI yet~~ — closed by `feat-003`; the gate now runs on every push and pull request.
- [ ] Live inference is deliberately not part of `init.sh` or CI (it needs a key); `./scripts/doctor.sh` covers it on a real machine.
- [ ] `danger-full-access` remains available as a preset. The repo documents the risk; it cannot enforce it.
- [ ] `scripts/update-ponytail.sh` needs network, so it stays out of CI and drift is only detected when someone runs it.

## Decisions Made

- **Adopt harness + OKF in this repo** — state in files, durable facts in `knowledge/`.
  - Context: config repo, not app code; a second machine and a second session must both restart deterministically.
  - Alternatives: process only in the global `dcnet-workflow` skill; knowledge inside `docs/` — both rejected.
  - Record: `knowledge/decisions/adopt-harness-and-okf.md`.
- **Pin the exact dsh version** — reproducibility without a lockfile, and a floor above CVE-2026-82533.
  - Record: `knowledge/decisions/pin-dsh-version.md`.
- **`init.sh` stays offline** — a gate that needs a secret is red everywhere, so config correctness and machine readiness are split.
  - Record: `knowledge/decisions/init-stays-offline.md`.
- **`feat-003` shipped directly on `main`** — one additive workflow, and this repo's convention is commit-then-publish on `main`.
  - Cost accepted: no PR isolation for this change; the workflow was unverified until the first push.
  - Record: `docs/specs/2026-09-10-ci-verification-design.md`.
- **Ponytail skills stay byte-identical upstream; the pin lives in the script** — the sync carries `skills/*/SKILL.md` + LICENSE only, `--apply` requires an explicit flag, and `git` is the undo.
  - Record: `docs/specs/2026-09-10-ponytail-update-script-design.md`, `knowledge/runbooks/update-ponytail-skills.md`.

## Files Modified This Session

- `AGENTS.md` — new: routing pointer (startup, rules, DoD, end-of-session).
- `feature_list.json`, `progress.md`, `session-handoff.md` — harness state.
- `init.sh` — new gate, then extended with the CI-wiring guard (`feat-003`).
- `docs/specs/README.md`, `docs/plans/README.md` — document locations (keeps the dirs in git).
- `docs/specs/2026-09-10-ci-verification-design.md`, `docs/plans/2026-09-10-ci-verification.md` — `feat-003` spec + plan.
- `docs/specs/2026-09-10-ponytail-update-script-design.md`, `docs/plans/2026-09-10-ponytail-update-script.md` — `feat-004` spec + plan.
- `scripts/update-ponytail.sh` — new: pinned upstream sync for the ponytail skills.
- `skills/README.md` — updated: the manual copy step is replaced by the script; no hardcoded version.
- `knowledge/**` — OKF bundle (index, log, 6 category indexes, 20 concepts).
- `.github/workflows/verify.yml`, `.nvmrc` — new: the CI gate.
- `README.md` — CI badge, layout entries, entry-point note.
- Unchanged: `settings.yaml`, `.env.example`, `dsh.version`, `install.sh`, `scripts/doctor.sh`, `skills/ponytail*/SKILL.md`, `docs/models.md`, `docs/modes.md`, `docs/troubleshooting.md`.

## Evidence of Completion

- [x] `./init.sh` → `exit 0`: 4 scripts parse; 5 features, none in-progress; `settings.yaml` default `opencode-go/deepseek-flash` + `dsh --dump-config` composes; 6 skill bundles; CI workflow parses and runs the gate; shellcheck clean.
- [x] CI-wiring guard negative tests: removing the `run: ./init.sh` step, removing the PyYAML step, or adding a `secrets.` reference each make `./init.sh` exit 1 — verified with PyYAML and with a PATH that lacks it.
- [x] `feat-004` local tests: `./scripts/update-ponytail.sh` → exit 0 with six skills + LICENSE `identical` at the pin `v4.9.0`; `--ref v4.8.4` → exit 1 (`ponytail` 2 changed lines, `ponytail-help` 6); `--apply --ref v4.8.4` rewrote exactly those two files and `git checkout -- skills` restored the tree byte-identical; `--apply` at the pin changed nothing; unknown ref → exit 2; `bash -n` + `shellcheck -S warning` clean.
- [x] `./scripts/doctor.sh` → `status: READY (6 ok, 0 warn)`, inference on `deepseek-flash` → 200.
- [x] `node ~/.agents/skills/harness-creator/scripts/validate-harness.mjs --target .` → `Overall: 100/100`, bottleneck none.
- [x] GitHub Actions runs green on `main`: [34457516258](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34457516258) (`a5d29af`), [34457635034](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34457635034) (`c5a1b9d`), [34458177413](https://github.com/vovanduc/deepseek-harness-config/actions/runs/34458177413) (`5db3486`, feat-004).
- [x] Knowledge links: 0 broken.

## Notes for Next Session

The route is `AGENTS.md` → `./init.sh` → `feature_list.json` → `progress.md` → `knowledge/index.md`.
This repo has no `package.json` and no lockfile by design: reproducibility rests on the pinned `dsh`
version in `dsh.version`, the pinned Node major in `.nvmrc`, and Node 20+.
