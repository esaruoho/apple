---
description: Handover for continuing the Apple Harness / harken memory-engineering work on a lesser model. Where everything lives, what is built and verified, the hard rules, and how to extend it.
---

# Apple Harness — Handover

Hand this to any model to continue the work. It is complete and running as of
2026-10-21. Read this, then the doctrine [`../concepts/apple-harness.md`](../concepts/apple-harness.md)
and the report card [`../../features/apple-harness.feature`](../../features/apple-harness.feature).

## WHERE everything lives (the folders)

| Thing | Path | In git? |
|---|---|---|
| **Engine (whitelabeled scaffold)** | `~/work/apple/harness/` (`lib/harness/*.py`, `config.example.plist`, `README.md`) | yes — `esaruoho/apple` |
| Engine CLI | `~/work/apple/bin/apple-harness` | yes |
| Remote FM binding | `~/work/apple/bin/fmremote` | yes |
| **harken (Esa's private instance)** | `~/work/harken/` (`harken.plist`, `harken` wrapper, `README.md`, `vault/`) | **no — local only** |
| Doctrine | `~/work/apple/wiki/concepts/apple-harness.md` | yes |
| Report card (triad) | `~/work/apple/features/apple-harness.feature` + `.session.md` | yes |
| Memory rule (no local heavy work) | `~/.claude/projects/-Users-esaruoho-work-apple/memory/feedback_harness_heavy_extraction_routes_to_mini.md` | n/a (memory) |
| This handover | `~/work/apple/wiki/operations/apple-harness-handover.md` | yes |

**Do NOT confuse with `~/work/harness/`** — that is a *separate, prior* shell
meta-harness (2026-10-20, atoms/listeners/procedures). Not ours. Leave it alone.

All engine work is committed+pushed to `esaruoho/apple` (`main`). Commits:
`9e355c00` (engine), `114e29dd` (capability model), `e639db37` (reconcile),
`5396b2f5` (oracle spaces).

## What it is

A **zero-token-first local ingestion engine**: point it at a folder; for each
asset it extracts text with native Apple organs (Vision OCR, Whisper via a
belt), structures it (NaturalLanguage NER + NLEmbedding), and only then spends
LLM tokens — handing the model entities + a tiny snippet, majority-voted. State
lives in a crash-only, resumable ledger. Two layers:

- **Layer 1 — `harness`** (whitelabeled, ships in apple): the engine. No Esa/Mini
  strings. A stranger clones apple and it runs on one Mac.
- **Layer 2 — `harken`** (`~/work/harken`, private): config overrides that bind
  the engine to Esa's fleet (Mini belts). Bindings only; no engine code.

## Architecture (five modules in `harness/lib/harness/`)

- `config.py` — loads a **plist** (`plistlib`, stdlib, zero deps). Holds the
  capability specs, modality map, vault/embeds paths. `DEFAULTS` is the honest
  local-only whitelabel config.
- `ledger.py` — `.harness-ledger.jsonl` at the pool root. Append-only, fsync'd,
  latest-row-per-path wins, tolerates a torn final line. States:
  `needs_analysis → extracting → extracted → structured → analyzed` (or `error`).
  The episodic memory; the source of truth for resume.
- `capabilities.py` — **the safety layer.** Resolves a capability
  (`ocr/transcribe/ner/embed/reason`) to a provider: `local` only if
  `local_preflight` proves it is ALREADY installed (no download), `fleet` only if
  `fleet_heartbeat` says the belt is alive, else **error**. Never auto-installs.
- `organs.py` — runs the resolved extraction/NER/embed commands. A fleet organ
  may deliver its result in a file (`fleet_collect`, `{stem}` template) instead
  of stdout.
- `reasoning.py` — majority vote-to-judge: calls the resolved `reason` command N
  times, takes the majority, flags ties (flip-flop).
- `loop.py` — Think→Act→Observe→Stop per asset. Writes Obsidian Asset Notes.
- `oracle.py` — post-pass: projects analyzed assets into per-entity
  `oracle_spaces/<slug>/{namespace.yaml,index.md}`.

CLI verbs (`apple-harness <verb>` / `harken <verb>`): `capabilities` (show where
each capability resolves), `init`, `ingest --pool DIR [--recursive]`, `resume
--pool DIR`, `status --pool DIR`, `oracle --pool DIR`.

## THE HARD RULES (do not violate — each cost a real incident)

1. **NEVER download a model to "run it locally".** Heavy extraction routes to
   CloudcityMacMini. Local only for LIGHT, OS-shipped ANE organs (`vision-ocr`,
   `apple-ner`, `apple-embed`). The capability `local_preflight` enforces this:
   whisp → model-already-in-cache; `fm` → macOS ≥ 26. Fail → fleet or error.
   (Incident: local whisp pulled large-v3 1.2 GB onto the laptop.)
2. **Transport is Syncthing belts, NOT SSH.** `fmremote` wraps `fm-submit`
   (fm-inbox→Mini→fm-outbox); transcription is `convey transcript` (Mini whisp
   belt); OCR-at-scale is `convey ocr`. SSH is brittle; don't use it as transport.
3. **No third-party deps.** Python stdlib + Apple frameworks only. Config is
   plist, ledger is JSONL, oracle YAML is hand-emitted. No PyYAML, no Homebrew,
   no pip, no docling/marker/torch.
4. **No nohup / no daemon on the Mini.** Long runs go under Cloudcity-Boot.app +
   `systems.yaml`. (Not yet wired for the harness.)
5. **Reasoning (`fm`) is non-deterministic** → always majority-vote, never a
   single call.

## Current state (honest)

**Built + runtime-verified (2026-10-21):** the full loop on text/image/pdf/audio;
capability resolution (local vs fleet) with the no-download gate proven (HF cache
stayed empty); `fmremote` round-trip to the Mini; majority-vote reasoning; the
ledger + idempotent resume; recoverable error on a belt blip + resume recovery;
oracle spaces. harken routes transcribe→Mini whisp, reason→fmremote.

**Not yet built (TODO, in priority order):**
1. **Async OCR for scanned/image-only PDFs** via `convey ocr` — needs the engine
   loop to grow a `submitted → awaiting → collect` substate (today crisp
   images/PDFs use synchronous local `vision-ocr`; scanned docs have no path).
2. **Event-driven listeners** — a drop-folder/Syncthing watcher that senses a new
   asset (push) and calls `harken ingest` (pull). Can reuse the prior
   `~/work/harness/listeners/` pattern.
3. **Cloudcity-Boot.app + `systems.yaml`** supervision for large (5TB) runs.
4. **Formula → LaTeX** extraction belt on the Mini (no belt exists yet).
5. Lift the two `@runtime-untested` card scenarios (image/pdf/audio modalities
   end-to-end was later verified; torn-ledger crash recovery still untested).

## How to run / verify (copy-paste)

```sh
# see where capabilities resolve on THIS machine (proves no-download behavior)
harken capabilities

# ingest a folder (image/pdf local; audio→Mini; reasoning→Mini)
harken ingest --pool ~/work/harken/testpool
harken status --pool ~/work/harken/testpool
harken resume --pool ~/work/harken/testpool   # finish any errored rows
harken oracle --pool ~/work/harken/testpool    # entity-first projection

# whitelabel engine (no fleet): on a non-Tahoe Mac, transcribe/reason read
# UNAVAILABLE rather than downloading — that is correct.
apple-harness capabilities
```

Outputs land in the vault: `<vault>/System/Assets/<id>.md` (Asset Notes),
`<vault>/oracle_spaces/<slug>/` (entity spaces), `<embeds>` JSONL (512-dim
vectors). harken's vault is `~/work/harken/vault`.

## How to extend (the pattern)

- **Add a capability provider** (e.g. a Qwen-MLX belt for `reason`): edit the
  capability's `fleet_cmd` + `fleet_heartbeat` in `harken.plist`. No engine code.
- **Add a modality**: add the extension → modality in `config.py` `modalities`,
  and modality → capability in `modality_capability`.
- **Route a heavy organ to the Mini**: give its capability a `fleet_cmd` (a
  `convey` verb / submit client), `fleet_heartbeat` (a belt liveness check), and
  `fleet_collect` if the belt writes a file. Set `prefer: fleet`.

## Reject when a future plan proposes it (from three external handovers)

- local docling/marker/whisp/torch (rule 1); SSH transport (rule 2); PyYAML (rule
  3); a parallel Qwen-over-SSH pipeline (it is just a `reason` fleet provider);
  putting the home in `convey` (the engine is in apple; convey is a consumer).

See also: [[feedback_harness_heavy_extraction_routes_to_mini]], the doctrine's
reconciliation sections, and `~/work/harken/README.md`.
