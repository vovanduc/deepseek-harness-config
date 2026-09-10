---
type: glossary
title: dsh vocabulary
description: The overloaded nouns — provider/route, model id, agent preset, access mode, profile, workspace, skill, DSH_HOME.
tags: [glossary]
---
# Terms

- **provider / route** — one entry under `llm-pi-ai.providers` (protocol + URL + credentials + model list). One route speaks one protocol, so a gateway serving two needs two routes. The id is permanent.
- **model id** — the `id` inside a route's `models`; what a session records.
- **agent preset** (`standard` / `ptc` / `minimal` / `cordis`) — which tools the agent has. `cordis` evaluates model-written JavaScript against the live runtime: a trust boundary, treat it as shell access.
- **access mode / permission preset** (`workspace-write` + `ask`, `danger-full-access` + `never`) — where writes are allowed and whether a prompt appears. The sandbox covers **files only**; reads and network are never confined.
- **workspace** — the directory dsh was launched from, unless another is chosen in the UI.
- **profile** — an installed runtime composition under `$DSH_HOME/profiles/<name>`. Not the same thing as an agent preset.
- **skill** — a `SKILL.md` bundle; see [the layout convention](../conventions/skill-bundle-layout.md).

# Related

[../../docs/modes.md](../../docs/modes.md) · [../systems/dsh-home-layout.md](../systems/dsh-home-layout.md)
