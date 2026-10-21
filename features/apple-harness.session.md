# Session — apple-harness

The spawning conversation for the Apple Harness. Faithful, not flattering.

## How to get back
- Session ID: `ce16f90d-5886-4101-8d57-510226c39db9`
- Resume: `claude --resume ce16f90d-5886-4101-8d57-510226c39db9`
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/ce16f90d-5886-4101-8d57-510226c39db9.jsonl`
- Date: 2026-10-21

## What was asked
Esa read a generic Gemini "AI harness" doc (`~/Downloads/harness-google.md`) describing
zero-token local ingestion on Apple Silicon, and wanted an **Apple Harness** that uses
the apple skills. The arc:
1. "talk to you about Harness" → I mapped the generic 5-layer architecture onto tools that
   already exist here (vision-ocr, whisp, apple-embed, fm, vault, convey/DreamGraph) and
   found only one missing box: the execution loop + status ledger.
2. Esa chose "documented doctrine first" → `wiki/concepts/apple-harness.md`.
3. Esa introduced the **two-layer whitelabel split** (companion-mac pattern): generic
   `harness` scaffold ships with apple; private `harken` (`~/work/harken`) supplies bindings.
4. A second plan arrived (`~/Downloads/apple_harness_scaffolding_plan.md`) written against the
   *pre-split* design. I reconciled it: adopt its skeleton, reject its convey/Mini couplings,
   corrected its verified bugs.
5. Esa's correction on reasoning: local `fm` is impossible here (macOS 15.6.1); use
   **`fmremote` → CloudcityMacMini**, which did not exist yet ("or it will, once you've done it").
6. "write the work, create the apple harness … like Apple would make it" → this build.

## Decisions and corrections (the grade's audit trail)
- **Config format = plist**, not YAML, specifically to keep the scaffold dependency-free
  (stdlib `plistlib`) and "like Apple would make it." The doctrine's earlier YAML snippet was
  superseded.
- **Reference organs are all LOCAL + Apple-native** (vision-ocr, apple-ner, apple-embed, fm)
  so the whitelabel runs on one Mac. The async `convey ocr` and the Mini are harken's bindings,
  NOT the engine's.
- **Reused `bin/apple-ner`** — the imported plan invented `bin/apple-tagger-ner`, which does not
  exist. DRY: reuse-before-rerolling.
- **`fmremote` is a thin wrapper over `fm-submit`**, not a new transport. All of fm-submit's
  decoration goes to stderr, so the harness captures a clean answer on stdout (verified).
- Honest grading: text-modality extraction, NER, embed, ledger, resume, fmremote round-trip,
  and 3-vote majority reasoning were **run live** this session (Mini was up, heartbeat 29s).
  Image/PDF/audio through the loop, `init`, and torn-ledger recovery were **not run** end-to-end
  and are graded `@runtime-untested` accordingly.

## Live verification (2026-10-21)
- Zero-token path: 2 text assets → correct entities (Tesla/Westinghouse/Russell/Schauberger/
  Linz/Austria), 512-dim vectors, Asset Notes, ledger → analyzed.
- `fmremote "…gold"` → `Au` (round-trip 6.9s); `…France` → `Paris`.
- Reasoning via fmremote, votes=3: both assets reached a 2/3 majority tag-set.
- Resume: 0 pending (idempotent).

## Known gaps / next
- Build **harken** (`~/work/harken`) as the binding layer; it can absorb the prior
  `~/work/harness` listener idea (event-driven drop-folder ingestion) as its trigger.
- Run image/PDF/audio through the loop end-to-end to lift those scenarios to @runtime-verified.
- Supervised large runs go under Cloudcity-Boot.app + systems.yaml (no nohup) — harken's concern.
