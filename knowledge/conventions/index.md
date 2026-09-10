---
type: index
title: Conventions — rules this repo follows
---
# Conventions

- [settings.yaml is symlinked, never copied](settings-symlink.md) — UI edits land in the repo, edits here go live.
- [Skill bundle layout](skill-bundle-layout.md) — top-level `<name>/SKILL.md`, `name` + `description` required.
- [Secrets never enter the repo](secrets-never-committed.md) — `apiKeyEnv` stores a variable name, not a value.
