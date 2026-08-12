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
`stat` the filesystem and use the DB purely as a lookup table.

### Apple's own Storage panel is one of the victims

System Settings ▸ General ▸ Storage ▸ Messages **decides what to list using
`total_bytes`, then displays and sorts by the real on-disk size.** Evidence from
this Mac, 2026-08-12:

- Every row visible in the panel had `total_bytes` between 233 and 758 MiB.
- Every genuinely-huge file missing from it had a tiny `total_bytes` — the 776.8 MiB
  PNG (recorded 5.4 MiB and 0.39 MiB for its two copies), `IMG_6510.MOV` (0.08 MiB),
  `Tomas Potkulautailee….mp4` (38.1 MiB), `IMG_2051.MOV` (1.45 MiB).
- The displayed sizes decreased monotonically and matched `stat` output in decimal
  MB (757.7 MiB shown as 794.5 MB), so display and sort use the filesystem — only
  the inclusion test uses the DB.

Threshold is bounded by observation to **>38.1 MiB and ≤233.5 MiB** of `total_bytes`;
100 MB is the natural guess but is not confirmed.

Consequence: **of 53 files ≥100 MB on disk (12.3 GB), the panel showed 27 (4.8 GB)
and hid 26 (7.4 GB)** — it conceals more than it reveals, and the single largest file
in the entire store is unreachable through it. Anything hidden this way must be
deleted from the conversation's ⌘I grid instead. Use `bin/messages-attachments` to
find out what the panel is not telling you.

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

## The two stores nothing shows you

Messages keeps 33 GB outside the attachment tree, in places no UI lists and iCloud
never touches. Measured 2026-08-12:

| Store | Files | Size | Status |
|---|---|---|---|
| `~/Library/Containers/com.apple.MobileSMS/Data/tmp/TemporaryItems` | 11,930 | 21.9 GB | scratch |
| `~/Library/Messages/Caches` | 22,411 | 10.8 GB | regenerable |

**Neither is CloudKit-backed**, so unlike the attachment store, `rm` is the correct
tool here — no tombstone required, nothing to reconcile.

`Caches/Previews` is 20,234 `.ktx` GPU textures, the thumbnails drawn in conversation
view. Derived from attachments, regenerated on demand. Zero rows in `chat.db` reference
it. Deleting costs a re-render.

`TemporaryItems` gives every file its own random-GUID directory — the shape of a
scratch dir. Messages copies an attachment here when it composes, previews, or
QuickLooks, then never returns for it. 15.35 GB of it had not been touched in over a
year; one 776.8 MiB PNG was present **three times** with a sha256 identical to the copy
in the attachment store.

### Is everything in TemporaryItems deletable?

Effectively yes, and the reason is the container contract, not a file-by-file audit.
`Data/tmp` is the app's `NSTemporaryDirectory()`. macOS documents container `tmp` as
purgeable — the system may clear it when the app is not running, so **no app is
permitted to depend on anything surviving there**.

There is one wrinkle worth knowing. 48 files in `TemporaryItems` *are* referenced by
`attachment` rows — Messages relying on something the contract says it cannot. They
total 17.9 MB, the largest is 4.0 MB, and every one belongs to a message dated
2025-09 or later, well inside the Messages-in-iCloud era. So even deleting those costs
at most a re-download, not data loss.

`bin/messages-attachments --strays` excludes them anyway, matching on both exact path
and containing directory. Practical rule: **delete freely in `TemporaryItems`; use
`--strays` if you want the 0.4% respected without thinking about it.**

Do not confuse this directory with `~/Library/Messages/Attachments`, where the opposite
rule applies — see the deletion rules above.

## Duplicates

The same file is commonly stored once per conversation it was sent to — sending one
video to three people costs three copies. 4.0 GB of byte-identical duplication among
files ≥100 MB on this Mac; one 777 MB PNG is stored twice for 1.55 GB. Deduplication
is not possible without deleting from one of the conversations. `--dupes` lists them.

## Related

- [`wiki/concepts/mail-app-internal-behaviors.md`](mail-app-internal-behaviors.md) — the equivalent gotcha list for Mail
- [`wiki/concepts/imessage-from-terminal.md`](imessage-from-terminal.md) — sending, which *is* scriptable
