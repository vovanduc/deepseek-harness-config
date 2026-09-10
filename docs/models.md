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
