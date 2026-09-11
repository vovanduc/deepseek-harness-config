# Troubleshooting

`./scripts/doctor.sh` catches most of these. Run it first — add `--json` for one machine-readable
object (`{status, ok, warn, fail, checks:[{id, status, message}]}`) instead of coloured text.

## `MISSING_CREDENTIAL: ... resolves OPENCODE_GO_API_KEY, which is not set`

The variable named by `apiKeyEnv` is not visible to the process. Three causes, in order of
likelihood:

1. The key is in `~/.dsh/.env` but the name does not match `apiKeyEnv` exactly — including case.
2. dsh was launched with a scrubbed environment (systemd unit, cron, CI) that also lacks the file
   layer. Put the value in `~/.dsh/.env` rather than relying on shell startup files: it is read by
   dsh itself, for every launcher.
3. The variable was exported *after* dsh started. The environment layer is a snapshot taken at
   launch; restart dsh.

`echo $OPENCODE_GO_API_KEY` in the same shell you launch dsh from tells you which layer you are
hitting.

## `GET /models` returns 200 even with a wrong key

This gateway lists models without validating the key; only an inference request is authenticated.
Never diagnose a credential with `curl .../models` — `scripts/doctor.sh` posts one real completion
for exactly this reason. A bogus key shows up as `401 Invalid API key` on
`POST /chat/completions`, not on `/models`.

## `400 ... MissingSessionID`

The OpenCode Go gateway routes by client session and refuses any request without the header. Keep
this in the route:

```yaml
      headers:
        x-opencode-session: deepseek-harness-config
```

## Every request fails on a gateway that holds a valid key

Most OpenAI-compatible gateways reject one of two things OpenAI accepts:

```yaml
      compat:
        supportsDeveloperRole: false   # a reasoning model's system prompt arrives as role:developer
        maxTokensField: max_tokens     # the request's output cap arrives as max_completion_tokens
```

Symptom for the first: only reasoning models fail. Symptom for the second: any model with an output
cap fails while the key and URL are right.

## `off` does not stop a DeepSeek model from thinking

An empty `off` sends no reasoning field at all, so an endpoint that thinks by default keeps
thinking. Set `compat.thinkingFormat: deepseek` on that model (or the route).

## `UNKNOWN_MODEL`

The model is not in the route's `models` list (an explicit list *replaces* the catalog). Add the
entry, or fix a typo in the id. `deepseek-flash` and `deepseek-v4-pro` are the two this repo
declares.

## The Effort menu is missing for a model I added by hand

Hand-declared models have no reasoning levels. Declare them with `reasoningEfforts` — see
[docs/models.md](models.md#reasoning-controls).

## An image is refused before sending

Hand-declared models are text-only. Add `input: [text, image]` to that model. Note that the attached
image stays in the session log, so the same request repeats until the session moves off that model.

## Settings changes do nothing / dsh will not start

```bash
dsh --profile headless --dump-config >/dev/null   # the composed tree, or the parse error
```

A key written with nothing after the colon (`supportsDeveloperRole:`) is refused rather than ignored,
and the error names the field. Unknown keys in a plugin section fail the same way.

## `npx @deepseek-ai/dsh ...` is slow to start

`npx` re-resolves the package each run. Install it once (`npm install -g @deepseek-ai/dsh@0.1.5-rc.1`)
and call `dsh`.

## The web UI answers `401` in the browser

The URL carries a one-time token; a plain `http://127.0.0.1:4319/` without it is refused by design.
Use the URL the server printed. Restarting prints a fresh one.

## A profile boots old code after an upgrade

Profiles live in `$DSH_HOME/profiles/<name>`; bundles resolve from the dsh installation, and the
user layer is `cordis.patch.yml` (usually empty). Confirm what is actually resolved:

```bash
dsh --profile web --dump-config | head
jq -r .version ~/.dsh/profiles/node_modules/@deepseek-ai/dsh-base/package.json
```

If a profile directory is genuinely broken, delete it and let it re-initialize from the shipped
template on the next boot — `settings.yaml` and `.env` live one level up and are unaffected.

## Security

- `0.1.1-rc.2` and earlier: CVE-2026-82533 — a sandboxed agent could reach the tool's own local web
  interface and switch its session to `danger-full-access`, with no approval prompt. Fixed in
  `0.1.2-alpha.2` (first fixed npm release); this repo pins `0.1.5-rc.1`.
- The sandbox confines writes only. Reads and network access are unconfined, and the agent's shell is
  handed the web interface address — so do not run the UI on a reachable interface.
- The project has no security policy file and has not been audited. Its own `SAFETY.md` says
  sandboxing and approval prompts "do not guarantee isolation or prevent damage".
