---
description: Apple Silicon's on-device ML stack as an automation surface — the Apple-native frameworks (Vision, NaturalLanguage, Speech, SoundAnalysis, CoreML, CreateML, and on macOS 26 FoundationModels), what each does, how to drive it with zero third-party deps, and how it plugs into the skill's pipelines. Proven: bin/vision-ocr.
---

# Apple Silicon on-device ML — the automatable stack

Apple Silicon ships a complete machine-learning stack in the OS, and almost all
of it is **Apple-native and scriptable** — which means it fits this skill's
pedigree exactly (Swift via `xcrun swiftc`, ASObjC, Shortcuts; no Homebrew, no
pip). The hardware (Neural Engine + GPU + unified memory) is already there; the
win is treating these frameworks as **automation surfaces**, not just app
features.

Probed, not guessed (the skill's "probe before naming a class" rule) — framework
presence verified in `/System/Library/Frameworks` on both machines, 2026-06-01.

## The hardware underneath
- **Neural Engine (ANE)** — 16-core on M-series; runs Core ML / Vision / NL
  inference at high TOPS, low power. `apple-report --ai` estimates its TOPS.
- **GPU (Metal / MPS)** — general ML compute; what MLX and llama.cpp use.
- **Unified memory** — the whole RAM is usable by ANE/GPU, so model size is
  bounded by RAM, not VRAM. `apple-report --can-run "70b q4"` uses this.
- **AMX / Accelerate (BNNS)** — CPU matrix/vector ML.

## The Apple-native frameworks (in-pedigree — automate these)

| Framework | What it does | Automation surface | Plugs into |
|---|---|---|---|
| **Vision** | OCR (Live Text), image classification, barcode, face, document/rectangle detection, saliency | Swift (`VNRecognizeTextRequest`…), Shortcuts | **`bin/vision-ocr`** ✓ · a fast local OCR first-pass before the Cloudcity pipeline |
| **NaturalLanguage** | language ID, tokenization, sentiment, named-entity, **word/sentence embeddings** | Swift (`NLTagger`, `NLEmbedding`), ASObjC | semantic search over the bulk-export vaults + wiki; tagging Sal/archive text |
| **Speech** | on-device speech-to-text (`SFSpeechRecognizer`) | Swift, Shortcuts | a local transcription option beside whisp |
| **SoundAnalysis** | sound event classification (`SNClassifySoundRequest`) | Swift | audio tagging |
| **Core ML** | run ANY `.mlmodel`/`.mlpackage` on ANE/GPU/CPU | Swift, `coremlc`, Shortcuts ("Run model") | drop-in custom models |
| **Create ML** | train image/text/sound/tabular models locally | CreateML.app, Swift framework | build a classifier from a folder of examples |
| **FoundationModels** | **on-device LLM** (Apple Intelligence) — guided generation, tool-calling | Swift (`SystemLanguageModel`, `LanguageModelSession`) | Apple-native local LLM — see availability below |

## Per-machine availability (probed 2026-06-01)

| | Vision | NL | Speech | SoundAnalysis | Core ML | Create ML | **FoundationModels** |
|---|---|---|---|---|---|---|---|
| **Laptop** (Sequoia 15.6.1) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **✗** (needs macOS 26) |
| **CloudcityMacMini** (Tahoe 26.3) | ✓ | ✓ | ✓ | ✓ | ✓ | ✓ | **✓ on-device LLM** |

So the **Mini is the on-device-LLM node** (Apple-native, no Ollama needed for
many tasks); both machines do the perception/classification ML today.

## Proven: `bin/vision-ocr` (the worked example)

On-device OCR via Vision — the same engine as Live Text, on the Neural Engine,
**zero pipeline, zero deps**. Self-building Swift (`vision-ocr.swift` + a wrapper
that `xcrun swiftc`-compiles to `~/.cache/apple/`). Reads images or PDFs
(rendered page-by-page) → text on stdout.

```
vision-ocr invoice.png
vision-ocr scan.pdf --pages 1 --lang en,fi
```

Verified 2026-06-01: OCR'd a test image perfectly, and **page 1 of a real
image-only 1949 scanned physics paper in ~1.85s** — accurately. That is the same
class of scan the Cloudcity ollama OCR pipeline grinds on for *days*
(see [[fleet-panel-unification]] / the OCR queue). **Implication:** vision-ocr is
a fast local **first pass** — reserve the LLM pipeline for what Vision can't read
(complex layout, handwriting, very low quality). A huge lever for the archive.

## Third-party Apple-Silicon ML (NOT skill pedigree — noted for context)
- **MLX** (Apple's array framework, pip), **Ollama**, **llama.cpp** — run great on
  Apple Silicon GPU/unified memory but install via pip/Homebrew, so they live in
  *services* (the Mini's OCR uses `ollama`/`mlx`), not in this skill's `bin/`.
- The skill's rule holds: in `bin/` we use the **system frameworks** above; the
  Cloudcity services may use third-party engines.

## How to automate it (the opportunities)
1. **vision-ocr first-pass** in the OCR pipeline — try Vision; only fall back to
   the ollama queue when Vision's output is empty/low-confidence. Days → seconds
   for text-bearing scans.
2. **NL embeddings → semantic search** across the bulk-export vaults
   ([[EXPORTERS]]) and the wiki — `bin/` tool + a Panel card.
3. **Speech** local transcription as a whisp alternative for short clips.
4. **FoundationModels on the Mini** — an Apple-native local LLM `bin/`/service
   (summarize, classify, clean OCR text) reachable via the Fleet runner.
5. Each becomes a `bin/<tool>` + a `commands/<name>.md` slash + optionally a
   Panel card and a Shortcut — the skill's zero-roundtrip pattern.

## Related
- `bin/vision-ocr` · `commands/vision-ocr.md` — the built tool
- [[automation-tiers]] · where these frameworks sit among the tiers
- [[fleet-panel-unification]] · the OCR pipeline vision-ocr can front-run
- `apple-report --ai` / `--can-run` — the model-size/TOPS estimator
