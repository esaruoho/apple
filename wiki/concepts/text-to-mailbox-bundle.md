---
description: How to turn any folder of email-shaped text files into an Apple-Mail-importable mailbox bundle hierarchy. Apple-native Python stdlib pipeline. The Sal-ethos answer to "I have 30,000 emails as text files, how do I read them in Mail.app?"
---

# Text → Apple Mail Mailbox Bundle

## The painpoint

You inherited / saved / exported a folder of email-shaped text content:

- A BBS dump (KeelyNet-style `Message NNNNN ... DATE/TIME: ...` records, hundreds of messages glued into one file)
- A folder of `.eml` files exported from Thunderbird / mutt / some other client
- A `.mbox` file you got off a backup tape
- A folder of `.txt` or `.md` files with email-style headers
- A folder of plain text files where each file is one message

You want to read this in Mail.app. You want to search it, thread it, filter it, export it back out. **You shouldn't have to write Python to do that.**

This is exactly the Mac-user pain Sal Soghoian's role existed to relieve. The Automator/Image Events/Folder Actions pattern for documents-and-folders, applied to email archives.

## The Apple Mail `.mbox` bundle format

Apple Mail's `.mbox` is **not a file**. It's a directory bundle (a "package") containing:

```
SomeMailbox.mbox/        (directory, with .mbox extension)
├── Info.plist           (XML metadata)
└── mbox                 (the actual flat mbox file, no extension)
```

When the `.mbox` extension is on a directory containing this structure, macOS treats it as a single document and Finder renders it as one icon. Double-click routes to Mail.app via the `.mbox` UTI. Mail's "Import Mailboxes → Files in mbox format" workflow walks a parent directory looking for these bundles.

**Common mistake**: writing a flat `.mbox` file with just the Unix-style mbox content. Mail can sometimes import that via the "Files in mbox format" flow, but double-click won't route, and Finder shows it as a generic "document" with no app association.

## The pipeline

`apple-folder-to-mbox` in `~/work/apple/bin/` implements the full chain:

1. **Walk the input directory** recursively for `*.eml`, `*.mbox`, `*.txt`, `*.md`, `*.msg`.
2. **Auto-detect format per file**:
   - `.eml` extension or RFC 5322 headers at top → email parser
   - `.mbox` extension or `^From <addr> <day>` separators → mbox splitter
   - BBS pattern (`Message NNNNN ... DATE/TIME: ...` + `====` separators) → BBS parser
   - Plain text → one-message-per-file (filename = subject, mtime = date)
3. **Parse into normalized message records**: `{sender, recipient, subject, date, body, folder, source_file}`.
4. **Group** by selected strategy:
   - `none` — single mailbox
   - `folder` — by source-folder field (BBS Folder header) or source-directory
   - `sender` — one mailbox per From: address
   - `year`, `year-month` — chronological splits
   - `source` — one mailbox per source file
5. **Write the bundle hierarchy**:
   - Parent: plain directory named after `--mailbox-name`
   - Children: `<group>.mbox/` Apple Mail bundles (Info.plist + mbox)
6. **Import**: `Mail.app → File → Import Mailboxes → Files in mbox format → parent dir → Continue`.

## CLI

```
apple-folder-to-mbox <input-dir> [<output-dir>] [options]

  --mailbox-name <name>    top-level mailbox name (default: input dir basename)
  --group-by <strategy>    none / folder / sender / year / year-month / source
  --format <fmt>           force a format instead of auto-detection
                           (auto / bbs / eml / mbox / email-headers / plain)
  --domain <domain>        synthetic email domain for messages lacking one
  --quiet                  suppress progress output
```

## Slash command

`/folder-to-mbox` — zero-roundtrip pointer to this tool. See `commands/folder-to-mbox.md`.

## Pedigree

**Python stdlib only.** `email`, `email.policy`, `email.utils`, `email.message.EmailMessage`, `unicodedata`, `re`, `pathlib`, `argparse`, `hashlib`, `datetime`. No Homebrew, no pip, no third-party. Apple-native rule satisfied.

## Implementation notes

- **mbox `From ` escape**: per the classic Unix mbox spec, any literal `From ` at the start of a line in a message body must be escaped to `>From ` to avoid being parsed as a separator. Tool handles this automatically.
- **Synthetic email addresses**: BBS messages don't have email addresses — they have names like `NORMAN WOOTAN` and `JERRY DECKER (SYSOP)`. Tool synthesizes addresses like `norman-wootan@archived.local` so Mail.app's address-book-grouping and threading still work.
- **`X-Archive-*` headers**: preserve original BBS metadata (folder, source file, original message ID, raw datetime) on each generated email so the archive provenance survives the import. Searchable inside Mail via Search → "Entire Message".
- **Idempotent**: re-running with the same `<output-dir>` clears the target mailbox folder and rebuilds. No stale artifacts.

## When to reach for it

- Triggers: "I have N text files, turn it into a mailbox", "ingest these emails", "make an mbox", "archive of saved emails", "import this folder into Mail", "30000 emails as text files".
- WWSD: would Sal have shipped a Folder Action / Automator workflow for this? Yes. Now we have it.
- Cross-skill: the merlib-dump archive at `~/work/merlib-dump/sources/norman-wootan/` was the first user — KeelyNet BBS dumps from 1994-1995, 2,509 messages parsed across 6 BBS folders, importable into Mail with one command.

## Cross-references

- `bin/apple-folder-to-mbox` — the script
- `commands/folder-to-mbox.md` — slash command
- `painpoints/MAIL-002-no-bulk-ingest-for-saved-text-archives.md` — the painpoint this solves
- `mail-exporter/` — Mail's bulk metadata export side (the inverse pipeline: Mail → text)
