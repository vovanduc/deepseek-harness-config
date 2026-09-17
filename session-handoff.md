# Session Handoff

## Current Objective

- Goal: apply the current config to this machine and make the settings-symlink drift impossible to
  miss. Both done.
- Current status: complete. `feat-014` and `feat-015` are `done`; **no open features**; repo clean
  and pushed.
- Branch / commit: `main` @ `5e24053` plus this session's closing commit.

## Completed since the previous handoff

Two features closed after `feat-013` (the diagram skill), which is what this file used to describe:

- `feat-014` — routed **Devin SWE-2** through omp's auth-gateway: a second provider
  (`omp-gateway`, `devin/swe-2`) reachable only via two loopback processes
  (`scripts/omp-gateway.sh`). Verified end to end: `swe-2 via gateway: OK`, a headless dsh turn
  returning `GW OK`, and the same in the UI with the `SWE-2 (Devin, via omp)` badge.
- `feat-015` — **the settings symlink drifted four times and nothing caught it.** Root cause is the
  app's own write path (`dsh-settings-file` → `dsh-atomic-write`: `writeFile` of a temp file, then
  `rename` over the target — `rename` replaces a symlink rather than following it), reproduced
  deliberately. `doctor.sh` used to accept `-L || -f` and record only "present", so all four drifts
  stayed green — one hid the whole `omp-gateway` route for a day. The check now requires the link,
  resolved into this repo, and reports whether the drift is latent or has already diverged. The most
  frequent trigger is cured: the repo carries `ui-onboarding.welcomeNoticeVersion`, so the welcome
  modal returns `null` before rendering and there is no Continue click to write.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Offline gate | `./init.sh` | exit 0 | 15 features / 0 in-progress, 5 plugins pinned, 7 skill bundles |
| Doctor | `./scripts/doctor.sh` | READY (6 ok) | settings check now requires the symlink |
| Gateway | `./scripts/omp-gateway.sh status` | `swe-2 via gateway: OK` | broker :8765 + gateway :4000 |
| SWE-2 through dsh | `dsh --profile headless --patch … "Reply with exactly: GW OK"` | `GW OK` (4.2 s) | proves dsh, not just curl |
| SWE-2 in the UI | pick model → send | `GW OK` (5 s) | badge `SWE-2 (Devin, via omp)` |
| Symlink check, 4 branches | `./scripts/doctor.sh` | NOT READY ×3, READY ×1 | diverged · identical-but-regular · link to `/tmp` · correct |
| Harness audit | `validate-harness.mjs --target .` | 100/100 | bottleneck none |
| Knowledge links | link check over `knowledge/**`, docs, README | 163 / 0 broken | 73 files |
| UI notice | fresh load | gone | link survives the load intact (no write) |

## Decisions Made

- **The link is one-way, and the docs now say so.** The server *reads* the repo file through it; a UI
  settings write replaces the link and lands in a standalone `~/.dsh/settings.yaml` that never reaches
  the repo. Four files previously claimed the UI's edits "land here and are ready to commit" —
  README, `install.sh`, the convention, its index — all corrected.
- **The trigger is an explicit settings write, not "using the UI".** Opening the UI, switching
  workspace and starting a session only *read* settings (measured: the link survived each). Corrected
  after review — an earlier note overreached.
- **Commit the onboarding ack rather than re-dismissing it.** Five dismissals meant five drifts; the
  key makes the modal not render, so the click no longer exists.
- **A UI-made change is merged by hand**, never `cp`'d back: the live file also carries app state, and
  a `vision-toolkit-*` provider id is only valid on the profile that registers it.
- **`diagrams/` is not this repo's deliverable** — test output from chat probes, removed.

## Blockers / Risks

- **Expect to relink after an explicit settings change.** There is no way to make the app write
  through a link without patching it; `doctor.sh` is the mitigation, not a fix. Run it after changing
  settings in the UI.
- **The gateway does not survive a reboot** — `nohup`, no launchd. After rebooting:
  `./scripts/omp-gateway.sh start` (idempotent; the `.env` key is unchanged).
- **`omp` here is 18.1.22**, below the `>= 18.2` the docs state, yet `auth-broker` and
  `auth-gateway` exist and work. Either the floor is stale or it is a soft note.
- **Skills and plugins compose per session** — a session opened before an install does not see it. No
  restart is needed for a skill, but a new session is.
- `web_search` is still unusable here (modsearch's keyless route 403s from this IP); `read_page` works.
- Nothing here is on the `headless` / `sdk` / `acp` profiles except what the skill provides.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `feature_list.json` (15 features, all done) and `progress.md`.
3. Review this handoff.
4. Run `./init.sh`. If it stops with `EPERM` on `$DSH_HOME/profiles/...`, that is the sandbox, not the
   repo — see `knowledge/gotchas/init-sh-needs-dsh-home-write.md`.
5. Before trusting the config, run `./scripts/doctor.sh` — it is the only gate that can see a drifted
   settings symlink.

## Recommended Next Step

- **Use the machine, then check the link.** The config is applied and both providers answer; the open
  question is whether the drift keeps happening in ordinary use now that the welcome notice no longer
  writes. Run `./scripts/doctor.sh` after any UI settings change and see whether anything else writes.
- Lower-priority candidates live in `progress.md` → What's Next: a modsearch key so `web_search`
  works, the `experiments/` scope question, and the two official subagent bundles.
