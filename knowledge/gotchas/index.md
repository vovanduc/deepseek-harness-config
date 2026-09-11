---
type: index
title: Gotchas — non-obvious traps
---
# Gotchas

- [`GET /models` answers 200 even with a wrong key](models-endpoint-not-authenticated.md) — only inference authenticates.
- [`400 MissingSessionID`](missing-session-id.md) — the OpenCode Go session header is mandatory.
- [Two compat flags for "valid key, every request fails"](compat-flags.md) — developer role, `max_tokens`.
- [An empty YAML value is refused, not ignored](empty-yaml-value-refused.md) — dsh will not start.
- [Hand-declared models are text-only](hand-declared-models-text-only.md) — add `input: [text, image]`.
- [`dsh web` exits 0 under a TTY](web-ui-exits-under-a-tty.md) — pipe stdout, or run it non-interactively.
- [The npm name `dsh-mermaid` belongs to MrmoLabs](dsh-mermaid-npm-name-collision.md) — the repo a plugin list links may not be the npm publisher.
