---
type: index
title: Conventions — rules this repo follows
---
# Conventions

- [settings.yaml is symlinked, never copied](settings-symlink.md) — the server reads the repo file through the link; a UI settings write replaces the link, so it is one-way.
- [Skill bundle layout](skill-bundle-layout.md) — top-level `<name>/SKILL.md`, `name` + `description` required.
- [Secrets never enter the repo](secrets-never-committed.md) — `apiKeyEnv` stores a variable name, not a value.
- [Append-only logs are edited at the end](append-only-logs.md) — anchoring an edit on an existing entry replaces it; the gates cannot see the loss.
