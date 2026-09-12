#!/usr/bin/env node
/**
 * Verification loop for the 3D proof of concept.
 *
 * Loads index.html in headless Chromium, records every console message and
 * uncaught exception, asserts the scene actually booted, and writes
 * screenshots. Exits non-zero if the page logged an error or never booted —
 * so "it compiles" can never be mistaken for "it works".
 *
 * No dependencies: Node 22 ships fetch and WebSocket, and Chrome speaks CDP.
 *
 *   node verify.mjs [--url file:///...] [--out .]
 */
import { spawn } from 'node:child_process';
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = dirname(fileURLToPath(import.meta.url));
const arg = (name, fallback) => {
  const i = process.argv.indexOf(name);
  return i === -1 ? fallback : process.argv[i + 1];
};
const OUT  = resolve(arg('--out', HERE));
const PAGE = arg('--url', 'file://' + join(HERE, 'index.html'));
const PORT = Number(arg('--port', '9333'));
const CHROME = arg('--chrome',
  '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome');

mkdirSync(OUT, { recursive: true });
const profile = mkdtempSync(join(tmpdir(), 'poc-chrome-'));

const chrome = spawn(CHROME, [
  '--headless=new', '--no-sandbox', '--hide-scrollbars',
  '--use-gl=angle', '--use-angle=swiftshader', '--enable-unsafe-swiftshader',
  '--disable-dev-shm-usage', '--no-first-run', '--no-default-browser-check',
  '--window-size=1600,1000', '--force-device-scale-factor=1',
  `--remote-debugging-port=${PORT}`, `--user-data-dir=${profile}`,
  'about:blank'
], { stdio: ['ignore', 'ignore', 'pipe'] });
chrome.stderr.on('data', () => {});   // Chrome is chatty on stderr; ignore it

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

async function endpoint(path, tries = 60) {
  for (let i = 0; i < tries; i++) {
    try {
      const r = await fetch(`http://127.0.0.1:${PORT}${path}`);
      if (r.ok) return await r.json();
    } catch { /* not up yet */ }
    await sleep(250);
  }
  throw new Error(`devtools endpoint ${path} never came up on ${PORT}`);
}

function cdp(ws) {
  let id = 0;
  const pending = new Map();
  const listeners = [];
  ws.addEventListener('message', (ev) => {
    const msg = JSON.parse(ev.data);
    if (msg.id !== undefined && pending.has(msg.id)) {
      const { resolve: res, reject } = pending.get(msg.id);
      pending.delete(msg.id);
      msg.error ? reject(new Error(msg.error.message)) : res(msg.result);
    } else if (msg.method) {
      for (const fn of listeners) fn(msg);
    }
  });
  return {
    send(method, params = {}) {
      const n = ++id;
      return new Promise((res, reject) => {
        pending.set(n, { resolve: res, reject });
        ws.send(JSON.stringify({ id: n, method, params }));
      });
    },
    on(fn) { listeners.push(fn); }
  };
}

const problems = [];
const logs = [];

function finish(code) {
  try { chrome.kill('SIGKILL'); } catch {}
  try { rmSync(profile, { recursive: true, force: true }); } catch {}
  process.exit(code);
}

try {
  await endpoint('/json/version');
  const targets = await endpoint('/json/list');
  const page = targets.find((t) => t.type === 'page');
  if (!page) throw new Error('no page target');

  const ws = new WebSocket(page.webSocketDebuggerUrl);
  await new Promise((res, rej) => {
    ws.addEventListener('open', res, { once: true });
    ws.addEventListener('error', () => rej(new Error('ws failed')), { once: true });
  });
  const client = cdp(ws);

  client.on((msg) => {
    if (msg.method === 'Runtime.consoleAPICalled') {
      const text = msg.params.args
        .map((a) => (a.value !== undefined ? String(a.value) : a.description || a.type))
        .join(' ');
      logs.push({ level: msg.params.type, text });
      if (msg.params.type === 'error') problems.push(`console.error: ${text}`);
    } else if (msg.method === 'Runtime.exceptionThrown') {
      const d = msg.params.exceptionDetails;
      problems.push(`uncaught: ${d.exception?.description || d.text}`);
    } else if (msg.method === 'Log.entryAdded') {
      const e = msg.params.entry;
      logs.push({ level: e.level, text: e.text });
      if (e.level === 'error') problems.push(`log(${e.source}): ${e.text}`);
    }
  });

  await client.send('Runtime.enable');
  await client.send('Log.enable');
  await client.send('Page.enable');
  await client.send('Emulation.setDeviceMetricsOverride',
    { width: 1600, height: 1000, deviceScaleFactor: 1, mobile: false });

  await client.send('Page.navigate', { url: PAGE });
  await new Promise((res) => {
    const t = setTimeout(res, 12000);
    client.on((m) => { if (m.method === 'Page.loadEventFired') { clearTimeout(t); res(); } });
  });
  await sleep(3500);   // let the shader compile and a few frames run

  const probe = await client.send('Runtime.evaluate', {
    expression: 'JSON.stringify(window.__poc || null)', returnByValue: true
  });
  const poc = JSON.parse(probe.result.value || 'null');

  // --eval asks the live scene a question instead of guessing from pixels.
  // Top-level `const` in a classic script lives in the global lexical scope,
  // so `scene`, `gF2`, `cam` are all reachable by name here.
  const expr = arg('--eval', null);
  if (expr) {
    const r = await client.send('Runtime.evaluate', {
      expression: expr, returnByValue: true, awaitPromise: true
    });
    if (r.exceptionDetails) {
      console.error('eval threw:', r.exceptionDetails.exception?.description);
      finish(2);
    }
    console.log(typeof r.result.value === 'string'
      ? r.result.value : JSON.stringify(r.result.value));
    finish(0);
  }

  async function shot(name, prelude) {
    if (prelude) {
      await client.send('Runtime.evaluate', { expression: prelude });
      await sleep(1600);
    }
    const r = await client.send('Page.captureScreenshot', { format: 'png' });
    const file = join(OUT, name);
    writeFileSync(file, Buffer.from(r.data, 'base64'));
    return file;
  }

  const files = [];
  files.push(await shot('shot-day.png'));
  files.push(await shot('shot-night.png',
    "document.getElementById('btnNight').click();"));
  files.push(await shot('shot-floor2.png',
    "document.getElementById('btnNight').click();setView('f2');"));

  console.log('page       ', PAGE);
  console.log('booted     ', poc ? 'yes' : 'NO');
  if (poc) console.log('scene      ', `${poc.seats} seats, ${poc.trees} trees, ${poc.zones} zones`);
  console.log('console    ', `${logs.length} message(s)`);
  for (const l of logs.filter((l) => l.level !== 'log').slice(0, 8)) {
    console.log(`  [${l.level}] ${l.text.slice(0, 150)}`);
  }
  for (const f of files) console.log('screenshot ', f);

  if (!poc) problems.push('window.__poc missing — the script never reached the end');
  if (problems.length) {
    console.error('\nFAILED:');
    for (const p of problems) console.error('  - ' + p);
    finish(1);
  }
  console.log('\nOK: booted with no console errors.');
  finish(0);
} catch (err) {
  console.error('verify failed:', err.message);
  finish(2);
}
