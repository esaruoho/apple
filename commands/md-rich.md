---
description: Render Markdown as rich text and put it on the macOS clipboard (Cmd-V pastes formatted). Apple-native pipeline. Usage `/md-rich <file.md>`.
allowed-tools: Bash
argument-hint: <source.md>
---

Convert Markdown → HTML → RTF → pbcopy. Cmd-V into Mail/Notes/TextEdit pastes formatted text.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/md-to-clipboard $ARGUMENTS
```

After the command completes, confirm "rich text on clipboard" — nothing else.
