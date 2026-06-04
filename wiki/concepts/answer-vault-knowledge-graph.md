---
description: Turning the stochastic one-shot RAG endpoint (va / vault-ask) into a self-organizing, precomputed, accumulating vault + knowledge graph of answers, built on the existing NLEmbedding / matrix-cache / fm-worker primitives.
---

# Answer Vault — a self-organizing knowledge graph from the archive

## The problem this solves

`va "question"` today is two layers:

1. **Retrieval** — deterministic. NLEmbedding gives a fixed vector; cosine over the matrix cache returns the same top-K passages every run.
2. **Synthesis** — stochastic one-shot, bounded by top-K=8 and one sampling pass.

Consequence: **asking again can only reword the answer, never enlarge it.** Nothing accumulates, nothing converges, and the answer is ephemeral (gone after the terminal scrolls, unless `va-batch` wrote a file). Esa's exact instinct — *"if I ask again, would I get a larger response?"* — currently answers **no**. This design makes it **yes, until saturation, then it stops.**

The conceptual shift: the **answer becomes a persistent, addressable node**, the question becomes its key, and the whole thing grows into a graph that organizes and extends itself. See also [`on-device-ml.md`](on-device-ml.md), [`fm-tools.md`](fm-tools.md).

## Node + edge model

| Node | Key | Holds |
|---|---|---|
| **Question** | embedding of the canonical question | text, status (new/synthesized/saturated), backlog priority |
| **Answer** | the Question it derives from | accumulated claims, each citation-anchored, version count |
| **Passage** | already in `~/.vault-embeds` | the source chunk + vector (exists today) |
| **Entity** | normalized name (Tesla, ZPE, Schauberger…) | backlinks |

Edges: Question→cites→Passage (cosine-weighted) · Answer→grounded-in→Passage · Question↔related↔Question (embedding sim) · Entity→appears-in→Answer/Passage · Answer↔corroborates/contradicts↔Answer (consilience).

## The key move: accumulating multi-pass synthesis

This is what makes "ask again → more" true. One question, swept across **different evidence windows**, then merged:

- Pass 1: passages 1–8 · Pass 2: 9–16 · Pass 3: 17–24 (or threshold bands, or sub-question decomposition of the question).
- Each window is *genuinely different evidence* → genuinely different sub-claims (not paraphrase jitter).
- A **claim-merge step** embeds each emitted claim, dedups by similarity, keeps only citation-anchored uniques, and appends them to the Answer node.
- Repeat until a pass surfaces **no new claims** → the question is **saturated**. (Loop-until-dry, at the single-question level.)

Result: the Answer node strictly grows with passes and then provably stops. This is the anti-one-shot mechanism encoded in software — and it aligns with the Free Energy archive rule against stopping early / completion-framing.

## Proactive / precomputed (so fetches are instant)

1. **Question generation (no typing required).** `vault-cluster` the corpus → extract dominant entities/topics per cluster → auto-emit questions ("What does {entity} say about {topic}?") into a backlog. The archive seeds its own questions.
2. **Background drain.** A worker on the Mini (6th+ instance of the trigger→worker chassis, same shape as `fm-worker`) pulls the backlog, runs accumulating synthesis, writes Answer nodes. Free, on-device, overnight.
3. **Instant fetch.** When Esa asks, first embedding-match against existing Question nodes. Close match (cosine ≥ τ) → return the **precomputed accumulated answer instantly**, no synthesis. Genuinely new question → synthesize live *and* enqueue it so the vault learns it.

## Self-growth

- **Follow-up spawning.** Each Answer's entities/claims seed new questions ("answer mentions Bedini's pulse motor → spawn 'measured COP of Bedini's pulse motor?'"). The graph extends itself.
- **Coverage metric.** When new questions stop surfacing new passages, a *topic* is saturated → a real, honest coverage number per cluster.
- **Consilience edges.** `vault-consilience` across Answer nodes → a contradiction/corroboration map. High value for a contested archive (Free Energy claims disagree constantly).

## Materialize as an Obsidian wiki

The graph renders to markdown exactly like the [`vault`](../../) skill already does for conversations:
- One page per Question (accumulated answer + evidence + `[[related questions]]`).
- One page per Entity (backlinks to every answer mentioning it).
- `[[wikilinks]]` → Obsidian graph view. A browsable knowledge wiki that **grew itself from the archive.**

## Feasibility — most of it already exists

| Capability | Status |
|---|---|
| Embedding (NLEmbedding, Neural Engine) | ✅ built (`vault-grep`, `embed`) |
| Matrix cache + delta-merge + staleness mtimes | ✅ built (`vault-grep` MATRIX_NPY/MANIFEST) |
| Retrieval top-K with per-file cap | ✅ built (`vault-ask` `fast_query_topk`) |
| Clustering | ✅ built (`vault-cluster`) |
| Cross-source agreement | ✅ built (`vault-consilience`) |
| Free on-device synthesis | ✅ built (`fm-worker` / `fm-submit`) |
| Trigger→worker background chassis | ✅ built (fm/ocr/voicebox/whisp) |
| Markdown-vault materialization | ✅ built (`vault` skill) |
| **Question-backlog generator** | ⬜ new — small |
| **Accumulating synthesis + claim-merge/dedup** | ⬜ new — the core algorithm |
| **Answer store keyed by question-embedding** (`~/.vault-answers/`) | ⬜ new — JSONL, mirrors `~/.vault-embeds` |
| **Proactive drain worker** | ⬜ new — clone of `fm-worker` |
| **Graph/wiki materializer** | ⬜ new — adapts the vault renderer |

Verdict: **high feasibility.** It's mostly orchestration of existing primitives plus two genuinely new pieces (claim-merge, question-spawn).

## Honest caveats

- **3B model is the quality floor.** Accumulation adds evidence, but the *claim-merge* step wants a stronger model. Cheapest fix: fm for the per-pass drafts (free, many calls), Claude for the one merge call per question (paid, but 1×, not N×).
- **Hallucination.** Drop any claim without a live citation at merge time. Free Energy "never invent" rule applies verbatim.
- **Dedup threshold tuning.** Too low → false claim merges; too high → duplicate nodes. Same for question-node matching.
- **Corpus drift.** Re-embedding a changed source invalidates cached answers. The matrix manifest already tracks file mtimes — reuse it to mark Answer nodes stale and re-drain them.

## Suggested build phases

1. **Answer store + instant fetch** — `~/.vault-answers/` JSONL; `va` checks it first, falls back to live synth, enqueues misses. (Immediate win: repeat questions become free + instant.)
2. **Accumulating synthesis** — multi-window sweep + claim-merge. (Makes "ask again → more" true.)
3. **Backlog generator + drain worker** — corpus seeds its own questions; Mini fills the vault overnight.
4. **Graph + Obsidian materializer** — the browsable knowledge wiki.
5. **Consilience + coverage** — contradiction maps + honest per-topic saturation numbers.

Proposed tool names (match existing `va*` / `vault-*` family): `vault-questions`, `vault-build`, `vault-answer-worker`, `vault-wiki`.
