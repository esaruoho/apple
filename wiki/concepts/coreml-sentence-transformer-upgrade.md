# CoreML sentence-transformer upgrade — the sharpness lift above NLEmbedding

**Status:** plan + runnable conversion scaffold, 2026-06-01. Not yet executed.

**Origin:** `apple-embed` + `vault-grep` / `sgrep` use `NLEmbedding.sentenceEmbedding` — 512-dim, on-device, no deps, fast. Works well for "very different words, same idea" ranking down to ~0.45. But `0.45–0.6` is murky: real paraphrases and incidental overlap both score in that band. For the archive consilience work (Bearden's "CEM incompleteness" ≈ Russell's "two-way light" ≈ Hilarion's "one-substance ontology"), tighter separation matters.

The wiki's `on-device-ml.md` page identifies the upgrade: **convert a sentence-transformer (e.g. `all-MiniLM-L6-v2`) to CoreML, run at inference time on the Neural Engine.** Runtime is pure CoreML, ANE-accelerated, zero third-party deps. Build-time uses `coremltools` (a Python package, run ONCE on a build machine, never shipped to the runtime).

---

## Why MiniLM, not the bigger sentence-transformers

- `all-MiniLM-L6-v2` is the de-facto sentence-similarity baseline. 6 layers, 384-dim, ~80MB compiled.
- Runs in single-digit ms per sentence on the ANE.
- Trained with sentence-pair supervision (= directly optimised for cosine ranking, unlike raw BERT which is anisotropic and clusters everything).
- Bigger models (`all-mpnet-base-v2`, etc.) score marginally higher on benchmarks but cost ~3× the latency and storage. Diminishing returns for our use case.

---

## Conversion procedure (build-time, one-shot)

Done on a build machine with Python + pip + coremltools. Result: `MiniLM.mlpackage` (~80 MB), checked into the apple skill repo or distributed alongside `apple-embed`.

```bash
# Build-time only — do once, ship the .mlpackage
python3 -m venv /tmp/coreml-venv
source /tmp/coreml-venv/bin/activate
pip install coremltools transformers torch sentencepiece

cat > /tmp/convert.py <<'PY'
import coremltools as ct
import torch
from transformers import AutoModel, AutoTokenizer

MODEL = "sentence-transformers/all-MiniLM-L6-v2"
MAX_LEN = 128

tok = AutoTokenizer.from_pretrained(MODEL)
mdl = AutoModel.from_pretrained(MODEL).eval()

# A representative example for tracing
ex = tok("the active vacuum is the source of energy",
         return_tensors="pt",
         padding="max_length",
         max_length=MAX_LEN,
         truncation=True)

# Trace the model so coremltools can convert
class Wrapped(torch.nn.Module):
    def __init__(self, m): super().__init__(); self.m = m
    def forward(self, input_ids, attention_mask):
        out = self.m(input_ids=input_ids, attention_mask=attention_mask)
        # mean-pool over tokens, masked by attention
        token_embs = out.last_hidden_state
        mask = attention_mask.unsqueeze(-1).float()
        summed = (token_embs * mask).sum(dim=1)
        counts = mask.sum(dim=1).clamp(min=1e-9)
        return summed / counts

wrapped = Wrapped(mdl).eval()
traced = torch.jit.trace(wrapped, (ex.input_ids, ex.attention_mask))

ml = ct.convert(
    traced,
    inputs=[
        ct.TensorType(name="input_ids",      shape=ex.input_ids.shape,      dtype=int),
        ct.TensorType(name="attention_mask", shape=ex.attention_mask.shape, dtype=int),
    ],
    outputs=[ct.TensorType(name="embedding")],
    compute_units=ct.ComputeUnit.ALL,     # ANE if available
    minimum_deployment_target=ct.target.macOS14,
    convert_to="mlprogram",
)
ml.save("MiniLM.mlpackage")

# Also dump vocab.txt for Swift-side tokenization
vocab = tok.get_vocab()
with open("MiniLM.vocab.txt", "w") as f:
    for tok_text, tok_id in sorted(vocab.items(), key=lambda kv: kv[1]):
        f.write(tok_text + "\n")
PY
python3 /tmp/convert.py
deactivate

# Outputs:
#   MiniLM.mlpackage    ← the model, ~80MB
#   MiniLM.vocab.txt    ← the WordPiece vocabulary, ~250KB
```

Ship `MiniLM.mlpackage` + `MiniLM.vocab.txt` to `~/work/apple/models/MiniLM/` and reference from `apple-embed-pro`.

---

## Runtime side — `apple-embed-pro` (Swift, no deps)

Replace `apple-embed`'s NLEmbedding call with CoreML inference. Pipeline:

1. **WordPiece tokenization in Swift.** Greedy longest-match against `MiniLM.vocab.txt`, with `##` continuation. ~80 lines of Swift, stdlib only. (Alternative: use the `swift-transformers` SwiftPM package, but that's a third-party dep — avoid if Apple-native pedigree must stay pure.)
2. **CoreML inference.** Load `MiniLM.mlpackage` once at startup, configure `MLModelConfiguration.computeUnits = .all` so the ANE is preferred.
3. **Output embedding.** 384-dim float vector per sentence.
4. **Same JSONL output format** as `apple-embed` so `vault-grep` / `sgrep` work unchanged. They just store 384-dim vectors instead of 512-dim.

Skeleton:

```swift
#!/usr/bin/env swift
import Foundation
import CoreML

let modelURL = URL(fileURLWithPath: NSString(string:
    "~/work/apple/models/MiniLM/MiniLM.mlpackage").expandingTildeInPath)
let config = MLModelConfiguration()
config.computeUnits = .all     // CPU + GPU + ANE

guard let model = try? MLModel(contentsOf: modelURL, configuration: config) else {
    FileHandle.standardError.write("apple-embed-pro: model not found at \(modelURL.path)\n".data(using:.utf8)!)
    exit(1)
}

// Load vocab for WordPiece
let vocabURL = modelURL.deletingPathExtension().appendingPathExtension("vocab.txt")
let vocab: [String] = (try? String(contentsOf: vocabURL).split(separator: "\n").map(String.init)) ?? []
let vocabMap: [String: Int] = Dictionary(uniqueKeysWithValues: vocab.enumerated().map { ($1, $0) })

// WordPiece tokenize  — ~80 lines, greedy longest-match with ## continuation
func tokenize(_ s: String, maxLen: Int = 128) -> ([Int], [Int]) {
    // … implementation detail; lower-case, strip accents, whitespace-split, then
    // for each whitespace-token: longest match in vocab, then ##suffix, repeat
    // Returns (input_ids, attention_mask) of length maxLen
    fatalError("implement when shipping")
}

while let line = readLine() {
    let t = line.trimmingCharacters(in: .whitespacesAndNewlines)
    if t.isEmpty { continue }
    let (ids, mask) = tokenize(t)
    // Run inference, emit JSON line {"t":"...","v":[...]}
    // … MLFeatureProvider, .featureValue(for: "embedding"), to [Double] …
}
```

---

## Drop-in for the existing tools

Once `apple-embed-pro` exists, the rest is symbol changes:

- `vault-grep` / `sgrep`: change `find_apple_embed()` to prefer `apple-embed-pro`, fall back to `apple-embed`. Old `~/.vault-embeds/` cache becomes incompatible (different vector dim) — invalidate by adding a `--model` flag and a per-model subdirectory: `~/.vault-embeds/MiniLM/` vs `~/.vault-embeds/NLEmbedding/`.
- `vault-consilience` / `vault-cluster`: nothing to change; they consume whatever the cache holds.
- Cosine thresholds will shift. NLEmbedding's `>0.6` strong → MiniLM's `>0.7` strong (sentence-transformers compress similar pairs to higher cosines and push unrelated ones lower). Update the wiki guide once benchmarked.

---

## Expected payoff

Re-run the cluster on the Hilarion corpus. Pairs that NLEmbedding ranked `0.85–0.95` (with frontmatter noise mixed in) should sharpen:

- True consilience pairs lift to `0.80–0.95` with clear separation
- Frontmatter / boilerplate pairs drop to `0.50–0.70` (below the noise floor we'd set)
- Tighter cutoff, fewer false positives

Same query "the active vacuum is the energy source" on the diary corpus — top hits should re-rank to put the actual Bearden claim above the structural template lines.

---

## Decision gate

This is a 1-day build (mostly the WordPiece Swift port). Worth doing when:

1. NLEmbedding's coarseness measurably blocks an archive task — e.g. you ran `vault-cluster` and the top 50 pairs are 80% boilerplate even after the YAML-key filter.
2. The CoreML pipeline is also wanted for OTHER models (sound classification fine-tuning, custom image classifier, etc.) — fixed cost, multiple uses.

Until then: NLEmbedding + the YAML-key + duplicate-text filter are good enough. The plan is here so when the moment arrives, the conversion procedure is a paste-and-run and the runtime is a known design.

---

## Companion docs

- `~/work/apple/wiki/concepts/on-device-ml.md` — framework map
- `~/work/apple/bin/apple-embed` — the current (NLEmbedding) embedder
- `~/work/apple/bin/vault-grep` — the consumer
