---
description: Chat with the Mini's MLX brain (Qwen3-4B) ARMED with the Apple skill + the folder you're in — identity from skill.md, this folder's context, per-turn retrieval from wiki/. The "What would the Apple skill say" button.
allowed-tools: Bash
argument-hint: "[--fm] [--quiet] [--system \"...\"]"
---

Open a knowledge-armed chat with the Mini's on-device LLM, grounded in the Apple
skill and the current folder.

Use Bash to execute (one call):

```
/Users/esaruoho/work/apple/bin/mlx-here $ARGUMENTS
```

Notes:
- MLX/Qwen3-4B brain by default (over Tailscale); `--fm` switches to Apple
  FoundationModels (over Syncthing). `--quiet` mutes the spoken reply.
- Arming = `skill.md` identity + this folder's context + per-turn retrieval from
  `wiki/` (135 pages) via `convey.knows.retrieve` — the same engine that grounds
  Convey's "What would Bearden say" roundtable personas.
- Equivalent to `fm-chat --mlx --apple --cwd "$PWD"`. `mlx-chat` is the same tool.
- In-chat: `/reset`, `/system TEXT`, `/history`, `/exit`. Resume later with the
  printed `fm-chat --resume <id>`.
