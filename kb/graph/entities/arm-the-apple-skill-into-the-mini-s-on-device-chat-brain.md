---
name: Arm the Apple skill into the Mini's on-device chat brain
slug: arm-the-apple-skill-into-the-mini-s-on-device-chat-brain
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/arm-apple-skill.feature.

## Claims
- Scenario (L41): mlx-here arms the skill from the current folder
- Scenario (L50): identity is set once, knowledge is retrieved per turn
- Scenario (L58): retrieval pulls real content, not the catalog
- Scenario (L66): --apple works on the FoundationModels brain too
- Scenario (L72): graceful degrade when convey is absent
- Scenario (L81): the spoken reply uses Voicebox, not macOS say
- Scenario (L91): voicebox-say integrates with the existing stop paths
- Scenario (L97): Ctrl-C never crashes the chat
- Scenario (L106): armed chats answer live sensor/state questions
- Scenario (L116): live-data routing is precise
- Scenario (L126): the spoken voice is the premium voice, not Eddy
- Scenario (L135): the spoken reading can be stopped, paused, and resumed
- Scenario (L148): AppleToolbox's ~/bin helper symlink must exist
- Scenario (L158): showing a reply is ONE shared call, never re-rolled (DRY)
- Scenario (L169): the controls act only on a live reading
- Scenario (L178): DispatchSource signal sources must be retained
- Scenario (L186): Qwen3-4B thinking mode is verbose

## Relationships
