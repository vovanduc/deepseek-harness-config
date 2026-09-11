---
type: gotcha
title: dsh web exits 0 immediately when stdout is a TTY
description: Under a real terminal dsh web prints nothing and exits 0 without serving; pipe stdout (or run it non-interactively) to actually get the server.
tags: [dsh, web, supervisor]
---
# Symptom

Supervising `dsh web --port <p> --no-open` with a PTY attached: the process exits
immediately, `exit=0`, no output, nothing listens on the port. Reproduced on
`dsh 0.1.5-rc.1` with a PTY and with stdin redirected from `/dev/null`; stdout was
the TTY in both runs.

# Working invocation

Any non-TTY stdout. Verified: stdout piped, and `hub start` with `pty: false`
(which is the supervisor path this repo uses).

```bash
hub start name=dsh-web application=dsh args=["web","--port","4319","--no-open"] pty=false
```

`GET /` then answers `401` until the browser exchanges the one-time token printed
in the log line — that is the expected sign the server is up.

# Related

[../runbooks/verify-change.md](../runbooks/verify-change.md) · [../systems/dsh-home-layout.md](../systems/dsh-home-layout.md)
