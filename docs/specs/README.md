# Specs

Design documents from the brainstorm phase of the DCNET workflow live here — one per feature:

```
docs/specs/YYYY-MM-DD-<topic>-design.md
```

A spec is written **before** code (hard gate) and referenced from the feature's `spec` field in
`feature_list.json`. Keep this directory at `docs/specs/`; the workflow deliberately does not use
`docs/superpowers/`.

Source of the process: the `dcnet-workflow` skill (`superpowers:brainstorming` writes the spec).
