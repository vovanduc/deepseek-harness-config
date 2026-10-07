# Session Handoff

## Current Objective

- Goal: build a Grok-Bot-style **teammates product on dsh** — a roster of persistent agents, each
  with its own computer — while learning plugin architecture by porting ideas from pi.dev, rakazo,
  and OpenMausBot.
- Repo scope expanded 2026-10-07: config deliverable **plus** this product live in the same repo
  (`knowledge/decisions/repo-hosts-teammates-product.md`).
- Current status: research + decision done; **`feat-016` (vertical slice) is `not-started`** and is
  the next thing to build.
- Branch: `main`.

## Read first

1. `knowledge/decisions/dsh-as-teammates-engine.md` — the ADR and its trade-offs.
2. `knowledge/systems/acp-surface.md` + `knowledge/systems/profiles-and-bundles.md` — verified
   mechanics at `0.1.5-rc.1` (ACP call table, profile anatomy, `--from-default-profile`).
3. `docs/research/dsh-grok-bot-brief-2026-10-07.md` — the source brief (ChatGPT), already critiqued
   against the installed version; its corrections are in the gotchas below.
4. `feature_list.json` → `feat-016` for acceptance criteria.

## Facts verified this session (0.1.5-rc.1)

- `dsh --profile bot-x --from-default-profile acp` creates a working ACP profile (tested with
  `probe-bot`, removed). Bundles resolve from the install anchor — no pnpm install needed.
- ACP carries: session new/list(cwd filter)/resume/close, `set_config_option` (model +
  reasoning_effort per session), prompt, cancel, update stream, **request_permission**. Missing:
  delete, fork, terminals, plans, modes, presentation cards — anything UI-rich needs a side channel.
- Sessions persist under `$DSH_HOME/sessions` **keyed by workspace dir**, shared across profiles →
  per-bot isolation = separate `DSH_HOME` (env var).
- `DSH_TELEMETRY_DISABLED=1` must be set for unattended bot profiles (OTel exports by default).
- Sandbox mode ≠ compute boundary; all `*-local` seams must move together, or run the whole dsh
  process in the bot's container (chosen for v1+).
- No browser/desktop tool in `dsh-base` — computer-use is a plugin/MCP problem, phase 3+.

## Next actions

1. `feat-016`: create `bot-amber` + `bot-onyx` ACP profiles, distinct `DSH_HOME`s/workspaces/personas;
   write `product/supervisor` (suggested home) speaking ACP stdio; run the 5 acceptance checks in
   the feature entry. Spec → `docs/specs/`, plan → `docs/plans/` per `dcnet-workflow`.
2. Keep `dsh.version` pinned; re-verify the ACP surface on any bump.

## Watch out

- The settings-symlink drift trap is unchanged: any settings write in the web/desktop UI replaces
  `~/.dsh/settings.yaml`'s symlink — run `./scripts/doctor.sh` after UI use.
- `--patch` overlays can vary a single profile at boot; per-bot profiles are for durable plugin
  sets, not required for per-bot models (use `set_config_option`).
