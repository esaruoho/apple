# Apple Mail.app internal behaviors — automation gotchas

Non-obvious behaviors of Apple Mail.app that you need to know before writing any automation that touches its data, scripting dictionary, or on-disk storage. Discovered the hard way during the [Mail flag → routing pipeline](mail-flag-pipeline.md) build-out 2026-05-26.

## 1. ROWID flips on every mailbox move

`messages.ROWID` in `~/Library/Mail/V10/MailData/Envelope Index` is **not stable**. Every mailbox move (manual, by rule, by AppleScript) deletes the old row and inserts a new one. Same message, new identity.

**Don't:** track "already processed" by ROWID.
**Do:** track by RFC822 `Message-ID` header (stable across moves).

Full detail: [mail-rowid-flip-on-move.md](mail-rowid-flip-on-move.md).

## 2. `source of m` returns bytes but doesn't persist them

Asking Mail's AppleScript dictionary for the source of a message forces a full IMAP fetch:

```applescript
tell application "Mail" to set _src to source of m
```

This pulls the complete RFC822 (with body + all attachments) from the IMAP server. The bytes are returned to your AppleScript context.

**But Mail does NOT write them to its own `.emlx` cache.** The on-disk `<ROWID>.partial.emlx` stays partial. Verified by experiment: `source of m` returned `OK:9944934` (9.9 MB), waited 13 s polling the disk path, no full `.emlx` ever appeared.

**Implication:** if you want the bytes, capture them yourself. Don't rely on the disk side-effect.

**Reliable capture pattern** (handles multi-MB bodies, binary-safe):

```applescript
use framework "Foundation"
tell application "Mail"
    -- ...locate the message m...
    set _src to source of m   -- triggers IMAP fetch, ~10–30 s for big msgs
end tell

set nsStr to current application's NSString's stringWithString:_src
set nsData to nsStr's dataUsingEncoding:4   -- NSUTF8StringEncoding
set wroteOK to nsData's writeToFile:tmpPath atomically:true
```

The Python caller then reads `tmpPath`. Implementation: `bin/mail-flag-worker` → `try_force_download()`.

## 3. `[Gmail]/All Mail` and similar virtual folders hang Mail

Gmail's `[Gmail]/All Mail` is a **server-side virtual mirror** of every message labeled anything. When you AppleScript-query it:

```applescript
set m to first message of mb whose message id is X
```

…Mail issues a remote IMAP query against the server-side virtual folder. For accounts with tens of thousands of historical messages, that query can run for **2–3 minutes per call**, blocking Mail.app entirely. Stacking multiple such calls (e.g. a polling timer) crashes Mail.app.

**Don't:** AppleScript-query virtual folders. Identify them by URL pattern.

**Marker patterns in `imap://...` URLs** (URL-encoded form as stored in SQLite `mailboxes.url`):

| Pattern | Provider |
|---|---|
| `/%5BGmail%5D/All%20Mail` | Gmail consumer "All Mail" |
| `/%5BGoogle%20Mail%5D/` | Google Workspace |
| `/%5BGmail%5D/All` | Gmail variants |

Implementation: `bin/mail-flag-worker` → `VIRTUAL_MAILBOX_MARKERS` tuple. The worker refuses to force-download messages whose `mailbox_url` matches any marker.

## 4. AppleScript `message id` is bracketless; RFC822 header has angle brackets

The RFC822 `Message-ID:` header value looks like `<UUID@host>`. Mail's AppleScript `message id` property returns the bare string `UUID@host` (no `<>`).

If you match by ID, strip the brackets:

```python
def strip_msgid_brackets(s: str) -> str:
    s = s.strip()
    if s.startswith("<") and s.endswith(">"):
        return s[1:-1]
    return s
```

```applescript
set m to first message of mb whose message id is "UUID@host"  -- works
set m to first message of mb whose message id is "<UUID@host>"  -- never matches
```

## 5. `Content-Disposition: inline` files are still attachments (for archival purposes)

Python's `email.message.Message.is_attachment()` returns `True` only for parts whose `Content-Disposition` is `attachment`. Parts marked `inline` (typically embedded images: hand-drawn diagrams, photos, screenshots) return `False`.

For automation that wants to ARCHIVE the email completely, this is the wrong filter — inline images are often THE valuable content.

**Better filter:**

```python
for part in msg.walk():
    if part.get_filename():           # any part with a filename
        payload = part.get_payload(decode=True) or b""
        if payload:
            attachments.append((part.get_filename(), payload))
```

Implementation: `bin/mail-flag-worker` — used in both the flagged-message extraction and the thread-bundle sibling extraction.

## 6. Account 1 is iCloud (on this machine); messages live across accounts

Mail's `account 1` is whatever the user set as their first account — usually iCloud. But messages can live in any account. AppleScript queries that iterate "every mailbox of account 1" miss messages in other accounts.

**Don't:** `account 1` for arbitrary message operations.
**Do:** scope by account UUID from the message's `mailbox.url`:

```applescript
set acct to first account whose id is "<UUID-from-mailbox-url>"
```

The mailbox URL `imap://<UUID>/<path>` exposes the UUID, which matches Mail's `account.id` property.

## 7. SQLite Envelope Index is the source of truth for metadata

`~/Library/Mail/V10/MailData/Envelope Index` (SQLite) tracks flagged state, flag color, conversation ID, subject, sender, mailbox membership, etc., for every message. **Reading it directly (read-only) is dramatically faster and safer than AppleScript polling.**

```python
import sqlite3
con = sqlite3.connect(
    "file:/Users/esaruoho/Library/Mail/V10/MailData/Envelope Index?mode=ro",
    uri=True, timeout=5
)
con.execute("SELECT ROWID, flag_color, flagged FROM messages WHERE flagged=1")
```

`?mode=ro` means SQLite refuses to write under any circumstance — safe to run while Mail has the DB open.

**Don't:** poll Mail.app via osascript scanning every mailbox.
**Do:** read SQLite directly. Use osascript only for verbs (move, flag, send) that have no on-disk equivalent.

Full hard-rule: project memory [`feedback_never_poll_mail_via_osascript_scan.md`](../../.claude/projects/-Users-esaruoho-work-apple/memory/feedback_never_poll_mail_via_osascript_scan.md).

## 8. .emlx file format (Apple's wrapper)

`<UUID>/<mailbox>.mbox/<sub-UUID>/Data/<shard>/Messages/<ROWID>.emlx`:

```
<first-line: byte length of RFC822 body as integer>
<RFC822 body bytes, exactly that length>
<optional plist trailer with Mail-specific metadata>
```

`.partial.emlx` has the same shape but the RFC822 body is just the headers + MIME structure with empty attachment payloads (Mail's lazy IMAP).

**Read pattern (handles both .emlx and raw .rfc822):**

```python
def read_emlx(path: Path) -> bytes:
    data = path.read_bytes()
    nl = data.find(b"\n")
    if nl < 0:
        return data
    try:
        body_len = int(data[:nl].strip())
    except ValueError:
        return data   # not an .emlx wrapper — return whole bytes
    return data[nl + 1 : nl + 1 + body_len]
```

This is forgiving: if the file doesn't start with an integer (e.g. a raw RFC822 captured via `source of m`), it returns the whole content unchanged.

## 9. Mail's lazy IMAP — `.partial.emlx` is the default

Default Mail preference for IMAP accounts (including iCloud) is "all messages but omit attachments". When mail arrives, Mail downloads:

- Full message headers
- MIME structure
- Inline text bodies

But not:

- File attachments (.pdf, .docx, .jpeg, .zip, …)
- Even inline images sometimes (depends on `download html attachments` per-account preference)

Until you click the message in Mail.app's UI, the attachments stay on the server. The on-disk file is `<ROWID>.partial.emlx`.

**Forcing a per-message download** (without changing global preference):

```applescript
tell application "Mail" to set _src to source of m
```

Costs ~10–30s for multi-MB messages. **Only safe for non-virtual mailboxes** (see §3).

## 10. FSEventStream needs `kFSEventStreamCreateFlagUseCFTypes`

When watching `~/Library/Mail/V10/MailData/` for SQLite WAL updates (to detect flag changes), the callback decodes paths from `eventPaths`. Without `kFSEventStreamCreateFlagUseCFTypes`, `eventPaths` is `UnsafePointer<UnsafePointer<CChar>>` (C array). With it, you get `CFArrayRef` of `CFStringRef`.

The Swift idiom:

```swift
let cfArray = Unmanaged<CFArray>.fromOpaque(eventPathsRaw).takeUnretainedValue()
let count = CFArrayGetCount(cfArray)
for i in 0..<count {
    let cfStr = unsafeBitCast(CFArrayGetValueAtIndex(cfArray, i), to: CFString.self)
    let p = cfStr as String
    // p is the full path of one event
}
```

**Without the flag**, `unsafeBitCast(eventPaths, to: NSArray.self)` will silently produce garbage and your callback will never match any path filter. The stream will run; events will fire; the filter will reject everything. You'll see no errors. Confusing.

Implementation: `topbar/AppleToolbox.swift` → `MailFlagWatcherRunner.startFSEvents()`.

## 11. AppleEvents queue at Mail, not the client

Killing `osascript` kills the CLIENT waiting for the reply. The AppleEvent it sent is already at Mail's event queue and **keeps running there**. If you fire a long-running scan, kill it, and immediately fire another, Mail has two long-running scans pending — sequentially. Mail processes them one at a time, never drains, becomes unresponsive.

**Don't:** retry a stuck osascript call in a loop hoping it'll work.
**Do:** fire ONE, wait for completion, give Mail time to recover. Use `subprocess.run(..., timeout=N)` so the client gives up gracefully — but understand the AppleEvent may still be running inside Mail.

## 12. Always use `account whose id is "<UUID>"` for cross-account ops

If a message is in Gmail (account UUID `5A8FF...`) but you only know its Message-ID, do not iterate all accounts looking for it. Scope to the right account directly via the UUID extracted from `mailboxes.url` in SQLite:

```python
m = re.match(r"^[a-z]+://([0-9A-Fa-f-]+)/", mailbox_url)
acct_uuid = m.group(1) if m else None
```

```applescript
set acct to first account whose id is "5A8FF046-3A0A-49CA-AD89-B72437C1A842"
```

`account.id` is the same UUID Mail uses for the on-disk dir name. Verified 2026-05-26.

## Related

- [mail-flag-pipeline.md](mail-flag-pipeline.md) — the pipeline this all came from
- [mail-rowid-flip-on-move.md](mail-rowid-flip-on-move.md) — gotcha #1 in detail
- `bin/mail-flag-worker` — the production implementation
- `bin/mail-flag-probe-envelope` — read-only research tool for the SQLite + .emlx layer
- Project memory: `feedback_never_poll_mail_via_osascript_scan.md`, `feedback_mail_rowid_flips_on_move.md`
