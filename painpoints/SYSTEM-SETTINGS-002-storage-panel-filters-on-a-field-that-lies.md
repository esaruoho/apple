# SYSTEM-SETTINGS-002: The Storage Panel Filters on a Field That Lies

**App:** System Settings ▸ General ▸ Storage ▸ Messages
**Intent:** Find and delete the largest Messages attachments to reclaim disk space
**Severity:** Correctness bug — the tool hides 60% of the bytes it exists to surface, including the single largest file
**Status:** Open
**Filed:** 2026-08-12

---

## The Friction

macOS ships one purpose-built surface for reclaiming space from Messages: the
attachment list in System Settings ▸ General ▸ Storage ▸ Messages. It has a Size
column, a sort arrow, and a Delete button. It is the only supported way to do this
without navigating to a years-old conversation by hand.

It does not show you your largest files.

On the machine that prompted this filing, the biggest single attachment in a 141 GB
store — a **776.8 MiB PNG** — is absent from the panel entirely. Not buried at the
bottom, not mis-sorted. Absent. The user went looking for it, sorted by size, and it
was not there.

The cause is a mismatch between two sources of truth inside Apple's own app:

> **The panel decides *what to list* using `chat.db`'s `attachment.total_bytes`,
> then *displays and sorts* using the real on-disk size.**

`total_bytes` records the size negotiated at transfer time, not what landed on disk.
It is routinely wrong by two to four orders of magnitude. So the inclusion test runs
on a field that lies, and every file whose recorded size is understated falls through
the floor — no matter how many hundreds of megabytes it actually occupies.

---

## The Evidence

Three independent observations, all from the same machine on 2026-08-12.

**1. Every visible row has a large `total_bytes`.** Reading the panel's top ten
against the database: `total_bytes` for those rows ranged from **233 to 758 MiB**.
Not one small value among them.

**2. Every huge-but-missing file has a tiny `total_bytes`.**

| File | `total_bytes` says | Actually on disk | Error | In panel? |
|---|---|---|---|---|
| `IMG_6510.MOV` | 0.08 MiB | 695.8 MiB | **8279x** | no |
| `…upscayl_16x…png` (copy A) | 0.39 MiB | 776.8 MiB | **2017x** | no |
| `IMG_9056.MOV` | 1.03 MiB | 435.2 MiB | 424x | no |
| `IMG_2051.MOV` | 1.45 MiB | 406.4 MiB | 281x | no |
| `…upscayl_16x…png` (copy B) | 5.40 MiB | 776.8 MiB | 144x | no |
| `Tomas Potkulautailee….mp4` | 38.1 MiB | 526.2 MiB | 14x | no |
| `HLER tikkurila 2023.mp4` | 233.5 MiB | 234.2 MiB | — | **yes** |
| `0231DB16-….mov` | 757.7 MiB | 757.7 MiB | — | **yes** |

**3. The display is honest even though the filter is not.** The panel's sizes fall
monotonically and match `stat` converted to decimal MB — 757.7 MiB rendered as
"794,5 MB". So the sort and the column read the filesystem. Only the decision about
which rows exist reads the database.

The threshold is bounded by observation to **greater than 38.1 MiB and at most
233.5 MiB** of `total_bytes`. 100 MB is the natural guess. It is not confirmed, and
the exact value does not change the conclusion.

**The damage, counted:** of 53 attachments at or above 100 MB on disk (12.3 GB
total), the panel surfaces **27 files / 4.8 GB** and conceals **26 files / 7.4 GB**.
It hides more than it shows. The user was at 52 GB free on a 1.8 TB disk when they
went looking.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

Sal's Principle #2: **Solve a real problem.** The real problem is a full disk. Apple
correctly identified it, built a panel for it, and shipped it in the default OS. Then
the panel answered a question the user did not ask — *which attachments were recorded
as large at transfer time* — while appearing to answer the one they did: *which
attachments are large right now*.

That is worse than having no tool. A missing feature sends the user looking for
another way. A tool that silently omits the answer sends them away believing there
is nothing more to find. The user in this case deleted several hundred megabytes of
family videos from the visible list while a 1.55 GB duplicated PNG sat two rows above
the top of it, invisible.

Sal's Principle #5: **Use what the user already has.** The user already has the real
sizes. They are on the filesystem — the same filesystem the panel reads for its Size
column, one function call from the code that builds the list. Nothing needed to be
invented. The panel simply had to ask the disk twice instead of once.

---

## What It Should Be

The fix is a one-line change in intent: filter on the same value you display.

```
for each attachment row in chat.db:
    path = resolve(row.filename)          # already done — the panel shows this file
    size = stat(path).st_size             # already done — this is the Size column
    if size >= threshold:                 # <- currently: if row.total_bytes >= threshold
        show(path, size)
```

There is no new API, no new permission, no schema migration, and no performance
argument — the panel already stats every file it lists in order to render the column
correctly. It stats the survivors. It needs to stat the candidates.

While there: the panel should also surface **duplicates**. Sending one video to three
people stores it three times, and this machine carries 4.0 GB of byte-identical
redundancy among files ≥100 MB alone. The panel has every path it needs to spot them.

---

## Fix Paths

1. **Apple (ideal):** Filter on the on-disk size, as above. Additionally, repair
   `total_bytes` on read — if the row disagrees with the file, the file is right.
2. **Apple (adjacent):** The conversation-level ⌘I attachment grid has the same
   provenance problem and no size display at all. Give it a sort-by-size.
3. **Workaround (what we built):** [`bin/messages-attachments`](../bin/messages-attachments)
   inventories the store by real on-disk size, joins each file back to its
   conversation and date, groups by conversation so one ⌘I visit clears several, and
   reports which files the Storage panel is hiding. Read-only; it never writes to
   `chat.db`. Concept page: [`wiki/concepts/messages-attachment-store.md`](../wiki/concepts/messages-attachment-store.md).
4. **Not a fix — do not do this:** deleting attachment files with `rm`, or deleting
   rows from `chat.db` with sqlite. With Messages in iCloud enabled the store is a
   CloudKit replica; neither produces a tombstone, so nothing is freed in iCloud and
   the deletion can be reconciled away. See the concept page.

---

## The Compounding Problem

This lands on top of [MESSAGES-001](MESSAGES-001-write-only-automation.md). Messages
exposes exactly three AppleScript commands — `send`, `log in`, `log out` — and no
attachment class, so there is **no scripted path to deleting an attachment at all**.
The UI is the only supported surface.

Which means the broken panel is not one option among several. For 26 files and 7.4 GB
on this machine, the only remaining route is to remember which conversation a file
was sent to, open it, press ⌘I, and scroll a grid with no size column back to 2017.

A user cannot reach their own largest files, and cannot write a script to do it for
them either.

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** -- software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.
