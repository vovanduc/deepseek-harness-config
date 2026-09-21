---
type: gotcha
title: An agent browser-preview proxy makes every POST /api return 403
description: dsh's Host/Origin fence rejects any request whose Origin host differs from the forwarded Host; a preview proxy on a different port passes the loopback check but fails the Origin match, so the UI loads but the first POST (e.g. Open folder) dies with HTTP 403.
tags: [dsh, web, browser-preview, proxy]
---
# Symptom

The web GUI loads fine through a browser-preview proxy (page renders, session
list works), then the first mutating call fails: *"Couldn't open folder —
directory picker failed: … transport failure for /api/directoryPicker/pick:
HTTP 403"*.

# Cause

`dsh-client-connection` fences every `/api` request (`isTrustedApiRequest`):
the `Host` header must be loopback or a declared `trustedHosts` authority, **and
when an `Origin` header is present its host must equal the `Host` host**
(`new URL(origin).host === hostUrl.host`). A preview proxy serves the page on
its own port (e.g. `127.0.0.1:51739`) but forwards `Host: 127.0.0.1:4319` to the
upstream — the browser's `Origin: http://127.0.0.1:51739` then mismatches → 403.

GETs send no `Origin`, so they pass on the Host check alone — which is why the
UI looks healthy until the first POST. Reproduced on dsh `0.1.5-rc.1`:

```bash
curl -X POST http://127.0.0.1:51739/api/directoryPicker/pick \
  -H 'Origin: http://127.0.0.1:51739' -H 'Content-Type: application/json' -d '{}'
# → 403 forbidden   (same request direct on :4319 → 401 unauthorized, fence passed)
```

# Fix

Always hand the user the printed **loopback token URL** (`dsh web` output),
opened in a normal browser tab — never a preview/proxy port. `trustedHosts`
cannot relax this: the Origin equality is unconditional, and `127.0.0.1` already
passes the Host half. A stale one-time token shows as `401`, not 403 — restart
`dsh web` to mint a fresh one.

# Related

[../runbooks/verify-change.md](../runbooks/verify-change.md) · [web-ui-exits-under-a-tty.md](web-ui-exits-under-a-tty.md)
