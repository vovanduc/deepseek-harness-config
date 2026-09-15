#!/usr/bin/env node
// measure-labels.mjs — render the laid-out .bpmn with the vendored bpmn-js and read
// the REAL painted text boxes out of the DOM, then report overlaps.
//
// Why: estimating label boxes ("Không" = 5 chars x 8.5 px) was wrong often enough that
// labels kept rendering on top of gateway names and each other. The rendered geometry
// is the only authority. Requires: the vendored viewer, and Chrome (this machine needs
// --no-sandbox, see knowledge/runbooks/draw-bpmn-workflow.md).
//
// Run: PUPPETEER_CACHE_DIR=... PUPPETEER_EXECUTABLE_PATH=/tmp/chrome-nosandbox.sh node measure-labels.mjs

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
// puppeteer lives in the throwaway build dir (it drags in ~70 MB); resolve it by env var.
import { createRequire } from "node:module";
const require = createRequire(import.meta.url);
const puppeteer = (await import(
  process.env.PUPPETEER_MODULE ?? "/tmp/bpmn-build/node_modules/puppeteer/lib/esm/puppeteer/puppeteer.js",
)).default;

const here = dirname(fileURLToPath(import.meta.url));
const model = process.argv[2] ?? join(here, "travel-expense.bpmn");
const xml = readFileSync(model, "utf8");
const viewer = readFileSync(join(here, "vendor", "bpmn-navigated-viewer.production.min.js"), "utf8");
const css = ["diagram-js.css", "bpmn-js.css", "bpmn-embedded.css"]
  .map((f) => readFileSync(join(here, "vendor", f), "utf8"))
  .join("\n");

const page = `<!doctype html><html><head><meta charset="utf-8"><style>
html,body{margin:0}#canvas{width:2400px;height:1600px}${css}</style></head>
<body><div id="canvas"></div>
<script type="text/xml" id="bpmnxml">${xml.replace(/<\/script>/g, "<\\/script>")}</script>
<script>${viewer}</script>
<script>
window.__ready = (async () => {
  const v = new BpmnJS({ container: "#canvas" });
  await v.importXML(document.getElementById("bpmnxml").textContent);
  await new Promise(r => requestAnimationFrame(() => requestAnimationFrame(r)));
  const out = [];
  // every painted text node, with its absolute box
  for (const t of document.querySelectorAll("#canvas text")) {
    const text = (t.textContent || "").trim();
    if (!text) continue;
    const r = t.getBoundingClientRect();
    const p = t.closest("[data-element-id]");
    out.push({
      text, id: p ? p.getAttribute("data-element-id") : null,
      x: +r.x.toFixed(1), y: +r.y.toFixed(1), w: +r.width.toFixed(1), h: +r.height.toFixed(1),
    });
  }
  return out;
})();
</script></body></html>`;

const tmp = "/tmp/bpmn-measure.html";
writeFileSync(tmp, page);

const browser = await puppeteer.launch({ headless: true, args: ["--no-sandbox"] });
const p = await browser.newPage();
await p.goto("file://" + tmp);
const boxes = await p.evaluate(() => window.__ready);
await browser.close();

const overlaps = [];
for (let i = 0; i < boxes.length; i++) {
  for (let j = i + 1; j < boxes.length; j++) {
    const a = boxes[i], b = boxes[j];
    if (a.x < b.x + b.w && b.x < a.x + a.w && a.y < b.y + b.h && b.y < a.y + a.h) {
      overlaps.push(`"${a.text}" [${a.id}] x "${b.text}" [${b.id}]`);
    }
  }
}

console.log(`${boxes.length} painted text boxes in ${model.split("/").pop()}`);
for (const o of overlaps) console.log("  OVERLAP: " + o);
if (!overlaps.length) console.log("  no text overlaps");
console.log("\nboxes:");
for (const b of boxes.sort((m, n) => m.y - n.y || m.x - n.x)) {
  console.log(
    `  ${b.text.replace(/\s+/g, " ").padEnd(34)} ${String(b.id).padEnd(26)} x ${b.x} y ${b.y} w ${b.w} h ${b.h}`,
  );
}
process.exit(overlaps.length ? 1 : 0);
