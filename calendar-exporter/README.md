# calendar-exporter

Apple Calendar → markdown vault. Reads
`~/Library/Group Containers/group.com.apple.calendar/Calendar.sqlitedb`
read-only (`?mode=ro&immutable=1`), never modifies Calendar's state.

## Install

```bash
cd ~/work/apple/calendar-exporter
cp .env.example .env
chmod +x scripts/calendar-exporter
```

Full Disk Access required (System Settings → Privacy & Security).

## Commands

```bash
calendar-exporter status                            # 24 calendars / 9,457 events
calendar-exporter calendars                         # per-calendar event counts
calendar-exporter events --since 2026-01-01 --calendar Perhe
calendar-exporter events --match 'kortela|grotz'
calendar-exporter upcoming -n 30                    # next 30 events from today
calendar-exporter export                            # full vault
```

## Vault layout

```
~/work/apple/exported/calendar/
├── INDEX.md
├── calendars/
│   ├── _index.md                    every calendar with event counts
│   ├── perhe.md                     per-calendar event lists
│   ├── home.md
│   └── ...
└── by-year/
    ├── _index.md
    ├── 2026.md                      every event from 2026
    └── ...
```

Per-event format: `\`YYYY-MM-DD HH:MM\` (duration)  **summary**  @ location`,
with description and URL if present.

## What's NOT here

- Attendee lists (could add via Attendee table join)
- Recurrence expansion (CalendarItem only stores the rule; expansion
  needs an iCal-compatible RRULE walker)
- Alarms (separate Alarm table; could add)
- Attachments (Attachment table → AttachmentFile)
- Phase 2 write actions (`create-event`, `delete-event`)

These are straightforward next-pass extensions.
