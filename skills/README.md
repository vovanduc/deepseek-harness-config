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

Adapted from [DietrichGebert/ponytail](https://github.com/DietrichGebert/ponytail), MIT — see
`LICENSE-ponytail-upstream`. Only the `SKILL.md` layer is carried over: upstream's Claude
Code / opencode plugin hooks (mode tracker, statusline, subagent re-injection) do **not** run here,
so the mode is not sticky — the agent picks the skill up when the task matches its description, or
when you ask for "ponytail mode" in so many words.

## Updating

The upstream ref is pinned in `scripts/update-ponytail.sh` (`UPSTREAM_REF`); this file deliberately
does not repeat a version, so the two cannot disagree. The local files are byte-identical to that ref.

```bash
./scripts/update-ponytail.sh                          # report drift (exit 1 when behind)
./scripts/update-ponytail.sh --apply                  # copy the upstream files over the local ones
./scripts/update-ponytail.sh --ref v4.10.0 --apply    # try a newer release
```

After applying a newer ref, set `UPSTREAM_REF` to it in the script and commit. `git` is the undo:
review with `git diff -- skills`, revert with `git checkout -- skills`.

Only `skills/*/SKILL.md` and `LICENSE` are synced — not upstream's built `.openclaw/skills/` copy,
and not the plugin hooks.

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
