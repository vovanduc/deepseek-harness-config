# Skills

Linked into `$DSH_HOME/skills` by `install.sh`, so every project on the machine sees them.

| Skill | What it does |
|---|---|
| `ponytail` | Lazy-senior-dev mode: YAGNI → reuse → stdlib → native → existing dependency → one line → minimum code |
| `ponytail-review` | Reviews a diff for over-engineering only — what to delete, what replaces it |
| `ponytail-audit` | Same lens over a whole repo, as a ranked list |
| `ponytail-debt` | Harvests every `ponytail:` comment into a debt ledger |
| `ponytail-gain` | Shows the benchmark scoreboard |
| `ponytail-help` | Reference card for the modes above |

## Origin

Adapted from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail) v4.9.0, MIT —
see `LICENSE-ponytail-upstream`. Only the `SKILL.md` layer is carried over: upstream's Claude
Code / opencode plugin hooks (mode tracker, statusline, subagent re-injection) do **not** run here,
so the mode is not sticky — the agent picks the skill up when the task matches its description, or
when you ask for "ponytail mode" in so many words.

To update: copy `skills/*/SKILL.md` from a newer upstream release over these directories.

## Adding your own

A skill is `<name>/SKILL.md` (or a flat `<name>.md`) at the top level of a scanned root, with
frontmatter:

```markdown
---
name: my-skill
description: What it does and, more importantly, when to use it — this text is what the model
  matches against.
---

# My skill

Instructions.
```

Optional frontmatter: `whenToUse`, `metadata`, `disable-model-invocation: true` (keeps it out of the
model's catalog), `user-invocable: false` (keeps it out of the slash-command list). Nested
`**/SKILL.md` is not discovered. See [../docs/modes.md](../docs/modes.md#skills) for the root
priority table.
