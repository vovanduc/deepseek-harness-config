---
type: gotcha
title: An empty YAML value is refused, not ignored
description: A settings key written with nothing after the colon fails the parse and dsh will not start; the error names the field. Unknown keys in a plugin section fail the same way.
tags: [settings, yaml]
---
# Symptom

Settings changes appear to do nothing, or dsh refuses to start.

# Diagnosis

```bash
dsh --profile headless --dump-config >/dev/null   # the composed tree, or the parse error
```

# Notes

- `reasoningEfforts: false` is a legal value (strips reasoning from the model).
- A bare `off:` entry is legal only for a model that thinks on request; otherwise add `compat.thinkingFormat: deepseek`.

# Related

[../../docs/troubleshooting.md](../../docs/troubleshooting.md) · [../runbooks/add-model-or-provider.md](../runbooks/add-model-or-provider.md)
