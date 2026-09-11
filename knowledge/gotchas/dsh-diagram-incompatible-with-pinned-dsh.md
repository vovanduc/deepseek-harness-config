---
type: gotcha
title: dsh-diagram 0.4.0 breaks the web UI on the pinned dsh
description: Its client bundle injects a `conversationEvents` service that does not exist in dsh 0.1.5-rc.1, so the layer composes but the client entry stays pending and the web boot dies with "Failed to load plugins".
tags: [dsh, plugins, compatibility]
---
# Symptom

With `dsh-diagram` in the web profile and a restart, the UI shows only:

```
HARNESS
Failed to load plugins
web boot: 1 entry did not activate
dsh-diagram: pending (waiting for service: conversationEvents)
```

The whole app fails to boot — not just the diagram feature. `dsh --profile web --dump-default-config`
still prints the `# == dsh-diagram` layer, so the host-side layer looks fine: only the browser proves
the failure.

# Cause

`dsh-diagram@0.4.0` declares `dsh.compatibility.dshReleases` up to `0.1.1-rc.2`, and its client bundle
injects `["slots", "conversationEvents"]` (`lib/client.js`). `conversationEvents` does not exist
anywhere in dsh **0.1.5-rc.1** (grep of the global install: 0 hits) — the client service was dropped
or renamed after 0.1.1, which is the release line the plugin was built against. A client entry whose
injected service never resolves blocks the boot.

Node and pnpm are not the problem (`^22.19.0` + `pnpm >=10` both satisfied). `dsh-mermaid@0.4.0`
injects nothing (`dsh.client.inject: []`) and works on 0.1.5-rc.1.

# Fix

Keep it out of the set: no entry in `plugins.json`, and

```bash
dsh plugin --profile web remove dsh-diagram   # drops the dependency AND the bundle entry
```

Do not hand-edit `dsh.profile.bundles` — the reconcile step inside `dsh plugin` is what keeps it
consistent with `dependencies`. Re-add only when a release lists dsh 0.1.5 in
`dsh.compatibility.dshReleases`. Removing the client half by hand (patching the installed manifest)
would leave the Canvas tab and the preview card — the reason to install it — still missing.

# Related

[../runbooks/dsh-plugins.md](../runbooks/dsh-plugins.md) · [web-ui-exits-under-a-tty.md](web-ui-exits-under-a-tty.md)
