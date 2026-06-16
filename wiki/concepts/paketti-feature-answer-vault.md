---
description: Theory — use the MLX bot to pre-generate grounded answers to Paketti feature questions, have Esa rate them for usefulness, and serve the vetted ones as an instant, trusted helper. A human-in-the-loop FAQ vault.
---

# Paketti Feature-Answer Vault (theory)

> Esa's ask: *"use the MLX bot to actually explain Paketti features — 'has Paketti got a system for changing pattern length?' → it describes the stuff. We create ready-made, dynamic answers, I value them on whether they are useful, and they become a 'did the user ask for this? are we sure? ok here's the info!' helper."*

## The core insight (from the live demo)

Armed with **paketti + renoise-api**, the bot answered the pattern-length question and **cited a real file** (`PakettiBeatstructureEditor.lua`) — but its reasoning was **shaky** ("Paketti has no dedicated system" is questionable). That is the whole design problem in one example:

- **The promise:** grounded generation cites real features/files, fast, free, private.
- **The risk:** a 4B model confabulates and reasons imperfectly — a plausible answer can be wrong.

So the architecture's first-class feature is **human vetting** — your "are we sure?" gate. The bot *drafts*; you *certify*; the certified answer is what gets reused.

## The pipeline

```
   features.md / categories.md / keybindings
                │  (1) SEED
                ▼
        candidate questions  ──(2) GENERATE──▶  mlx-here (paketti+renoise)
                                                      │  grounded draft + citations
                                                      ▼
                                              UNVETTED answer
                                                      │  (3) RATE  ✅ useful / ✏️ fix / ❌ wrong
                                                      ▼
                                          ┌─────  VETTED VAULT  ─────┐
   user question ──(5) semantic match────▶│  (NLEmbedding lookup)    │
                                          └──────────┬───────────────┘
                         match + vetted? ──yes──▶ serve INSTANT trusted answer
                                          ──no───▶ live MLX draft + queue it for vetting (4)
```

1. **Seed** — enumerate feature-questions from the corpus. Each Paketti feature → one or more natural questions ("Can Paketti change pattern length?", "How do I set the default pattern length?").
2. **Generate** — each question through the armed MLX bot → a draft answer grounded in the paketti + renoise-api docs, with file/keybinding citations.
3. **Rate** — you review each draft: **✅ useful** (enters the vault) / **✏️ fix** (edit then enter) / **❌ wrong** (discard). One-time human judgment per answer.
4. **Grow** — questions that miss the vault get answered live and **queued** for your rating, so the vault self-extends from real use.
5. **Serve** — on a question, semantically match it (NLEmbedding) against the **vetted** vault. High match + vetted → instant trusted answer (no model call, deterministic). Low match → live MLX draft, flagged "best guess, not vetted — want me to verify?"

The **"are we sure?" gate** = serve a vault answer only when it is (a) vetted-useful AND (b) matches the question above a confidence threshold. Otherwise it says so plainly. That is precisely your "did the user ask for this? are we sure? ok here's the info."

## Why it works (and the honest limit)

- Turns a flaky 4B model into a **reliable FAQ** by spending human judgment **once** per answer, then reusing it free and instant.
- Grounded generation *reduces* hallucination at draft time; **vetting catches the rest** — the demo proves vetting is mandatory, not optional (that pattern-length answer earns a ✏️ "fix").
- The vault is **reusable and shareable** — it could become the public Paketti FAQ / docs, generated then human-certified.
- **Limit:** quality is capped by (a) the corpus and (b) your rating effort. It is a curated knowledge base, not an oracle.

## It reuses what already exists (DRY — don't re-roll)

- **Generation:** `mlx-here` / `fm-mlx`, armed with paketti + renoise-api (shipped today).
- **Storage + rating + versions:** convey **`kb`** / **DreamGraph** — "an answer is a conveyable unit" (convey principle 0046); kb already versions entries.
- **Instant semantic lookup:** Apple **NLEmbedding** — `bin/apple-semantic-match`, the shared `bin/embed` cache — deterministic, on-device, no model call.
- **Prior art:** `wiki/concepts/answer-vault-knowledge-graph.md` is this same idea generically; this page applies it to Paketti.

## MVP — three small tools

1. **`paketti-faq-gen`** — enumerate N feature-questions from the corpus → run each through the armed MLX → write `{question, answer, citations, status: unvetted}` into a vault file (or `convey kb`).
2. **`paketti-faq-rate`** — a simple loop: show each unvetted Q&A, you press ✅ / ✏️ / ❌; sets the status (✏️ opens it for a quick edit).
3. **`paketti-ask "..."`** — embed the question, match against vetted entries; hit → print the trusted answer instantly; miss → live MLX draft + auto-queue for rating.

The value loop: **you rate → the vault grows → lookups get faster and more trusted → the 4B bot becomes a certified Paketti knowledge base instead of a gamble.**

Related: [`mlx-here-usecase`](mlx-here-usecase.md) · [`reply-presentation`](reply-presentation.md) · `answer-vault-knowledge-graph` · convey `kb` / DreamGraph (principle 0046/0050).
