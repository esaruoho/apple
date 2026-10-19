# Session content search (`ssearch`)

description: Search what was actually *said* inside Claude/Codex/Gemini/fm-chat/Converse session logs, across every project, and get the resume command for each hit. The content-search companion to the `sessions` TUI.

`bin/sessions` lists and **resumes** sessions for a folder. `bin/ssearch` **searches
the dialogue** inside them. Together: "find the chat where the agent said X, then jump
back into it."

## Why it exists

Finding "the conversation where the agent mentioned heat pump / phase conjugation" by
hand is an hour of per-provider `jq`/`grep`, and it keeps going wrong for three reasons
this tool handles:

1. **Three layers, one word.** A term like `valve` or `heat pump` usually appears in
   **tool-reads** (archive text the agent *quoted*) and in injected **rule-boilerplate**
   (CLAUDE.md / AGENTS.md pasted into context), not in the **dialogue**. ssearch searches
   dialogue only by default, strips boilerplate, and labels tool-reads/reasoning when you
   opt into them with `--all`.
2. **Five providers, five formats.** Claude JSONL, Codex rollout JSONL, Gemini chat JSONL,
   fm-chat JSONL, Converse JSON — each with a different turn shape. ssearch has a decoder
   per provider (same path + resume conventions documented in `bin/sessions`).
3. **Memory ≠ wording.** You remember the concept, not the sentence. Rank by how many terms
   a session hits, use `--any` for OR, and the richest conversation floats to the top.

## Usage

```
ssearch "phase conjugate" "orthogonal port"      # AND: turns with ALL terms
ssearch --any valve "heat pump"                  # OR:  turns with ANY term
ssearch --role assistant "gating shield"         # only what the agent said
ssearch --folder ~/work/merlib-dump VALVE        # scope to one project's sessions
ssearch --days 30 "phase conjugate"              # time window (default 14; 0 = all)
ssearch --all "heat pump"                         # also search tool-reads + reasoning
ssearch --files "phase conjugate"                 # ranked sessions + resume cmds only
ssearch --extract out.md "phase conjugate" orthogonal   # full matching turns → markdown
```

Matching is **fixed-string, case-insensitive** by default — safe from ugrep-style
catastrophic backtracking (see the global regex rule). `--regex` opts into Python regexes.

Each hit prints the provider, date, term score, turn count, and the exact resume command:
- Claude → `claude --dangerously-skip-permissions --resume <uuid>`
- Codex → `codex resume <uuid>`
- Gemini → `cd <project> && gemini --resume <sessionId>`
- fm-chat → `fm-chat --resume <uuid>` · Converse → `fm-converse --session <name>`

Slash: `/ssearch …`. Apple-native, stdlib only.

## Related

- [`bin/sessions`](../../bin/sessions) — the TUI picker/resumer (upstream `esaruoho/sessions`).
- The zero-roundtrip pattern — `bin/<tool>` + `commands/<name>.md` + slash.
