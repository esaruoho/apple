---
app: Mail.app
painpoint_id: MAIL-002
title: No bulk-ingest path for saved-as-text email archives
severity: high
resolved_by: bin/apple-folder-to-mbox + commands/folder-to-mbox.md
date_logged: 2026-05-26
---

# MAIL-002 — No bulk-ingest path for saved-as-text email archives

## The pain

You retain communications. Years of them. They live on disk as:
- `.eml` files exported from past email clients
- `.mbox` flat files from old Thunderbird / mutt / pine
- Forum dumps, BBS captures, archive scrapes — `.txt` or `.md` files with email-shaped records
- One-message-per-file plain text

You want to read this in Mail.app. You want it searchable, threadable, sortable, exportable back out via Mail's existing tools. The data should live as **mail**, not as a folder of opaque files.

Mail.app's official import path is `File → Import Mailboxes…` with these options:
- Apple Mail (different version)
- mbox files
- Microsoft Outlook for Mac (.olm)
- Outlook for Windows (.pst)
- Eudora
- Entourage
- Thunderbird

Notably absent: **a folder of `.txt` / `.md` files, or anything BBS-shaped, or anything that isn't already in one of the half-dozen blessed formats.**

The "Files in mbox format" option works, but it requires the folder to be an Apple-Mail `.mbox` *bundle directory* with the exact internal structure (`Info.plist` + `mbox` file inside). Most users have flat files or directories of `.eml`, which Mail won't auto-discover.

## What users actually do

1. Give up and let the archive rot on disk unread.
2. Open one file at a time in a text editor when they need to find something.
3. Pay for a third-party tool (Postbox, MailMate) that has more import flexibility.
4. Write a Python script using the `mailbox` stdlib module + manual `Info.plist` generation.

Options 1-3 are user-hostile. Option 4 is the WWSD-correct answer, but **it shouldn't be on the user to write the Python**. This is exactly the kind of folder-batch transform that Sal's Automator/Image Events/Folder Actions tradition would have handled with a one-click workflow.

## What Apple should ship (and doesn't)

A `File → Import Mailboxes → Folder of email files` option that:
- Recursively walks a directory
- Auto-detects file format per file (`.eml`, flat `.mbox`, `.txt` with headers, etc.)
- Generates the Apple-Mail bundle structure automatically
- Optionally groups by sender / date / source-subdirectory

This is straightforward engineering. Mail has the parser (it uses `MFMessage`), has the bundle writer (it manages `~/Library/Mail/V*/...`), has the import UI. Connecting these three pieces is a small Apple-internal patch. It does not exist.

## The Apple-skill replacement

`bin/apple-folder-to-mbox` does what Apple should have shipped. Python stdlib only (apple-native rule satisfied — no Homebrew / no pip).

```
apple-folder-to-mbox <input-dir> [<output-dir>] \
    [--mailbox-name "Name"] \
    [--group-by none|folder|sender|year|year-month|source] \
    [--format auto|bbs|eml|mbox|email-headers|plain]
```

Output: parent folder containing N Apple-Mail `.mbox` bundles, ready for Mail's `File → Import Mailboxes → Files in mbox format → select parent folder` flow.

Wiki: [`wiki/concepts/text-to-mailbox-bundle.md`](../wiki/concepts/text-to-mailbox-bundle.md). Slash: `/folder-to-mbox`.

## Test cases proven 2026-05-26

| Input | Format | Messages | Groups |
|---|---|---|---|
| `merlib-dump/sources/norman-wootan/` | BBS (KeelyNet) | 2,509 | 7 folders |

## Cross-references

- Wiki concept: `wiki/concepts/text-to-mailbox-bundle.md`
- Slash command: `commands/folder-to-mbox.md`
- Mail's metadata side: `mail-exporter/` (the inverse — Mail → text catalog)
- Sal-archive analog painpoints: `painpoints/NOTES-001-record-audio.md` (Notes can record audio but can't export it bulk), `painpoints/SCREENSHOT-001-no-scripting-for-screen-capture.md` (similar shape: official path exists, but no programmatic bulk).
