#!/usr/bin/env node
/**
 * Faithful simulator of the dsh web document-preview HTML path.
 *
 * dsh-client-ui-sidebar-documentpreview does NOT load a local .html by URL. It reads
 * the file, collects only direct classic <script src> and <link rel=stylesheet href>
 * references, base64-encodes them, and builds a bootstrap that — inside an
 * opaque-origin, script-enabled iframe — turns each asset into a blob: URL and
 * document.write()s the rewritten HTML.
 *
 * This reproduces that pipeline byte-for-byte so the viewer can be proven against the
 * real delivery mechanism without clicking through the UI:
 *
 *   node preview-sim.mjs [--page index.html] [--out /tmp/preview-sim.html]
 *
 * Prints the asset set it packed and the limits it checked.
 */
import { readFileSync, writeFileSync } from 'node:fs';
import { dirname, resolve, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const arg = (n, d) => { const i = process.argv.indexOf(n); return i > 0 ? process.argv[i + 1] : d; };

const PAGE = resolve(HERE, arg('--page', 'index.html'));
const OUT = arg('--out', '/tmp/preview-sim.html');

// same limits as the plugin
const MAX_ASSET_BYTES = 4 * 1024 * 1024;
const MAX_TOTAL_BYTES = 32 * 1024 * 1024;
const MAX_ASSETS = 64;

const html = readFileSync(PAGE, 'utf8');

// same rule: relative only, no scheme, no leading slash/hash/query, no NUL
const isRelative = (r) => r.length > 0 && !/^(?:[a-z][a-z\d+.-]*:|[/\\#?])/iu.test(r) && !r.includes('\0');

const assets = [];
const seen = new Set();
for (const m of html.matchAll(/<link\b[^>]*rel\s*=\s*["']?[^"'>]*stylesheet[^"'>]*["']?[^>]*>/giu)) {
  const href = m[0].match(/href\s*=\s*["']([^"']+)["']/iu)?.[1];
  if (href && isRelative(href) && !seen.has(href)) { seen.add(href); assets.push({ kind: 'css', reference: href }); }
}
for (const m of html.matchAll(/<script\b[^>]*\bsrc\s*=\s*["']([^"']+)["'][^>]*>/giu)) {
  const tag = m[0];
  const type = tag.match(/\btype\s*=\s*["']([^"']+)["']/iu)?.[1];
  // only classic scripts are packed: modules are explicitly unsupported
  if (type && type !== 'text/javascript' && type !== 'application/javascript') continue;
  const src = m[1];
  if (isRelative(src) && !seen.has(src)) { seen.add(src); assets.push({ kind: 'script', reference: src }); }
}

let total = Buffer.byteLength(html);
const packed = [];
for (const a of assets) {
  const bytes = readFileSync(join(dirname(PAGE), a.reference));
  if (bytes.length > MAX_ASSET_BYTES) throw new Error(`${a.reference}: ${bytes.length} > MAX_ASSET_BYTES`);
  total += bytes.length;
  if (assets.length > MAX_ASSETS) throw new Error(`more than ${MAX_ASSETS} assets`);
  packed.push({ kind: a.kind, reference: a.reference, text: bytes.toString('utf8'), bytes: bytes.length });
}
if (total > MAX_TOTAL_BYTES) throw new Error(`total ${total} > MAX_TOTAL_BYTES`);

const b64 = (s) => Buffer.from(s, 'utf8').toString('base64');
const bundle = {
  html,
  assets: packed.map(({ kind, reference, text }) => ({ kind, reference, text })),
};

// the exact bootstrap the plugin builds (decoded, readable form)
const bootstrap = `<!doctype html><meta charset="utf-8"><script>(()=>{
const bytes=data=>Uint8Array.from(atob(data),character=>character.charCodeAt(0));
const text=data=>new TextDecoder('utf-8',{fatal:true}).decode(bytes(data));
const bundle=JSON.parse(text("${b64(JSON.stringify(bundle))}"));
let html=bundle.html;
if(bundle.assets.length){
  const parsed=new DOMParser().parseFromString(html,'text/html');
  for(const asset of bundle.assets){
    const script=asset.kind==='script';
    const url=URL.createObjectURL(new Blob([asset.text],{type:script?'application/javascript':'text/css'}));
    const attribute=script?'src':'href';
    for(const element of parsed.querySelectorAll(script?'script[src]':'link[rel~="stylesheet" i][href]')){
      if(element.getAttribute(attribute)===asset.reference)element.setAttribute(attribute,url);
    }
  }
  html='<!doctype html>'+parsed.documentElement.outerHTML;
}
document.open();document.write(html);document.close();
})()<\/script>`;

// Wrap it exactly as the plugin does: opaque-origin iframe, bootstrap delivered via srcdoc.
// NOTE: the bootstrap contains a literal `</script>` (it document.write()s one), so it MUST be
// escaped before being embedded in an inline script — otherwise the outer <script> ends early
// and srcdoc is never set. dsh's own source writes `<\/script>` for this reason.
//
// The page itself asserts nothing: a parent cannot read a sandboxed frame's DOM
// (SecurityError, origin "null"), so the viewer self-measures into `window.__fit` and the
// checker reads that from the frame's own context.
const srcdocPayload = JSON.stringify(bootstrap).replace(/<\//gu, '<\\/');

const outer = `<!DOCTYPE html><html><head><meta charset="utf-8"><title>preview-sim</title>
<style>html,body{margin:0;height:100%}iframe{width:100%;height:100vh;border:0}</style></head><body>
<iframe id="f" sandbox="allow-scripts"></iframe>
<div id="sim" data-assets="${packed.length}" data-bytes="${total}" hidden></div>
<script>document.getElementById("f").setAttribute("srcdoc", ${srcdocPayload});</script>
</body></html>`;

writeFileSync(OUT, outer);
console.log(`packed ${packed.length} asset(s), ${total} bytes (limits: ${MAX_ASSET_BYTES}/asset, ${MAX_TOTAL_BYTES} total, ${MAX_ASSETS} files)`);
for (const p of packed) console.log(`  ${p.kind.padEnd(6)} ${String(p.bytes).padStart(8)}  ${p.reference}`);
console.log(`wrote ${OUT}`);
