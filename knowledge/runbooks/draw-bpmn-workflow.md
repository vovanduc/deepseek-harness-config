---
type: runbook
title: Draw a real BPMN workflow (no plugin does it)
description: BPMN is the notation for business workflows and nothing in the dsh ecosystem renders it, so the working setup is a vendored bpmn-js viewer plus bpmn-auto-layout for the DI that bpmn-js refuses to render without. Measured end to end on 2026-09-15.
tags: [bpmn, diagrams, workflow, runbook]
---
# When to use this

The diagram must be **valid BPMN 2.0** — pools/lanes, exclusive and parallel gateways, typed tasks
(user / service / script), events — or must be openable in Camunda Modeler, bpmn.io, or an engine.
For a picture of a process where the notation does not matter, use mermaid instead
(`knowledge/gotchas/diagram-plugins-er-and-flow.md`): it needs no setup, and it also covers ER
diagrams.

**No dsh plugin draws BPMN.** Verified 2026-09-15 against the full npm `dsh-plugin` keyword
(4 449 packages), the curated index (3 660 entries) and its ranking data (`data/stars.json`,
`data/downloads.json`): zero hits for `BPMN`, and the four diagram-renderer plugins that exist are all
refused by the pre-flight on the pinned dsh. So this is a build, not an install.

# The three facts that make it work

1. **`bpmn-js` renders offline from `file://`.** `dist/bpmn-navigated-viewer.production.min.js`
   (194 514 B) is UMD and exposes the global `BpmnJS`; it needs only its own CSS
   (`diagram-js.css`, `bpmn-js.css`, and the `bpmn-font` CSS for task/event icons). No CDN at runtime,
   no build step, no bundler.
2. **Model-authored XML has no DI, and `bpmn-js` refuses to render without it.** The same file with
   and without `bpmndi:BPMNDiagram`:
   ```
   with DI     -> 35 .djs-element, SVG 31 KB
   without DI  -> "ERROR: no diagram to display", 0 elements
   ```
   `bpmn-auto-layout` (`layoutProcess(xml) -> xml`, bpmn-io, ⭐101, deps `bpmn-moddle` + `min-dash`)
   generates it. **This step is load-bearing — do not skip it and do not ask the model to hand-place
   coordinates.**
3. **The model authors valid BPMN unprompted.** Asked for the same process as XML with no DI it
   returned 4 501 bytes: 8 tasks, 3 exclusive gateways, 14 sequence flows — which `bpmn-auto-layout`
   resolved to 28 shapes / 28 edges and `bpmn-js` rendered to a 36 KB SVG. So the loop is
   model → XML → auto-layout → viewer, with no hand editing.

# Recipe

```bash
npm install bpmn-auto-layout@1.3.0        # ~240 KB, no build
curl -sLo viewer.js  https://unpkg.com/bpmn-js@18.28.0/dist/bpmn-navigated-viewer.production.min.js
curl -sLo bpmn-js.css https://unpkg.com/bpmn-js@18.28.0/dist/assets/bpmn-js.css
curl -sLo diagram-js.css https://unpkg.com/bpmn-js@18.28.0/dist/assets/diagram-js.css
curl -sLo bpmn-font.css https://unpkg.com/bpmn-js@18.28.0/dist/assets/bpmn-font/css/bpmn-embedded.css
```

1. Ask the model for the process as one `xml` fence — a `<bpmn:definitions>` with a process, events,
   tasks, gateways and `<bpmn:sequenceFlow>`s, and **no** `bpmndi` section.
2. `node -e "require('bpmn-auto-layout').layoutProcess(require('node:fs').readFileSync(0,'utf8')).then(x=>console.log(x))" < process.bpmn > process.layout.bpmn`
3. View it: a page that inlines the laid-out XML and boots `BpmnJS`:

   ```html
   <link rel="stylesheet" href="diagram-js.css">
   <link rel="stylesheet" href="bpmn-js.css">
   <link rel="stylesheet" href="bpmn-font.css">   <!-- task / event icons -->
   <div id="canvas"></div>
   <script type="text/xml" id="bpmnxml">…laid-out XML (only `</script>` would need escaping)…</script>
   <script src="viewer.js"></script>
   <script>
     const viewer = new BpmnJS({ container: "#canvas" });
     viewer.importXML(document.getElementById("bpmnxml").textContent)
       .then(() => viewer.get("canvas").zoom("fit-viewport"));
   </script>
   ```

   Open it from `file://`. `viewer.saveSVG()` returns the SVG if a static image is wanted.

# Show it inside the dsh web UI (no plugin)

Working, self-contained page: **`experiments/bpmn-viewer/`**. The official
`dsh-client-ui-sidebar-documentpreview` (already installed) renders a local `.html` — it reads the
file, packs **only direct classic `<script src>` and `<link rel=stylesheet href>`** references, and
re-writes them to `blob:` URLs inside an **opaque-origin `sandbox="allow-scripts"` iframe**. Limits:
4 MB per asset, 32 MB / 64 files total.

Three rules follow from that, and each one bit before it was found:

- **Vendor the viewer + CSS, reference them relatively.** A CDN `<script>` is never packed, and an
  opaque origin cannot fetch what it was not handed.
- **Inline the BPMN XML** in a `<script type="text/xml">` block. `fetch("x.bpmn")` is not part of the
  packed set and the frame's origin is opaque.
- **No CSS `url()`** — the packer does not rewrite them. Use `bpmn-embedded.css` (font base64-inlined)
  so task/event glyphs appear.

Two traps that only show up in this host:

- `canvas.zoom("fit-viewport")` **throws** (`SVGMatrix.scale … non-finite`) when the container is 0×0,
  which is the normal state at mount, and silently leaves scale 1 when it is merely hidden. Fit
  declaratively instead: set `viewBox` from the content bbox + `width/height:100%` +
  `preserveAspectRatio="xMidYMid meet"`; then every later resize is automatic.
- The viewer must **measure itself**: a parent cannot read a sandboxed frame's DOM
  (`SecurityError: Blocked a frame with origin "null"`), and a page global is not reliably readable
  across automation worlds. Publish the check into the DOM (`<pre id="fit">`) and read that.

```bash
cd experiments/bpmn-viewer && node preview-sim.mjs   # reproduces the host pipeline offline
# then read #fit inside the frame: {"pass":true,"elements":38,...}
```

# Export to an image (simpler than a viewer)

If a file (PNG / SVG / PDF) is what you need, skip the viewer page entirely — `bpmn-to-image` renders
through a bundled bpmn-js + puppeteer:

```bash
npm install bpmn-to-image@0.10.0
node node_modules/.bin/bpmn-to-image process.layout.bpmn:process.png --no-footer
# or ...:process.svg  ...:process.pdf  — one target per invocation, colon-separated
```

Verified 2026-09-15: both inputs above exported in **6.5 s** — `purchase.png` (32 945 B) and
`gen.svg` (36 417 B), both with Vietnamese labels and correct gateway/task semantics.

Cost, measured: **70 MB `node_modules`** (`bpmn-js`, `meow`, `chalk`, `puppeteer`) plus a Chrome
download if the machine has none — this one already had `~/.cache/puppeteer` (1.5 GB) from
2025-12-11, so the install reused it. Prefer this over the viewer when the output is an artifact;
prefer the viewer when the diagram must be *interactive* (pan/zoom, or a live `.bpmn` in a workspace).

# Traps

- **`fetch()` of the `.bpmn` next to the HTML fails under `file://`** (`net::ERR_FAILED` — CORS on
  file URLs). Inline the XML in a `<script type="text/xml">` block, or serve over HTTP.
- **`view.html` alone proves nothing.** A page that loads the viewer and stops renders a blank canvas
  with no error in the page. Assert on `.djs-element` count and on `saveSVG()` bytes — that is what
  separated "looks fine" from "no diagram to display" here.
- **mermaid cannot be talked into BPMN.** `render("bpmn\nA --> B")` → *No diagram type detected*.
  A `flowchart TD` with `subgraph` lanes is the mermaid-shaped approximation, not BPMN.
- **`.bpmn` opens in Camunda Modeler / bpmn.io directly**, which is often enough on its own — the
  vendored viewer is only needed for viewing inside the workspace.

# Not verified

Whether BPMN can be **previewed from a chat message** (an agent-produced `.bpmn` rendered inline
rather than opened from the Files panel). The MCP route is blocked at the plugin layer
(`dsh-mcp-adapter@0.6.3` fails the pre-flight on `@deepseek-ai/dsh-client-runtime`;
`dsh-mcp-proxy@0.1.0` / `dsh-mcp-lens@0.1.0-rc.9` pass but the upstream BPMN MCP servers are tiny —
`dattmavis/BPMN-MCP` ⭐12, `oisee/mcp-bpmn` ⭐9; the `bpmn-js-mcp` repo the search engines cite
**404s**), and no official `@deepseek-ai` MCP package is installed here.

Everything above runs outside the chat: a workspace `.html` opened in the document preview, or a file
exported by CLI.

# Related

[../gotchas/diagram-plugins-er-and-flow.md](../gotchas/diagram-plugins-er-and-flow.md) · [dsh-plugins.md](dsh-plugins.md) · [../index.md](../index.md)
