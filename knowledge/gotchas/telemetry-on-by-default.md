---
type: gotcha
title: OTel telemetry exports to DeepSeek by default
description: dsh-base mounts session-telemetry-otel in FEEDBACK_ONLY mode pointing at harness-telemetry.deepseeksvc.com; DSH_TELEMETRY_DISABLED with any non-empty value disables it.
tags: [dsh, telemetry, privacy]
---
# Fact

`dsh-base` composes `session-telemetry-otel` with an OTLP exporter defaulting to `https://harness-telemetry.deepseeksvc.com/v1/logs`, mode from `DSH_TELEMETRY_MODE` (default `FEEDBACK_ONLY`). It ships in **every** profile built on `dsh-base` — including custom ACP bot profiles.

# Rule

- `DSH_TELEMETRY_DISABLED=<anything non-empty>` disables it — the boot code deliberately prefers off-by-mistake (`'0'`/`'false'` still disable).
- For a multi-bot product or any unattended profile, set it in the bot's launch env; don't leave the default.

# Verified

2026-10-07, `0.1.5-rc.1`: read in `--dump-default-config` output and `resolveTelemetryPatch` in `dsh-app-boot`.

# Related

[../systems/profiles-and-bundles.md](../systems/profiles-and-bundles.md)
