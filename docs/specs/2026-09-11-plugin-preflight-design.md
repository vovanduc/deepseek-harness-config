# Plugin pre-flight compatibility — design

- **Feature:** `feat-007` (catch an incompatible plugin before it reaches a profile)
- **Date:** 2026-09-11
- **Status:** approved (single maintainer)

## Problem

`dsh-diagram@0.4.0` composed fine and then **killed the whole web boot**: its client half needs a
service the pinned dsh does not provide, so the browser showed `Failed to load plugins` and rendered
nothing. `dsh --profile web --dump-default-config` was happy throughout — the config dump proves the
**host** layer only. The only existing detection was a human restarting the browser.

`plugins.json` pins exact versions, but a correct pin is not a compatible one.

## Facts established (2026-09-11, npm registry + this machine)

- `npm view <name>@<version> dsh --json` returns the package's custom `dsh` manifest **without
  installing it** — the whole check can run before anything touches a profile.
- `dsh.compatibility.dshReleases` is a map of dsh release → status:
  `{"0.1.0-rc.6": "compatible", "0.1.1-rc.2": "compatible", …}`. `dsh-diagram@0.4.0` stops at
  `0.1.1-rc.2`, so the pinned `0.1.5-rc.1` is simply absent.
- `dsh.client.inject` lists the client services/ids the plugin needs; the client half exists only
  when `dsh.client` is present. `dsh-diagram@0.4.0` injects
  `@deepseek-ai/dsh-client-runtime`, `@deepseek-ai/dsh-client-connection`,
  `@deepseek-ai/dsh-client-locale`, `@deepseek-ai/dsh-client-ui-conversation`.
- Offline oracle for "does the pinned dsh provide this id": the id is a directory under
  `<npm root -g>/@deepseek-ai/dsh/node_modules/`, **or** the literal string occurs somewhere under
  that install's `@deepseek-ai/`. `grep -rIl --fixed-strings` over it takes well under a second.
  On this machine `@deepseek-ai/dsh-client-runtime` and `conversationEvents` are both absent, which
  matches the observed failure.
- **Limit:** the manifest lists package-scoped ids. The bare service name that actually blocked the
  boot (`conversationEvents`) lives in the *compiled* `client.js`, not in the manifest. So the
  pre-flight is a filter, not a guarantee; the browser after a restart remains the final gate.

## Goal

Refuse to install a plugin whose manifest says it cannot work on the pinned dsh — before it touches a
profile and before anyone restarts a browser to find out.

## Non-goals

- Not a sandbox and not a code review: it reads metadata, never executes plugin code.
- It does not boot a profile or start a server.
- It does not replace the browser check, and it does not detect a bare service name that only exists
  in compiled client code.
- It does not police host-only plugins (no `dsh.client`) — those cannot kill the web boot this way.

## Design

`scripts/plugin-preflight.sh <name>@<version> [--dsh-version <v>]`

| Check | Rule | Verdict |
|---|---|---|
| Pin | spec must carry an exact `@version` | usage error (`2`) |
| A — compatibility | if `dsh.compatibility.dshReleases` is present, the target dsh version must be a key whose status is `compatible`; absent map = *not declared*, not a failure | FAIL (`1`) |
| B — client inject | every id in `dsh.client.inject` must resolve in the pinned install (directory, or literal string under `@deepseek-ai/`) | FAIL (`1`) |
| Source | spec not resolvable on npm (e.g. a git source) = cannot verify | FAIL (`1`), with the escape hatch below |

Exit codes: `0` ok, `1` incompatible or unverifiable, `2` usage/lookup error. `--dsh-version`
overrides the target (read from `dsh.version`) so check B can be exercised alone.

`scripts/install-plugins.sh` runs the pre-flight before each `add`; a plugin that fails is skipped and
counted, so nothing enters the profile. `--skip-preflight` is the deliberate override.

`init.sh` gains a wiring guard: the pre-flight script exists, is executable, and `install-plugins.sh`
still calls it.

## Decisions and trade-offs

| Decision | Why | Accepted cost |
|---|---|---|
| Check the published manifest via `npm view`, not the installed tree | nothing touches a profile, and it works before install | network per plugin; a GitHub-only plugin cannot be checked |
| Block on "cannot verify", not just on "known bad" | the failure mode is a dead UI, and the escape hatch is one flag | a legitimate git-sourced plugin needs `--skip-preflight` |
| No `dsh.compatibility` = pass with a note | most community plugins omit it (dsh-mermaid, smooth-stream, sysmon all do) | a plugin that omits it is only covered by check B |
| Keep it a separate script | testable in isolation, reusable by hand before adding a plugin | one more file to wire |

## Acceptance criteria

1. `./scripts/plugin-preflight.sh dsh-mermaid@0.4.0` → exit 0 (no compatibility map; `inject: []`).
2. `./scripts/plugin-preflight.sh dsh-diagram@0.4.0` → exit 1, naming the pinned release that the plugin's compatibility map omits.
3. `--dsh-version 0.1.1-rc.2` on `dsh-diagram@0.4.0` (a release its map *does* claim) → still exit 1, via check B alone, naming `@deepseek-ai/dsh-client-runtime` — so the two checks are independent and the compatibility map is not the only net.
4. An unpinned spec → exit 2; a non-npm/unresolvable spec → exit 1 with the override named.
5. `install-plugins.sh` skips a failing plugin (no profile change) and `--skip-preflight` proceeds.
6. `init.sh` fails if the pre-flight script is removed or `install-plugins.sh` stops calling it.
7. `./init.sh`, the harness audit and CI stay green.

## Verification plan

- The fixtures above, run for real; plus `install-plugins.sh --dry-run` showing the pre-flight verdict.
- A negative wiring test (drop the call) and restore.
- `./init.sh`, the audit, the link check, and the CI run after pushing.

## Process note

Same as the earlier specs: `superpowers:*` is not installed, so spec and plan are written by hand and
the tasks run inline. The `dsh-diagram` regression case is the fixture — it is the bug this feature
exists to prevent.
