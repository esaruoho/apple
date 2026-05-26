# Mail flag → routing pipeline (v2)

> 📖 **Public:** [Trigger→worker chassis (public)](https://esaruoho.github.io/apple/chassis)

**Status:** v2 shipped 2026-05-26. SQLite + .emlx architecture, FSEvents trigger (in progress). Purple/FreeEnergy contract live; six other colors stubbed.

Flag a message in Mail with a color, the worker extracts it (.eml + body→markdown + attachments routed per-extension + **full conversation thread** as a chronological bundle), then moves it to `Processed/<Color>`. Zero LLM roundtrip. Mail.app touched at most ONCE per processed message (the move).

Fourth instance of the trigger→worker chassis (Finder tag, Voice Memo `#process`, Stickies, Mail flag).

## v1 → v2 — what changed and why

**v1 (2026-05-26 morning) — clobbered Mail.app.** Polling design: every 30s, `osascript` asked Mail to scan every mailbox of every account for flagged messages. Ticks stacked because the previous query hadn't returned. Six concurrent `messages of mb whose flag index is N` queries hammered Mail simultaneously. Mail became unresponsive, eventually crashed.

**v2 (2026-05-26 afternoon) — respects Mail.app.** Detection moved off-line: read Mail's own SQLite Envelope Index (read-only) + read .emlx files directly from disk. Mail.app is queried by AppleScript only for the final "move to Processed/<Color>" step, sequentially, with a 15-second hard timeout. See the [v1 postmortem section](#v1-postmortem-why-the-polling-design-clobbered-mailapp) below.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────────┐
│                                                                          │
│   User flags a message in Mail (any color)                              │
│              │                                                           │
│              ▼                                                           │
│   Mail.app writes to ~/Library/Mail/V10/MailData/Envelope Index-wal     │
│   (verified: SQLite reflects flag changes within ~5 seconds)            │
│              │                                                           │
│              ▼                                                           │
│   AppleToolbox FSEventStream on Envelope Index-wal (debounced 3s)       │
│              │                                                           │
│              ▼                                                           │
│   mail-flag-worker --tick  (under flock — only one worker, ever)        │
│       1. read SQLite read-only:                                          │
│            SELECT ROWID, flag_color, mailbox FROM messages              │
│              WHERE flagged=1 AND flag_color IN <enabled colors>          │
│       2. dedup against state.processed_message_ids                       │
│          (by RFC822 Message-ID — survives ROWID flips on move)           │
│       3. hard cap: max 20 messages per tick                              │
│       4. for each new message:                                           │
│            a. resolve mailbox URL → on-disk .mbox dir                    │
│            b. find <ROWID>.emlx (skip .partial.emlx — retry next tick)   │
│            c. read RFC822 from disk, parse via stdlib email module       │
│            d. save .eml to contract.eml_dest                             │
│            e. body → markdown (stdlib html.parser) → contract.body_md_dest │
│            f. find all conversation_id siblings via SQLite               │
│            g. save sibling .eml files + thread.md (chronological)        │
│            h. route attachments from ALL thread messages per contract    │
│               (SHA-256 dedup so identical attachments don't duplicate)   │
│            i. ONE osascript: move flagged msg to Processed/<Color>      │
│               (account-scoped, 15s timeout, best-effort)                 │
│            j. record Message-ID in state.processed_message_ids           │
│       5. write status JSON for AppleToolbox menu row                     │
│                                                                          │
└──────────────────────────────────────────────────────────────────────────┘
```

## Detection: SQLite + .emlx (no Mail.app contact)

`~/Library/Mail/V10/MailData/Envelope Index` is a SQLite database Mail maintains for itself. The `messages` table includes `flagged INTEGER`, `flag_color INTEGER`, `conversation_id INTEGER`, etc. We open it `?mode=ro` so we can never write — safe to read while Mail has the DB open.

.emlx files live on disk under `<account-UUID>/<mailbox>.mbox/<sub-UUID>/Data/<shard>/Messages/<ROWID>.emlx`. The shard path uses ROWID digits; `Path.rglob("<ROWID>.emlx")` finds it in milliseconds on APFS.

**.emlx format:** first line = byte length of RFC822 body; then RFC822 bytes; then optional plist trailer. Stdlib `email` module parses the RFC822 part cleanly.

**`.partial.emlx`** = IMAP hasn't pulled the full body+attachments yet. Two-tier handling:

- **Virtual mailboxes** (Gmail `[Gmail]/All Mail` and friends — identified by URL marker, see [mail-app-internal-behaviors.md §3](mail-app-internal-behaviors.md)) → SKIP. Force-downloading hangs Mail for minutes per query. Park in `skipped_temp`, retry every tick. Thread bundling usually rescues attachments via iCloud Sent Messages siblings.
- **Real mailboxes** (iCloud INBOX, plain IMAP, custom folders) → FORCE-DOWNLOAD via a bounded `tell Mail to set _src to source of m` + `NSString:writeToFile` to our own tmp file. 30s timeout, single attempt per tick, captures the bytes ourselves because Mail does NOT persist them to its .emlx cache. Implementation: `try_force_download()` in `bin/mail-flag-worker`. See [mail-app-internal-behaviors.md §2](mail-app-internal-behaviors.md) for the why.

Early Message-ID dedup runs BEFORE any force-download attempt — `.partial.emlx` has headers (just no body), we read those, check `processed_message_ids`, skip the 30 s download if we've already routed this message under a previous ROWID.

## Attachment routing — inline files count too

The worker routes ANY MIME part with a non-empty `Content-Disposition` filename, not just parts marked `Content-Disposition: attachment`. **Inline images** (hand-drawn diagrams, photos, screenshots embedded in email body) are the actual archival content for many Free Energy / research / how-to mails. Python's `email.message.Message.is_attachment()` would skip them — we deliberately don't use it.

Validated 2026-05-26: a 154 KB iCloud message with subject `"C"` from Merja Valve had a single `Content-Disposition: inline; filename="Note of C.jpeg"` part. The worker correctly routed it to `~/work/mediabank/inbox/images/Note_of_C.jpeg`. See [mail-app-internal-behaviors.md §5](mail-app-internal-behaviors.md).

## Thread bundling (the real archival win)

For each flagged message we also find every sibling in the same `conversation_id`. Each full-emlx sibling is saved as a separate `.eml` next to the flagged one, and a chronological `mail-<date>-<subj>-THREAD.md` combines all messages with proper From/To/Subject/Attachments headers.

**Bonus:** Esa's Sent Messages are full .emlx files (locally composed, not IMAP-partial). So even when an incoming Gmail reply is `.partial.emlx`, the attachments Esa SENT are captured from the Sent Messages copy. Routing fires from any thread message that has the attachment, deduped by SHA-256 hash so identical files don't get queued twice.

## ROWID flip on move — a critical gotcha

When Mail moves a message between mailboxes (whether you do it manually, by rule, or via our worker), SQLite **renumbers it**: the old ROWID disappears and a brand-new ROWID is created in the destination mailbox. Same message, new identity.

If you track "already-processed" by ROWID, the worker re-processes the same message every tick after moving it to Processed/<Color> → duplicate routing → infinite loop.

**Fix:** dedup by RFC822 Message-ID header (stable across moves), not by ROWID.

Full detail: [mail-rowid-flip-on-move.md](mail-rowid-flip-on-move.md).

## Mail Rules ≠ user-flag trigger

Mail's rule system can condition on **incoming-mail attributes only** (sender, subject, headers, account, junk-status, content). There is no rule condition for "user just flagged this message".

So user-flagging requires the FSEvents/SQLite path. Mail Rules are useful for the inverse: "incoming-mail matching X → auto-flag purple + run dispatch.scpt" — build this manually in Mail Settings → Rules → Run AppleScript → `~/work/apple/bin/mail-flag-dispatch.scpt`.

## Gmail vs iCloud

**iCloud INBOX flagging works end-to-end.** Validated 2026-05-26 with a real message — .eml + body.md + 7 thread attachments + thread.md + move to Processed/FreeEnergy, all in under 3 seconds.

**Gmail `[Gmail]/All Mail` virtual folder is fragile.** Mail's IMAP queries against this folder are slow because it's a server-side virtual mirror of every labeled message. `osascript` calls block Mail for minutes. **We do not force-download Gmail partials.** They sit in `skipped_temp` until Mail eventually pulls them (via user opening the message, or background sync). Thread bundling rescues most cases: even with a partial Gmail incoming, the full Sent Messages siblings on iCloud provide the attachments.

**iCloud INBOX and plain IMAP are safe.** `.partial.emlx` in these mailboxes IS force-downloaded automatically — the worker fires one bounded `source of m` osascript with 30s timeout, captures the RFC822 bytes via `NSString:writeToFile` to a temp file, then proceeds with normal routing. End-to-end latency for a 150 KB message with inline image: ~13 seconds.

## The contract file

`~/work/apple/bin/mail-flag-config.json` — JSON, keyed by SQLite `flag_color` integer (0..6).

```jsonc
"1": {
  "name": "FreeEnergy",
  "_comment": "VERIFIED 2026-05-26: Mail UI 'Purple' flag = SQLite flag_color=1.",
  "enabled": true,
  "eml_dest":     "~/work/mediabank/inbox/mail/eml/",
  "body_md_dest": "~/work/merlib-dump/articles/_inbox/",
  "url_action":   null,
  "attachments": {
    ".pdf":                                        "~/.claude/skills/bbs/bin/bbs-ocr-submit.sh",
    ".md .txt .markdown":                          "~/work/merlib-dump/articles/_inbox/",
    ".mp3 .m4a .wav .flac .aiff .aac .opus .ogg":  "~/work/whisp-transcripts/whisp-submit",
    ".mp4 .m4v .mov .mkv .avi .webm":              "~/work/whisp-transcripts/whisp-submit",
    ".jpg .jpeg .png .heic .tif .tiff .gif .webp": "~/work/mediabank/inbox/images/",
    ".epub .mobi .azw .azw3":                      "~/work/mediabank/inbox/books/",
    ".zip .tar .tar.gz .tgz .7z .rar":             "~/work/mediabank/inbox/archives/",
    "*":                                           "~/work/mediabank/inbox/misc/"
  },
  "processed_mailbox": "Processed/FreeEnergy"
}
```

Destination values:
- **Directory** (ends with `/` or doesn't exist as executable) → artifact copied in
- **Submit script** (executable file) → artifact passed as `argv[1]`

Extension keys list multiple extensions separated by spaces. `"*"` is the fallback. Edit this file freely — the worker re-reads on every tick.

## Flag-color → UI-name mapping

Apple Mail's flag colors as Esa sees them in his sidebar:

| SQLite `flag_color` | Mail UI name | Verified |
|---|---|---|
| 0 | (default flag) | ~24,000 messages, likely Red per UI count |
| 1 | **Purple** | ✓ 2026-05-26 — user flagged a test message Purple, SQLite recorded 1 |
| 2 | Yellow (likely) | 1-2 messages |
| 3 | Green (likely) | small count |
| 4 | Blue (likely) | 0 currently |
| 5 | (unknown) | 547-655 messages, likely Green per UI count |
| 6 | Gray (likely) | 0 currently |

The mapping varies by macOS version. Use `mail-flag-worker --probe` to list flagged messages by SQLite color so you can match indices to UI labels on a given machine.

## Adding a new color contract

1. Edit `bin/mail-flag-config.json` — set the slot's `enabled` to `true`, fill in destinations + attachments map + `processed_mailbox`
2. Run `bin/install-mail-flag-mailboxes` to create the `Processed/<Color>` mailbox(es)
3. Next FSEvents tick picks up the new config — no rebuild needed

## CLI

```
mail-flag-worker --status                    # contract summary + queue state
mail-flag-worker --probe                     # list flagged messages by color (SQLite, no Mail contact)
mail-flag-worker --tick                      # one safe pass (FSEvents calls this)
mail-flag-worker --backfill --dry-run        # preview backfill of existing flagged messages
mail-flag-worker --reset <rowid>             # re-queue a processed ROWID
```

## Files

| Path | What |
|---|---|
| `bin/mail-flag-config.json` | Contracts. Edit to wire flags. |
| `bin/mail-flag-worker` | v2 worker. Python stdlib + osascript. |
| `bin/mail-flag-probe-envelope` | Research probe for SQLite + .emlx + watch-mode. Read-only. |
| `bin/mail-flag-dispatch.applescript` | Mail-Rule entry point (source). |
| `bin/mail-flag-dispatch.scpt` | Compiled. Point Mail rules at this. |
| `bin/install-mail-flag-mailboxes` | Creates `Processed/<Color>` mailboxes. |
| `topbar/AppleToolbox.swift` | `MailFlagWatcherRunner` (FSEvents — task #13 to wire in). |
| `~/work/comms/queue/mail-flag-state.json` | processed_message_ids, skipped_temp, processed_threads |
| `~/work/comms/queue/mail-flag-worker.log` | Worker log |
| `~/work/comms/queue/mailflag-{done,failed}/` | Per-message audit JSON records |

## Audit record shape (`mailflag-done/<rowid>-<ts>.json`)

```json
{
  "rowid": 1336611,
  "flag_color": 1,
  "contract": "FreeEnergy",
  "mailbox_url": "imap://...",
  "message_id": "<CAPC1g=KD==nQoywjjgggephKsgQzVacobNJ9jy+cXHCwBpHLsg@mail.gmail.com>",
  "conversation_id": 629560,
  "thread_siblings": 6,
  "dispatched": [
    {"type":"eml",               "path":"...", "ok": true},
    {"type":"body_md",           "path":"...", "ok": true},
    {"type":"thread_md",         "path":"...", "ok": true, "messages": 4},
    {"type":"thread_eml",        "rowid": 1335803, "path":"...", "ok": true},
    {"type":"thread_attachment", "from_rowid": 1335803, "name":"x.pdf", "dest":"...", "ok": true},
    {"type":"move",              "to":"Processed/FreeEnergy", "ok": true}
  ],
  "status": "done"
}
```

## v1 postmortem — why the polling design clobbered Mail.app

**v1 design (lasted 4 hours, deleted after Mail.app crashes):**

```python
# ran every 30s in AppleToolbox
osascript -e '''
tell application "Mail"
    repeat with acc in accounts
        repeat with mb in mailboxes of acc
            repeat with m in (messages of mb whose flag index is 1)
                ...
'''
```

Three compounding bugs:

1. **Catastrophic query scope.** `messages of mb whose flag index is N` forces Mail to evaluate that predicate over every message in every mailbox — including Sent, Drafts, Trash, Junk, on-server folders, smart mailboxes. For Esa's IMAP setup that's hundreds of mailboxes and ~25,000 messages.
2. **No overlap protection.** The Swift `Timer` fired every 30s regardless of whether the previous tick had returned. Within 3 minutes there were 6 concurrent osascript scans queued at Mail.
3. **No timeout.** osascript had no upper bound; if Mail hung, the next tick spawned another scan anyway.

Net effect: Mail.app received an ever-growing queue of "scan every mailbox of every account" AppleEvents, processed them serially, never drained → Mail.app unresponsive → Mail.app crashed.

**v2 lessons baked in:**
- Detection is **off-line** (SQLite + filesystem). Mail.app sees zero AppleEvents for detection.
- The ONE AppleEvent per message (the move) is **account-scoped** (`account whose id is "<UUID>"`) so it doesn't iterate the wrong account.
- Hard timeout (15s) on the move script — if Mail can't comply quickly we leave the message in place rather than queue more work.
- `flock` on the worker process — only one worker can be running, ever.
- Hard cap: 20 messages per tick → mass-flagging 100 messages drains in batches with Mail breathing between.
- `.partial.emlx` is **never force-downloaded** — Gmail virtual folders made `source of m` hang Mail for 2-3 minutes per call. We wait for Mail to download naturally.

## Related

- [mail-app-internal-behaviors.md](mail-app-internal-behaviors.md) — every Mail.app gotcha discovered during this build, consolidated (ROWID flip, source-of-m doesn't persist, virtual-folder hangs, FSEvents CFTypes flag, inline-attachment routing, etc.)
- [mail-rowid-flip-on-move.md](mail-rowid-flip-on-move.md) — gotcha #1 in standalone detail
- [finder-tag-pipeline.md](finder-tag-pipeline.md) — sibling pipeline (tag-watcher)
- [voice-memos-process-tag-pipeline.md](voice-memos-process-tag-pipeline.md) — sibling pipeline (Voice Memos `#process`)
- [stickies-claude-trigger.md](stickies-claude-trigger.md) — sibling pipeline (Stickies)
