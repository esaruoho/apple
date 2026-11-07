---
name: fm-converse — a remembering conversation with the on-device LLM
slug: fm-converse-a-remembering-conversation-with-the-on-device-llm
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/dist/fm-converse.gherkin.feature.

## Claims
- Scenario (L11): A follow-up question keeps the prior context
- Scenario (L20): Replay stays inside the 4096-token FoundationModels window
- Scenario (L30): Markdown renders as ANSI on a terminal, plain when piped
- Scenario (L39): A worker/guardrail/timeout error is surfaced, not swallowed
- Scenario (L47): A file path is read and summarised instead of sent literally
- Scenario (L56): Context-overflow self-heal retries without history
- Scenario (L65): The conversation is keyed to the newest Converse session dir
- Scenario (L74): Stored conversation remains replay memory while the livefile is the durable artifact
- Scenario (L83): A terminal fm-converse turn becomes a Converse-shaped livefile
- Scenario (L92): Converse.app-owned turns are not duplicated by fm-converse
- Scenario (L101): Captured fm-converse turns are pushed to Scaff
- Scenario (L53): A follow-up question keeps the prior context
- Scenario (L62): Replay stays inside the 4096-token FoundationModels window
- Scenario (L72): Markdown renders as ANSI on a terminal, plain when piped
- Scenario (L81): A worker/guardrail/timeout error is surfaced, not swallowed
- Scenario (L89): A file path is read and summarised instead of sent literally
- Scenario (L98): Context-overflow self-heal retries without history
- Scenario (L107): The conversation is keyed to the newest Converse session dir
- Scenario (L116): Stored conversation remains replay memory while the livefile is the durable artifact
- Scenario (L125): A terminal fm-converse turn becomes a Converse-shaped livefile
- Scenario (L134): Converse.app-owned turns are not duplicated by fm-converse
- Scenario (L143): Captured fm-converse turns are pushed to Scaff
- Scenario (L152): A flubuild turn uses the same replay memory and livefile transcript shape
- Scenario (L173): Flubuild budgets input with the server tokenizer and exposes HTTP failures

## Relationships
