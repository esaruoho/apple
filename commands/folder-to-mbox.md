---
description: Turn any folder of email-shaped files (BBS dumps, .eml, .mbox, .txt, .md) into an Apple-Mail-importable mailbox bundle hierarchy. Apple-native Python stdlib, zero round-trip, programmatic. Usage `/folder-to-mbox <input-dir> [<output-dir>] [--group-by folder|sender|year|year-month|source|none] [--format auto|bbs|eml|mbox|email-headers|plain] [--mailbox-name "Name"]`.
allowed-tools: Bash
argument-hint: <input-dir> [<output-dir>] [--group-by ...] [--format ...] [--mailbox-name "..."]
---

# /folder-to-mbox

You came across a directory of saved emails / BBS dumps / message archive — hundreds, thousands, hundreds of thousands of text files. You want to read them in Apple Mail. You shouldn't have to write Python.

This command turns any folder of email-shaped files into a proper Apple-Mail-importable mailbox bundle hierarchy. Drag into Mail, import, done.

## Supported input formats (auto-detected per file)

- `*.eml` — RFC 5322 email files
- `*.mbox` — classic Unix mbox (concatenated, `From ` separators)
- `*.txt`, `*.md` — BBS-style dumps (KeelyNet `Message NNNNN ... DATE/TIME:` headers)
- `*.txt`, `*.md` — RFC 5322 headers at top
- `*.txt`, `*.md` — plain text (one message per file, filename = subject, mtime = date)

## Examples

```bash
# auto-detect, single mailbox bundle
/folder-to-mbox ~/archives/keelynet

# BBS dump, grouped by BBS Folder field, with custom mailbox name
/folder-to-mbox ~/archives/keelynet ~/output \
    --format bbs --group-by folder \
    --mailbox-name "KeelyNET Message Archive"

# Folder of .eml files exported from somewhere, grouped by year-month
/folder-to-mbox ~/exported-mail --group-by year-month

# Group all messages by sender so you have one mailbox per person
/folder-to-mbox ~/archive --group-by sender
```

## Output structure

```
<output>/<Mailbox-Name>/                      (plain parent folder)
├── <Group1>.mbox/                            (Apple Mail bundle)
│   ├── Info.plist
│   └── mbox
├── <Group2>.mbox/
│   ├── Info.plist
│   └── mbox
...
```

## Apple Mail import

`Mail.app → File → Import Mailboxes… → Files in mbox format → select the parent folder → Continue.` Mail discovers all sub-bundles and offers each as a separate mailbox.

Or double-click any individual `.mbox` bundle inside that folder to import just one group.

## Implementation

Pure Python stdlib (Apple-skill pedigree rule — no Homebrew, no pip). Script: `~/work/apple/bin/apple-folder-to-mbox`. Wiki concept: [`wiki/concepts/text-to-mailbox-bundle.md`](../wiki/concepts/text-to-mailbox-bundle.md).

## Run

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/apple-folder-to-mbox $ARGUMENTS
```

After completion, report the summary table verbatim + the Apple Mail import instruction.
