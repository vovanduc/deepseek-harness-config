---
type: gotcha
title: There is no ERD or BPMN plugin — mermaid already draws both, and the nicer renderers are blocked
description: A scan of 4 449 `dsh-plugin` npm packages and 3 660 curated entries finds zero dedicated ERD, DBML, PlantUML or BPMN plugins; ER and flow diagrams already render through the installed dsh-mermaid, while every fancier renderer injects the missing `@deepseek-ai/dsh-client-runtime`.
tags: [plugins, diagrams, mermaid, erd, bpmn, dsh]
---
# Symptom

Looking for a plugin to draw **ER diagrams** or **business flows** turns up a long list of diagram
plugins, and the obvious picks install but kill the web boot — or, worse, the search looks empty and
you assume the capability is missing.

# What the catalogue actually contains

Measured 2026-09-14 over the whole npm `dsh-plugin` keyword (4 449 packages, paginated) and the
curated index (3 660 entries), matching name + description + keywords:

| Term | Packages | Curated entries |
|---|---|---|
| `BPMN` | 0 | 0 |
| `DBML` / `dbdiagram` | 0 | 0 |
| `ER diagram` / `entity relationship` / `schema diagram` | 0 | 0 |
| `PlantUML` | 0 | 0 |
| `swimlane` | 0 | 1 (a git commit graph — unrelated) |
| `excalidraw` | 2 | 2 |
| `mermaid` | 8 | 12 |
| `flowchart` | 3 | — |
| `drawio` | 1 | 2 |

**No plugin in the ecosystem produces an ERD or a BPMN diagram.** The only ER-capable entries are
mermaid *renderers* (`zhangTELL/dsh-diagram` lists ER among the types it draws), and that one publishes
as `@dsh-local/dsh-diagram`, which injects `@deepseek-ai/dsh-client-runtime` — the service absent from
dsh `0.1.5-rc.1`, so it is blocked like `dsh-drawio`, `dsh-flowchart` and `dsh-visualizer`.

# Why the capability is already here

`dsh-mermaid@0.4.0` bundles **mermaid 11.17.0** in `lib/mermaid-runtime.js` (3.4 MB, served same-origin
at `/dsh-mermaid/mermaid-runtime.js`; the client lazily `import()`s it and calls its `render`).
Mermaid 11 supports `erDiagram` and `flowchart`/`graph` natively; it has never supported BPMN.

Verified against the plugin's own served runtime in a real browser (2026-09-14):

```
render("probe", erDiagram ...)  -> <svg class="erDiagram">    11 776 bytes
render("probe", flowchart TD …) -> <svg class="flowchart">    17 675 bytes
render("probe", "bpmn\nA --> B")-> No diagram type detected — mermaid has no BPMN
```

Vietnamese identifiers and edge labels (`KHACH_HANG ||--o{ DON_HANG : "dat"`, `B -- Có --> C[...]`)
render fine — mermaid is not ASCII-only.

`detectType` reports `UnknownDiagramError` for these same sources **before** `render` has run: the
diagram implementations load lazily on first render, so probing with `detectType` gives a false
negative. Render, then judge.

# Fix

- **ER diagram / business flow:** nothing to install. Ask for a mermaid fence — `erDiagram` or
  `flowchart TD` — and `dsh-mermaid` draws it.
- **BPMN proper:** impossible in mermaid. Model a BPMN-ish process as `flowchart TD` with lanes as
  `subgraph`, or draw it in drawio/Excalidraw by hand. No dsh plugin does BPMN.
- **Do not install** `dsh-drawio`, `dsh-flowchart`, `dsh-visualizer` or `@dsh-local/dsh-diagram` on
  the pinned dsh — all four inject `@deepseek-ai/dsh-client-runtime` and the unresolved service kills
  the whole web boot. `./scripts/plugin-preflight.sh <spec>` catches this before anything is installed.
- Candidates that **do** pass and touch this area, if the plain renderer is not enough:
  `dsh-mermaid-comm` (host-only: steers the model toward mermaid and validates syntax with the real
  parser), `@tt-a1i/archify-dsh` (host-only skill: architecture / workflow / sequence / data-flow
  diagrams), `dsh-handwritten-notes` (hand-drawn style), `@goodandready/dsh-live-canvas` (live
  iframe preview). None of them adds a diagram *type* mermaid lacks.

# Generalisation

A "plugin for X" question has three possible answers, and only one of them is "install something":
already present in an installed bundle, absent ecosystem-wide, or blocked by the host. Check the
capability the installed bundle actually ships (its bundled library version) before searching for a
plugin, and scan the namespace before concluding a capability is missing — the catalogue is 4 000+
entries, so "no results on page one" means nothing.

# Related

[plugin-fit-vs-popularity.md](plugin-fit-vs-popularity.md) · [dsh-diagram-incompatible-with-pinned-dsh.md](dsh-diagram-incompatible-with-pinned-dsh.md) · [../runbooks/dsh-plugins.md](../runbooks/dsh-plugins.md) · [../../docs/plugins.md](../../docs/plugins.md)
