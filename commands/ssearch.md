---
description: Content-search inside Claude/Codex/Gemini/fm-chat/Converse sessions — find the chat where the agent actually said something, across every project, with the resume command for each hit. Usage `/ssearch "phase conjugate" "orthogonal port"` (AND; add `--any` for OR, `--folder <dir>`, `--days N`, `--role assistant`, `--all`, `--extract out.md`).
allowed-tools: Bash
argument-hint: [--any] [--folder DIR] [--days N] [--role assistant|user] [--all] [--files] [--extract out.md] TERM...
---

Run the apple-skill `ssearch` wrapper on `$ARGUMENTS`.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/ssearch $ARGUMENTS
```

What it does: decodes the DIALOGUE turns of every session log (Claude `~/.claude/projects`,
Codex `~/.codex/sessions`, Gemini `~/.gemini/tmp`, fm-chat, Converse), searches them
fixed-string + case-insensitive, ranks sessions by how many of the terms they hit, and prints
snippets + the exact `resume` command for each. The companion to `/sessions` (which only
picks/resumes): `/sessions` resumes, `/ssearch` finds.

Key flags:
- bare terms = AND (turn must contain all); `--any` = OR.
- `--role assistant` restricts to what the agent said (filters out your prompts + injected rules).
- dialogue-only by default; `--all` also searches tool-reads + reasoning (labeled `[tool-read]`/`[reasoning]`).
- `--days N` time window (default 14; `--days 0` = all history); `--folder DIR` scopes to one project's sessions.
- `--files` = ranked session list + resume cmds only; `--extract out.md` = full matching turns → markdown.
- `--regex` opts into Python regexes (default is fixed-string, safe from ugrep-style backtracking).

After the call, report the top hit(s) and their resume commands. Do not re-run.
