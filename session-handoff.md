# Session Handoff

## Current Objective

- Goal: make diagram requests work from a chat message, and prove both notations do.
- Current status: complete. `feat-013` is `done`; **no open features**; repo clean and pushed.
- Branch / commit: `main` @ `77f82d3` plus this session's closing commit.

## Completed since the previous handoff

Three features closed after `feat-009` (the plugin set), which is what this file used to describe:

- `feat-010` — restored the `$DSH_HOME/settings.yaml` **symlink**; it had drifted to a regular file,
  so no repo edit was reaching the server while every check still passed.
- `feat-011` — `input: [text, image]` on `deepseek-flash`, proven at the gateway first, then in-harness.
- `feat-012` — `experiments/office-3d-poc/`: a one-file Three.js scene with a headless-Chromium
  verification loop.
- `feat-013` — **this session.** Diagram requests from chat:
  - `experiments/bpmn-viewer/` — real BPMN 2.0 renders in the **document preview** with no plugin
    (bpmn-js vendored, XML inlined, `viewBox` fit, self-check published into `<pre id="fit">`).
  - `skills/draw-bpmn/` — the notation decision plus four steps and seven measured traps, linked into
    `~/.dsh/skills` so the request resolves from chat in **any** workspace.
  - `inline.mjs` — refuses XML without DI and retitles the page from the process name.
  - `knowledge/runbooks/draw-bpmn-workflow.md` — the full recipe and every trap.

## Verification Evidence

| Check | Command | Result | Notes |
|---|---|---|---|
| Offline gate | `./init.sh` | exit 0 | 13 features / 0 in-progress, 5 plugins pinned, 7 skill bundles |
| Doctor | `./scripts/doctor.sh` | READY (6 ok) | 7 skills linked, inference 200 |
| Harness audit | `validate-harness.mjs --target .` | 100/100 | bottleneck none |
| Knowledge links | link check over `knowledge/**`, docs, README | 153 / 0 broken | 64 files |
| **BPMN from chat** | fresh web session, one prompt | real BPMN | `travel-expense.*`: 5 tasks, 6 gateways, 12 flows, 20 DI shapes, 127 steps, 14 min |
| **BPMN from chat** | fresh headless session, no repo pointer | real BPMN | `xin-nghi-phep.{source.bpmn,bpmn,html,svg,png}` + `make-bpmn.mjs` |
| **mermaid from chat** | web session, "…bằng mermaid" | 2 `flowchart` SVGs inline | "Mermaid diagram rendered", 15 s — re-proved *after* the skill existed |
| Viewer (real UI) | Files panel → `index.html` | `pass:true` | blob frame, `sandbox="allow-scripts"`; panel 614×692 and fullscreen both fit |
| Viewer (offline) | `node preview-sim.mjs` | `pass:true` | reproduces the host pipeline byte for byte |
| `inline.mjs` guards | no-DI input; no-`name` input | exit 1; id fallback | stale inlines are visible now |

## Decisions Made

- **Chat is the surface, so a skill is the mechanism.** The viewer is a static workspace page and the
  runbook is workspace-local — neither can fire unprompted, and an agent in workspace `mdm` sees
  neither. Only `~/.dsh/skills` is injected into every session's context. → `skills/draw-bpmn/`.
- **mermaid stays the default for sketches.** The skill explicitly tells the model *not* to use it for
  a quick process picture; verified that the model follows that (it declined the skill for a plain
  mermaid ask).
- **Get passed a known-expected failure.** A dsh session asked for `danger-full-access` to run
  `./init.sh`, whose compose step is documented to fail in-sandbox
  (`knowledge/gotchas/init-sh-needs-dsh-home-write.md`). Declined.
- **`diagrams/` is not this repo's deliverable** — test output from chat probes, left untracked.

## Blockers / Risks

- **`bpmn-auto-layout` drops lanes and pools** (`bpmn:Lane` is not a flow element → 0 lanes, no error)
  and **collapses several branches onto one channel** (three flows shared `y=140`; an explicit merge
  gateway does not help). Real swimlanes need hand-written lane DI or Camunda Modeler.
- **Hand-placed DI converges, it does not solve.** Even with `measure-labels.mjs` reading real painted
  text boxes, the travel-expense run's labels still sit awkwardly. Auto-layout stays the right default
  unless exact routing is required.
- **Skills and plugins compose per session** — a session opened before an install does not see it. No
  restart is needed for a skill (`dsh-tool-skill` recomputes per `agent/pre-step`), but a **new
  session** is.
- `web_search` is still unusable here (modsearch's keyless route 403s from this IP); `read_page` works.
- Nothing here is on the `headless` / `sdk` / `acp` profiles except what the skill provides.

## Next Session Startup

1. Read `AGENTS.md`.
2. Read `feature_list.json` (13 features, all done) and `progress.md`.
3. Review this handoff.
4. Run `./init.sh` before editing. If it stops with `EPERM` on `$DSH_HOME/profiles/...`, that is the
   sandbox, not the repo — see `knowledge/gotchas/init-sh-needs-dsh-home-write.md`.

## Recommended Next Step

- **Use it once for real, then decide what to keep.** Ask a fresh chat session for a BPMN diagram of a
  process you actually have; the skill will produce `*.source.bpmn` + `*.bpmn` + a viewer page + PNG.
  If the label placement is good enough, fold `measure-labels.mjs`'s approach into the skill's
  "Definition of done"; if not, the answer is Camunda Modeler for the final polish, not more automation.
- Lower-priority candidates live in `progress.md` → What's Next: a modsearch key so `web_search` works,
  the `experiments/` scope question, and the two official subagent bundles.
