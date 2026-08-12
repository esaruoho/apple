---
description: How ~/Library/Messages/Attachments really works, why chat.db sizes lie, and the only safe way to delete an attachment when Messages in iCloud is on.
---

# Messages attachment store

The on-disk backing for iMessage/SMS attachments, at `~/Library/Messages/Attachments`.
Measured on this Mac 2026-08-12, after a clearing pass: **104,961 files / 135.0 GB**,
with `chat.db` itself another 919 MB — 147 GB total, against 49 GB free on the boot
volume. The store was 141.1 GB / 105,018 files before the pass.

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

## Trap 1: `total_bytes` is the TRANSMITTED size, not the file on disk

**Corrected 2026-08-12.** This page previously said `total_bytes` "lies". It does not.
It faithfully records **what Messages actually sent**, which is frequently not the file
sitting on disk.

The proof came from one message. Esa sent an 814,483,067-byte PNG. iMessage would not
transmit it, so Messages compressed a JPEG, sent that, and kept his original attached to
the same message:

| Attachment | `is_outgoing` | `total_bytes` | on disk |
|---|---|---|---|
| the PNG | 1 | **5,664,632** | 814,483,067 |
| the JPEG | 0 | 5,664,632 | **5,664,632** |

`total_bytes` on the PNG equals the JPEG's byte count *exactly*. The number was never
wrong — it was answering a different question.

Consequences, in order of importance:

1. **The original is invisible.** Nothing renders it. The conversation shows the JPEG.
   Scrolling the transcript to the right date shows no bubble for it, because it was
   never part of the conversation. Hunting one by eye is impossible — a full day was
   lost to this before the mechanism was understood.
2. **It is often your only full-quality copy.** The recipient has the compressed
   version. You have the original, filed where no UI shows it. `Keep messages ▸ 1 Year`
   and whole-conversation deletes destroy these silently. On this Mac that is 8.57 GB
   across 43 conversations, mostly family video.
3. **Every size-based tool under-reports it**, including Apple's own Storage panel.

Tool: [`bin/messages-staged-originals`](../../bin/messages-staged-originals) — finds
them in four tiers, rescues before deleting, and only offers deletion of the tier it
can prove.

Other observed disagreements (cause not always the downscale path — incoming files
show it too, and those are a separate phenomenon):

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

Messages keeps ~30 GB outside the attachment tree, in places no UI lists and iCloud
never touches. Measured 2026-08-12:

| Store | Files | Size | Status |
|---|---|---|---|
| `~/Library/Containers/com.apple.MobileSMS/Data/tmp/TemporaryItems` | 11,915 | 18.8 GB | 99.2% duplicate — see the audit below |
| `~/Library/Messages/Caches` | 22,412 | 10.8 GB | regenerable |

**Neither is CloudKit-backed**, so unlike the attachment store, `rm` is the correct
tool here — no tombstone required, nothing to reconcile. That makes them *safe to
delete* in the sync sense; it does **not** make every file in them a duplicate. Read
"Is everything in TemporaryItems deletable?" below before any bulk pass.

`Caches/Previews` is ~20,200 `.ktx` GPU textures, the thumbnails drawn in conversation
view. Derived from attachments, regenerated on demand. Zero rows in `chat.db` reference
it. Deleting costs a re-render.

`TemporaryItems` gives every file its own random-GUID directory — the shape of a
scratch dir. Messages copies an attachment here when it composes, previews, or
QuickLooks, then never returns for it.

Ages, by creation time (birth and modify agree — no copied-timestamp artefact, so the
folder is genuinely stratified rather than mis-measured):

| Age | Files | Size |
|---|---|---|
| under 30 days | 61 | 0.07 GB |
| 30 days – 1 year | 5,340 | 6.11 GB |
| 1–3 years | 6,452 | 11.97 GB |
| over 3 years | 62 | 0.61 GB |

So it is **both** actively used and full of 2024 — say "12 GB of it is 1–3 years old",
never "the folder is untouched", which invites the obvious objection that there are
files from this week. One 776.8 MiB PNG was present **three times** with a sha256
identical to the copy in the attachment store; all three are now deleted.

### Is everything in TemporaryItems deletable? No — and "delete freely" was wrong

An earlier version of this page said the container contract settles it: `Data/tmp` is
the app's `NSTemporaryDirectory()`, macOS documents container `tmp` as purgeable, so no
app is permitted to depend on anything surviving there, so delete freely. The contract
part is true. **The conclusion was not**, and it was reached by reasoning about what the
directory is *called* rather than measuring what is *in* it.

The measurement that settles it: identical content implies identical size, so a file
whose size appears nowhere in the attachment store **cannot have a counterpart there**.
Index the store's distinct sizes (64,539 of them here) and check every stray against it.

Result on this Mac — three buckets, not two:

| Bucket | Files | Size | |
|---|---|---|---|
| referenced by `chat.db` | 48 | 17.9 MB | keep |
| **no counterpart in the store** | **118** | **143.5 MB** | **keep** |
| duplicated or derived | 11,749 | 18.6 GB | reclaimable |

18.6 of 18.8 GB really is duplicate. But that 143.5 MB is not scratch:

- `intefin_pylväs_vocals_v2.wav` ×2 — 91 MB of vocal recording
- nine `Audio Message.caf` voice memos
- six TIFFs (`IMG_9375`, `IMG_3264`, `IMG_1700`, each twice)
- `org.lackluster.Paketti_V3.54.xrnx` ×2 — a Paketti release build
- `VTT_CR_00092_26.pdf`, `Maasäteilyraportti.pdf`, `путь-мистики--семинар-2.pdf`
- two `.numbers`, a `.shortcut`, a `.gif`

Two limits on that test, both worth stating. It compares against the **attachment
store only**, not the whole disk — the `.xrnx` is near-certainly also in the Paketti
repo, so those files are unique *to Messages*, not necessarily unique in the world.
And **derived extensions are exempt** (`.ktx`, `.plist`): a re-encoded thumbnail never
size-matches its source, so testing it for uniqueness would flag all 20,000 of them
meaninglessly.

`Caches` survives the same test as a genuine cache. Its 307 MB of non-`.ktx` files are
all named `PhotosSearchSection-at_0_<attachment-GUID>` — renders *of* an attachment,
named after the attachment they came from. Derived by construction.

Practical rule: **use `--strays`, which reports all three buckets and offers only the
third.** The guard costs 450 MB of 29.7 GB — 1.5% — to remove the entire category of
risk. On a first bulk run move to `~/.Trash` rather than `rm`, so it is undoable.

Do not confuse this directory with `~/Library/Messages/Attachments`, where the opposite
rule applies — see the deletion rules above.

## Duplicates

The same file is commonly stored once per conversation it was sent to — sending one
video to three people costs three copies. 3.2 GB of byte-identical duplication among
files ≥100 MB on this Mac; one 777 MB PNG is stored twice for 1.55 GB. Deduplication
is not possible without deleting from one of the conversations. `--dupes` lists them.

## Claims this page has had to retract

Everything here was established on 2026-08-12, and five confident figures on the way to
it were wrong. They are kept because the failure mode is more reusable than the facts:
**every one came from trusting a proxy for the truth — a filename, a path string, a
directory's name, a database column — instead of the truth.**

| Claimed | Reality | The proxy that lied |
|---|---|---|
| 16.5 GB of orphans | live attachments | full-path string equality |
| 10.9 GB of orphans | **100% live** on spot-check | filename, after case+Unicode fixes |
| `TemporaryItems` is all scratch | 48 files are live attachments | the directory's name |
| `Keep messages ▸ 1 Year` frees 109.7 GB | destroys 8.57 GB of irreplaceable originals | the size column |
| 29.5 GB of temp + caches reclaimable | 118 files / 143.5 MB have no counterpart | the container contract |

The correct move in every case was the same and cheap: check each candidate against the
authority that would know otherwise — `chat.db` for anything it references, a size
index for anything it does not — and spot-check the answer independently before
reporting a number.

A wrong "safe to delete" is unrecoverable in a way a wrong "keep" never is. State what
is lost before what is gained, and prefer `~/.Trash` to `rm` on any first bulk run.

## Related

- [`wiki/concepts/mail-app-internal-behaviors.md`](mail-app-internal-behaviors.md) — the equivalent gotcha list for Mail
- [`wiki/concepts/imessage-from-terminal.md`](imessage-from-terminal.md) — sending, which *is* scriptable
