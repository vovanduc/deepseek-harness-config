# Modes

Two independent choices, both in the composer next to the input box:

- **agent preset** — what tools the agent has. `Standard mode` button; default in
  `settings.yaml` → `agent-presets.default`.
- **access mode** — where it may write and whether it asks. `Access mode, current: ...` button;
  default in `settings.yaml` → `permission.defaultPreset`.

## Agent presets

| UI | id | What it is | Use for |
|---|---|---|---|
| **Standard mode** | `standard` | Full coding agent: shell (`bash`/`pwsh`), file edit, file search, jobs, skills, plan mode, goals, subagents (plus fork and external backends), workflow + ralph, ask-user, todo, web, present, context compaction | Everything, by default |
| **PTC mode** | `ptc` | Standard **minus** the `workflow` tool; the remaining tools are presented as a generated TypeScript SDK, so the model authors one program that performs many tool calls | Many small steps — read/edit ten files in one round trip instead of ten |
| **Minimal mode** | `minimal` | Exactly one tool: a persistent shell. The persona is the entire system prompt, runtime context is suppressed, no compaction, no subagents | Benchmarking a model, raw shell work |
| **Creator mode** | `cordis` | Standard plus the Cordis toolset: inspect the running runtime, mount trial plugins in memory, author new presets. Ships the `editing-cordis-compositions` and `cordis-plugin-development` skills | Writing your own presets/plugins |

**Creator mode is a trust boundary.** `cordis_mount` evaluates model-written JavaScript against the
live runtime, and a preset that agent writes becomes something other sessions can mount. Its own
documentation says to treat a session on that preset as shell access. Do not run it on a machine
holding credentials and databases you care about.

Presets authored by hand live one directory per preset under
`${DSH_HOME:-$HOME/.dsh}/.agent-presets/<id>/`. Never edit the shipped preset install: an upgrade
overwrites it. To change a shipped preset, copy its composition into a new preset directory and edit
the copy.

## Permission presets

| UI | Sandbox | Approval | Meaning |
|---|---|---|---|
| **Workspace Write** (default) | `workspace-write` | `ask` | Writes stay inside the workspace; anything asking for more raises a prompt |
| **Danger Full Access** | `danger-full-access` | `never` | No sandbox, no prompts |

The sandbox covers **files only**: reads and network access are never confined, even under
`workspace-write`. `danger-full-access` removes the last barrier between the agent and your home
directory; use it for a single task and switch back.

Switch inside a session with the `/permission` command (bare, it reports the current preset and the
available table) or with the composer button.

## Instructions files

The agent is given `AGENTS.md` and `CLAUDE.md`, walking up to the project root (the nearest ancestor
containing `.git`; without one, the current directory). `AGENTS.local.md` and `CLAUDE.local.md` are
loaded as additive local overlays — the right place for notes that must not be committed.

A byte budget caps the injected text (`agent-instructions` plugin, `maxBytes`, default 65536):
broader files are dropped before the most specific one is truncated.

## Skills

A skill is a directory bundle `<name>/SKILL.md` or a flat `<name>.md` at the **top level** of a
scanned root — nested `**/SKILL.md` is deliberately not discovered. Frontmatter requires `name` and
`description`; optional are `whenToUse`, `metadata`, `disable-model-invocation` (hide from the model)
and `user-invocable` (hide the slash command). A bad boolean drops the whole skill with a warning
instead of silently permitting a surface.

Roots, in priority order:

| Rank | Root |
|---|---|
| 100 | `<projectRoot>/.dsh/skills` |
| 200 | `<projectRoot>/.agents/skills` |
| 300 | `customSkillDirs` (plugin config) |
| 400 | `~/.dsh/skills` |
| 500 | `~/.agents/skills` |

`install.sh` links this repo's `skills/` into `~/.dsh/skills`, so a synced machine gets them too.
