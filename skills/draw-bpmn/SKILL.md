---
name: draw-bpmn
description: >
  Draw a real BPMN 2.0 process diagram (Camunda / bpmn.io compatible) from a described
  workflow, and render it either as a workspace page inside the dsh web UI or as an
  SVG/PNG file. Use when the user asks for BPMN, a business process model, a swimlane
  process, or a workflow that must be opened in a BPMN tool or fed to an engine — and
  whenever they reject a mermaid flowchart as "not real BPMN". Do NOT use for a quick
  process sketch where the notation does not matter; a mermaid `flowchart TD` fence is
  better there and needs no setup.
---

# Choosing the notation first

| The user wants | Use |
|---|---|
| a quick picture of a process, in chat | a mermaid ` ```mermaid flowchart TD ` fence — `dsh-mermaid` renders it inline, nothing to install |
| **BPMN** — gates, typed tasks, events, opens in Camunda Modeler / bpmn.io, feeds an engine | this skill |

If it is ambiguous, ask which. Naming a mermaid swimlane "BPMN" is wrong and the user will notice.

# There is no plugin for this

No dsh plugin draws BPMN (verified across 4 449 npm `dsh-plugin` packages and the curated index).
The four renderer plugins that exist are all refused by the pre-flight on the pinned dsh — never
install `dsh-drawio`, `dsh-flowchart`, `dsh-visualizer` or `@dsh-local/dsh-diagram`; they inject the
missing `@deepseek-ai/dsh-client-runtime` and kill the web boot.

The working path is a **build**, and the full recipe with every trap is
[`knowledge/runbooks/draw-bpmn-workflow.md`](../../knowledge/runbooks/draw-bpmn-workflow.md).
A ready-made viewer lives in
[`experiments/bpmn-viewer/`](../../experiments/bpmn-viewer/) — copy that directory rather than
re-deriving it.

# The four steps

1. **Author the XML.** One `<bpmn:definitions>` → process with events, tasks, gateways,
   `<bpmn:sequenceFlow>`s. Write it as `<name>.source.bpmn` and include **no** `bpmndi`/`dc`/`di`
   section — hand-placing coordinates is wasted effort and usually wrong.
2. **Generate the DI.** `bpmn-auto-layout` (`layoutProcess(xml) -> xml`, `npm i bpmn-auto-layout@1.3.0`)
   → `<name>.bpmn`. **This step is mandatory**: `bpmn-js` renders nothing without it
   (*"no diagram to display"*, zero elements). Keep both files; the source is what you edit.
3. **View or export.**
   - *In the UI*: copy `experiments/bpmn-viewer/`, inline the laid-out XML into its
     `<script type="text/xml">` block, and the user opens the `.html` from the Files panel —
     no plugin, no build.
   - *As a file*: `bpmn-to-image <name>.bpmn:<name>.png` (also `.svg`, `.pdf`) in one command,
     at the cost of ~70 MB of dependencies.
4. **Look at it.** Render and actually inspect the result. Overlapping edge labels on short
   gateway branches are the usual defect — shorten the label or lengthen the flow, then re-render.
   A clean console is not proof the diagram is right.

# Traps that cost real time

- **`bpmn-auto-layout` silently drops lanes and pools.** `bpmn:Lane` is not a flow element, so the
  grid never places it and the DI comes back with 0 lanes while the process itself is fine. If the
  user asked for swimlanes, either model them as `subgraph`-style grouping with the role in the task
  label (`[GĐ] Phê duyệt`), or add the lane DI by hand — and say which you did. Do not claim a
  swimlane diagram when the lanes did not render.
- **No `file://` `fetch`.** Opening the viewer from disk, a relative `fetch("x.bpmn")` fails
  (`net::ERR_FAILED`) — inline the XML in a `<script type="text/xml">` block.
- **`zoom("fit-viewport")` misbehaves in the document preview** (throws on a 0×0 container, silently
  no-ops when hidden). The viewer already fixes this with a `viewBox` fit — keep it.
- **The document preview packs only direct classic `<script src>` and `<link rel=stylesheet>`.** CDN
  URLs are dropped and CSS `url()` is not rewritten, so vendor the viewer and use
  `bpmn-embedded.css` (its font is base64-inlined).
- **`.mmd` + mermaid is not BPMN.** If you produce mermaid, call it a flowchart, not a BPMN model.

# Definition of done

- `*.source.bpmn` (no DI) and `*.bpmn` (laid out) both exist, or a single laid-out file plus a note.
- The diagram was rendered and visually checked for label collisions.
- If the user asked for lanes, the answer states plainly whether lanes are present.
- The artifact is somewhere they can open — a viewer page in the workspace, or a PNG/SVG.
