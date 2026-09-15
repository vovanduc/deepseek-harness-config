# Models and providers

All model configuration lives in `$DSH_HOME/settings.yaml` under `llm-pi-ai.providers`. The map key
is the **provider id** — it is permanent, because sessions, saved model defaults and credential
references record it. To rename a route, add the new one and delete the old.

## The configured route: `opencode-go`

```yaml
llm-pi-ai:
  providers:
    opencode-go:
      displayName: OpenCode Go
      api: openai-completions
      baseURL: https://opencode.ai/zen/go/v1
      apiKeyEnv: OPENCODE_GO_API_KEY
      headers:
        x-opencode-session: deepseek-harness-config
      compat:
        supportsDeveloperRole: false
        maxTokensField: max_tokens
      models:
        - id: deepseek-flash
          name: DeepSeek V4.1 Flash
          contextWindow: 1048576
          maxTokens: 65536
          input: [text, image]
```

Why each line is there:

- `api: openai-completions` — the route's wire protocol. A route the installed catalog does not ship
  must name one; the accepted values are `openai-completions`, `openai-responses`,
  `anthropic-messages`. One provider speaks one protocol, so a gateway serving two needs two routes.
- `headers.x-opencode-session` — **required by this gateway**. Without it every request fails
  `400 MissingSessionID`. The value identifies the client; any stable string works.
- `compat.supportsDeveloperRole: false` — the gateway rejects the `developer` role that pi-ai uses
  for a reasoning model's system prompt.
- `compat.maxTokensField: max_tokens` — the gateway reads `max_tokens`, not `max_completion_tokens`.
- `contextWindow` / `maxTokens` — on a hand-declared model nothing can be inferred, so both are
  stated. A configured `maxTokens` also becomes that model's per-request output default.
- `apiKeyEnv` — the **name** of the environment variable holding the key. See
  [Credentials](#credentials).
- `input` — the modalities this model accepts. Omit it and the model is text-only; see
  [Images](#images).

Models this route also serves (list them the same way if you want them in the picker):

```
deepseek-flash            deepseek-v4-flash        deepseek-v4-pro
deepseek-v4-flash-vision-exp
glm-5.3  glm-5.3-flash    kimi-k3  kimi-k2.7-code  minimax-m3
qwen3.8-max  qwen3.8-flash  grok-4.5  grok-4.6  mimo-v2.5-pro  ...
```

Query the live list yourself:

```bash
set -a; . ~/.dsh/.env; set +a
curl -s https://opencode.ai/zen/go/v1/models -H "Authorization: Bearer $OPENCODE_GO_API_KEY" \
  | python3 -c 'import json,sys; print("\n".join(m["id"] for m in json.load(sys.stdin)["data"]))'
```

## The second route: `omp-gateway` (Devin SWE-2)

Cognition's SWE-2 has **no public API** — it only runs inside Devin's harness, over Connect-RPC
to `server.codeium.com`. What does speak that protocol is omp's built-in `devin` provider, and
omp ships an `auth-gateway` that re-exposes every credential it holds as a local
OpenAI-compatible endpoint. That is the whole bridge: no community proxy, no plugin.

```
dsh ──openai-completions──▶ omp auth-gateway (127.0.0.1:4000) ──Connect-RPC──▶ Devin backend (SWE-2)
                                    │ bearer
                            omp auth-broker (127.0.0.1:8765) holds the Devin session token
```

```bash
brew install omp                 # once; needs omp >= 18.2
devin auth login                 # once; writes ~/.local/share/devin/credentials.toml
./scripts/omp-gateway.sh start   # broker → uploads the Devin key → gateway; prints the .env line
echo 'OMP_GATEWAY_API_KEY=<printed value>' >> ~/.dsh/.env
./scripts/omp-gateway.sh status  # "swe-2 via gateway: OK"
```

Then pick **SWE-2 (Devin, via omp)** in the composer, or set `agent-default-model` to
`omp-gateway` / `devin/swe-2`.

What was measured at the gateway on 2026-09-15 (the exact wire dsh uses):

| Request | Result |
|---|---|
| plain completion | `GW OK`, 7.4 s round trip, `usage` populated |
| `stream: true` + `tools` | streamed `tool_calls` deltas with server-minted ids, `finish_reason` set |
| `system` role + `reasoning_effort: high/medium/max` | answered; `reasoning_content` returned beside `content` |
| no bearer | `{"error":"unauthorized"}` — the token in `.env` is required |

Two traps:

- **Start order is load-bearing.** The gateway computes its model catalog at boot from the
  providers that have a credential *at that moment*; a gateway started before the Devin key was
  uploaded answers `Unknown model: devin/swe-2` until restarted. The script does it in order.
- **`max_tokens` is shared with reasoning.** A 20-token cap was eaten by `reasoning_content`
  and came back `finish_reason: length` with `content: null`. The route declares 131072; do not
  probe with tiny caps.

Quota: on a Devin Pro plan `swe-2` (any effort) is quota-free; other Devin ids (`glm-5-2`
variants, Claude/GPT through Devin) burn the plan's weekly quota and fail hard with
`failed_precondition: Your weekly usage quota has been exhausted` when it is gone — so only
`devin/swe-2` is declared here. Cognition announced SWE-2 "free for the next month" on
2026-09-10; re-check `devin models list` for `[Free]` around 2026-10-10.

## Adding another provider

```yaml
llm-pi-ai:
  providers:
    my-gateway:
      displayName: Company gateway
      api: openai-completions
      baseURL: https://gateway.example/v1
      apiKeyEnv: GATEWAY_API_KEY
      compat:
        supportsDeveloperRole: false   # most OpenAI-compatible gateways need this
        maxTokensField: max_tokens     # ...and this
      defaultContextWindow: 262144     # fallback for entries that state neither capacity
      defaultMaxTokens: 32768
      defaultInput: [text]
      models:
        - id: some-model
          name: Some Model
```

Then declare the key in `~/.dsh/.env` (`GATEWAY_API_KEY=...`). A first call failing with
`MISSING_CREDENTIAL` means the name in `apiKeyEnv` and the name in `.env` disagree.

### Reasoning controls

A model you declare by hand has no reasoning levels until you state them. The picker's **Effort**
menu comes from:

```yaml
      models:
        - id: some-reasoner
          reasoningEfforts:
            off:
            high: high
            max: max        # left side = menu label, right side = what goes on the wire
          compat:
            thinkingFormat: deepseek   # sends thinking:{type:enabled|disabled} beside the effort
```

`off` may be left empty only when the endpoint thinks on request. A model that thinks unless told
otherwise — DeepSeek behind a generic gateway — needs `thinkingFormat: deepseek` for `off` to have
any effect. `reasoningEfforts: false` strips reasoning from a model the gateway cannot serve.

### Images

Hand-declared models are text-only until they say otherwise:

```yaml
          input: [text, image]
```

A refused image is refused *before* it is sent, naming the model — and the attachment stays in the
session log, so the session keeps retrying it until you move off that model.

Capability is the model's, not the flag's. This route serves two models and only one of them has
vision: DeepSeek's own model table marks **Vision as supported on `deepseek-flash` and not
supported on `deepseek-v4-pro`**. Measured against the gateway on 2026-09-12 with a 64×64 PNG of a
blue square, `deepseek-flash` answered `A blue square.` So declare `input: [text, image]` on Flash
and leave it off Pro, and do the whole image-driven workflow on Flash.

### Correcting one model of a built-in provider

`modelOverrides` reshapes a single catalog model without replacing the other thirty-seven:

```yaml
    anthropic:
      modelOverrides:
        claude-sonnet-4-5:
          input: [text]
```

## Choosing the model

- Composer → **Select model**. Selecting one also makes it the default for new sessions.
- Sessions already in flight keep the model recorded in their own log.
- The default for *new* sessions is `agent-default-model` in `settings.yaml`:

```yaml
agent-default-model:
  provider: opencode-go
  model: deepseek-v4-pro
```

If a saved default names a provider that no longer exists, the composer blocks input until you pick
another model. That is why deleting a route is a two-step edit: re-point the defaults first.

## Credentials

`apiKeyEnv` names an environment variable; the value never appears in `settings.yaml`. Resolution
order, first hit wins:

| # | Source | Notes |
|---|---|---|
| 1 | the environment `dsh` was launched in | read-only; a per-run override beats everything |
| 2 | `~/.dsh/.credentials.yaml` | what the web UI's **Settings → Models** writes |
| 3 | `<workspace>/.env` | per-project override |
| 4 | `~/.dsh/.env` | what `install.sh` seeds (mode 600) |

Keys saved anywhere but layer 1 take effect on the next request, without a restart.
