# imessage-export

Extract URLs (with surrounding message context) and full conversations from specific iMessage contacts into Markdown with YAML frontmatter. Pure macOS, pure Python stdlib, zero external dependencies.

Built for archival, second-brain, and Obsidian-vault workflows. Output is plain markdown — works with any consumer.

## What it does

- Reads `~/Library/Messages/chat.db` (read-only)
- Resolves contact identifiers (phone / email) to handles, including phone-number normalization
- Extracts URLs from message text, with N messages of context before and after each URL
- Optionally fetches `<title>` / `og:title` / `og:description` for each URL (cached)
- Optionally exports full conversation transcripts (not just URLs)
- Incremental — only re-exports messages newer than last run
- Outputs per-contact `links.md` / `conversation.md` plus a cross-contact `_all-links.md` index and `_manifest.json`

## Installation

```bash
git clone https://github.com/esaruoho/apple.git
cd apple/imessage-export
cp .env.example .env             # edit your paths and name
cp config.example.json config.json  # add your contacts
```

No `pip install` needed — stdlib only.

### Grant Full Disk Access

The terminal app running this script needs Full Disk Access to read `chat.db`:

1. **System Settings** → **Privacy & Security** → **Full Disk Access**
2. Add your terminal app (Terminal, iTerm2, etc.)
3. Restart the terminal app

The script will detect missing access and tell you what to do.

## Configuration

Two files, both gitignored:

### `.env` — paths and identity

```env
OUTPUT_PATH=~/imessage-export-output
MY_NAME=Your Name
CHAT_DB=~/Library/Messages/chat.db
```

### `config.json` — contacts and settings

```json
{
  "contacts": [
    {
      "name": "Jane Doe",
      "identifiers": ["jane@example.com", "+15551234567"],
      "tags": ["friend"]
    }
  ],
  "context_messages_before": 2,
  "context_messages_after": 2,
  "exclude_domains": ["maps.apple.com"]
}
```

Don't know which identifiers to use? Run discover:

```bash
./scripts/imessage-export discover --min-messages 10
```

## Usage

```bash
./scripts/imessage-export export                       # all configured contacts, links only
./scripts/imessage-export export --contact "Jane Doe"  # one contact
./scripts/imessage-export export --full                # full conversation + links index
./scripts/imessage-export export --since 3m            # only last 3 months
./scripts/imessage-export export --enrich              # also fetch og:title/description
./scripts/imessage-export export --force               # re-export everything

./scripts/imessage-export discover                     # list handles in your database
./scripts/imessage-export contacts                     # show configured contacts + stats
./scripts/imessage-export status                       # show last run / link counts
./scripts/imessage-export search "query"               # search across extracted contexts
```

## Output structure

```
$OUTPUT_PATH/
├── _all-links.md            cross-contact link index, newest first
├── _manifest.json           per-contact summary
├── jane-doe/
│   ├── links.md             URLs grouped by date, with context blockquotes
│   └── conversation.md      full transcript (only with --full)
└── another-contact/
    └── …
```

Each markdown file starts with YAML frontmatter (Obsidian-compatible):

```yaml
---
title: "Links shared by Jane Doe"
contact: "Jane Doe"
identifiers: ["jane@example.com"]
source: imessage
total_links: 127
first_link: 2025-11-24T07:06:43
last_link: 2026-02-22T04:44:14
exported_at: 2026-02-22T07:07:38+00:00
tags: [imessage, friend]
---
```

## How it works (highlights)

### `attributedBody` typedstream parsing

On modern macOS (10.13+), the `text` column in `chat.db` is `NULL` for ~99% of messages. The actual text lives in the `attributedBody` blob, encoded as Apple's typedstream serialization (NOT NSKeyedArchiver).

This script includes a **stdlib-only typedstream parser** that decodes the variable-length integer encoding (`0x00–0x7F` literal, `0x80–0xBF` 2-byte, `0xC0–0xDF` 3-byte, `0xE0–0xEF` 4-byte) and trims trailing attribute markers (`NSDictionary`, `NSFont`, etc.) to extract clean UTF-8 text.

### Phone-number normalization

Handles store numbers in various formats (`+15551234567`, `15551234567`, `(555) 123-4567`). The script strips non-digits and matches on the last 10 digits.

### URL metadata caching

Persistent JSON cache (`.url-metadata-cache.json`) keyed by URL, crash-safe (saves every 20 fetches). Sites that work well: GitHub, news, blogs, papers. Sites that don't (return bare URLs in output): YouTube, Twitter/X, Reddit, Instagram, Google Meet — they require auth or render via JS.

### Incremental export

State at `scripts/.export-state.json` records the last exported `message.date` per contact. Subsequent runs only fetch messages newer than that timestamp unless `--force` or `--since` is used.

### Apple epoch

iMessage timestamps use nanoseconds since 2001-01-01 UTC on macOS 10.13+. The script auto-detects (threshold `> 1e12`) and falls back to seconds for older systems.

## Privacy

- The script reads `chat.db` **read-only** (SQLite URI mode)
- Nothing is uploaded; everything stays on your machine
- `.env` and `config.json` are gitignored — your contacts and paths never end up in version control
- Output directory is your choice — keep it outside the repo

## Limitations

- macOS only (uses `~/Library/Messages/chat.db`)
- Doesn't handle group chats specially — messages from group chats containing your contacts will appear, attributed to whoever sent them
- Doesn't extract attachments (images, files) — only text and URLs
- Tapback/reaction messages are filtered out by default (`associated_message_type != 0`)
- Sticker / GamePigeon / Apple Pay messages may appear as empty text

## Part of `esaruoho/apple`

This tool lives in the `apple` repo's automation collection — practical macOS automation in the spirit of Sal Soghoian's "Product Manager of Automation Technologies" role. See the parent repo for AppleScript reference, scripting dictionary indexes, automation tier guides, and more.

## License

See `../LICENSE` in the parent `apple` repository.
