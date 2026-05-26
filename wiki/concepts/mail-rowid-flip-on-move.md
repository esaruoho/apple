# Mail SQLite ROWID flips when a message is moved between mailboxes

**Discovered 2026-05-26** during the [Mail flag → routing pipeline](mail-flag-pipeline.md) build-out.

## The behaviour

Apple Mail's `~/Library/Mail/V10/MailData/Envelope Index` SQLite database tracks every message with an integer `ROWID` (autoincrement primary key) in the `messages` table. Naively you might assume the ROWID is stable for the lifetime of a message — it is **not**.

**Whenever a message moves between mailboxes** — whether you do it manually in Mail's UI, via AppleScript (`move m to mb`), via a Mail Rule, or via a third-party IMAP client — Mail implements the move as **delete the old row + insert a new row in the destination mailbox**. The new row gets the next autoincrement ROWID. The previous ROWID is gone (or recycled — but never the same number).

Observed empirically:

| Before move | After move (same message) |
|---|---|
| `ROWID = 1335981` in iCloud INBOX | `ROWID = 1336611` in Processed/FreeEnergy |
| (1335981 is GONE from `messages` table) | New row created with new ROWID |

A second move of the same message re-renumbers again (`1336611 → 1336624` was observed when the message was re-routed after a reset).

This is an IMAP semantic too — IMAP `MOVE` (or `COPY` + `STORE \Deleted` + `EXPUNGE`) on the server side also generates a new server-side UID. Mail's local SQLite mirrors that.

## Why it matters for automation

Any pipeline that **tracks "I already processed this message" by ROWID** is broken: the same message can re-appear as a brand-new ROWID after any move, including moves performed BY the pipeline itself.

The [mail-flag pipeline](mail-flag-pipeline.md) v2 hit this directly: after the worker routed a flagged message and moved it to `Processed/FreeEnergy`, the next tick saw a new ROWID with the same flag and re-processed it — duplicate `.eml`, duplicate body markdown, duplicate attachments to OCR queue, infinite loop.

## The fix

**Dedup by RFC822 `Message-ID`, not by SQLite ROWID.** The RFC822 Message-ID is the header value from the message itself (`<UUID@host>` form) — written by the sending client, stable for the lifetime of the message, identical across every account/mailbox/copy/move.

Implementation in `bin/mail-flag-worker`:
- `state.processed_message_ids` is a set of strings (RFC822 Message-ID without angle brackets)
- For each candidate ROWID, read its `.emlx` from disk, parse the header, extract Message-ID
- If already in `processed_message_ids` → mark ROWID processed but skip routing
- After routing → add Message-ID to `processed_message_ids`

Cost: one extra disk read per candidate ROWID per tick. With the 20-message hard cap, that's negligible.

The integer `messages.message_id` column in SQLite is **also** stable across moves (it's a 64-bit hash of the RFC822 Message-ID), so an alternative is to dedup by that integer instead of reading .emlx. We use the RFC822 string because it's human-readable and survives if Mail's hashing scheme ever changes.

## What about ROWID for the SOURCE OF TRUTH (which message to process)?

ROWID is fine for the **detection query** — "give me every flagged message with color X right now". It's only fragile when used as a **persistent identity key**. Use ROWID for the query; use Message-ID for the dedup state.

## Related

- [mail-flag-pipeline.md](mail-flag-pipeline.md) — the pipeline this taught us
- `bin/mail-flag-worker` — the worker that survives the ROWID flip via Message-ID dedup
