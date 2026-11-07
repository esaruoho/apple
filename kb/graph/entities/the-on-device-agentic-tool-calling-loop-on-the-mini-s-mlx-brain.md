---
name: The on-device agentic tool-calling loop on the Mini's MLX brain
slug: the-on-device-agentic-tool-calling-loop-on-the-mini-s-mlx-brain
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/mlx-agent-tool-loop.feature.

## Claims
- Scenario (L47): the loop executes a tool then returns a final answer
- Scenario (L55): the SAFE tool registry runs the real verbs read-only
- Scenario (L64): the sandbox refuses paths outside $HOME
- Scenario (L71): --dry-run lists the registry and mlx-here --agent routes here
- Scenario (L78): a real task drives the belt end-to-end on the Mini
- Scenario (L91): long files are paged (a bug the live run surfaced)
- Scenario (L101): transient 502/503 reload windows are retried (a 2nd bug the live run surfaced)
- Scenario (L108): the queue twin runs the loop on the Mini (Comms/Syncthing path)
- Scenario (L120): the loop refuses an answer that cites an un-opened file (grounding enforcement)
- Scenario (L134): the final answer is shown via the ONE shared presenter (DRY)

## Relationships
