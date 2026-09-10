---
type: convention
title: A skill is a top-level <name>/SKILL.md with name + description frontmatter
description: dsh discovers only top-level skill bundles. Nested **/SKILL.md is ignored on purpose; frontmatter requires name and description.
tags: [dsh, skills]
---
# Rule

- Layout: `skills/<name>/SKILL.md`, or a flat `skills/<name>.md`, at the **top level** of a scanned root.
- Frontmatter: `name` and `description` are required. Optional: `whenToUse`, `metadata`, `disable-model-invocation`, `user-invocable`.
- `install.sh` links `skills/*/` into `$DSH_HOME/skills`.
- `./init.sh` fails when a bundle is missing `name` or `description`.

# Why

dsh deliberately does not walk nested `**/SKILL.md`, so a bundle one level too deep simply never appears — no error.

# Gotchas

- A non-boolean value for `disable-model-invocation` / `user-invocable` drops the whole skill with a warning instead of defaulting.
- Root priority, first wins: `<project>/.dsh/skills`, `<project>/.agents/skills`, `customSkillDirs`, `~/.dsh/skills`, `~/.agents/skills`.

# Related

[../../skills/README.md](../../skills/README.md) · [../decisions/pin-dsh-version.md](../decisions/pin-dsh-version.md)
