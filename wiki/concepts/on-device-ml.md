# On-device ML — Apple's built-in inference layer (no Homebrew, no pip, no network)

**The gap this fills:** the skill knew automation (AppleScript, Shortcuts, image batch) but nothing about the *intelligence* frameworks Apple ships in every macOS. Same shape as the ASObjC miss — a first-party capability sitting unused for years. Discovered 2026-06-01 while replacing a brittle "shares ≥3 words" keyword matcher (in the Paketti forum archive) with real meaning-similarity. The keyword matcher missed paraphrases; an on-device embedding ranked them correctly in one pass.

All of this satisfies the **Apple-native pedigree constraint**: first-party SDK frameworks, callable from Swift, zero third-party deps, runs on the Neural Engine / locally, no network.

## NaturalLanguage — the one to reach for first

`NLEmbedding` (built in since **macOS 10.15**, 2019) gives **on-device neural embeddings**:

- `NLEmbedding.sentenceEmbedding(for: .english)` → **512-dim sentence vectors.** `emb.vector(for: "some text")`.
- `NLEmbedding.wordEmbedding(for: .english)` → word vectors + `neighbors(for:)`.
- Cosine of two vectors = similarity by **meaning**, not shared words.

```swift
import NaturalLanguage
let emb = NLEmbedding.sentenceEmbedding(for: .english)!   // dim 512
let a = emb.vector(for: "dont make me retype the instrument number")!
let b = emb.vector(for: "Quick Replace Instrument Number")!   // ~0 shared words
// cosine(a,b) ≈ 0.63  — ranked top over unrelated lines a keyword matcher would tie
```

**Cosine guide (this model):** `>0.8` strong · `0.6–0.8` maybe · `<0.6` usually noise. It's a *light* model — excellent for **ranking** candidates, but confirm hits by hand (or escalate to CoreML / Foundation Models). The same framework also does, all on-device: language identification (`NLLanguageRecognizer`), tokenization (`NLTokenizer`), named-entity recognition + POS (`NLTagger`), and sentiment.

### Tested finding: the built-in *transformer* (`NLContextualEmbedding`) does NOT beat it for similarity

`NLContextualEmbedding(language: .english)` (macOS 14+) is a real BERT-style transformer Apple ships built-in — `try ce.load()`, then `embeddingResult(for:)` gives per-token vectors you mean-pool. Tempting as a free upgrade. **But measured on the same task it was worse for similarity ranking:** scores compressed into 0.82–0.86 for *everything* (related and unrelated alike) and it mis-ranked the target — the known raw-BERT *anisotropy* problem (embeddings cluster in a narrow cone; you need sentence-transformer fine-tuning to spread them). Static `NLEmbedding` gave wider separation (0.51 vs 0.30–0.41) and ranked correctly. **Lesson:** `NLContextualEmbedding` is for downstream tasks (classification/NER features), not drop-in sentence similarity. The genuine text-similarity upgrade is a *fine-tuned sentence-transformer* — which Apple does not ship ready-made → CoreML (below).

### The reusable tool

**`bin/apple-semantic-match`** — Swift, NLEmbedding, no deps. This is the "find connections between files in a folder" engine:

```
apple-semantic-match --dir <folder>                 # most meaning-related FILE PAIRS in a folder
apple-semantic-match --from <A> --to <B> [--top N]   # each line in A → nearest line(s) in B
apple-semantic-match --query "text" --to <B>          # one query → nearest lines in B
        [--threshold X] [--json]
```

Proven: in folder mode, "how to slice a breakbeat into pieces" ↔ "chopping a drum loop into slices" scored 0.525 (top pair) with **zero shared words**, while an unrelated note fell away.

## The rest of the on-device family (the map)

One first-party framework per job — all local, all no-dep:

| Framework | What it does on-device | Since |
|-----------|------------------------|-------|
| **NaturalLanguage** | embeddings, language ID, tokenize, NER, sentiment | 10.15 |
| **Vision** | OCR (`VNRecognizeText`), saliency, object/face/body, barcodes, image similarity (`VNFeaturePrint`) | 10.13+ |
| **Speech** | on-device speech-to-text (`SFSpeechRecognizer`, `requiresOnDeviceRecognition`) | 10.15 |
| **SoundAnalysis** | sound classification (`SNClassifySoundRequest`) | 10.15 |
| **Translation** | on-device text translation | 15 (Sequoia) |
| **CoreML** | run ANY converted model (sentence-transformers, etc.) on the Neural Engine — the upgrade path when NLEmbedding is too light | 10.13 |
| **CreateML** | train/fine-tune locally | 10.14 |
| **FoundationModels** | the ~3B on-device LLM (`LanguageModelSession`) — real reasoning, structured output | **macOS 26 only** |

### Image analogue — ships ready, no conversion: `bin/apple-image-similar`

`Vision.VNGenerateImageFeaturePrintRequest` → `VNFeaturePrintObservation` is the image analogue of NLEmbedding — but unlike the text-similarity upgrade, **this one Apple ships fully tuned and built-in.** Embed each image on the Neural Engine, `obs.computeDistance(&d, to: other)` ranks by visual content (L2; 0 = identical).

```
apple-image-similar --dir <folder> [--top N] [--threshold D] [--json]   # most-similar / duplicate PAIRS
apple-image-similar --query <image> --dir <folder>                       # nearest images to one image
```

Proven: 33-image folder in 2.6 s — flagged two PNGs shot 2 s apart at **distance 0.000** (near-duplicate), then graded the rest. Distance guide: `<10` near-dup · `10–20` similar · `>25` unrelated (content-dependent). This is the dedup / "find the screenshot like this one" engine, zero deps.

## Sharper text similarity — CoreML sentence-transformer on the ANE (the real upgrade)

When `NLEmbedding` is too coarse and you need sentence-transformer quality, stay on the Apple stack via CoreML — the *only* dep is build-time, runtime is pure system framework:

1. **Convert once (build-time, needs `coremltools` — a pip dep, used once, never shipped):**
   ```python
   # pip install coremltools transformers torch   ← build machine only
   import coremltools as ct, torch
   from transformers import AutoModel, AutoTokenizer
   name = "sentence-transformers/all-MiniLM-L6-v2"   # 384-dim, fast, strong
   tok, mdl = AutoTokenizer.from_pretrained(name), AutoModel.from_pretrained(name).eval()
   ex = tok("hello", return_tensors="pt", padding="max_length", max_length=128)
   traced = torch.jit.trace(mdl, (ex.input_ids, ex.attention_mask))
   ct.convert(traced, inputs=[ct.TensorType("input_ids", ex.input_ids.shape, dtype=int),
                              ct.TensorType("attention_mask", ex.attention_mask.shape, dtype=int)],
              compute_units=ct.ComputeUnit.ALL,          # ALL = let CoreML use the Neural Engine
              minimum_deployment_target=ct.target.macOS14).save("MiniLM.mlpackage")
   ```
2. **Runtime (zero deps): load `MiniLM.mlpackage` via CoreML, mean-pool, cosine.** The catch is the **WordPiece tokenizer** in Swift. Two Apple-clean routes: (a) hand-roll WordPiece from the model's `vocab.txt` with stdlib (greedy longest-match, `##` continuation) — ~80 lines, fully dep-free; (b) Apple's own example pipeline uses `swift-transformers` (SwiftPM), which is a dep — avoid if pedigree must stay pure. Set `MLModelConfiguration.computeUnits = .all` so inference runs on the ANE.

Quality vs effort: `all-MiniLM-L6-v2` ≈ the standard sentence-similarity baseline, far sharper separation than `NLEmbedding`, ~384-dim, runs in single-digit ms/sentence on the ANE. Reach for it only when ranking quality actually blocks you — `NLEmbedding` + human review (the [[../../bin/INDEX|apple-semantic-match]] pattern) clears most jobs.

## Availability note (check before promising) — it's PER-MACHINE, not per-fleet

The mistake to avoid (made 2026-06-01): I checked FoundationModels on the *laptop*, saw ABSENT, and wrote off the capability for everything. Wrong — **availability is per machine.** Check the box you actually intend to run on.

- **This laptop** (2026-06): macOS **15.6.1**, M3 Pro → NaturalLanguage ✓, Vision ✓, Speech ✓, Translation ✓, CoreML ✓. **FoundationModels ABSENT** (needs macOS 26 + Apple Intelligence).
- **CloudcityMacMini** (the always-on server): macOS **26.3**, **M2 Pro** → **FoundationModels AVAILABLE** — verified 2026-06-01: framework present at `/System/Library/Frameworks/FoundationModels.framework` and `SystemLanguageModel.default.availability == .available` (on-device model downloaded, Apple Intelligence enabled). The ~3B on-device LLM (`LanguageModelSession`) — real reasoning + structured output — is usable on the Mini, **zero-token, zero-network.** This is the obvious next worker: an FM-on-Mini service (summaries / structured extraction / classification) sitting alongside ocr/voicebox/whisp, dispatched via the Syncthing file-bridge.
- Probe a machine: `ls /System/Library/Frameworks/FoundationModels.framework` + `sw_vers`, then a 3-line Swift check of `SystemLanguageModel.default.availability` (framework presence ≠ enabled; only the availability property confirms the model is downloaded + AI toggled on). On the Mini, run it via the file-bridge (drop `run --direct …` into `pakettibot-inbox/`), not SSH.
- For a heavier/sharper embedding than NLEmbedding without leaving the Apple stack: convert a sentence-transformer to **CoreML** (`coremltools`, build-time only) and run it on the ANE.

## FoundationModels as a fleet worker — `fm-worker` / `fm-submit` / `fm-chat` (2026-06-01)

FM only exists on macOS 26, so on the fleet it lives on the **Mini**. Three tools make
it usable from any machine, zero-network, zero-cost — the 6th instance of the
trigger→worker chassis (Finder tag, Voice Memo, Stickies, Mail flag, Panel, now FM):

- **`bin/fm-worker`** (Mini): watches `~/work/comms/queue/fm-inbox/<id>.json`
  (`{prompt, system?}`), runs `bin/fm`, times the model wall-clock, writes the answer
  to `fm-outbox/<id>.json`. Stateless — only ever execs `bin/fm`, never a shell.
- **`bin/fm-submit`** (any Mac): one-shot prompt → answer (`--wait`/`--system`/`--status`).
- **`bin/fm-chat`** (any Mac): live REPL. Conversation memory is replayed **client-side**
  (the worker is stateless) — verified working: a neutral fact stated in turn 1 is
  correctly recalled in turn 3.

Deploy = `git -C …/apple reset --hard origin/main` on the Mini (the deploy node diverges
from origin via its own auto-regen commits, so `pull --ff-only` fails — reset is the clean
path; untracked WIP is preserved) then `nohup …/bin/fm-worker &`. For durable persistence
it should become a Cloudcity-Boot pane (currently nohup'd).

### Measured speed (M2 Pro Mini, 2026-06-01)
**Model is fast: ~0.9–1.5 s** to generate a sentence or short list (`model_ms` in every
result). The variable cost is the **Syncthing round-trip: ~4 s good case, ~11 s** when a
scan cycle lags — `syncthing-nudge` on both inbox and outbox keeps it near the floor. So
"how fast is FM" = ~1 s of model + transport. Run `fm-chat` *on the Mini* to drop the
transport entirely.

### Guardrails are aggressive — expect refusals
Apple's on-device model has a trigger-happy safety guardrail. Two refusal shapes seen:
a hard `guardrailViolation("May contain unsafe content")` error, and soft in-content
declines ("I'm sorry, but I can't assist with that"). Personal-info recall ("what is my
name") trips it even in a benign chat. The client tools humanize the hard-guardrail error;
rephrasing usually clears it. This is an FM property, not a pipeline bug.

## See also

- [asobjc.md](asobjc.md) — the other "first-party capability we missed for years" (Cocoa from AppleScript)
- [automation-tiers.md](automation-tiers.md) — where on-device ML sits in the macOS automation atlas
- Origin worked example: the Paketti forum archive at `~/work/cc/vault/music/paketti/forum/` — `_build/semantic_match.swift` matches 1,898 forum feature-requests to 1,115 shipped changelog features semantically, on-device, in ~2.5 min.
