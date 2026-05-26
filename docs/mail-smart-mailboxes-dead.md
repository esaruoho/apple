---
layout: default
title: "Mail Smart Mailboxes — READ-ONLY in practice"
---

# Mail Smart Mailboxes — READ-ONLY in practice


[← Back to home](./)
**Do not write to `~/Library/Mail/V*/MailData/SyncedSmartMailboxes.plist` and expect Mail to honour it.** Mail keeps its own in-memory canonical version and overwrites the on-disk plist within ~1 second of launch, even when Mail was fully quit during the write. The "Synced" prefix in the filename is real — it's reconciled against Mail's own canonical state on launch.

## The empirical proof (2026-05-13)

1. Quit Mail (`pgrep -x Mail` returns nothing).
2. Append a `from` criterion to "Free Energy" smart mailbox using `plistlib`. File grew 12597 → 12835 bytes, mtime 09:29:06, new sender visible via re-read.
3. Relaunch Mail.
4. ~17 seconds later, file shrunk back to 12597 bytes, mtime jumped to 09:29:23 (Mail's write), criterion gone.

Same outcome whether the script initiated the quit or the user did it manually. An earlier draft of `mail-exporter` had `add-from / remove-from / human-digest` write commands that all reported success; they were demonstrably broken because the only verification was reading the same file we wrote, not checking whether Mail honoured it after launch. Code stripped.

## What works (read)

- `mail-exporter smartboxes list / show / dump / export / diff` — pure reads against the plist.
- **Decoded criterion schema:** `NotInTrash`, `NotInJunk`, `NotInASpecialMailbox` + `SpecialMailboxType`, `InSpecialMailbox`, `DateLastViewed` / `DateReceived` / `DateSent` + `Qualifier` + `Expression` + `DateUnitType`, `Compound` (recursive AND/OR groups with `AllCriteriaMustBeSatisfied`), generic `Subject` / `From` / `Body` + `Qualifier` + `Expression`.
- `MailboxType=7` is the smart-mailbox sentinel.
- `SpecialMailboxType`: 0 = Inbox, 1 = Drafts, 2 = Outbox, 3 = Sent, 4 = Trash, 5 = Junk, 6 = Archive.
- `DateUnitType`: 1 = day, 2 = week, 3 = month, 4 = year.

## What does NOT work (write)

- Raw plist edits (any tool, any quit-and-write dance).
- `AppleScript make new smart mailbox` — `mail.sdef` has no smart-mailbox class. Confirmed by grep on `dictionaries/mail/mail.sdef.xml`.

**The only viable write path:** UI-scripting Mail's "Edit Smart Mailbox" sheet via System Events. Drives Apple's own dialog so Mail's own iCloud-aware write fires. Not yet built.

## Predicate inventory (from the actual UI dropdown, 2026-05-13)

Entire message, From, Any recipient, Subject, Date received, Date last viewed, Account, Sender is VIP, Sender is member of group, Message is flagged / unflagged / read / unread, Priority low / normal / high, Message has flag, Message was / not replied to, Message is / is not in mailbox, Contains attachments, Any attachment name, Attachment type.

**NO "Sender is in my Contacts" predicate. NO "Message is addressed to a mailing list" predicate.** Both were fabrications in earlier specs.

## How this generalises

This is a **Tier-5-flavoured trap**: the data is visible AND editable on disk, but the app refuses to honour external writes. Distinct from Stickies (where quit-then-write works) and Vocal Shortcuts (where quit-then-write works). **Test before assuming the [Tier 5 backdoor](tier-5-backdoor.md) generalises** — Mail is the counter-example.

## Companion docs

`analysis/mail/smart-mailboxes.md` (diagnostic + schema), `human-digest-logic.md`, `human-only-expansion-list.md`, `raw-source-forensics.md`.
