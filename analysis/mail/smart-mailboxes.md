# Mail Smart Mailboxes — Read / Edit / Write Analysis

Written 2026-05-13. Apple's official `Mail.app` Smart Mailbox model, what
the scripting dictionary covers, what it doesn't, where the data actually
lives on disk, and which read/edit/write paths are viable today.

## TL;DR

| Operation | Viable? | Path |
|-----------|---------|------|
| **Read** smart mailbox definitions | ✅ Yes | `plutil` / `PlistBuddy` against `SyncedSmartMailboxes.plist` |
| **Read** per-mailbox UI state (sort, filters, unread count) | ✅ Yes | `SmartMailboxesLocalProperties.plist` |
| **Edit/write** smart mailbox definitions | ❌ Not via raw plist | iCloud sync reverts on Mail relaunch — UI scripting only |
| **AppleScript create/modify** a smart mailbox | ❌ **No** | Mail.sdef has zero `smart mailbox` class / property |
| **Reference** an existing smart mailbox by name from AppleScript | ⚠️ Sometimes | `mailbox "Name"` may resolve, but criteria invisible |

The Mail scripting dictionary models `mailbox`, `account`, `rule`, `rule condition` — but **Smart Mailboxes are absent**. They are a UI-only feature backed by a plist. So you cannot create or modify their criteria via AppleScript/JXA. You CAN read and rewrite the plist directly.

## Your current smart mailboxes (6)

From `~/Library/Mail/V10/MailData/SyncedSmartMailboxes.plist`:

1. **Today** — date-last-viewed within ±1 day, omit trash/sent/junk
2. **Junky Junk Smartbox** — InSpecialMailbox 5 (Junk)
3. **All Unread**
4. **iCloud Junk**
5. **Bandcamp Contacts**
6. **Free Energy**

## Storage map

`~/Library/Mail/V10/MailData/` (V10 == macOS Sequoia Mail container version):

| File | Purpose | Sync? |
|------|---------|-------|
| `SyncedSmartMailboxes.plist` | Definitions: name, ID, criteria tree, MailboxType=7 | iCloud-synced across Macs |
| `SmartMailboxesLocalProperties.plist` | Per-Mac UI state: sort order, filters, focus, unread count, scroll position | Local only |
| `SyncedRules.plist` / `UnsyncedRules.plist` | Mail rules (similar criteria schema, separate file) | Mixed |
| `FlagMailboxes.plist` | Flag-color virtual mailboxes | — |
| `VIPMailboxes.plist` + `VIPs.plist` | VIP sender list | — |
| `Envelope Index` | SQLite message index (NOT smart-mailbox config) | Local |

## Definition schema (SyncedSmartMailboxes.plist)

Each smart mailbox is a dict with:

```
MailboxID                          UUID (string)
MailboxName                        Display name
MailboxType                        7  (smart mailbox sentinel)
MailboxAllCriteriaMustBeSatisfied  1 = AND, 0 = OR (top-level)
MailboxChildren                    Array of nested smart mailboxes
MailboxCriteria                    Array of criterion dicts
IMAPMailboxAttributes              Bit flags (17 typical)
```

### Criterion dict shape

Every criterion has `CriterionUniqueId` (UUID) + `Header` (predicate kind).
The Mail criteria DSL uses these `Header` values (observed in your plist):

- `NotInTrashMailbox` — implicit "omit trash" filter
- `NotInASpecialMailbox` + `SpecialMailboxType` (int) — omit Drafts/Sent/Junk/etc.
- `InSpecialMailbox` + `SpecialMailboxType` — match a special mailbox
- `NotInJunkMailbox` — omit junk
- `DateLastViewed` + `Qualifier` + `Expression` + `DateIsRelative` + `DateUnitType` — date predicates
- `Compound` — nested group with `Criteria` array + `AllCriteriaMustBeSatisfied`
- Standard headers (not in your file but documented): `From`, `To`, `Cc`, `Subject`, `MessageContent`, `Sender`, `MessageIsRead`, `MessageIsFlagged`, `MessageHasAttachments`, `AccountID`, `EveryMessage`

### SpecialMailboxType constants (Mail.framework)

| Int | Meaning |
|-----|---------|
| 0 | Inbox |
| 1 | Drafts |
| 2 | Outbox |
| 3 | Sent |
| 4 | Trash |
| 5 | Junk |
| 6 | Archive |

### Qualifier values (for non-date criteria)

`Contains`, `DoesNotContain`, `Is`, `IsNot`, `BeginsWith`, `EndsWith`,
`IsGreaterThan`, `IsLessThan` (dates), `IsInTheLast` / `IsNotInTheLast`
(date with `DateIsRelative=1`).

`DateUnitType`: 1 = day, 2 = week, 3 = month, 4 = year.

## Read recipes

### List smart mailbox names

```bash
plutil -p ~/Library/Mail/V10/MailData/SyncedSmartMailboxes.plist \
  | grep 'MailboxName ='
```

### Convert to JSON for downstream tooling

```bash
plutil -convert json -o - \
  ~/Library/Mail/V10/MailData/SyncedSmartMailboxes.plist \
  | jq '.[] | {name: .MailboxName, id: .MailboxID, criteria: .MailboxCriteria}'
```

### Show criteria for one mailbox by name

```bash
plutil -convert json -o - \
  ~/Library/Mail/V10/MailData/SyncedSmartMailboxes.plist \
  | jq '.[] | select(.MailboxName == "Free Energy")'
```

### Per-mailbox UI state (sort/filter/unread)

```bash
plutil -p ~/Library/Mail/V10/MailData/SmartMailboxesLocalProperties.plist
```

Each entry has `MailboxUnreadCount`, `MailboxUserInfo.SortOrder`
(`received-date`, `from`, `subject`, ...), `SortedDescending`,
`SelectedFilters` (e.g. `Unread`), `FocusEnabled`, `DisplayInThreadedMode`.

## Edit / write — raw plist write DOES NOT STICK (2026-05-13 finding)

**Empirical correction.** An earlier draft of this document claimed raw
plist edits work if Mail is quit first. That claim was wrong. Tested in
production on 2026-05-13:

1. Quit Mail (confirmed via `pgrep -x Mail` returning nothing).
2. Append a `from` criterion to `SyncedSmartMailboxes.plist` with a fresh
   UUID and `Header=from`. The file on disk now contains 7 senders.
3. Re-read the file with our own tool — confirms 7 senders.
4. Relaunch Mail.
5. Open Mail → Mailbox → Edit Smart Mailbox on "Free Energy" — Mail's UI
   shows only the original 6 senders. The 7th is gone.
6. Re-read the file again — it is back to 6 senders. Our edit was
   reverted somewhere in Mail's relaunch sequence.

Most likely cause: the `Synced` prefix in the filename is real — the
file is reconciled against an iCloud / CloudKit canonical version when
Mail launches. Local edits made while Mail is quit lose to the cloud
state. The same constraint almost certainly applies to `SyncedRules.plist`
and other `Synced*.plist` files in `MailData/`.

**Implication:** the `mail-exporter smartboxes add-from / remove-from /
create` commands in the codebase currently produce confirmable WRITES to
the local plist, but those writes do not survive Mail's next launch.
Until a working write path is found, treat the smart-mailbox API as
**read-only in practice**.

### Paths still worth trying

- **UI scripting Mail's Smart Mailbox sheet** via System Events. Drives
  the same dialog the user clicks through; Mail then performs its own
  iCloud-aware write. Slow and fragile (depends on the dialog layout)
  but goes through the supported write path.
- **Disable iCloud Mail temporarily**, do the plist edit, re-enable.
  Disruptive — not a real workflow tool.
- **Investigate whether `notifyutil -p` of a specific channel makes Mail
  reload from disk** rather than from cache.
- **Check the `EMUbiquitouslyPersistedDictionary-*.plist` files** — Mail
  uses them for similar reconcilable state; maybe there's a write API.

### Historical (does-not-work) recipe

1. `osascript -e 'tell application "Mail" to quit'`
2. Wait until process is gone (`pgrep -x Mail` returns nothing)
3. Back up the plist: `cp ...SyncedSmartMailboxes.plist ...SyncedSmartMailboxes.plist.bak`
4. Edit via `/usr/libexec/PlistBuddy` or rewrite via `plutil -convert json` round-trip
5. Relaunch Mail; verify the smart mailbox appears with intended criteria

Notes:

- Generate fresh UUIDs (`uuidgen`) for `MailboxID` and every
  `CriterionUniqueId` on inserts — duplicates confuse Mail.
- `MailboxType` must be `7` for it to render as a smart mailbox.
- iCloud sync will propagate changes to your other Macs within minutes.
- This is the same approach as the established Vocal Shortcuts / Stickies
  pattern in the apple skill: quit the app, edit the store, relaunch.

## AppleScript / sdef gap

Confirmed by grepping `dictionaries/mail/mail.sdef.xml`: **zero matches
for "smart"**. Classes Mail exposes:

`mailbox`, `account` (+ `imap account`, `iCloud account`, `pop account`),
`smtp server`, `rule`, `rule condition`, `message`, `recipient`,
`signature`, `outgoing message`, `message viewer`.

So:

- ❌ `make new smart mailbox ...` — does not exist
- ❌ Smart mailbox criteria are not exposed
- ⚠️ `mailbox "Free Energy"` may resolve as a normal `mailbox` reference,
  letting you read its `messages` (the *result set*), but you cannot
  inspect or change the criteria.

This matches the broader Tier-5 "back-door" pattern: Apple shipped the UI
feature, never expanded the sdef, so the only programmable surface is
the plist on disk.

## Recommended next moves

If you want a Sal-style fat-tool here:

1. **`mail-exporter smartboxes list`** — read both plists, emit one md
   file per smart mailbox with criteria + current unread count + sort
   state. Pure read-only, no Mail-quit required (plists are stable
   between Mail launches; just last-saved snapshot).
2. **`mail-exporter smartboxes show <name>`** — pretty-print one
   smart mailbox's full criteria tree, decoded.
3. **`mail-exporter smartboxes diff`** — snapshot + diff over time, to
   notice when iCloud sync changes criteria from another Mac.
4. **`mail-exporter smartboxes create / edit`** (write-side, Phase 2) —
   quit Mail, mutate plist with auto-backup, relaunch. Mirror the
   `bin/avs-prefs-write.py` pattern (list/dump/backup/restore/add/remove
   + auto-backup on every write).

The read side ships immediately. The write side needs the same
quit-app-edit-relaunch dance Vocal Shortcuts uses.
