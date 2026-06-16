---
description: What mlx-here is for — the free, local, folder-aware "ask this project's docs" assistant, and where it ends and Claude begins.
---

# mlx-here — the use case

`mlx-here` (= `fm-chat --mlx --apple --cwd "$PWD"`; `mlx-chat` is the same) is a chat with a small on-device LLM (Qwen3-4B) running on the always-on Mac Mini, reachable from any Mac terminal over Tailscale. It is **armed**: handed the knowledge of whichever skill GOVERNS the folder you're in, that folder's context, and per-turn retrieval from that skill's own docs.

## One line

**The cheap, private, folder-aware "ask this project's docs" button — Claude stays the expensive agent that does the work.**

## What "armed" resolves to (the governing skill)

Standing in a folder, it arms the right skill, not always Apple:

1. an in-repo `SKILL.md` / `skill.md` (e.g. `~/work/impulse-tracker`) →
2. else the folder name matched against an installed Claude skill (e.g. `~/work/paketti` → `~/.claude/skills/paketti/`; symlink/`.xrnx` names are tokenised so `org.lackluster.Paketti.xrnx` → `paketti`) →
3. else Apple (fallback).

Retrieval runs over that skill's corpus (the repo's `.md` docs, and the skill dir's reference `.md` when the skill lives outside the repo). See `arm_apple.detect_skill()`.

## When you'd actually type it

- **Grounded recall without spending Opus tokens** — "what are the 3 parts of a Paketti keybinding name?" answered from the paketti docs. No API cost, no cloud, on your tailnet.
- **Reserve Claude for the work** — the 4B model recalls / summarises / points at files; you keep Opus for implementing and committing.
- **Private + offline-ish** — nothing leaves your machines; runs on the Mini's Neural Engine.
- **Hands-free-ish** — it speaks replies (Zoe (Premium), via the shared `present()` path).
- **The hand-off seam** — `/copy` / `/copy code` drops a reply on the clipboard → paste into your editor or into Claude. The free local brain drafts; the clipboard hands it to the scalpel that commits. It is read-only and toolless by design — the copy is the only outbound path.

## What it is NOT (the honest limit)

Qwen3-4B is a **lookup / summarise / recall** assistant grounded in the skill's docs. It is not a coding agent: it cannot run commands, edit files, or be trusted for hard multi-step reasoning. Its quality is capped by the skill's docs (the retrieval). When you need real work done, that is still Claude.

Related: [`reply-presentation`](reply-presentation.md) (how it renders + speaks) · the report card `features/arm-apple-skill.feature` · memory `arm_governing_skill_not_apple`.
