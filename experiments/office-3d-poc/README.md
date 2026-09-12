# Office 3D — proof of concept

This is an **experiment**, not part of the config toolchain. It exists to answer one question:
can `deepseek-flash` do what the Coder Horizon post *"Dựng mô hình 3D văn phòng công ty bằng
Three.js"* does with Claude?

The answer, measured rather than assumed, is in `feature_list.json` → `feat-012`.

## What is here

```
index.html            the whole scene + UI, one file, no build step
vendor/three.min.js   Three.js r160 UMD, pinned (sha256 170c6789…1d49fa), MIT
verify.mjs            the verification loop; no npm dependencies
```

Open `index.html` from `file://` — no server, no build, no network.

Controls: drag to orbit, right-drag (or shift-drag) to pan, wheel to zoom, pinch on touch.
Six views, a day/night toggle, and six clickable zones with an info card.

## Verify it

```bash
node verify.mjs          # loads it in headless Chromium, screenshots, fails on any console error
node verify.mjs --eval 'JSON.stringify({kids: gF2.children.length})'
```

`verify.mjs` drives Chrome over the DevTools Protocol. It launches Chromium, enables
`Runtime`/`Log`, navigates, records every console message and uncaught exception, asserts
`window.__poc` exists, and writes `shot-day.png`, `shot-night.png`, `shot-floor2.png`.
It exits non-zero if anything logged an error or the script never reached the end — so
"it parses" can never be mistaken for "it renders".

`--eval` asks the live scene a question instead of guessing from pixels. Top-level `const`
in a classic script lands in the global lexical scope, so `scene`, `gF2` and `cam` are
reachable by name.

The screenshots are ignored by git; regenerate them with the command above.

## What the exercise actually proved

Five findings, each one found by looking at a render rather than by reasoning about the code:

1. **A zero-scale `InstancedMesh` is silent.** `new THREE.Vector3()` is `(0,0,0)`, not
   `(1,1,1)`. A helper that composes `Matrix4(p, q, s)` without setting `s` produces
   degenerate matrices: the instances vanish with no console warning at all. This ate the
   fence pickets, the stone pillars, the roof posts, the bamboo blinds and the balcony
   flower boxes in one go, and only the palette-check-and-look loop caught it. Fixed in
   `instanced()` — see the comment there.
2. **"Console has no errors" is not verification.** After the first successful run the log
   was clean and the scene still had a black void where the ground floor was, a black
   picture-frame where the roof railing was, and neighbour blocks filling the whole frame.
   All three passed every automated check.
3. **Mullion pitch decides whether a facade reads as glazing or as a jail.** One vertical
   every 1.07 m over a 14 m elevation looked like bars; one every 2.33 m reads as a curtain
   wall. Nothing about the code changed except a divisor.
4. **Camera standoff has to scale with the subject.** A 14 × 12 m building at a 26–28° field
   of view needs 45–55 m of distance. The first pass used 25–30 m and the presets pointed
   straight into a neighbour building.
5. **The post's "single file" rule is unnecessary.** The stated reason was running offline
   from `file://` — but a relative classic `<script src="vendor/three.min.js">` also runs
   offline from `file://`. Keeping Three.js beside the scene instead of inlining it leaves a
   37 KB editable file instead of a 700 KB one, and the post itself never resolves this
   tension, only mentions the file bloat as bug #7.

Also worth recording: the reference post recommends **Three.js r128** (April 2021). r160 is
the last release that still ships a UMD build, and it brings `outputColorSpace =
SRGBColorSpace`, without which a pastel low-poly scene washes out. So r160 is the right
compromise while `file://` rules out ES modules — a module loaded from `file://` is blocked
by CORS.

## Provenance

Three.js r160 UMD, fetched from `https://unpkg.com/three@0.160.0/build/three.min.js`,
669,884 bytes, MIT licensed. Verify with:

```bash
shasum -a 256 vendor/three.min.js
# 170c6789f43217c96b3170f4b42fafe135de7f7cd48497a4218f9757ee1d49fa
```

The upstream build prints its own deprecation warning on load, which `verify.mjs` records as
a warning, not an error.
