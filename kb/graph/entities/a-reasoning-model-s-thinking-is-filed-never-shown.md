---
name: A reasoning model's thinking is filed, never shown
slug: a-reasoning-model-s-thinking-is-filed-never-shown
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/fm-think-no-leak.feature.

## Claims
- Scenario (L64): The exact payload that leaked to Discord now yields no answer, not a trace
- Scenario (L77): A completed answer ships clean while its thinking is filed silently
- Scenario (L86): reasoning fields are NEVER promoted to the answer
- Scenario (L95): An untagged trace is still caught
- Scenario (L105): An unclosed think tag leaves no answer behind
- Scenario (L112): Discord is guarded at the last mile
- Scenario (L122): The revise prompt no longer forces the model to deliberate in circles
- Scenario (L132): The filed thinking is extractable and correctable from the laptop
- Scenario (L143): The 14B reasoner gets a budget it can actually finish in
- Scenario (L156): A correction typed as two quick messages arrives as ONE thought
- Scenario (L168): Our own provenance header is never fed back to the model
- Scenario (L177): Prompt delimiters are not copied into the answer
- Scenario (L185): Blank messages are never posted
- Scenario (L192): The model's answer is never our own grounding read back to us
- Scenario (L200): A drafted answer cannot cite the changelog by bare date
- Scenario (L209): A "has this been fixed?" question actually reaches the fix
- Scenario (L224): The thread is re-answered with prose, not deliberation
- Scenario (L232): A 4-bit 14B still under-uses grounding it was handed
- Scenario (L241): The circling rate is watched, not just recorded

## Relationships
