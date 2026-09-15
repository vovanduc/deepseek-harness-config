#!/usr/bin/env node
// make-travel-expense.mjs — inject a hand-placed bpmndi block into the DI-free
// source of the travel-expense process and write the laid-out .bpmn.
//
// Why hand-placed instead of bpmn-auto-layout: on this process the engine emitted a
// DUPLICATE BPMNEdge (Flow_04 twice, because Gateway_KeToanDongY and Gateway_QuanLyDongY
// share the same target) and routed the revision loop 633 px back across the main row.
// Hand-placing is deterministic and refuses to write on any id mismatch.
//
// Run: node make-travel-expense.mjs

import { readFileSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const SOURCE = join(here, "travel-expense.source.bpmn");
const TARGET = join(here, "travel-expense.bpmn");

// ---------------------------------------------------------------- geometry
// Main row:  y 60, 80 px tall tasks, 80 px gaps, 50 px gateways centred at y 75.
// Accounting row above: y 20 (only entered when the amount exceeds 10 million).
// Revision loop below:  y 280.
const TASK = { w: 100, h: 80 };
const EVENT = { w: 36, h: 36 };
const GATE = { w: 50, h: 50 };

const shapes = [
  // id, x, y, w, h, extra attributes
  // Main row y 240 — events/tasks 80 px tall, gateways 50 px centred on y 280.
  // Accounting row ABOVE (y 100) — entered only when the amount exceeds 10 million.
  // Amount-check row BELOW (y 360). Revision loop at the bottom (y 500).
  ["StartEvent_DeNghi", 45, 262, EVENT.w, EVENT.h, ""],
  ["Task_NopDeNghi", 116, 240, TASK.w, TASK.h, ""],
  ["Task_QuanLyDuyet", 251, 240, TASK.w, TASK.h, ""],
  ["Gateway_QuanLyDongY", 396, 255, GATE.w, GATE.h, ' isMarkerVisible="true"'],
  ["Task_KeToanDuyet", 686, 100, TASK.w, TASK.h, ""],
  ["Gateway_KeToanDongY", 821, 115, GATE.w, GATE.h, ' isMarkerVisible="true"'],
  ["Task_HoanUng", 886, 240, TASK.w, TASK.h, ""],
  ["EndEvent_HoanUngXong", 1021, 262, EVENT.w, EVENT.h, ""],
  ["Gateway_Tren10Trieu", 391, 400, GATE.w, GATE.h, ' isMarkerVisible="true"'],
  ["Task_ChinhSuaDeNghi", 226, 500, TASK.w, TASK.h, ""],
];

const edges = [
  // id, waypoints — anchored to the real sourceRef/targetRef boxes above.
  // Each flow owns a corridor: V1 421, V2 446, V3 470, V4 536, V5 640, V6 736,
  // V7 846, V8 886; tracks H84 (accounting return), H385 (amount row),
  // H450 (below), H540 (revise entry), H600 (manager-reject return).
  ["Flow_01", [[81, 280], [116, 280]]],                                              // start -> nộp
  ["Flow_02", [[216, 280], [251, 280]]],                                             // nộp -> quản lý
  ["Flow_03", [[351, 280], [396, 280]]],                                             // quản lý -> gateway
  ["Flow_04", [[421, 305], [421, 590], [300, 590], [300, 580]]],                     // Không -> chỉnh sửa
  ["Flow_04b", [[276, 500], [276, 330], [301, 330], [301, 320]]],                    // chỉnh sửa -> quản lý
  ["Flow_05", [[421, 305], [421, 400]]],                                             // Có -> gateway >10tr
  ["Flow_06", [[441, 415], [736, 415], [736, 180]]],                                 // >10tr -> kế toán
  ["Flow_07", [[786, 140], [821, 140]]],                                             // kế toán -> gateway
  ["Flow_08", [[846, 165], [846, 200], [936, 200], [936, 240]]],                     // Có -> hoàn ứng
  ["Flow_09", [[441, 435], [886, 435], [886, 320]]],                                 // Không -> hoàn ứng
  ["Flow_10", [[846, 115], [846, 84], [960, 84], [960, 680], [276, 680], [276, 580]]],  // Không -> chỉnh sửa
  ["Flow_11", [[986, 280], [1021, 280]]],                                            // hoàn ứng -> end
];

// Flow labels: id -> [centre x, centre y], each clear of every shape.
const labels = {
  Flow_04: [460, 440],
  Flow_05: [468, 362],
  Flow_06: [560, 403],
  Flow_08: [946, 188],
  Flow_09: [620, 407],
  Flow_10: [700, 72],
};
const textWidth = (t) => Math.round(t.length * 8.5);

// ---------------------------------------------------------------- read source
const source = readFileSync(SOURCE, "utf8");

if (/<bpmndi:BPMNDiagram/.test(source)) {
  console.error("REFUSING: source already carries a bpmndi block; edit the DI-free source.");
  process.exit(1);
}

// Every flow element id declared in the source (process + its children).
const elementIds = new Set(
  [...source.matchAll(/<bpmn:(?:process|startEvent|endEvent|userTask|serviceTask|exclusiveGateway|parallelGateway)\s+id="([^"]+)"/g)]
    .map((m) => m[1]),
);
// Every sequence flow id, and its name (labels must match the source, not invent any).
const flowIds = new Map(
  [...source.matchAll(/<bpmn:sequenceFlow\s+id="([^"]+)"([^>]*)\/>/g)].map((m) => [
    m[1],
    (/name="([^"]*)"/.exec(m[2]) ?? [, undefined])[1],
  ]),
);
// id -> {source, target} so an edge can be checked against its real endpoints.
const flowEnds = new Map(
  [...source.matchAll(/<bpmn:sequenceFlow\s+id="([^"]+)"([^>]*)\/>/g)].map((m) => [
    m[1],
    {
      source: /sourceRef="([^"]+)"/.exec(m[2])[1],
      target: /targetRef="([^"]+)"/.exec(m[2])[1],
    },
  ]),
);

// Filled in by the checks below, reported at the end.
const crossings = [];
const labelOffsets = {};

// ---------------------------------------------------------------- emit
const xml = [
  `  <bpmndi:BPMNDiagram id="BPMNDiagram_Process_DuyetChiPhiCongTac">`,
  `    <bpmndi:BPMNPlane id="BPMNPlane_Process_DuyetChiPhiCongTac" bpmnElement="Process_DuyetChiPhiCongTac">`,
];
const eventIds = new Set(
  [...source.matchAll(/<bpmn:(startEvent|endEvent)\s+id="([^"]+)"/g)].map((m) => m[2]),
);
// bpmn-js renders a gateway's name centred BELOW the diamond whatever bounds are
// supplied, so a gateway whose incoming branch labels sit underneath carries its own
// name above the shape instead (measured with measure-labels.mjs).
// Gateway names are placed by hand: bpmn-js centres an unplaced name on the shape,
// which here put decision names on top of the branch labels and the task text.
// side: -1 left of the diamond, +1 right; y omitted => vertically centred.
const nameAbove = new Set([]);
const namePlaced = new Map([
  ["Gateway_QuanLyDongY", { side: 1, y: null }],
  ["Gateway_Tren10Trieu", { side: 0, y: 468, dx: -14 }],
]);
for (const [id, x, y, w, h, extra] of shapes) {
  xml.push(`      <bpmndi:BPMNShape id="${id}_di" bpmnElement="${id}"${extra}>`);
  xml.push(`        <dc:Bounds x="${x}" y="${y}" width="${w}" height="${h}" />`);
  if (eventIds.has(id)) {
    xml.push(`        <bpmndi:BPMNLabel>`);
    xml.push(`          <dc:Bounds x="${x + w / 2 - 60}" y="${y + h + 6}" width="120" height="18" />`);
    xml.push(`        </bpmndi:BPMNLabel>`);
  } else if (namePlaced.has(id)) {
    const n = namePlaced.get(id);
    const lw = 110;
    const lx =
      n.side === 1 ? x + w + 8 : n.side === -1 ? x - 8 - lw : x + w / 2 - 60 + (n.dx ?? 0);
    const ly = n.y ?? y + (h - 18) / 2;
    xml.push(`        <bpmndi:BPMNLabel>`);
    xml.push(`          <dc:Bounds x="${lx}" y="${ly}" width="${lw}" height="18" />`);
    xml.push(`        </bpmndi:BPMNLabel>`);
  }
  xml.push(`      </bpmndi:BPMNShape>`);
}
for (const [id, points] of edges) {
  xml.push(`      <bpmndi:BPMNEdge id="${id}_di" bpmnElement="${id}">`);
  for (const [x, y] of points) xml.push(`        <di:waypoint x="${x}" y="${y}" />`);
  const label = labels[id];
  if (label) {
    const [cx, cy] = label;
    const w = textWidth(flowIds.get(id));
    xml.push(`        <bpmndi:BPMNLabel>`);
    xml.push(
      `          <dc:Bounds x="${cx - w / 2}" y="${cy - 9}" width="${w}" height="18" />`,
    );
    xml.push(`        </bpmndi:BPMNLabel>`);
  }
  xml.push(`      </bpmndi:BPMNEdge>`);
}
xml.push(`    </bpmndi:BPMNPlane>`);
xml.push(`  </bpmndi:BPMNDiagram>`);
const diBlock = xml.join("\n");

// ---------------------------------------------------------------- validate
const problems = [];
for (const [id] of shapes) {
  if (!elementIds.has(id)) problems.push(`shape ${id} matches no element in the source`);
}
for (const id of elementIds) {
  if (id !== "Process_DuyetChiPhiCongTac" && !shapes.some(([s]) => s === id))
    problems.push(`element ${id} has no shape`);
}
for (const [id] of edges) {
  if (!flowIds.has(id)) problems.push(`edge ${id} matches no sequenceFlow in the source`);
}
for (const id of flowIds.keys()) {
  if (!edges.some(([e]) => e === id)) problems.push(`sequenceFlow ${id} has no edge`);
}
for (const id of Object.keys(labels)) {
  if (!flowIds.get(id)) problems.push(`label on ${id}, but that flow has no name in the source`);
}
// An edge must actually start at its source shape and end at its target shape.
// (Flow_07 once floated 70 px off Task_KeToanDuyet after the task moved.)
const shapeById = new Map(shapes.map(([id, x, y, w, h]) => [id, { x, y, w, h }]));
const inside = (pt, box, slack = 1) =>
  pt[0] >= box.x - slack && pt[0] <= box.x + box.w + slack &&
  pt[1] >= box.y - slack && pt[1] <= box.y + box.h + slack;
for (const [id, points] of edges) {
  const ends = flowEnds.get(id);
  if (!ends) continue;
  const from = shapeById.get(ends.source), to = shapeById.get(ends.target);
  if (from && !inside(points[0], from)) {
    problems.push(`${id} starts at (${points[0]}) which is outside ${ends.source}`);
  }
  if (to && !inside(points[points.length - 1], to)) {
    problems.push(
      `${id} ends at (${points[points.length - 1]}) which is outside ${ends.target}`,
    );
  }
}
// A label must sit on the edge it names, not on some other flow's segment.
const segDist = (pt, a, b) => {
  const dx = b[0] - a[0], dy = b[1] - a[1];
  const len2 = dx * dx + dy * dy;
  const t = len2 === 0 ? 0 : Math.max(0, Math.min(1, ((pt[0] - a[0]) * dx + (pt[1] - a[1]) * dy) / len2));
  return Math.hypot(pt[0] - (a[0] + t * dx), pt[1] - (a[1] + t * dy));
};
for (const [id, centre] of Object.entries(labels)) {
  const points = edges.find(([e]) => e === id)?.[1];
  if (!points) continue;
  let best = Infinity;
  for (let i = 0; i + 1 < points.length; i++) {
    best = Math.min(best, segDist(centre, points[i], points[i + 1]));
  }
  labelOffsets[id] = Math.round(best);
}
if (problems.length) {
  console.error("REFUSING to write — DI does not match the source:");
  for (const p of problems) console.error("  - " + p);
  process.exit(1);
}

// Label collision check: no two label boxes may overlap.
const boxes = Object.entries(labels).map(([id, [cx, cy]]) => {
  const w = textWidth(flowIds.get(id));
  return { id, x1: cx - w / 2, y1: cy - 9, x2: cx + w / 2, y2: cy + 9 };
});
// Edge crossings are legitimate in BPMN, but each one is a decision, not an
// accident: report them instead of discovering them in the render.
const segs = [];
for (const [id, points] of edges) {
  for (let i = 0; i + 1 < points.length; i++) {
    segs.push({ id, i, a: points[i], b: points[i + 1] });
  }
}
const cross = (o, a, b) => (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0]);
const crosses = (s, t) => {
  const d1 = cross(t.a, t.b, s.a), d2 = cross(t.a, t.b, s.b);
  const d3 = cross(s.a, s.b, t.a), d4 = cross(s.a, s.b, t.b);
  return ((d1 > 0) !== (d2 > 0)) && ((d3 > 0) !== (d4 > 0)) ? 1
    : (d1 === 0 || d2 === 0 || d3 === 0 || d4 === 0) ? 0 : -1;
};
for (let i = 0; i < segs.length; i++) {
  for (let j = i + 1; j < segs.length; j++) {
    const s = segs[i], t = segs[j];
    if (s.id === t.id) continue;                    // same flow
    if (s.b[0] === t.a[0] && s.b[1] === t.a[1]) continue;
    if (t.b[0] === s.a[0] && t.b[1] === s.a[1]) continue;
    if (crosses(s, t) === 1) crossings.push(`${s.id} x ${t.id}`);
  }
}
for (let i = 0; i < boxes.length; i++) {
  for (let j = i + 1; j < boxes.length; j++) {
    const a = boxes[i], b = boxes[j];
    if (a.x1 < b.x2 && b.x1 < a.x2 && a.y1 < b.y2 && b.y1 < a.y2) {
      problems.push(`labels ${a.id} and ${b.id} overlap`);
    }
  }
}
// Label collision with shapes. A gateway is a 45-degree diamond, so its painted area
// is much smaller than its bounding box: test the diamond, not the box (a box test
// passed a label that rendered straight on top of a gateway).
const gatewayIds = new Set(
  [...source.matchAll(/<bpmn:exclusiveGateway\s+id="([^"]+)"/g)].map((m) => m[1]),
);
for (const b of boxes) {
  for (const [id, x, y, w, h] of shapes) {
    if (id === "Process_DuyetChiPhiCongTac") continue;
    if (gatewayIds.has(id)) {
      const cx = x + w / 2, cy = y + h / 2, rx = w / 2, ry = h / 2;
      const corners = [[b.x1, b.y1], [b.x2, b.y1], [b.x1, b.y2], [b.x2, b.y2]];
      const cxh = (b.x1 + b.x2) / 2, cyh = (b.y1 + b.y2) / 2;
      const hit = [...corners, [cxh, cyh]].some(
        ([px, py]) => Math.abs(px - cx) / rx + Math.abs(py - cy) / ry <= 1,
      );
      // also catch a diamond corner poking into the label box
      const diamondIn = [[cx, y], [cx, y + h], [x, cy], [x + w, cy]].some(
        ([px, py]) => px >= b.x1 && px <= b.x2 && py >= b.y1 && py <= b.y2,
      );
      if (hit || diamondIn) problems.push(`label ${b.id} overlaps gateway ${id}`);
    } else if (b.x1 < x + w && x < b.x2 && b.y1 < y + h && y < b.y2) {
      problems.push(`label ${b.id} overlaps shape ${id}`);
    }
  }
}
if (problems.length) {
  console.error("REFUSING to write — label collision:");
  for (const p of problems) console.error("  - " + p);
  process.exit(1);
}

const laid = source.replace(
  /(\n<\/bpmn:definitions>)/,
  `\n${diBlock}$1`,
);
writeFileSync(TARGET, laid);

const xs = shapes.flatMap(([, x, , w]) => [x, x + w]);
const ys = shapes.flatMap(([, , y, , h]) => [y, y + h]);
console.log(
  `wrote ${TARGET.split("/").pop()}: ${shapes.length} shapes, ${edges.length} edges, ` +
    `${Object.keys(labels).length} labels; content bbox ${Math.min(...xs)},${Math.min(...ys)} ` +
    `${Math.max(...xs) - Math.min(...xs)}x${Math.max(...ys) - Math.min(...ys)}`,
);
if (crossings.length) console.log(`  edge crossings (expected): ${crossings.join(", ")}`);
console.log(`  label offset from own flow: ${JSON.stringify(labelOffsets)}`);
