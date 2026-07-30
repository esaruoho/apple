# Session — fm-think-no-leak (PakettiAskBot leaked its chain-of-thought to Discord)

CARD >> `features/fm-think-no-leak.feature`

## How to get back here (clickable)

- Transcript: [file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-convey/ba01d30b-e1c7-4ac5-8873-89e720dae9b7.jsonl](file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-convey/ba01d30b-e1c7-4ac5-8873-89e720dae9b7.jsonl)
- Session ID: `ba01d30b-e1c7-4ac5-8873-89e720dae9b7`
- Resume: `claude --resume ba01d30b-e1c7-4ac5-8873-89e720dae9b7`
- Date: **2026-07-30**, session working ~11:10–14:19 EEST (fix built and verified 11:14–11:18 UTC)
- CWD: `/Users/esaruoho/work/convey` (the change lands in `~/work/apple` + `~/work/pakettiaskbot`)

## The request (Esa, verbatim in substance)

> we have a serious problem with the PakettiAskBot now. it suddenly started printing its
> thinking. and the thinking is convoluted. it keeps saying "wait, what.." … this kind of
> thinking is interesting, but it should not be user-facing. the thinking should be something i
> should have access to, because it seems to be saying "wait hold on" constantly. why do you
> think that is? please fix it so that it talks to the user, without this craziness going on, but
> that it stores the thinking to the cloudcitymacmini so we can extract it later and correct its
> thinking. what is the cause of these "wait hold on"-isms?

He pasted two Discord messages of raw trace, from a `revise` job — the model re-reading
`"and the dialog is highlighted"` over and over. Three asks, not one: **stop showing it**,
**keep it where I can get at it**, **tell me why it talks like that**.

## What I found (and the order I found it in)

1. `systems.yaml` → the bot's engine is `apple/bin/paketti-ask --discord`, brain `fm-mlx`.
2. `paketti-ask` / `paketti_faq.py` — no `<think>` handling anywhere. Not the leak itself,
   but no guard either.
3. `bin/fm-mlx` — **the leak.** The reply extractor was
   `content or reasoning_content or reasoning or …`. An `or` chain across an answer field and
   two *thinking* fields publishes the trace the moment `content` is missing.
4. Probed the Mini directly (`curl … /v1/chat/completions`, `max_tokens: 300`) and got the
   proof: mlx_lm.server **0.31.2** returned `message.reasoning` with **no `content` key at all**
   and `finish_reason: "length"`. The response body was literally
   *"Okay, the user is asking if the LFO dialog is highlighted… Reconsider carefully…"* — the
   same shape Esa pasted.
5. `git diff bin/fm-mlx` — the `or reasoning` fallback was **uncommitted**, alongside two more
   uncommitted edits in the same hunk: model `Qwen3-4B → Qwen3-14B-MLX-4bit`, and
   `FM_MLX_MAX_TOKENS` default **4096 → 1024**. That is the "suddenly started": a 14B reasoner
   cannot close a think block in 1024 tokens, so `content` was absent constantly.

Two faults that multiply. Neither alone ships a trace; together they ship one every time.

## Answering "why the 'wait hold on'-isms?"

Two layers, and it mattered to separate them:

- **Layer 1 — that's what thinking IS.** Qwen3 is RL-trained to backtrack; "wait, no, let's
  re-read" is the deliberation register. Nothing is wrong with the model. It was never meant to
  be read.
- **Layer 2 — the loop was pathological, and that's a PROMPT bug.** `pakettiaskbot`'s `revise`
  prompt labelled the user's reply "The user's instruction" when it is nearly always a sentence
  *fragment*, then stacked three constraints that pull against each other (KEEP everything / ADD
  what they ask / alter nothing). With nothing it could act on, the model re-read the prompt
  forever — which burns the budget inside the think block, which *guarantees* fault 1. The
  convoluted trace and the leak are the same event.

Same lesson as `convey-prism`: never give a voice two conflicting instructions.

## What I built

- **`bin/fm_think.py`** — the one splitter. `split(payload) → (answer, thinking, meta)`. Reads
  answer-bearing fields **only**; `reasoning` / `reasoning_content` are always thinking. Handles
  closed `<think>…</think>`, an unclosed tail, a stray `</think>`, and untagged traces (two
  distinct tics required, so an answer that says "wait" once survives). `log()` files traces.
- **`bin/fm-mlx`** — calls `split` + `log`; empty answer → non-zero exit with an honest stderr,
  never the trace. `max_tokens` default restored to 4096.
- **`bin/paketti_faq.py`** — `_split_thinking()` per brain: defense in depth, and a
  thinking-only reply counts as a brain FAILURE so it falls through to the next brain.
- **`pakettiaskbot/index.js`** — `peelThinking` + `fileThinking` at the last mile before
  Discord (a public post is irreversible), and the `revise` prompt rewritten: NOTE not
  instruction, explicit fallback for an uninterpretable note ("smallest edit, decide once"), and
  no reasoning in the output.
- **`bin/paketti-thinking`** — the reader Esa asked for: list / `--circles` / `--grep` /
  `--show N` / `--show N --md` (a Question / Thinking / **Correction** file to mark up) /
  `--stats`. Store is `~/work/comms/queue/paketti-faq/thinking.jsonl` — the Mini writes it,
  Syncthing carries it, no SSH.

## Verification (not asserted — run)

- 5 unit cases on `fm_think.split` (mlx-0.31 truncated shape, inline block, reasoning-alongside-
  answer, untagged trace, innocent "wait") — all pass.
- Live against the Mini: `FM_MLX_MAX_TOKENS=200 fm-mlx --raw "Is the LFO dialog highlighted?
  Reconsider carefully."` → **stdout empty**, exit 1, 964 chars filed. The same call that leaked.
- Live: `fm-mlx --raw "Answer in one sentence: what is an LFO?"` → one clean sentence, 705 chars
  filed silently.
- `node --check index.js`, plus the **real** `peelThinking` source extracted from `index.js` and
  run against 4 cases — all pass.
- E2E: `paketti-ask --discord` fed the exact pathological revise shape → a clean 3-sentence
  Discord answer, 1385 chars of thinking filed, **zero** backtracking tics in the trace (the
  prompt fix held).
- `paketti-thinking` listing / `--circles` / `--stats` / `--show 1 --md` all exercised.

## Judgment calls I made without asking

- **Kept thinking ON.** Qwen3 supports `/no_think`, which would have been the cheap fix — but
  Esa explicitly wants the thinking *stored so it can be corrected*. Suppressing it would have
  answered ask #1 by destroying ask #2.
- **A thinking-only reply is a FAILURE, not an answer.** It rides the queue's existing retry +
  backoff rather than getting a new mechanism, and the final-attempt message is honest.
- **Restored 4096 rather than pinning back to Qwen3-4B.** The 14B is the better brain; the
  budget was the regression.
- **Filed traces into the existing `paketti-faq/` share** instead of inventing a new queue dir —
  it is already Syncthing-mirrored and already the FAQ's home.

## Grades, honestly

`@hw-verified` only where I actually hit the Mini (the two fm-mlx scenarios, the reader, the
E2E). Everything else is `@built` — unit-tested, not yet exercised by a real Discord user. The
watch-the-circling-rate scenario is `@todo` and says so.

## RESULT

See the RESULT block in `features/fm-think-no-leak.feature` and the commits below.
