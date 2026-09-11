---
type: log
title: Knowledge change log
---
# Knowledge change log

<!-- YYYY-MM-DD — <type>/<concept> — thêm|sửa: mô tả -->

2026-09-10 — bundle created — adopt OKF: `index.md`, `log.md`, six category indexes.
2026-09-10 — convention/settings-symlink — added: repo file is the live `$DSH_HOME/settings.yaml`.
2026-09-10 — convention/skill-bundle-layout — added: top-level discovery + required frontmatter.
2026-09-10 — convention/secrets-never-committed — added: `apiKeyEnv` names, never values.
2026-09-10 — decision/adopt-harness-and-okf — added: state in files, knowledge in `knowledge/`.
2026-09-10 — decision/pin-dsh-version — added: exact pin + CVE-2026-82533 floor.
2026-09-10 — decision/init-stays-offline — added: split offline gate from machine readiness.
2026-09-10 — system/dsh-home-layout — added: what `$DSH_HOME` holds and who owns it.
2026-09-10 — api/opencode-go-route — added: full route contract with reasons.
2026-09-10 — service/credential-resolution — added: four-layer resolution order.
2026-09-10 — glossary/dsh-vocabulary — added: overloaded nouns (provider, preset, profile, skill).
2026-09-10 — runbook/new-machine-setup — added: clone → install → key → READY.
2026-09-10 — runbook/verify-change — added: `init.sh` vs `doctor.sh` vs harness audit.
2026-09-10 — runbook/add-model-or-provider — added: model/provider edit procedure.
2026-09-10 — gotcha/models-endpoint-not-authenticated — added: `/models` does not authenticate.
2026-09-10 — gotcha/missing-session-id — added: the required OpenCode Go header.
2026-09-10 — gotcha/compat-flags — added: developer role + max_tokens field.
2026-09-10 — gotcha/empty-yaml-value-refused — added: empty value fails the parse.
2026-09-10 — gotcha/hand-declared-models-text-only — added: images need `input: [text, image]`.
2026-09-10 — runbook/ci-verification — added: GitHub Actions runs `./init.sh`; the PyYAML step is load-bearing; `init.sh` now fails if the wiring is removed.
2026-09-10 — runbook/ci-verification — updated: action majors bumped to v7 (Node 24 runner runtime, clears the Node 20 deprecation annotation).
2026-09-10 — runbook/update-ponytail-skills — added: pinned upstream ref, drift check vs apply, and what is deliberately not synced (built `.openclaw` copy, plugin hooks).
2026-09-11 — gotcha/web-ui-exits-under-a-tty — added: `dsh web` exits 0 without serving when stdout is a TTY; supervise it non-interactively.
