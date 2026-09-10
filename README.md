# deepseek-harness-config

[![verify](https://github.com/vovanduc/deepseek-harness-config/actions/workflows/verify.yml/badge.svg)](https://github.com/vovanduc/deepseek-harness-config/actions/workflows/verify.yml)

My [DeepSeek Harness](https://github.com/deepseek-ai/deepseek-harness) (`dsh`) configuration, kept
in git so a second machine starts in the same state as the first.

Everything here is dsh-only: providers, default model, session defaults, skills — plus the delivery
harness (`AGENTS.md`, `feature_list.json`, `knowledge/`). Secrets are never committed — credentials
live in `~/.dsh/.env`, which is gitignored.

```
settings.yaml        providers + default model + session defaults   (symlinked to ~/.dsh/settings.yaml)
.env.example         credential template                            (copied to ~/.dsh/.env once)
dsh.version          the dsh build this config is verified against
.nvmrc               Node major pinned for CI (22)
skills/              SKILL.md bundles linked into ~/.dsh/skills
scripts/doctor.sh    read-only health check: CLI, settings parse, credential, live inference call
docs/                models, modes, troubleshooting + specs/plans for a feature
AGENTS.md            agent routing: startup workflow, working rules, Definition of Done
init.sh              offline verification gate — run first, every session
feature_list.json    feature state + evidence        progress.md      cross-session context
session-handoff.md   handoff for a larger session
knowledge/           durable knowledge (OKF): conventions, decisions, systems, runbooks, gotchas
.github/workflows/   CI: runs ./init.sh on push and pull request
```

Working in this repo — human or agent — starts at [AGENTS.md](AGENTS.md); `./init.sh` must be green
before any change and CI runs the same gate on every push and pull request. Durable facts belong in
[knowledge/](knowledge/index.md), not in chat.

## On a new machine

```bash
git clone https://github.com/vovanduc/deepseek-harness-config ~/Code/deepseek-harness-config
cd ~/Code/deepseek-harness-config
./install.sh
$EDITOR ~/.dsh/.env          # put the real key in
./scripts/doctor.sh          # expect: status: READY
```

`install.sh` installs the pinned `dsh` globally, symlinks `settings.yaml` into `~/.dsh/`, seeds
`~/.dsh/.env` (mode 600) if absent, links the skills, then runs the doctor. It is idempotent and
moves anything it would overwrite to `*.bak-<timestamp>`.

Because `settings.yaml` is a **symlink**, the file the running server reads is this repo's file:
changes made in the web UI's Settings pages land here and are ready to `git commit`. The same holds
in reverse — edit here, and the next request picks it up (no restart).

## Running it

```bash
dsh web                       # browser UI, prints a one-time-token URL, opens the browser
dsh web --port 4319 --no-open # fixed port, no browser
dsh --profile headless "run the tests"   # one task, print the answer, exit
dsh --profile acp             # serve automation clients over ACP on stdio
```

The workspace is the directory you launch from unless you pick another in the UI. The Web UI's URL
carries a one-time token that the browser exchanges for a cookie — every restart prints a new one;
the old cookie keeps working.

## What is configured

| Setting | Value | Where |
|---|---|---|
| Provider | `opencode-go` — OpenAI-compatible gateway | `settings.yaml` → `llm-pi-ai.providers` |
| Default model | `deepseek-flash` (DeepSeek V4.1 Flash, 1M ctx) | `settings.yaml` → `agent-default-model` |
| Session preset | `standard` | `settings.yaml` → `agent-presets.default` |
| Permissions | `workspace-write` (sandboxed writes + approval prompts) | `settings.yaml` → `permission.defaultPreset` |

Adding another provider or model is a `settings.yaml` edit — see [docs/models.md](docs/models.md).
The four session modes and the permission presets are in [docs/modes.md](docs/modes.md).

## Security notes

- `dsh` runs a coding agent that holds a shell. The default sandbox confines **writes** to the
  workspace; **reads and network access are not confined**, and an agent can reach a local service.
- Do not run the web UI on an address reachable from outside the machine. It binds loopback by
  default; if you must expose it, use `--trusted-host` deliberately and stop the server when idle.
- Version `0.1.1-rc.2` and earlier carried CVE-2026-82533 (an agent could lift its own sandbox
  through the local web interface). Fixed releases start at `0.1.2-alpha.2`; this repo pins
  `0.1.5-rc.1`. Re-check `dsh.version` before installing on a new machine.
- The project has not been security-audited. Treat `danger-full-access` as "no guardrails".
