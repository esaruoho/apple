# Thought Multiplier

Type once, radiate to many, catch every rebound. A system built inside Ray Browser that turns a single typed thought into multiple simultaneous outputs.

## Architecture

```
Layer 1: SEED CAPTURE -----> Studio app (pinned tab, text field)
Layer 2: THE FORK ----------> Agent Scripter pipeline (5 parallel branches)
Layer 3: DESTINATIONS ------> Archive, LLM, Browser, Email, Graph
Layer 4: REBOUND CAPTURE ---> Dashboard showing all branch outputs
Layer 5: SELF-UPDATING -----> Studio versioning (conversational refinement)
```

## Files

| File | Purpose |
|------|---------|
| `thought-multiplier/architecture.md` | Full architecture document |
| `thought-multiplier/studio-prompts.md` | Exact prompts to paste into Ray Studio |
| `thought-multiplier/agent-scripter-pipeline.md` | Agent Scripter JSON pipeline specs (Phase 1 archive-only, Phase 2 +LLM, Phase 3 full 5-branch fork) |
| `thought-multiplier/archive-schema.md` | JSONL archive format specification |
| `thought-multiplier/studio-apps/seed-capture.html` | Seed Capture Studio app (Phase 1) |
| `thought-multiplier/studio-apps/rebound-dashboard.html` | Rebound Dashboard (Phase 5) |
| `thought-multiplier/studio-apps/graph-viewer.html` | Thought Graph visualization (Phase 4) |
| `bin/thought-archive.py` | CLI archive manager (stats, search, add, export). Archive lives at `~/thought-archive.jsonl`. |

## Three lineages

- **Sal Soghoian** — data type chaining; one-input parallel pipelines; user-first power.
- **Walter Russell (RBI)** — Self-Multiplication (P2), Rebound (P3), Dead Centers (P5).
- **BBS / Cloudcity** — the operating system that replaces siloed internet — this IS the BBS ingest surface.

## Why only Ray Browser

AI Agent (18 tools) + Agent Scripter (visual pipelines) + Studio (app factory) + Phi-4 (local LLM) + BGE embeddings + Chat with Tabs + Studio versioning + Privacy screening. No other browser has even three of these.

See also [pattern-reusability](../concepts/pattern-reusability.md) — Thought Multiplier is the most explicit instance of the "scripts are single-use; principles are reusable" thread.
