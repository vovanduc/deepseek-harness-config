#!/usr/bin/env node
/**
 * Inline a laid-out BPMN file into the viewer page.
 *
 * The viewer keeps its XML in a `<script type="text/xml" id="bpmnxml">` block: the document
 * preview packs only direct classic scripts and stylesheets, so a runtime `fetch()` of a
 * relative .bpmn would never reach the sandbox. Re-inlining by hand is easy to get wrong
 * (and leaves the page showing a stale process), so it is a script:
 *
 *   node inline.mjs <laid-out.bpmn> [--page index.html] [--id bpmnxml]
 *
 * Refuses XML that would break the block (`</script>`) or that lacks DI — bpmn-js renders
 * nothing without `bpmndi:BPMNDiagram`, which `bpmn-auto-layout` supplies.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const arg = (n, d) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : d; };

const source = arg('--source', process.argv[2]);
const page = resolve(HERE, arg('--page', 'index.html'));
const id = arg('--id', 'bpmnxml');

if (!source) {
  console.error('usage: node inline.mjs <laid-out.bpmn> [--page index.html] [--id bpmnxml]');
  process.exit(2);
}

const xml = readFileSync(resolve(HERE, source), 'utf8').trim();

if (xml.includes('</script')) {
  throw new Error(`${source}: contains "</script", which would end the inline block early`);
}
if (!/bpmndi:BPMNDiagram/.test(xml)) {
  throw new Error(
    `${source}: no bpmndi:BPMNDiagram — bpmn-js renders nothing without DI.\n` +
    `  Run it through bpmn-auto-layout first (see knowledge/runbooks/draw-bpmn-workflow.md).`
  );
}

const html = readFileSync(page, 'utf8');
const open = `<script type="text/xml" id="${id}">`;
const start = html.indexOf(open);
if (start === -1) throw new Error(`${page}: no ${open} block`);
const bodyStart = start + open.length;
const end = html.indexOf('</script>', bodyStart);
if (end === -1) throw new Error(`${page}: unterminated ${open} block`);

const before = html.slice(0, bodyStart);
const after = html.slice(end);
const previous = html.slice(bodyStart, end).trim();
const processId = (xml.match(/<bpmn:process\b[^>]*\bid="([^"]+)"/) || [])[1] || '(unknown)';
const shapes = (xml.match(/bpmndi:BPMNShape/g) || []).length;

writeFileSync(page, `${before}\n${xml}\n${after}`);

console.log(`inlined ${source} -> ${page.split('/').pop()}`);
console.log(`  process ${processId} · ${shapes} shapes · ${xml.length} bytes`);
console.log(`  replaced ${previous.length} bytes of previous XML`);
