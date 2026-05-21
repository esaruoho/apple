---
name: Sal cross-decade lineages — WWDC patterns alive in 2026
description: 8 architectural patterns Sal introduced at WWDC 2003-2015 that survive (under different names) into 2026 macOS Sequoia; reference these primary sources before inventing new automation patterns in the repo
type: reference
originSessionId: f28a1d2b-4331-43e3-9b69-6e7756ffc44e
---
Eight architectural patterns Sal Soghoian demoed at WWDC that are still alive — sometimes renamed — in macOS Sequoia 2026 and in this repo. **Reference primary sources before inventing new automation patterns.** Full doc at `analysis/sal/sal-cross-decade-lineages.md`.

## The 8 lineages

1. **Voice trigger as offline-local primitive** — `listen for` (2011) → Speakable Workflows (2013) → Vocal Shortcuts (2024) → Hey Sal v1 (2026)
2. **Framework bridge from a scripting language** — `call method` (2003) → Scripting Bridge (2007) → ASOC (2009/2011) → JXA `$` bridge (2014)
3. **Config-via-filesystem (user-placed-file pattern)** — Finder-comment droplet prefs (2003, WWSD #38) → PDF Services (2003) → Services folder (2007) → `~/Library/Application Scripts/` (2012, WWSD #39) → Script Libraries (2013)
4. **Workflow as host-app-embedded engine** — `AMWorkflow` (2007) → Savant Systems (2008) → App Extensions (2014) → App Intents (2020)
5. **Content pipeline upstream of sealed device** — HTML5 Web-Apps for iPad (2010) → Books/Markdown (2014) → MTC 2019 → CCATP 2023 → `bin/apple-grand-export` (2026)
6. **Filename-as-trigger-phrase (route by intent, not handler)** — Speakable Workflows (2013) → Vocal Shortcuts (2024) → Hey Sal matcher (2026)
7. **Auto-conversation hosts (iChat responder template)** — iChat responder (2011) → Messages handlers (2012) → pakettibot cloudcity (2026)
8. **Configurator as drag-drop fleet operator** — Hayman ARD-Services (2009) → Apple Configurator 2 + Automator (2015)

## When to apply

When the user proposes a new automation pattern, **check this map first**:
- If the pattern has a 10-25 year Sal lineage, read the primary source (named WWDC session) before designing
- Probe the current surface — does the named API still work in Sequoia 2026? Often yes, just undocumented
- Inherit Sal's structural choices even if you rebuild the implementation

## Why this matters

These aren't trivia. They're load-bearing architecture. When Esa ships a voice trigger, a config-via-filesystem pattern, or a workflow exporter in this repo, **the right reference material is sometimes 23 years old.** Per-session deep-dives in `sources/sal/wwdc/<session>/analysis.md`.
