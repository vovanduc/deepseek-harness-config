# Plugin set expansion — plan

- **Feature:** `feat-009`
- **Date:** 2026-09-11
- **Spec:** [../specs/2026-09-11-plugin-set-expansion-design.md](../specs/2026-09-11-plugin-set-expansion-design.md)

## Tasks

| # | Task | Status |
|---|---|---|
| 1 | Survey `awesome-dsh-plugin/awesome-dsh-plugin`: category counts, `data/stars.json` + `data/downloads.json`, the two "manager" entries | done |
| 2 | Shortlist candidates for the three gaps (discovery, web search, vision) | done |
| 3 | Resolve the real npm spec for each candidate and verify `repository.url` matches the repo | done |
| 4 | `./scripts/plugin-preflight.sh` every candidate against dsh `0.1.5-rc.1` | done — 5 pass, 3 blocked |
| 5 | Add `feat-009` as `in-progress`; write the spec + this plan | done |
| 6 | Add the four entries to `plugins.json` | done |
| 7 | `./scripts/install-plugins.sh` and read the summary | done |
| 8 | `dsh plugin --profile web list` + `--dump-default-config` layer check | done |
| 9 | Update `docs/plugins.md`, the knowledge runbook, a new gotcha, `knowledge/log.md` | done |
| 10 | Close the feature: evidence in `feature_list.json`, `progress.md`, `session-handoff.md` | done |
| 11 | `./init.sh`, knowledge link check, harness audit | done |
| 12 | Commit + push on `main`; confirm CI | done |

## Notes

- Order matters: pre-flight before install (task 4 before 7) — that gate is what refused the three
  popular candidates.
- Deliberately out of order relative to `docs/plugins.md`: the restart is not performed here, so the
  four plugins are installed and composed but not yet served to the browser.
