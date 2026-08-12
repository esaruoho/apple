# SYSTEM-SETTINGS-002: Messages Hides Your Originals, Then Offers to Delete Them

**App:** Messages.app + System Settings ▸ General ▸ Storage ▸ Messages
**Intent:** Find and delete the largest Messages attachments to reclaim disk space
**Severity:** Data-loss hazard — the full-quality original of every oversized send is invisible to every Apple surface, and the OS's own remedy destroys it without warning
**Status:** Open
**Filed:** 2026-08-12
**Revised:** 2026-08-12 — the original filing blamed a wrong number. The number is right; see *The Correction*.

---

## The Friction

macOS ships one purpose-built surface for reclaiming space from Messages: the
attachment list in System Settings ▸ General ▸ Storage ▸ Messages. It has a Size
column, a sort arrow, and a Delete button.

It does not show you your largest files.

On the machine that prompted this filing, the biggest single attachment in the store —
an **814 MB PNG** — was absent from the panel entirely. Not buried, not mis-sorted.
Absent. The user sorted by size and it was not there.

Nor was it in the conversation. He scrolled a 15,000-message thread back two and a half
years to the exact date, and found the discussion of the image with **no image bubble
for it**. Two independent surfaces, both blind to the same 814 MB.

---

## The Correction

The first version of this filing said `attachment.total_bytes` was simply wrong — off by
up to 8279x — and that Apple had wired the panel's filter to a lying field. That was a
misreading, and it cost the user most of a day hunting a bubble that could not exist.

`total_bytes` is not wrong. **It records what Messages actually transmitted.**

Send a file larger than iMessage will carry and Messages does not refuse. It compresses
a copy, sends that, and keeps your original on disk, attached to the same message. One
message, two attachments:

| Attachment | `is_outgoing` | `total_bytes` | Bytes on disk |
|---|---|---|---|
| the PNG (your original) | 1 | **5,664,632** | 814,483,067 |
| the JPEG (what was sent) | 0 | 5,664,632 | **5,664,632** |

`total_bytes` on the original equals the transmitted file's size *exactly*. The field was
answering a different question than anyone reading it assumed.

That single fact explains both blindnesses. The panel filters on transmitted size, so a
5.6 MB record never clears the threshold no matter how large the file is. And the
transcript renders the transmitted attachment, so the original — never sent, never part
of the conversation — has no bubble to find. **It is not hard to locate. It is not
locatable.**

---

## The Real Damage Is Not Disk Space

Disk space is the lesser half. The important consequence:

> **The staged original is frequently the only full-quality copy in existence.**
> The recipient has the compressed version. You have the original — filed where no
> interface will show it to you.

On this machine: **8.57 GB across 43 conversations**, overwhelmingly family video.
A 278.6 MB clip transmitted as 216 KB. A 174.3 MB clip transmitted as 19.3 MB.

Now consider what macOS offers a user whose disk is full. **Messages ▸ Settings ▸
General ▸ Keep messages ▸ 1 Year** — the one-click remedy, which on this machine would
have removed 109.7 GB. It would also have destroyed every one of those 8.57 GB of
originals, silently, with no warning, no listing, and no way to have known they were
there.

Apple's storage advice and Apple's hidden originals are on a collision course, and the
user is never told.

---

## The Evidence

Measured 12 August 2026. Files whose real on-disk size materially exceeds their recorded
transmitted size:

| File | Recorded (transmitted) | Actually on disk | Factor | In panel? |
|---|---|---|---|---|
| `IMG_6510.MOV` | 0.08 MiB | 695.8 MiB | **8279x** | no |
| `…upscayl…png` (copy A) | 0.39 MiB | 776.8 MiB | 2017x | no |
| `IMG_9056.MOV` | 1.03 MiB | 435.2 MiB | 424x | no |
| `IMG_2051.MOV` | 1.45 MiB | 406.4 MiB | 281x | no |
| `…upscayl…png` (copy B) | 5.40 MiB | 776.8 MiB | 144x | no |
| `Tomas Potkulautailee….mp4` | 38.1 MiB | 526.2 MiB | 14x | no |
| `HLER tikkurila 2023.mp4` | 233.5 MiB | 234.2 MiB | — | **yes** |
| `0231DB16-….mov` | 757.7 MiB | 757.7 MiB | — | **yes** |

The two files whose records match their disk size are the two the panel displays. Every
file it omits was compressed on the way out.

**Three confirmations of the mechanism:**

1. Every row visible in the panel had a recorded size between 233 and 758 MiB. Not one
   small value among them.
2. Every huge file it omitted had a small one — bounded by observation to a threshold
   above 38.1 MiB and at or below 233.5 MiB. 100 MB is the natural guess; unconfirmed,
   and the exact figure changes nothing.
3. The panel's displayed sizes fall monotonically and match `stat` in decimal MB. The
   column and the sort read the filesystem. Only the decision about which rows exist
   reads the database.

**Counted:** of 51 attachments ≥100 MB on disk (10.7 GB), the panel surfaces
**27 files / 4.8 GB** and conceals **24 files / 5.9 GB**. It hides more than it shows.
(The two 776.8 MiB PNGs above were deleted during the investigation, which is why these
totals are lower than the first revision's 53 / 12.3 / 7.4 GB.)

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

**Principle #2 — solve a real problem.** The real problem is a full disk. Apple
identified it, built a panel for it, and shipped it by default. Then the panel answered
a question nobody asked — *which attachments were large when transmitted* — while
appearing to answer the one everybody asks: *which attachments are large right now*.

That is worse than shipping nothing. A missing feature sends you looking elsewhere. A
tool that silently omits the answer sends you away believing there is nothing more to
find.

**Principle #5 — use what the user already has.** The real sizes are on the filesystem,
which the panel already reads to render its Size column. Nothing needed inventing. It
had to ask the disk twice instead of once.

And a principle this filing had to learn the hard way: **if you keep something on a
person's behalf, tell them you kept it.** Messages made a decision — compress this,
send the small one, keep the big one — and recorded it nowhere the person could see.
Every downstream failure follows from that silence.

---

## What It Should Be

**1. Filter on the size you display.**

```
for each attachment row in chat.db:
    path = resolve(row.filename)     # already done — the panel shows this file
    size = stat(path).st_size        # already done — this is the Size column
    if size >= threshold:            # currently: if row.total_bytes >= threshold
        show(path, size)
```

No new API, no new permission, no schema change, no performance argument — the panel
already stats every file it lists to render the column. It stats the survivors. It needs
to stat the candidates.

**2. Name the thing.** An attachment whose on-disk size exceeds its transmitted size is a
*staged original*. Label it as one, in the panel and in the ⌘I grid: "Original — 278 MB.
Sent as 216 KB." One line of text ends the entire confusion.

**3. Warn before destroying originals.** "Keep messages ▸ 1 Year" should say: *this will
also delete 1,340 original photos and videos that exist only here.* With a button to
export them first.

**4. Offer the choice at send time.** The user was never asked whether to keep an 814 MB
original. Ask, once, and remember the answer.

**5. Surface duplicates.** Sending one video to three people stores it three times —
2.5 GB of byte-identical redundancy among files ≥100 MB on this machine alone.

---

## Fix Paths

1. **Apple (ideal):** all five above. (2) and (3) matter more than (1); disk space is
   recoverable, a lost original is not.
2. **Apple (adjacent):** the ⌘I attachment grid has the same provenance blindness and no
   size display at all. Give it sizes and a sort.
3. **Workaround — find and rescue:** [`bin/messages-staged-originals`](../bin/messages-staged-originals)
   identifies staged originals in four tiers by direction and corroboration, copies them
   out foldered by conversation, and offers deletion only of the tier it can prove — to
   the Trash, never `rm`.
4. **Workaround — see what the panel hides:** [`bin/messages-attachments`](../bin/messages-attachments)
   inventories by real on-disk size, joined to conversation and date. Read-only.
5. **Not a fix:** deleting attachment files with `rm`, or rows from `chat.db` with
   sqlite. With Messages in iCloud the store is a CloudKit replica; neither produces a
   tombstone. See [`wiki/concepts/messages-attachment-store.md`](../wiki/concepts/messages-attachment-store.md).

---

## The Compounding Problem

This lands on top of [MESSAGES-001](MESSAGES-001-write-only-automation.md). Messages
exposes exactly three AppleScript commands — `send`, `log in`, `log out` — and no
attachment class. **There is no scripted path to deleting an attachment at all.**

So the broken panel is not one option among several. For the files it conceals, the only
remaining route is to remember which conversation something was sent to, open it, and
scroll a grid with no size column back through years — and for staged originals, even
that fails, because there is no bubble to click.

A user cannot see their own largest files, cannot reach them by hand, cannot script
around it, and is offered a remedy that would delete the irreplaceable ones without
saying so.

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** -- software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.
