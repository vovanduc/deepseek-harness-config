---
type: convention
title: Append-only logs are edited at the end, never by replacing an entry
description: knowledge/log.md and progress.md are append-only. Editing them with a search-and-replace whose old_string is an existing entry silently deletes that entry — the file still parses, the gate still passes, and the loss is invisible. Anchor edits at EOF or on a structural boundary instead.
tags: [knowledge, harness, editing, okf]
---
# The rule

`knowledge/log.md` and the dated sections of `progress.md` are **append-only**. To add an entry:

- **Do** anchor the edit on the file's end — append, or use a structural boundary that cannot match an
  entry (the trailing newline at EOF, the section heading above the list).
- **Do not** take an existing entry as `old_string` and put a *different* entry in `new_string`. That
  is a **replace**, not an append: the old entry disappears.

```diff
- 2026-09-15 — gotcha/x — verified end to end: <long evidence>
+ 2026-09-15 — runbook/y — added: <new work>
```
The diff is one line of `-` and one line of `+`, so `git diff` reads as a tidy edit. It is a deletion.

# Why it is invisible

- The markdown still renders; the front matter still parses.
- `./init.sh` passes — it validates shape, not history.
- The link check passes — nothing linked to the line.
- The lost content is prose: an evidence line, a measurement, a retraction. Nothing fails without it.

Both times this happened here it was noticed by someone reading the diff, not by a gate:

- `api/opencode-go-route` — a measured cost profile was replaced by a new entry.
- `gotcha/diagram-plugins-er-and-flow` — the live-composer end-to-end proof and the curated-data scan
  were replaced by the BPMN runbook entry.

# How to check

After editing any append-only file, prove the change is additive rather than trusting the tool result:

```bash
git diff <commit-before> -- knowledge/log.md | grep -E '^-' | grep -vE '^---'
```

An append-only edit prints **nothing**. Anything else is a deletion that needs a reason. Same check
against the previous commit works for `progress.md`.

# Related

[../index.md](../index.md) · [../log.md](../log.md) · [../../AGENTS.md](../../AGENTS.md)
