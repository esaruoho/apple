#!/usr/bin/env python3
"""Convert sentence-transformers/all-MiniLM-L6-v2 to a CoreML .mlpackage.

BUILD-TIME ONLY — needs torch + transformers + coremltools in a venv (see
bin/build-minilm.sh). The runtime is pure CoreML + a hand-rolled WordPiece
tokenizer in Swift (bin/minilm-embed), zero pip deps, runs on the Neural Engine.

The exported model takes int input_ids + attention_mask (fixed length SEQ) and
returns token_embeddings [1, SEQ, 384] (the last hidden state). Sentence
embedding = attention-mask mean-pool over the tokens, done Swift-side, then L2
normalize — the standard sentence-transformers pooling.

Outputs MiniLM.mlpackage + vocab.txt to argv[1] (default ./).
"""
import os
import sys

import torch
import coremltools as ct
from transformers import AutoModel, AutoTokenizer

OUT = sys.argv[1] if len(sys.argv) > 1 else "."
os.makedirs(OUT, exist_ok=True)
NAME = "sentence-transformers/all-MiniLM-L6-v2"
SEQ = 256   # all-MiniLM-L6-v2's max_seq_length; covers a paragraph chunk

print(f"[convert] loading {NAME} …", flush=True)
tok = AutoTokenizer.from_pretrained(NAME)
mdl = AutoModel.from_pretrained(NAME).eval()


class Wrap(torch.nn.Module):
    """Return just last_hidden_state so the traced graph has a tensor output."""
    def __init__(self, m):
        super().__init__()
        self.m = m

    def forward(self, input_ids, attention_mask):
        return self.m(input_ids=input_ids, attention_mask=attention_mask).last_hidden_state


w = Wrap(mdl).eval()
ex = tok("hello world", return_tensors="pt", padding="max_length", max_length=SEQ, truncation=True)
print("[convert] tracing …", flush=True)
with torch.no_grad():
    traced = torch.jit.trace(w, (ex["input_ids"], ex["attention_mask"]))

print("[convert] converting to CoreML …", flush=True)
mlmodel = ct.convert(
    traced,
    inputs=[
        ct.TensorType(name="input_ids", shape=ex["input_ids"].shape, dtype=int),
        ct.TensorType(name="attention_mask", shape=ex["attention_mask"].shape, dtype=int),
    ],
    compute_units=ct.ComputeUnit.ALL,
    minimum_deployment_target=ct.target.macOS14,
)
pkg = os.path.join(OUT, "MiniLM.mlpackage")
mlmodel.save(pkg)
tok.save_vocabulary(OUT)   # writes vocab.txt
# record the output feature name(s) so the Swift side knows what to read
spec = mlmodel.get_spec()
out_names = [o.name for o in spec.description.output]
print(f"[convert] SAVED {pkg}")
print(f"[convert] VOCAB {os.path.join(OUT, 'vocab.txt')}")
print(f"[convert] SEQ={SEQ} DIM=384 OUTPUTS={out_names}")
