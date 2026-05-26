---
layout: default
title: "Hey Sal v0 + seven cross-package layers shipped 2026-05-08"
---

---
description: bin/apple-grand-search + apple-grand-export + hey-sal + apple-summarize + apple-bootstrap + voice-memos xref --calendar + scripts/exporter-loupedeck. Apple-native dispatch on top of the 15 -exporter packages.
---

# Hey Sal v0 + seven cross-package layers shipped 2026-05-08


[← Back to home](./)
## What landed today

Seven cross-package tools sitting on top of the 15 `-exporter` packages. All Apple-native (no pip, no Homebrew except optional ripgrep that gracefully falls back to `grep -r`).

| Tool | Purpose | Verified live on Esa's Mac |
|------|---------|---|
| `bin/apple-grand-search PATTERN` | unified ripgrep across `~/work/apple/exported/` | 16 hits for "Kortela" across voice-memos + safari + 11 other vaults |
| `bin/apple-grand-export [--quick]` | runs all 13 read-only exporters in dependency order | 9 exporters in 28s in `--quick` mode |
| `bin/hey-sal "<utterance>" [--speak]` | natural-language router → exporter dispatch | "what did i record on Mauri Rantala" → 1 hit; "what's on my calendar today" → 3 events; "when did i last visit forum.renoise.com" → 5 visits |
| `bin/apple-summarize <file>` | LLM stub. macOS 26+ uses `LanguageModelSession`; today falls back to rule-based bullet extraction | rule-based today; auto-detects `LanguageModelSession()` instantiation |
| `bin/apple-bootstrap [--check] [--quick]` | one-command setup: env copies, plist probe, runs every exporter, opens INDEX.md | works |
| `voice-memos-exporter xref --calendar [--window N]` | first cross-package xref; matches recordings ±N min to Calendar events | Lintuparvenkuja recording → "Esko" appointment at that street; Sahaajankatu → Weekly All-hands; Recording 169 → Daily Core Team |
| `scripts/exporter-loupedeck/*.applescript` | 6 AppleScript wrappers binding exporter actions to Loupedeck buttons (today / latest-recording / snap / hey-sal / tabs-status / reminders) | reference scripts; user binds in Loupedeck Service |

## Hey Sal architecture (v0 → v1)

```
v0 (today, macOS 15.6.1):
  utterance → regex pattern bank → dispatch fn → exporter binary → display + optional `say`

v1 (when macOS 26 lands):
  utterance → FoundationModels LanguageModelSession (intent JSON) → dispatch → exporter → display + speak
```

Auto-detection in `apple-summarize` is the template: try to compile `let _ = LanguageModelSession()`; if it works, use FoundationModels; otherwise fall back. **Do not check just `import FoundationModels`** — the framework header imports on 15.6.1 but the API is `@available(macOS 26.0, *)` only.

## Hey Sal v0 intent registry (13 patterns)

Order matters — first match wins. Each handler returns `(display, brief)` where `brief` is what `say` reads aloud.

```
i_voice_memos_search          (?:what|did|find|show).{0,30}(?:voice memo|recording|record(?:ed)?).{0,20}?(?:on|about|of|for|with|matching)\s+(.+?)\??$
i_voice_memos_summarize       (?:summari[sz]e|summary of)\s+(?:my\s+)?(?:latest|last|newest)\s+(?:voice memo|recording)
i_voice_memos_latest          (?:my\s+)?(?:latest|recent)\s+(?:voice memo|recording)s?
i_mail_search (subject)       (?:find|show|where).*?(?:email|mail|message).*?from\s+([\w@.]+).*?(?:about|on|re|regarding)\s+(.+?)\??$
i_mail_search (sender only)   (?:find|show).*?(?:email|mail).*?from\s+([\w@.]+)
i_safari_history              (?:when|last).*(?:visit|browse|see).*?([\w.\-]+\.[a-z]{2,})
i_safari_dups                 (?:most.{0,10}cited|most.{0,10}duplicate|duplicate).*?(?:url|tab|bookmark)
i_calendar_today              (?:what.{0,15}(?:on|in).{0,15}calendar|today.{0,10}schedule|upcoming.{0,10}events?)
i_iwork_match (with arg)      (?:show|list|my)\s+(?:me\s+)?(?:my\s+)?(pages|numbers|keynote)\s+(.+?)\??$
i_iwork_match (bare app)      \b(pages|numbers|keynote)\s+(.+?)$
i_iwork_match (just show)     (?:show|list|my)\s+(?:me\s+)?(?:my\s+)?(pages|numbers|keynote)
i_take_photo                  (?:take|snap|capture).*(?:my|a)\s+(?:photo|picture|selfie)
i_reminders                   (?:list|show|what).{0,15}reminders?
i_status                      (?:what.?s|status|tell me|show me).{0,20}(?:apple|library|everything)
```

## Cross-package xref pattern (voice-memos → calendar)

The first cross-package xref uses the Calendar SQLite directly (Cocoa epoch + ±window seconds), no AppleScript needed. Same idiom should apply to:

- `voice-memos xref --notes` → match recording titles to Notes.app body content
- `safari xref --notes` → match open-tab URLs to Notes.app body URL mentions
- `mail xref --calendar` → match received messages to ±60 min meetings
- `photos xref --calendar` → match photo capture date to ±10 min events
- `reminders xref --calendar` → match reminder due_date to events near it

Template: open the foreign SQLite read-only, do a windowed JOIN by timestamp, decorate the source record's .md frontmatter with an `xref:` block.

## How to use Hey Sal

```bash
hey-sal "what did i record on Mauri Rantala" --speak
hey-sal "find email from kortela about pyrolysis"
hey-sal "when did i last visit forum.renoise.com"
hey-sal "what's on my calendar today"
hey-sal "show me my pages CVs"
hey-sal "take my photo"
hey-sal --list-intents
```

Pipe also works:
```bash
echo "what did I record yesterday" | hey-sal --speak
```

Bind to a Loupedeck button via `scripts/exporter-loupedeck/hey-sal.applescript` (prompts for utterance via dialog, runs `hey-sal --speak`).
