# mail-exporter

Apple Mail.app metadata catalog via the Envelope Index SQLite.
Tier 1 app — Mail has a full sdef plus App Intents — but for **bulk
message metadata** (counts, subject search, top senders, mailbox
topology) the SQLite is faster than walking AppleScript across
331,000+ messages.

Source: `~/Library/Mail/V*/MailData/Envelope Index` (highest-V wins).
Read-only (`?mode=ro&immutable=1`).

```bash
mail-exporter status                                      # counts overview
mail-exporter mailboxes                                   # IMAP/local with unread + total
mail-exporter top-senders --limit 30
mail-exporter subjects --match 'invoice|receipt'
mail-exporter search --sender ruby --since 2025-01-01
mail-exporter export --per-mailbox-limit 500              # markdown vault
```

Live on this Mac:
- **331,867 messages**
- **181,698 unique subjects**
- **25 mailboxes** (largest: INBOX 18,978; Sent 4,574; Junk 43)

Vault layout:

```
~/work/apple/exported/mail/
├── INDEX.md
├── top-senders.md                       top 200 senders by msg count
└── mailboxes/
    ├── _index.md
    ├── inbox.md                         latest 200 message headers
    ├── sent-messages.md
    └── ...
```

## What's NOT here

- **Message bodies** — those live as `.emlx` files in
  `~/Library/Mail/V*/<account>/<mailbox>.mbox/Data/...`. For full-text
  search of bodies, the Spotlight index is the right tool
  (`mdfind -onlyin ~/Library/Mail "your search"`).
- **Attachments** — separate `attachments` SQLite table; could add.
- **Threads / conversations** — `conversations` table exists; Phase 2.
- **Phase 2 write actions** (`compose`, `mark-read`, `flag`) — Mail's
  sdef supports these via AppleScript.
