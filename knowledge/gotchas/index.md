---
type: index
title: Gotchas — non-obvious traps
---
# Gotchas

- [`GET /models` answers 200 even with a wrong key](models-endpoint-not-authenticated.md) — only inference authenticates.
- [`400 MissingSessionID`](missing-session-id.md) — the OpenCode Go session header is mandatory.
- [Two compat flags for "valid key, every request fails"](compat-flags.md) — developer role, `max_tokens`.
- [An empty YAML value is refused, not ignored](empty-yaml-value-refused.md) — dsh will not start.
- [Hand-declared models are text-only](hand-declared-models-text-only.md) — add `input: [text, image]`; the flag is not the capability.
- [`$DSH_HOME/settings.yaml` can stop being a symlink](settings-symlink-drift.md) — repo edits go nowhere and every check still passes.
- [`./init.sh` needs write access outside the workspace](init-sh-needs-dsh-home-write.md) — `EPERM` on `cordis.yml` is the sandbox, not the repo.
- [`dsh web` exits 0 under a TTY](web-ui-exits-under-a-tty.md) — pipe stdout, or run it non-interactively.
- [A browser-preview proxy 403s every POST `/api`](browser-preview-proxy-403.md) — the Host/Origin fence mismatches the proxy port; use the loopback token URL directly.
- [dsh-diagram breaks the web boot on the pinned dsh](dsh-diagram-incompatible-with-pinned-dsh.md) — its client needs a `conversationEvents` service 0.1.5-rc.1 does not have.
- [The npm name `dsh-mermaid` belongs to MrmoLabs](dsh-mermaid-npm-name-collision.md) — the repo a plugin list links may not be the npm publisher.
- [Popularity is not fitness](plugin-fit-vs-popularity.md) — the top-starred plugins in two categories are refused on dsh 0.1.5-rc.1, and one publishes under a different npm name.
- [No ERD or BPMN plugin exists](diagram-plugins-er-and-flow.md) — `dsh-mermaid` already draws both (mermaid 11.17), and every fancier renderer is blocked by the missing client runtime.
