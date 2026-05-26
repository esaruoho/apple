---
layout: default
title: "Sal Hand-Crafted Conformance — Siri Phrase Rules"
---

# Sal Hand-Crafted Conformance — Siri Phrase Rules


[← Back to home](./)
**Every Siri phrase MUST be hand-crafted.** No auto-deriving from filenames. The phrase is the user interface — it must sound like something a human would say out loud. This is WWSD Principle 11.

Derived from Sal Soghoian's 251 dictation commands (dictationcommands.com). Full analysis: `analysis/siri-phrase-humanization.md`.

**8 mandatory patterns:**

| # | Pattern | Example |
|---|---------|---------|
| 1 | **Articles** — "the", "a", "my" | "empty **the** trash", "make **a** new folder" |
| 2 | **Question forms for queries** | "**how many** tabs are open", "**what's** playing" |
| 3 | **Conversational verbs** — "make" not "create", "show me" not "list", "turn on" not "toggle" | "**show me** my playlists" |
| 4 | **Deictic context** — "this", "these" for current selection | "archive **this** email", "export **these** photos" |
| 5 | **No app name residue** — the phrase stands alone | "compile this script" not "Editor Compile" |
| 6 | **Prepositions** — "to", "from", "as", "in" | "export this **as** a PDF", "add this **to** favorites" |
| 7 | **Full natural sentences** — not abbreviated labels | "make a new document from the clipboard" not "New From Clipboard" |
| 8 | **Describe outcomes** — what happens, not which menu item | "when was the last backup" not "Machine Latest Backup" |

**Implementation:** `PHRASE_OVERRIDES` dict in `bin/shortcut-gen.py` — 296 entries, one per script. When adding a new workflow script, you MUST add a hand-crafted phrase to this dict. The test: say it out loud. If it sounds like a menu label, rewrite it.

**The generic fallback in `siri_phrase_from_name()` exists only as safety net. It should never be reached for shipped scripts.**
