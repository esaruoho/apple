---
name: voicebox-worker — a TTS queue that survives the worker dying mid-job
slug: voicebox-worker-a-tts-queue-that-survives-the-worker-dying-mid-job
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/voicebox-worker.feature.

## Claims
- Scenario (L68): A job the worker died on mid-synth is re-queued at boot
- Scenario (L79): A poison input that orphans every time is capped, never wedges the queue
- Scenario (L90): A non-JSON (.txt) job's content is preserved on recovery
- Scenario (L98): A stalled generation is bounded and cancelled so one job can't freeze the queue
- Scenario (L108): pending counts only UNCLAIMED jobs — an orphan reads as done until next boot
- Scenario (L117): The guardian can kickstart the worker before its own synth budget

## Relationships
