# The Thought Multiplier — Architecture

> Type once, radiate to many, catch every rebound.

## What It Is

A system built entirely inside Ray Browser that turns a single typed thought into multiple simultaneous outputs — archive, LLM refinement, web publish, email, and visual graph. Five existing Ray features converge: AI Agent (18 tools), Agent Scripter (visual pipelines), Studio (app factory), Chat with Tabs (context-aware LLM), and local Phi-4 inference.

This IS BBS/Cloudcity — the personal operating system vision, finding its concrete implementation through Ray Browser's stack.

## RBI Foundation

| Principle | Where It Lives |
|-----------|---------------|
| P2: Self-Multiplication | One seed, five expressions |
| P3: The Rebound | Each destination responds — you catch the ball |
| P4: Implosion | All energy gathers in the Seed Capture before radiating |
| P5: Dead Center of Rest | The pure seed exists unmodified in the archive |
| P9: Thought Transference | "Many spots of sunlight... all extensions of one light" |

## Five Layers

```
Layer 1: SEED CAPTURE -----> Studio app (pinned tab, text field)
Layer 2: THE FORK ----------> Agent Scripter pipeline (5 parallel branches)
Layer 3: DESTINATIONS ------> Archive, LLM, Browser, Email, Graph
Layer 4: REBOUND CAPTURE ---> Dashboard showing all branch outputs
Layer 5: SELF-UPDATING -----> Studio versioning (conversational refinement)
```

## The Fork (Layer 2 Detail)

```
Seed Input (from Layer 1 localStorage)
    |
    +---> Branch 1: ARCHIVE    (raw text -> local JSONL + RayGraph)
    |
    +---> Branch 2: LLM        (seed -> Phi-4 local -> refined version)
    |
    +---> Branch 3: BROWSER    (seed -> navigate to CMS tab -> paste)
    |
    +---> Branch 4: EMAIL      (seed -> navigate to email tab -> compose)
    |
    +---> Branch 5: GRAPH      (seed -> Studio graph app -> update)
```

All five branches run **in parallel** — no dependencies between them.

## Build Phases

| Phase | What | Files |
|-------|------|-------|
| 1 | Seed Capture + Archive | `studio-apps/seed-capture.html`, `bin/thought-archive.py` |
| 2 | Add LLM Branch | Extend Agent Scripter pipeline, update dashboard |
| 3 | Add Browser + Email | Tab-navigation branches for CMS and email |
| 4 | Add Graph | `studio-apps/graph-viewer.html` |
| 5 | Rebound Dashboard | `studio-apps/rebound-dashboard.html` |
| 6 | Profile Portability | Studio versioning + sharing |

## Verification Checklist

- [ ] Phase 1: Type a seed -> appears in localStorage AND archive JSONL
- [ ] Phase 2: Type a seed -> original AND Phi-4 output appear side-by-side
- [ ] Phase 3: Type a seed -> CMS editor and email compose are populated
- [ ] Phase 4: Type 10 seeds over a day -> graph shows clustering
- [ ] Phase 5: Type a seed -> rebound dashboard shows all 4 outputs + next-seed suggestion
- [ ] Phase 6: Log in on second machine -> all Studio apps present

## Three Lineages

| Lineage | Contribution |
|---------|-------------|
| **Sal Soghoian** | Data type chaining, one-input parallel pipelines, user-first power |
| **Walter Russell** (RBI) | Self-Multiplication, Rebound, Dead Centers, Love Cycle |
| **BBS/Cloudcity** | The operating system that replaces siloed internet |

## BBS Architecture Mapping

```
BBS ARCHITECTURE                    THOUGHT MULTIPLIER IN RAY
---                                 ---
7 Ingest Surfaces                   Layer 1: Seed Capture (Studio app)
Ingest -> Extract -> Analyze        Layer 2: The Fork (Agent Scripter)
Knowledge Graph                     Layer 3E: The Graph
Dashboard / Compositor              Layer 4: Rebound Dashboard
Open/Closed Circles                 Layer 5: Profile Portability
Profile|Profile Mirror              Layer 5: Self-Updating Tools
```

## Why Only Ray Browser

AI Agent (tab interaction) + Agent Scripter (visual pipelines) + Studio (app factory) + Phi-4 (local LLM) + BGE embeddings (local) + Chat with Tabs + Studio versioning + Privacy screening. No other browser has even three of these.
