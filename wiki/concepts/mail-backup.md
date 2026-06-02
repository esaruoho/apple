---
title: Mail.app pristine backup — single-account snapshot
type: concept
related:
  - mail-app-internal-behaviors
  - mail-rowid-flip-on-move
  - mail-flag-pipeline
  - text-to-mailbox-bundle
---

# Mail.app pristine backup — single-account snapshot

**Tool:** `bin/backup-mailbox` · **Slash:** `/backup-mailbox` · **First built:** 2026-05-27

A pristine backup of a Mail.app account is a recursive copy of its V10 directory:

```
~/Library/Mail/V10/<account-UUID>/
  INBOX.mbox/
  [Gmail].mbox/                 # for Gmail IMAP — All Mail, Sent Mail, Drafts, etc.
  <custom-folder>.mbox/
  ...
```

Each `.mbox` is a folder containing `Info.plist` + `<random>/Data/<hash-buckets>/Messages/<n>.emlx`. An `.emlx` file is RFC822 source + an Apple-specific plist trailer. Restoring is just dropping the V10 dir back under `~/Library/Mail/V10/` on any Mac and relaunching Mail.

## Why pristine ≠ exported

| | Pristine V10 copy | File → Export Mailbox… (`.mbox`) |
|---|---|---|
| Format | Apple `.emlx` (RFC822 + trailer) | Unix `mbox` (single concatenated file) |
| Restores into Mail.app | yes, drop-in | yes, via Import Mailboxes |
| Portable to Thunderbird/mutt | with conversion | yes, native |
| Preserves Mail's read flags, labels, internal state | yes | partial |
| Includes attachments | yes (inline `.emlx`) | yes (inline) |

For an active backup you want to be able to roll back to, **pristine wins**. For long-term archive in tools that aren't Mail.app, export mbox.

## The two gotchas

### 1. Mail.app must be running when you resolve the UUID

Mail's scripting suite (`tell application "Mail" to get id of every account`) only answers while the process is live. If Mail isn't running, every property accessor errors with `-2741 ("Expected class name but found identifier")`. The `repeat with a in every account` loop form **never works** from `osascript -e` — it errors with the same code regardless of whether Mail is running. Use the flat-list form (`get name of every account` etc.) and zip the three lists yourself.

### 2. Quit Mail *after* you've resolved the UUID, *before* you rsync

`.emlx` files are written non-atomically. Snapshotting while Mail is syncing IMAP can leave you with a half-written message. Order:

1. Resolve account → UUID (Mail running).
2. Quit Mail and wait until `pgrep -x Mail` returns nothing.
3. `rsync -a ~/Library/Mail/V10/<UUID>/ <dest>/`.
4. Rename top-level `.mbox` folders.
5. Verify by counting `.emlx` in source vs dest.

`backup-mailbox` does all five.

## V10 UUID ↔ account mapping

The V10 directory UUIDs are **not** the same as the account UUIDs in `~/Library/Accounts/Accounts4.sqlite`. Mail.app maintains its own UUID per IMAP/POP store. The only reliable way to map them is `tell application "Mail" to get id of every account` — the IDs returned are the V10 directory names.

Orphan V10 directories (no longer attached to an active account) do exist — Mail's GC is lazy. They show up in `~/Library/Mail/V10/` but not in `Mail → get every account`. They're worth backing up separately if you want to preserve "Recovered Messages" folders.

## Gmail IMAP quirk

Gmail-via-IMAP exposes the All-Mail / Sent-Mail / Drafts / Spam / Starred / Important / Trash containers under `[Gmail]/`. Mail.app preserves the literal `[Gmail]` folder name on disk: `[Gmail].mbox/`. The `INBOX.mbox/` for a Gmail account is usually a thin shell — Gmail labels don't duplicate messages into INBOX, so the actual archive lives in `[Gmail].mbox/All Mail.mbox/`.

`backup-mailbox` slugifies `[Gmail]` → `gmail` in the rename pass, so you end up with `<prefix>-inbox.mbox` (empty for pure-Gmail accounts) and `<prefix>-gmail.mbox` (the real archive). That asymmetry is Gmail's, not the tool's.

## Companion rules

- `wiki/concepts/mail-app-internal-behaviors.md` — 12 internal-behavior gotchas (ROWID flips, virtual-folder hangs, AppleEvent queue semantics).
- `wiki/concepts/mail-rowid-flip-on-move.md` — why dedup must be by RFC822 `Message-ID`, not by `ROWID`.
- `wiki/concepts/mail-flag-pipeline.md` — flag-routing pipeline that reads `.emlx` directly.
- `wiki/concepts/text-to-mailbox-bundle.md` — companion exporter that turns any folder of email-shaped files into an importable mailbox bundle.
