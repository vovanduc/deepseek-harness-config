# BPMN viewer — real BPMN 2.0 processes, no plugin

A self-contained page that renders **valid BPMN 2.0** (gateways, typed tasks, events, sequence
flows) inside the dsh web **document preview**, with no plugin, no build step and no network at
runtime. Built 2026-09-15 after the ecosystem scan showed **no dsh plugin draws BPMN**
(`knowledge/gotchas/diagram-plugins-er-and-flow.md`).

For a quick process picture, prefer mermaid (`flowchart TD`) — it needs nothing. Reach for this when
the diagram must be *BPMN*: openable in Camunda Modeler / bpmn.io, or consumed by an engine.

## What's here

| File | Role |
|---|---|
| `index.html` | the viewer — bpmn-js + the diagram's XML inlined, ~11 KB |
| `purchase.bpmn` | the source process, **already run through `bpmn-auto-layout`** (carries `bpmndi:BPMNDiagram`) |
| `vendor/bpmn-navigated-viewer.production.min.js` | bpmn-js 18.28.0 UMD navigated-viewer, 194 514 B |
| `vendor/{diagram-js,bpmn-js,bpmn-embedded}.css` | 27 562 / 4 159 / 96 188 B — styles + icon font |
| `preview-sim.mjs` | reproduces the host's document-preview pipeline offline and prints the packed asset set |

Total shipped to the page: **4 assets, 333 995 B** — well inside the preview's limits (4 MB per
asset, 32 MB / 64 files total).

## How it reaches the browser

`dsh-client-ui-sidebar-documentpreview` (official, already installed) does **not** load a local
`.html` by URL. It reads the file, collects only **direct classic `<script src>` and
`<link rel=stylesheet href>`** references, base64s them, and builds a bootstrap that — inside an
**opaque-origin, `sandbox="allow-scripts"` iframe** — turns each asset into a `blob:` URL and
`document.write()`s the rewritten HTML.

Three consequences shaped this page:

1. **Vendor the JS/CSS and reference them relatively.** The preview packs them; a CDN `<script>` would
   be dropped, and an opaque origin cannot fetch anything it was not handed.
2. **Inline the BPMN XML.** A runtime `fetch("purchase.bpmn")` is not part of the packed set and the
   frame's origin is opaque, so it fails. The XML lives in a `<script type="text/xml">` block.
3. **No CSS `url()` dependencies.** The plugin packs `.css` as text and does not rewrite `url()` or
   `@import`; `bpmn-embedded.css` is the variant whose font is fully base64-inlined, so the BPMN task
   and event glyphs still appear.

## The two bugs this page had to solve

Both were found by rendering and looking, not by reading code.

**1. `bpmn-js` refuses to render XML without DI.** The model authors clean BPMN but never emits the
`bpmndi:BPMNDiagram` section:

```
with DI     -> 35 .djs-element, SVG 31 KB
without DI  -> "ERROR: no diagram to display", 0 elements
```

`bpmn-auto-layout` (`layoutProcess(xml) -> xml`) generates it. `purchase.bpmn` here is post-layout;
if you edit the process, run it through again before re-inlining.

**2. `canvas.zoom("fit-viewport")` is not usable in this host.** The preview mounts the iframe before
the panel is laid out, so the container measures 0×0 and the fit silently leaves the diagram at scale
1 — overflowing a narrow panel, huddling in a corner of a wide one — and when the container is 0×0 it
throws instead:

```
The provided float value is non-finite   (SVGMatrix.scale, from zoom("fit-viewport"))
```

So the page sizes itself **declaratively**: pin a `viewBox` to the rendered content's bbox and set the
SVG to `width/height: 100%` with `preserveAspectRatio="xMidYMid meet"`. The browser then re-fits on
every container resize by itself, whether the panel is hidden, narrow, or fullscreen. A
`ResizeObserver` re-publishes the check so the result stays truthful across a hidden→visible switch.

## Verify

```bash
node preview-sim.mjs                 # packs the assets, prints the set and the limits it checked
```

That writes `/tmp/preview-sim.html`: the host's pipeline, byte for byte (opaque-origin sandbox,
blob-rewritten assets, `document.write` bootstrap). Open it and read the viewer's own check out of the
frame's DOM:

```js
document.getElementById("fit").textContent
```

The viewer measures itself because a parent cannot read a sandboxed frame's DOM
(`SecurityError: Blocked a frame with origin "null"`), and a page global is not reliably visible across
automation worlds — the DOM copy is the one to trust. A pass looks like:

```json
{"pass":true,"elements":38,"painted":38,"viewBox":"46 20 1575 245",
 "container":{"w":1365,"h":768},"paintedBox":{"x":9,"y":287,"w":1348,"h":195},
 "inside":true,"fills":true}
```

`pass` requires every element painted, the painted box inside the container, and the box using at
least half of the panel — a diagram left at scale 1 fails the last condition.

Verified 2026-09-15, three ways:

1. **Opened directly** (`file://`) on a sized page — `pass: true`.
2. **Through `preview-sim.mjs`'s sandbox** — the host pipeline reproduced byte for byte
   (opaque-origin `allow-scripts` frame, blob-rewritten assets, `document.write` bootstrap) —
   `pass: true`.
3. **In the real dsh UI**, the file opened from the Files panel. The frame is a
   `blob:http://127.0.0.1:4319/…` URL with `sandbox="allow-scripts"`, and it reports:

   ```json
   panel:      {"pass":true,"painted":38,"container":{"w":614,"h":692},"paintedBox":{"w":606,"h":88}}
   fullscreen: {"pass":true,"painted":38,"container":{"w":1365,"h":692},"paintedBox":{"w":1348,"h":195}}
   ```

   `pass: true` in both the narrow panel and fullscreen — the diagram refits on its own, which is the
   property the viewBox approach was chosen for. The rendered diagram shows the correct BPMN glyphs
   (user-task figures, service-task cogs, gateway ×, start/end circles), so the packed
   `bpmn-embedded.css` font resolves inside the sandbox too.

**Measurement note.** Read `#fit` in the *same* automation cell that forces a render. An idle tab is
frozen between operations, and a frozen frame reports `clientWidth/clientHeight 0` with `rAF` paused,
so a later read republishes `container {w:0,h:0}` — a freeze artifact that looks exactly like a fit
failure. Pair the resize with a screenshot or a same-cell read to force the frame's lifecycle.

## Regenerating

```bash
# 1. edit the process, strip every bpmndi/dc/di section -> process.bpmn
npm install bpmn-auto-layout@1.3.0
node -e "require('bpmn-auto-layout').layoutProcess(require('node:fs').readFileSync(0,'utf8'))\
.then(x=>process.stdout.write(x))" < process.bpmn > purchase.bpmn
# 2. re-inline purchase.bpmn into index.html's <script type="text/xml" id="bpmnxml"> block
node preview-sim.mjs && node -e "…"   # then read /tmp/preview-sim.html's frame #fit
```

Need a PNG/SVG/PDF instead of a page? `bpmn-to-image` does it in one command (~6.5 s, but 70 MB of
dependencies). See `knowledge/runbooks/draw-bpmn-workflow.md`.
