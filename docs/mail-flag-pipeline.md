---
layout: default
title: "Mail flag → routing pipeline"
---

# Mail flag → routing pipeline



[← Back to home](./)
**Status:** spine shipped 2026-05-26. Purple/FreeEnergy contract live; six other colors stubbed (disabled).

Flag a message in Mail with a color, and the worker extracts it (.eml + attachments + body→markdown + URLs) and fans the typed parts out to existing pipelines per a per-color contract — then moves the message to `Processed/<Color>`. Zero LLM roundtrip in the hot path.

Mirrors the [Finder-tag pipeline](finder-tag-pipeline.md) (`tag-watcher`) and the [Voice Memos `#process` pipeline](voice-memos-process-tag-pipeline.md). Same chassis, Mail as the trigger surface.

## Architecture

```
┌──────────────────────────────────────────────────────────────────────┐
│                                                                      │
│   User flags a message in Mail (any color)                          │
│              │                                                       │
│              ▼                                                       │
│   AppleToolbox MailFlagWatcherRunner (every 120 s)                  │
│       1. mail-flag-worker --poll                                    │
│              ── scans Mail via osascript for every flagged message  │
│              ── for any Message-ID not already represented in       │
│                 inbox/work/done/failed, writes a .job to            │
│                 ~/work/comms/queue/mailflag-inbox/<slug>.job        │
│       2. mail-flag-worker                                           │
│              ── for each .job:                                      │
│                   · pulls full RFC822 via osascript                 │
│                   · saves .eml to contract.eml_dest                 │
│                   · parses MIME via stdlib email module             │
│                   · prefers text/html → markdown via stdlib         │
│                     html.parser (textutil fallback)                 │
│                   · writes body markdown with YAML frontmatter      │
│                     to contract.body_md_dest                        │
│                   · for each attachment: looks up extension in      │
│                     contract.attachments → submit-script OR copy    │
│                     to destination directory                        │
│                   · for each URL in body: optional url_action       │
│                   · moves Mail message to Processed/<Color>         │
│                   · archives .job into mailflag-done/               │
│              ── fires native banner: "📧 N mail flags routed"       │
│                                                                      │
└──────────────────────────────────────────────────────────────────────┘
```

## Why Mail Rules are NOT the primary trigger

Mail's rule system can only condition on **incoming-mail attributes** (sender, subject, headers, account, junk-status, content). There is no rule condition for "user just flagged this message". So flag-triggered routing requires polling.

Mail Rules are still useful for the inverse case: when you want incoming mail matching some pattern to be **auto-flagged AND processed** in one shot. For that, build a rule in Mail → Settings → Rules with:
- Condition: whatever incoming pattern (e.g. From contains "kortela.fi")
- Actions: "Set Color of Flag → Purple" + "Run AppleScript → ~/work/apple/bin/mail-flag-dispatch.scpt"

The .scpt is compiled from `mail-flag-dispatch.applescript` and uses the standard `perform mail action with messages` handler. It writes a `.job` directly (skipping the poll), so the next worker tick processes it.

## The contract file

`~/work/apple/bin/mail-flag-config.json` — JSON, keyed by Mail's `flag index` (integer 0..6).

```jsonc
"5": {
  "name": "FreeEnergy",
  "enabled": true,
  "eml_dest":     "~/work/mediabank/inbox/mail/eml/",
  "body_md_dest": "~/work/merlib-dump/articles/_inbox/",
  "url_action":   null,                     // null = skip URL extraction
  "attachments": {
    ".pdf":                                 "~/.claude/skills/bbs/bin/bbs-ocr-submit.sh",
    ".md .txt .markdown":                   "~/work/merlib-dump/articles/_inbox/",
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

Destination values can be either:
- A **directory** (ends with `/` or doesn't exist as an executable file) — the artifact is copied in
- A **submit script** (executable file) — the artifact is passed as `argv[1]`

Extension keys can list multiple extensions separated by spaces. `"*"` is the fallback.

## Flag-index → color mapping

Apple Mail's standard order is roughly rainbow but **varies by macOS version**. Verify yours:

```bash
~/work/apple/bin/mail-flag-worker --probe
```

This lists every flagged message in every account, with its `flag index` and subject. Flag one test message per color, then run `--probe` to see the indices, then edit `mail-flag-config.json` so the `name` field matches.

## Adding a new color contract

1. Edit `~/work/apple/bin/mail-flag-config.json`
2. Set the slot's `enabled` to `true`, fill in `eml_dest`, `body_md_dest`, `attachments`, `processed_mailbox`
3. `~/work/apple/bin/install-mail-flag-mailboxes` (creates the Processed/<Name> mailbox in Mail)
4. AppleToolbox's MailFlagWatcherRunner picks up the new config on its next 120-second tick — no rebuild needed

## Files

| Path | What |
|---|---|
| `bin/mail-flag-config.json` | Contracts. Edit this to wire flags. |
| `bin/mail-flag-worker` | Python worker. Spine. `--status`, `--poll`, `--probe`, `--dry-run`, `--reset <id>`. |
| `bin/mail-flag-dispatch.applescript` | Mail-Rule entry point (source). |
| `bin/mail-flag-dispatch.scpt` | Compiled. What you point Mail rules at. |
| `bin/install-mail-flag-mailboxes` | Creates `Processed/<Color>` mailboxes for every enabled contract. Safe to re-run. |
| `topbar/AppleToolbox.swift` | `MailFlagWatcherRunner` (120s loop) + `📧 Mail flags` menu row. |
| `~/work/comms/queue/mailflag-inbox/` | New jobs land here (`.job` JSON). |
| `~/work/comms/queue/mailflag-work/` | Jobs in flight. |
| `~/work/comms/queue/mailflag-done/` | Completed jobs (audit trail; each `.job` lists every dispatched artifact). |
| `~/work/comms/queue/mailflag-failed/` | Failed jobs (error in JSON). |
| `~/work/comms/queue/mail-flag-worker.log` | Worker log. |
| `~/work/comms/queue/mail-flag-worker.status.json` | Live counts read by AppleToolbox. |

## Job-file shape

```json
{
  "message_id": "<...@host>",
  "flag_index": 5,
  "subject": "Free Energy paper",
  "sender": "name <email@x>",
  "account": "iCloud",
  "mailbox": "INBOX",
  "date_received": "...",
  "queued_at": "2026-05-26T08:00:00Z",
  "status": "done",
  "claimed_at": "...",
  "done_at": "...",
  "dispatched": [
    {"type":"eml",        "path":"...", "ok": true},
    {"type":"body_md",    "path":"...", "ok": true},
    {"type":"attachment", "name":"x.pdf", "ext":".pdf", "dest":"...bbs-ocr-submit.sh", "ok": true, "note":"submitted → ..."},
    {"type":"move",       "to":"Processed/FreeEnergy", "ok": true}
  ]
}
```

The `dispatched` array is the per-mail audit trail. Inspect `mailflag-done/<id>.job` to see exactly where every part of that mail went.

## Why this design

- **Same chassis as tag-watcher** — operators learn one pattern, reuse it across trigger surfaces (Finder tag, Voice Memo `#process`, Mail flag).
- **Worker, contract, spine** — Esa's framing. The worker is fixed code; contracts are pure data; the spine is the LaunchAgent loop. Add a flag = add a contract.
- **All routing destinations are existing pipelines** — bbs-ocr-submit, whisp-submit, mediabank inbox, merlib-dump inbox. No new infra category.
- **Zero LLM roundtrip** — Mail Rule (if used) writes a job file; worker runs; bash/Python all the way down. Claude tokens only spent later when you ask "what landed in the inbox today?"
