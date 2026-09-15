---
type: api
title: The omp-gateway route — Devin SWE-2 without a public API
description: SWE-2 only speaks Devin's Connect-RPC, so dsh reaches it through omp's auth-gateway, a local OpenAI-compatible front for omp's built-in devin provider. Two loopback processes, one bearer, one script.
tags: [provider, devin, swe-2, omp, gateway]
---
# Why a gateway and not a key

Cognition ships SWE-2 only inside Devin (Desktop / CLI / Web / Fusion); there is no API key to
put in `apiKeyEnv`. omp (Oh My Pi, the other harness on this machine) has a first-class `devin`
provider that talks Connect-RPC to `server.codeium.com` with the Devin CLI session token, and
`omp auth-gateway serve` re-encodes OpenAI Chat Completions ↔ that provider. dsh therefore
sees an ordinary `openai-completions` route.

# Contract (`settings.yaml` → `llm-pi-ai.providers.omp-gateway`)

| Field | Value | Why |
|---|---|---|
| `api` | `openai-completions` | the gateway's `/v1/chat/completions` |
| `baseURL` | `http://127.0.0.1:4000/v1` | `omp auth-gateway serve --bind=127.0.0.1:4000` |
| `apiKeyEnv` | `OMP_GATEWAY_API_KEY` | the gateway's own bearer (`omp auth-gateway token`); no bearer → `{"error":"unauthorized"}` |
| `compat.supportsDeveloperRole` | `false` | Devin has no `developer` role; `system` is honoured |
| `compat.maxTokensField` | `max_tokens` | what the gateway reads |
| `models[0].id` | `devin/swe-2` | the only quota-free Devin id worth routing; effort ladder `medium/high/max` |

# Processes (`scripts/omp-gateway.sh`)

1. `omp auth-broker serve --bind=127.0.0.1:8765` — credential vault; creates
   `~/.omp/auth-broker.token` on first start.
2. `omp auth-broker migrate --from-local --include-env` with `DEVIN_API_KEY` exported from
   `~/.local/share/devin/credentials.toml` (`windsurf_api_key`, a `devin-session-token$…` value)
   — uploads the Devin key. Idempotent.
3. `omp auth-gateway serve --bind=127.0.0.1:4000` — **after** step 2. The gateway builds its
   `/v1/models` at boot from providers holding a credential; started earlier it answers
   `Unknown model: devin/swe-2` until restarted (measured).

`status` posts one real completion with the bearer and expects `GW OK`.

# Verified 2026-09-15 (at the gateway, i.e. the wire dsh uses)

- `devin/swe-2` plain → `GW OK` in 7.4 s; `stream: true` + `tools` → streamed `tool_calls`
  deltas; `system` + `reasoning_effort` `medium`/`high`/`max` → answered with
  `reasoning_content` beside `content`; no bearer → `unauthorized`.
- Then in dsh itself (same day, after `./install.sh` put `dsh 0.1.5-rc.1` back on this
  machine): `doctor.sh` READY (6 ok), `dsh web` booted clean with the 5 plugins served, and
  the user ran a composer session on *SWE-2 (Devin, via omp)* — confirmed working.

# Cost and limits

Devin Pro: `swe-2` at any effort is quota-free (Cognition's "free for the next month",
2026-09-10 → re-check ~2026-10-10 with `devin models list`). Every other Devin id burns the
weekly plan quota and, when exhausted, fails hard (`failed_precondition: … weekly usage quota
has been exhausted`) — which is why only `devin/swe-2` is declared. Latency is 1–1.5 min on a
small tool task through omp; expect the same here.

# Related

[../../docs/models.md](../../docs/models.md) · [opencode-go-route.md](opencode-go-route.md) · [credential-resolution.md](credential-resolution.md) · [../../scripts/omp-gateway.sh](../../scripts/omp-gateway.sh)
