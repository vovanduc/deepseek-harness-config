---
type: index
title: Systems — layout, routes, credentials
---
# Systems

- [What lives in `$DSH_HOME`](dsh-home-layout.md) — symlinked settings vs machine-local state.
- [Profiles, bundles, and patch layers](profiles-and-bundles.md) — shipped templates, `--from-default-profile`, `--patch`, `--dump-config`; desktop = `dsh-base` + `dsh-web-app`.
- [The ACP automation surface](acp-surface.md) — standard ACP v1 calls, omissions, and per-bot ACP profiles.
- [The `opencode-go` route contract](opencode-go-route.md) — every field the gateway needs, and why.
- [The `omp-gateway` route — Devin SWE-2](omp-gateway-route.md) — no public API; omp's auth-gateway fronts its `devin` provider on loopback.
- [Credential resolution order](credential-resolution.md) — four layers, first hit wins.
