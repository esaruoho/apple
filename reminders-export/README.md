# reminders-export

Export Apple Reminders lists to clean Markdown with YAML frontmatter.
AppleScript-driven, incremental, no SQLite spelunking — Reminders.app's
scripting dictionary covers everything (lists, reminders, due/completion
dates, priority, flagged, body).

One file per reminder, organised by list. Output is plain markdown — works
with Obsidian, Logseq, or any consumer.

## Install

```bash
cd ~/work/apple/reminders-export
cp .env.example .env
cp config.example.json config.json
chmod +x scripts/reminders-export
```

First run prompts for Automation permission (Terminal → control Reminders).

## Usage

```bash
./scripts/reminders-export lists                        # list all Reminders lists + counts
./scripts/reminders-export export --lists Work,Home     # export specific lists
./scripts/reminders-export export --all                 # every list
./scripts/reminders-export export --include-completed   # include completed reminders
./scripts/reminders-export export --force               # re-export unchanged
./scripts/reminders-export status                       # last run / per-list counts
```

## Output shape

```
~/reminders-vault/
  work/
    2026-04-12__call-dentist__3F2B81A0.md
    2026-05-01__file-tax-return__7C4E1922.md
  groceries/
    2026-05-07__milk__1A0E6633.md
```

Each file:

```yaml
---
id: "x-coredata://.../REMCDReminder/p123"
title: "Call dentist"
list: "Work"
completed: false
priority: 5
flagged: false
creation_date: "2026-04-12T09:14:00"
modification_date: "2026-04-12T09:14:00"
due_date: "2026-04-15T10:00:00"
completion_date: ""
---

# Call dentist

Annual cleaning. Bring insurance card.
```

## State + incremental

`.state.json` tracks each reminder's last seen `modification_date`. Re-running
`export` only writes reminders whose modification date advanced. Use `--force`
to re-emit everything.

## Notes

- Built on Reminders.app's scripting dictionary (see
  `~/work/apple/dictionaries/reminders/reminders.md`).
- `priority`: 0 = none, 1–4 = high, 5 = medium, 6–9 = low (per sdef).
- ISO dates emitted via the `«class isot»` coercion AppleScript supports.
- Completed reminders are excluded by default — flip `INCLUDE_COMPLETED=true`
  in `.env` or pass `--include-completed`.
