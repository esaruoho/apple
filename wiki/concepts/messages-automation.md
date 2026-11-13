# Messages/iMessage Automation

Messages has the **thinnest sdef** — 3 commands: `send`, `login`, `logout`. Write-only by design.

**What works:** Send text/files to participants, list 201 chats, list participants with handles, URL schemes (`imessage://`, `sms://`) open compose window

**What doesn't work:** Read message content, search, delete, react, auto-reply, access history. No App Intents for sending. The only Intent is Focus Mode filtering.

**Workaround:** `~/Library/Messages/chat.db` (SQLite) is readable with Full Disk Access but SIP-protected.

## Count messages per contact locally

Run `python3 bin/messages-counts`. Reports land in gitignored
`exported/imessage-counts/counts.md` and `counts.json`, with private file permissions.

The counter uses Python's stdlib SQLite reader with `mode=ro` and `query_only=ON`.
It selects metadata only: no message text, attributed bodies or attachment data.
It reads Contacts identity metadata locally, combines phone/email handles only on
unique exact contact matches (including aliases explicitly recorded by Messages),
counts distinct message IDs for sent/received totals, and keeps group chats separate.
Reactions and system/associated events are reported separately. Unknown and ambiguous
identities remain separate rather than being guessed. Dates are UTC.

Counts describe history available on this Mac, not necessarily all iCloud history
or the other participant's history. The report audits orphan records and overlaps.
Source schemas are internal Apple formats; inspect them again if an OS change causes
the counter to fail. Missing Full Disk Access is an access boundary, not a reason to
modify database permissions.

Report card: [messages-counts](../../features/messages-counts.feature).

