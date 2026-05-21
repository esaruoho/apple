# Paketti ↔ Claude Code Bridge — Backend Design v1

Drafted: 2026-05-08
Author: Claude Opus 4.7 (apple skill session)
Scope: backend only — protocol, daemon, and response delivery. UX side designed separately once this contract is fixed.

## Goal

Let Paketti send a prompt to Claude Code, have Claude (with full skills + edit access to `~/work/paketti`) act on it, and surface the result back to Renoise as a modal dialog — without blocking Renoise's audio/UI thread.

## Why a queue file, not sockets / popen

- Renoise Lua is single-threaded with the audio engine; `io.popen("claude --print …")` would block playback for the duration of the call (often 10–60 s).
- Sockets in Renoise Lua are doable but require a hand-rolled HTTP client, TLS handling for non-local cases, and timeout/cancellation logic.
- A queue file inherits the **existing pakettibot inbox/outbox pattern** at `~/work/comms/queue/`, which Esa already trusts and which Cloudcity-Boot.app already monitors. Same disk-drop bridge, new directory.

## Directory layout

```
~/work/comms/queue/
  paketti-claude-inbox/     ← Paketti drops <id>.json here
  paketti-claude-processing/← daemon moves file here while running
  paketti-claude-outbox/    ← daemon writes <id>.response.json here
  paketti-claude-archive/   ← daemon moves successful inbox+outbox pairs here
  paketti-claude-failed/    ← daemon moves errored requests here with .error.txt
```

State files:
```
/tmp/paketti-claude-flag.txt       ← payload the smoke branch turns into a dialog
/tmp/paketti-claude-session.txt    ← last known Claude session_id (for resume)
/tmp/paketti-claude-bridge.lock    ← daemon serialization lock
```

## Request format — `<id>.json`

```json
{
  "id": "2026-05-08T17-50-12-abc123",
  "prompt": "Rename PakettiFooBar to PakettiQuux throughout the codebase",
  "mode": "edit",
  "context": {
    "renoise_version": "3.5.4",
    "song_path": "/Users/.../current.xrns",
    "selected_track_index": 3,
    "selected_instrument_index": 0,
    "selected_sample_index": 0,
    "current_view": "MIDDLE_FRAME_PATTERN_EDITOR",
    "paketti_focus_file": "PakettiSamples.lua",
    "paketti_focus_line": 412
  },
  "resume_session": true,
  "created_unix": 1715180412
}
```

### Field semantics

| Field | Required | Notes |
|-------|----------|-------|
| `id` | yes | Paketti generates `os.date("!%Y-%m-%dT%H-%M-%S") .. "-" .. random6()`. UTC, filesystem-safe. |
| `prompt` | yes | Raw user prompt as typed in the Paketti dialog. |
| `mode` | yes | `ask` = read-only, `edit` = Claude may modify `~/work/paketti`, `skill` = expects a specific skill invocation. |
| `context` | optional | Runtime snapshot. Daemon prepends to prompt as a system-style preamble so Claude knows what Paketti was doing. |
| `resume_session` | optional | If true and `/tmp/paketti-claude-session.txt` exists, daemon passes `--resume <id>` to keep the conversation thread. |
| `created_unix` | yes | For audit + stale-request rejection (>30 min old → discard). |

## Response format — `<id>.response.json`

```json
{
  "id": "2026-05-08T17-50-12-abc123",
  "ok": true,
  "session_id": "abc-claude-session-uuid",
  "result": "I renamed 7 occurrences across PakettiSamples.lua, PakettiInstruments.lua, and main.lua. Touched main.lua to trigger reload.",
  "files_changed": ["PakettiSamples.lua", "PakettiInstruments.lua", "main.lua"],
  "elapsed_seconds": 23.4,
  "cost_usd": 0.084,
  "claude_raw": { "...full --output-format json blob..." }
}
```

On failure: `ok: false`, `error: "..."`, no other fields required.

## Daemon — `~/work/apple/bin/paketti-claude-bridge.py`

### Pseudocode

```python
INBOX = ~/work/comms/queue/paketti-claude-inbox
PROCESSING = ~/work/comms/queue/paketti-claude-processing
OUTBOX = ~/work/comms/queue/paketti-claude-outbox
ARCHIVE = ~/work/comms/queue/paketti-claude-archive
FAILED = ~/work/comms/queue/paketti-claude-failed
LOCK = /tmp/paketti-claude-bridge.lock
SESSION_FILE = /tmp/paketti-claude-session.txt
FLAG_FILE = /tmp/paketti-claude-flag.txt
PAKETTI_DIR = ~/work/paketti
TIMEOUT = 180  # seconds per request

def run_once():
    with file_lock(LOCK):  # serialize: only one Claude call at a time
        for req_path in sorted(INBOX.glob("*.json")):
            req = json.load(req_path)
            if now_unix() - req["created_unix"] > 1800:
                move_to(req_path, FAILED, suffix=".stale")
                continue
            move_to(req_path, PROCESSING)
            try:
                resp = invoke_claude(req)
                write_outbox(req["id"], resp)
                write_flag_and_reload(req["id"], resp)
                move_to(processing_path, ARCHIVE)
            except Exception as e:
                write_outbox(req["id"], {"ok": False, "error": str(e)})
                write_flag_and_reload(req["id"], error_payload(e))
                move_to(processing_path, FAILED)
```

### Claude invocation

```python
def invoke_claude(req):
    prompt = build_prompt(req)  # context preamble + user prompt
    args = [
        "claude", "--print",
        "--output-format", "json",
        "--add-dir", str(PAKETTI_DIR),
        "--permission-mode", "acceptEdits",  # local trusted use
    ]
    if req.get("resume_session") and SESSION_FILE.exists():
        args += ["--resume", SESSION_FILE.read_text().strip()]
    proc = subprocess.run(args, input=prompt, capture_output=True,
                          text=True, timeout=TIMEOUT)
    blob = json.loads(proc.stdout)
    if blob.get("session_id"):
        SESSION_FILE.write_text(blob["session_id"])
    return {
        "ok": proc.returncode == 0 and blob.get("subtype") == "success",
        "session_id": blob.get("session_id"),
        "result": blob.get("result", ""),
        "elapsed_seconds": blob.get("duration_ms", 0) / 1000,
        "cost_usd": blob.get("total_cost_usd", 0),
        "claude_raw": blob,
    }
```

### Prompt assembly

```python
def build_prompt(req):
    ctx = req.get("context") or {}
    preamble = "\n".join([
        f"# Paketti runtime context (informational)",
        f"- Renoise version: {ctx.get('renoise_version','?')}",
        f"- Song: {ctx.get('song_path','(unsaved)')}",
        f"- Selected track/instrument/sample: "
        f"{ctx.get('selected_track_index')}/"
        f"{ctx.get('selected_instrument_index')}/"
        f"{ctx.get('selected_sample_index')}",
        f"- Current view: {ctx.get('current_view','?')}",
        f"- Paketti focus: "
        f"{ctx.get('paketti_focus_file','?')}:{ctx.get('paketti_focus_line','?')}",
        "",
        f"# Mode: {req.get('mode','ask')}",
        "- ask  = answer only, do NOT edit files",
        "- edit = you MAY edit files under ~/work/paketti",
        "- skill = invoke the named skill explicitly if helpful",
        "",
        "# User prompt",
        req["prompt"],
    ])
    return preamble
```

### Response delivery to Renoise

```python
def write_flag_and_reload(req_id, resp):
    truncated = resp["result"][:4000]  # Renoise show_message has length limit
    payload = (
        f"Claude reply (id {req_id})\n"
        f"{'='*60}\n"
        f"{truncated}\n\n"
        f"({resp.get('elapsed_seconds',0):.1f}s · "
        f"${resp.get('cost_usd',0):.4f} · "
        f"session {resp.get('session_id','?')[:8]})"
    )
    Path(FLAG_FILE).write_text(payload)
    # Bump main.lua mtime to fire _AUTO_RELOAD_DEBUG → smoke branch reads flag.
    (PAKETTI_DIR / "main.lua").touch()
```

The existing smoke-branch in `main.lua` (added 2026-05-08) handles the dialog pop. No further Renoise-side code is needed for v1 read-out. The branch already auto-deletes the flag, so the next reload is silent.

## launchd plist — `com.esa.paketti-claude-bridge.plist`

Path: `~/Library/LaunchAgents/com.esa.paketti-claude-bridge.plist`

```xml
<plist version="1.0"><dict>
  <key>Label</key><string>com.esa.paketti-claude-bridge</string>
  <key>ProgramArguments</key>
  <array>
    <string>/usr/bin/python3</string>
    <string>/Users/esaruoho/work/apple/bin/paketti-claude-bridge.py</string>
    <string>--once</string>
  </array>
  <key>WatchPaths</key>
  <array>
    <string>/Users/esaruoho/work/comms/queue/paketti-claude-inbox</string>
  </array>
  <key>StandardOutPath</key>
  <string>/Users/esaruoho/work/apple/analysis/paketti-claude-bridge/daemon.log</string>
  <key>StandardErrorPath</key>
  <string>/Users/esaruoho/work/apple/analysis/paketti-claude-bridge/daemon.err</string>
  <key>RunAtLoad</key><true/>
</dict></plist>
```

`WatchPaths` re-fires the daemon on every directory mtime change, which happens whenever a new request file is dropped. The `--once` flag tells the daemon to drain the inbox and exit (rather than running as a long-lived service), which keeps memory clean and lets launchd handle restart-on-crash.

Load:
```bash
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/com.esa.paketti-claude-bridge.plist
```

## Concurrency, errors, edge cases

- **Serialization**: file lock on `/tmp/paketti-claude-bridge.lock`. Two requests in quick succession process FIFO, dialogs appear in order. Paketti will see only the most recent dialog if requests stack — that's acceptable for v1 (Renoise modal queueing is automatic).
- **Stale requests**: anything older than 30 min in inbox at process time → moved to `failed/` with `.stale` suffix.
- **Timeout**: 180 s. Killed `claude` process → error written to outbox + flag.
- **`claude` not in PATH**: daemon checks at startup, writes `daemon.err`, exits non-zero so launchd marks it failed (visible in Console.app).
- **Renoise not running**: flag file is still created; next time Renoise focuses the tool reload picks it up. No data loss.
- **Audit trail**: `archive/` retains all successful pairs; rotate via cron weekly.

## Security / trust boundary

This bridge runs on Esa's local Mac with `--permission-mode acceptEdits`. That means Claude can write files under `~/work/paketti` (and only there — `--add-dir` confines its edit scope) without per-edit prompts. **Network access** in Claude Code follows the user's normal Claude Code config; no extra exposure. The inbox dir is local-user-readable only; nothing exposed off-Mac. If a future version takes prompts from Renoise on a different machine, add a shared-secret HMAC field to the request format and verify in the daemon.

## Open questions deferred to UX phase

1. Does the Paketti dialog let user pick `mode` (ask/edit) or is it always `edit`?
2. Does the dialog show a "thinking…" non-modal indicator while waiting, or just nothing until the modal pops?
3. Should there be a "cancel" path that drops a `<id>.cancel` file the daemon can detect?
4. Conversation history surfacing — does Paketti show the running thread anywhere (sidebar?), or is it only "ask one thing, see one reply"?

These belong to the UX-side spec and don't affect the protocol.
