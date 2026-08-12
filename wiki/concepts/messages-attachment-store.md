---
description: How ~/Library/Messages/Attachments really works, why chat.db sizes lie, and the only safe way to delete an attachment when Messages in iCloud is on.
---

# Messages attachment store

The on-disk backing for iMessage/SMS attachments, at `~/Library/Messages/Attachments`.
Measured on this Mac 2026-08-12: **105,018 files / 141.1 GB**, with `chat.db` itself
another 963 MB — 153 GB total, against 52 GB free on the boot volume.

Tool: [`bin/messages-attachments`](../../bin/messages-attachments) — read-only inventory
by real on-disk size, joined to the conversation. `--why` prints the deletion rules.

## Layout

```
Attachments/<xx>/<yy>/<GUID>/<file>
Attachments/<xx>/<yy>/at_<n>_<GUID>/<file>
```

`<xx>/<yy>` are hash-bucket directories. **Every attachment gets its own GUID
directory**, normally holding exactly one file. The `at_<n>_` prefix appears on
attachments that arrived as part of a multi-part transfer.

The GUID directory — not the filename — is the attachment's durable identity.

## Trap 1: `attachment.total_bytes` lies, sometimes by 8000x

`chat.db`'s `total_bytes` records the size negotiated at transfer time, not what
landed on disk. Verified counter-examples:

| File | DB says | On disk | Error |
|---|---|---|---|
| `IMG_6510.MOV` | 86.1 KB | 695.8 MB | 8279x |
| `…upscayl_16x…png` (copy A) | 394.4 KB | 776.8 MB | 2017x |
| `IMG_9056.MOV` | 1.0 MB | 435.2 MB | 424x |
| `…upscayl_16x…png` (copy B) | 5.4 MB | 776.8 MB | 144x |

**Any inventory that sorts by `total_bytes` hides the worst offenders.** Always
`stat` the filesystem and use the DB purely as a lookup table. This is also why the
System Settings storage panel can rank things oddly — cross-check it.

## Trap 2: three independent reasons a filename join fails

Joining disk paths to `attachment.filename` by string equality silently invents
"orphans". All three of these were hit in sequence on one machine:

1. **Case.** DB holds `IMG_6510.mov`; disk holds `IMG_6510.MOV`. APFS is
   case-insensitive, so they are one file.
2. **Unicode form.** APFS returns NFD-decomposed names where the DB holds NFC —
   splits every filename containing `ä`/`ö`.
3. **Rename.** The DB frequently keeps the sender's transfer name (`IMG_7134.mov`)
   while the file landed under its own UUID (`E1629902-….mov`) in the same directory.

(3) is fatal to any filename-based join. **Key on the normalised GUID directory.**

Cost of learning this the hard way: a naive full-path join reported 16.5 GB of
orphans; case+Unicode normalisation cut it to 10.9 GB; a spot-check found **100% of
those were false** — live attachments. Directory-keying gives the true figure: 5 files,
548 KB. There is essentially no orphan garbage in this store. Verify before deleting.

## The deletion rules (Messages in iCloud ON)

Check first — `CloudKitSyncingEnabled = 1` means the store is a CloudKit replica:

```bash
defaults read ~/Library/Preferences/com.apple.madrid.plist | grep CloudKitSyncingEnabled
```

- **Do not `rm` a linked attachment.** The `attachment` row survives, so the
  conversation shows a message whose file is missing, and since the attachment still
  exists in iCloud nothing is freed there and it can come back down. Futile rather
  than destructive — but not the fix.
- **Never edit `chat.db`.** Deleting rows with sqlite produces no CloudKit tombstone,
  so iCloud still holds the attachment and can reconcile the edit away. It also risks
  inconsistent `message_attachment_join` state. No supported repair exists.
- **`rm` is safe only for true orphans** — no `attachment` row references the GUID
  directory. On this Mac that is ~548 KB of leftover stickers. Not a lever.

## No automation path exists

`sdef /System/Applications/Messages.app` exposes exactly three commands — `send`,
`login`, `logout` — and classes `participant`, `account`, `chat`, `file transfer`.
**There is no attachment class and no delete verb.** No AppleScript, ASObjC, or
Shortcuts route to deleting an attachment. This is a hard ceiling, not a gap in our
tooling — a genuine [WWSD](../entities/sal-soghoian.md) pain point worth logging in
`painpoints/`.

The supported surfaces, all of which write the tombstone and stay consistent:

1. **System Settings ▸ General ▸ Storage ▸ Messages** — sorted list, delete button.
   Fastest for bulk.
2. **Conversation ▸ ⌘I ▸ attachments grid ▸ right-click ▸ Delete** — precise, one at a time.
3. **Messages ▸ Settings ▸ General ▸ Keep messages ▸ 30 Days / 1 Year** — blunt and
   automatic; deletes messages, not just files.

## Duplicates

The same file is commonly stored once per conversation it was sent to — sending one
video to three people costs three copies. 4.0 GB of byte-identical duplication among
files ≥100 MB on this Mac; one 777 MB PNG is stored twice for 1.55 GB. Deduplication
is not possible without deleting from one of the conversations. `--dupes` lists them.

## Related

- [`wiki/concepts/mail-app-internal-behaviors.md`](mail-app-internal-behaviors.md) — the equivalent gotcha list for Mail
- [`wiki/concepts/imessage-from-terminal.md`](imessage-from-terminal.md) — sending, which *is* scriptable
