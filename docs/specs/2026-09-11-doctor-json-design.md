# doctor.sh --json — design

- **Feature:** `feat-005` (machine-readable readiness)
- **Date:** 2026-09-11
- **Status:** approved (single maintainer)

## Problem

`scripts/doctor.sh` is the machine-level readiness check (CLI version, settings, credential, live
inference, skills). It prints coloured text and a `status: READY` line, so anything that wants to
consume it — `init.sh`, CI, a setup script, a second agent — has to parse colour codes and prose.
`feat-007`'s pre-flight and `install.sh` both had to guess at readiness rather than read it.

## Goal

One flag that prints a single JSON object on stdout with stable keys and the same verdict and exit
code as the human report.

## Non-goals

- No change to what is checked, or to the exit codes (0 ready, 1 not ready).
- No colour, no prose, no extra writes in `--json` mode.
- Not a general logging framework: the checks stay exactly as they are, only the reporting changes.
- No schema file; the contract is the key set, documented here and in the runbook.

## Design

`./scripts/doctor.sh [--json] [--help]`

Each check records a `(status, id, message)` triple; the human path prints it live exactly as today,
the JSON path buffers and emits once at the end.

| Check id | Meaning |
|---|---|
| `cli` | `dsh` on PATH, and its version vs `dsh.version` |
| `settings` | `$DSH_HOME/settings.yaml` present |
| `compose` | `dsh --profile headless --dump-config` succeeds |
| `credential` | the variable named by `apiKeyEnv` is set and not a placeholder |
| `inference` | one live completion (`max_tokens: 1`), or a skip/warn |
| `skills` | `$DSH_HOME/skills` exists, plus a count |

```json
{
  "status": "READY",
  "ok": 6,
  "warn": 0,
  "fail": 0,
  "checks": [{ "id": "cli", "status": "ok", "message": "dsh 0.1.5-rc.1 on PATH" }]
}
```

`status` is `READY` when `fail` is 0, else `NOT_READY`; the exit code matches. The early return when
`settings.yaml` is missing also goes through the same emitter, so `--json` never prints a partial
object.

JSON is serialised with `node` (already required by the repo) so quoting and escaping are correct;
messages are passed as `status|id|message` lines and split on the first two separators.

## Decisions and trade-offs

| Decision | Why | Accepted cost |
|---|---|---|
| Buffer in JSON mode, print live in human mode | keeps the human output byte-identical while `--json` stays pipeable | two code paths in one small `record` helper |
| `id` + `message` per check | a consumer keys off `id`, not off English prose | ids become a small public contract |
| `node` for serialisation | correct escaping without hand-rolled JSON in bash | node must exist — it already must for dsh |

## Acceptance criteria

1. `./scripts/doctor.sh` output is unchanged in shape and exits 0 on this machine.
2. `./scripts/doctor.sh --json` prints exactly one JSON object; `python3 -m json.tool` accepts it; no ANSI escapes appear.
3. Keys are exactly `status`, `ok`, `warn`, `fail`, `checks`; each check has `id`, `status`, `message`.
4. Counts and `status` agree with the human run; exit code is identical in both modes.
5. With `DSH_HOME` pointed at a missing directory, both modes report `NOT_READY` and exit 1 — JSON still complete.
6. `--help` exits 0; an unknown flag exits 2.
7. `./init.sh --with-doctor` (human path) still works, and the offline gate stays green.

## Verification plan

Run both modes and diff their verdicts; parse the JSON and assert the key set and counts; the
`DSH_HOME` negative case for a complete-but-failing object; `--help` / bad flag; `./init.sh`;
`shellcheck`; then CI after pushing.

## Process note

`superpowers:*` is not installed; spec and plan are written by hand and the tasks run inline.
