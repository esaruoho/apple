---
description: How to put genuine rich text on the macOS clipboard from a CLI without Homebrew/pip/PyObjC. Failures + working path documented 2026-05-08.
---

# Apple-native rich-text clipboard recipe (Markdown → RTF → clipboard)

## Goal

Take a Markdown source, render it as rich text, put it on the macOS clipboard so `Cmd-V` into Mail / TextEdit / Notes pastes with bold / italic / lists / links / code formatting. Apple-native only.

**Why:** Composing email drafts in Markdown but sending via Mail.app where the recipient expects formatted text. Same pattern applies to any CLI-to-rich-text handoff.

## Working pipeline

```bash
# 1. Render Markdown → HTML (Python; group consecutive lines into paragraphs)
python3 your-md-to-html.py SRC.md > /tmp/email.html

# 2. HTML → RTF via Apple's textutil (ships with macOS)
textutil -convert rtf -stdout /tmp/email.html > /tmp/email.rtf

# 3. RTF → clipboard via AppleScript with the «class RTF » class type
osascript <<'EOF'
set theData to read (POSIX file "/tmp/email.rtf") as «class RTF »
set the clipboard to theData
EOF

# 4. Verify
osascript -e 'clipboard info'
# expected: «class RTF », <bytes>
```

## Failures encountered + why they failed

### ❌ `pbcopy < file.rtf`

Puts raw RTF bytes on clipboard as `public.utf8-plain-text`. Cmd-V pastes the RTF source code, not the rendered text.

### ❌ `pbcopy -Prefer rtf < file.rtf`

`pbcopy` doesn't have a `-Prefer` flag. (`pbpaste` does, but it reads not writes.)

### ❌ `python3` with `from AppKit import NSPasteboard`

```
ModuleNotFoundError: No module named 'AppKit'
```

`/opt/homebrew/Cellar/python@3.14/...` (Homebrew Python) doesn't bundle PyObjC. Apple's `/usr/bin/python3` does — but `/usr/bin/python3` triggers a "select developer tools" prompt on a fresh install. Don't rely on PyObjC for cross-Mac portability.

### ❌ `osascript -e 'set the clipboard to (POSIX file "X" as «class RTF »)'`

Setting the clipboard to a *file reference* doesn't work — the clipboard refuses the coercion. You must `read` the file first to get the actual bytes.

## Critical syntax detail

The pasteboard type is **`«class RTF »`** with a TRAILING SPACE inside the chevrons. Without the space:

```bash
osascript -e 'set the clipboard to (read X as «class RTF»)'  # ❌ syntax error
osascript -e 'set the clipboard to (read X as «class RTF »)'  # ✅ works
```

This is because Apple Event class codes are 4 characters; `RTF ` with space-padding is the official 4-char code. Use the same pattern for HTML (`«class HTML»`), JPEG (`«class JPEG»`), etc.

## Markdown → HTML rendering: paragraph grouping

The first failed attempt wrapped every source line in `<p>...</p>`, producing 80px of vertical space between every line because Markdown source uses hard wraps every ~70 chars. **Fix**: group consecutive non-blank, non-special (non-#, non-`-`, non-blockquote) lines into a single paragraph BEFORE wrapping in `<p>`:

```python
buf = []
def flush_buf():
    global buf
    if buf:
        para = ' '.join(buf).strip()
        if para:
            out_lines.append(f'<p>{para}</p>')
        buf = []
for raw in body.splitlines():
    line = raw.rstrip()
    if not line.strip():
        flush_buf()
        continue
    if line.startswith('## '):
        flush_buf()
        out_lines.append(f'<h2>{line[3:]}</h2>')
        continue
    # ... handle ## / # / - / etc ...
    buf.append(line)
flush_buf()
```

Inline replacements (bold, italic, code, links) run AFTER paragraph join, otherwise asterisk-italics that span source-line wraps don't match.

## Cross-machine portability

The recipe uses only `python3` (no PyObjC), `textutil` (ships with macOS), and `osascript` (ships with macOS). Works on every Mac since at least 10.10. `/usr/bin/python3` works too if Homebrew Python isn't installed.

## When to use

- CLI tools that produce documents the user wants to send via Mail
- Generated reports that should paste into Pages / Word / TextEdit with formatting
- Hey Sal output that needs to land in a Note with structure
- Any place where the alternative is making the user manually convert formats
