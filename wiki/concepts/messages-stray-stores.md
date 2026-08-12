---
description: The 29 GB Messages keeps outside the attachment store — the container temp dir and the preview caches — what is genuinely disposable in them, and the test that separates a duplicate from the only copy.
---

# Messages stray stores

Two stores outside `~/Library/Messages/Attachments` that no UI lists and iCloud never
touches — together ~29 GB on this Mac. Measured 2026-08-12.

The main store and its opposite deletion rule:
[`messages-attachment-store.md`](messages-attachment-store.md).

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

## Is everything in TemporaryItems deletable? No — and "delete freely" was wrong

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

## Related

- [`messages-attachment-store.md`](messages-attachment-store.md) — the main store, where the opposite deletion rule applies
- `bin/messages-attachments --strays` — reports all three buckets, offers only the disposable one
