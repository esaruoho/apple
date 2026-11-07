---
name: fm-mlx reuses Say, Karaoke, and Markdown (DRY)
slug: fm-mlx-reuses-say-karaoke-and-markdown-dry
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/fm-mlx-dry.feature.

## Claims
- Scenario (L86): the reply is shown the SAME way as fm-chat, in richtext
- Scenario (L95): it speaks by default (automatic talk), TTY-gated
- Scenario (L103): a captured/piped call stays silent (roundtable safety)
- Scenario (L110): nothing is duplicated — one renderer, one framer
- Scenario (L119): --raw is the shared brain interface
- Scenario (L125): fm-chat --mlx is a live REPL that prints AND says each reply
- Scenario (L133): convey roundtable uses the MLX brain BY DEFAULT, the same way
- Scenario (L143): md_to_plain strips markers for speech; md_to_ansi styles for the terminal

## Relationships
