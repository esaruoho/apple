# =============================================================================
# REPORT CARD: fm-think-no-leak — a reasoning model's THINKING is filed, never spoken
# Skin: CLI tool + library (claim = a model payload in → an answer out, a trace filed)
# Convention: ~/.claude/skills/report-card/SKILL.md
# SESSION >> features/fm-think-no-leak.session.md   (the vibe diff that spawned this)
#
# STATUS OF THIS CARD: born of a live incident (2026-07-30). PakettiAskBot started
# posting its raw chain-of-thought into #paketti-helper — pages of
#   "Wait, what. Wait no, wait, let's re-read the user's message. Oh! Wait…"
# Esa: "this kind of thinking is interesting, but it should not be user-facing. the
# thinking should be something i should have access to … store the thinking to the
# cloudcitymacmini so we can extract it later and correct its thinking. what is the
# cause of these 'wait hold on'-isms?"
#
# ROOT CAUSE (two faults that multiply, both verified live against the Mini):
#   1. LEAK SITE — bin/fm-mlx extracted the reply as
#        content or reasoning_content or reasoning or …
#      mlx_lm.server 0.31.2 puts Qwen3's chain-of-thought in `message.reasoning` and
#      emits NO `content` key at all until `</think>` closes. So whenever the model
#      was still thinking when the budget ran out, `content` was absent, the `or`
#      chain fell through, and the RAW TRACE became the answer. Compounded by two
#      uncommitted edits in the same hunk: model swapped Qwen3-4B → Qwen3-14B (thinks
#      far longer) while max_tokens was LOWERED 4096 → 1024. That is the "suddenly
#      started": a 14B reasoner cannot finish a think block in 1024 tokens.
#   2. WHY THE TRACE READS LIKE PANIC — the tics are normal Qwen3 deliberation, but
#      the loop was pathological because pakettiaskbot's `revise` prompt was
#      unresolvable: the user's reply is usually a FRAGMENT ("and the dialog is
#      highlighted"), it was labelled "The user's instruction", and three constraints
#      pulled against each other (KEEP everything / ADD what they ask / alter
#      nothing). With nothing it could act on, the model re-read the prompt forever —
#      burning the whole budget inside the think block, which guarantees fault 1.
#      Same lesson as convey-prism: never give a voice two conflicting instructions.
#
# ── WHAT THIS CARD SPAWNS ───────────────────────────────────────────────────
#   Codespace : bin/fm_think.py        (this unit — the ONE answer/thinking splitter)
#               bin/fm-mlx            (calls split() + log(); no `or reasoning`)
#               bin/paketti_faq.py    (_split_thinking — defense in depth per brain)
#               bin/paketti-thinking  (the reader: list/--circles/--grep/--show/--stats)
#               ~/work/pakettiaskbot/index.js  (peelThinking + fileThinking, last mile
#                                               before Discord; revise prompt fixed)
#   Thinkspace: features/fm-think-no-leak.session.md
#   Areaspace : fm_think OWNS the answer-vs-thinking boundary and the trace file
#               format. It MUST NOT own: the HTTP round-trip (fm-mlx), grounding or
#               fabrication-stripping (paketti_faq), Discord posting (pakettiaskbot),
#               or prompt wording (each caller). Every caller reuses this one split —
#               nobody re-rolls a `<think>` regex.
#
# GRADES: @hw-verified = run live against the Mini's MLX server this session.
#         @built       = code shipped + unit-tested, not yet exercised in production.
# =============================================================================

Feature: A reasoning model's thinking is filed, never shown
  The brain deliberates. Deliberation is scratch work that is SUPPOSED to read like
  "wait, hold on, let me re-read that" — and a human must never see it. But it is the
  most correctable artifact the bot produces, so it is never dropped: it is filed to
  a JSONL on the Mini under the Syncthing share, readable from any peer with no SSH.

  Background:
    Given the Mini runs mlx_lm.server 0.31.2 with Qwen/Qwen3-14B-MLX-4bit
    And traces are filed to ~/work/comms/queue/paketti-faq/thinking.jsonl
    And that path is inside the comms Syncthing folder, so the laptop sees it

  @hw-verified
  Scenario: The exact payload that leaked to Discord now yields no answer, not a trace
    Given the model is asked a question and hits max_tokens before "</think>" closes
    And the response therefore has message.reasoning but NO message.content
    When fm-mlx extracts the reply
    Then stdout is EMPTY — the trace is never printed
    And stderr says the model spent its whole budget thinking and names the fix
    And the exit status is non-zero so the caller treats it as a failure
    And the full trace is filed with truncated_in_think=true
    # bin/fm-mlx:69-92 (split/log) · bin/fm_think.py:104-140 (split)
    # VERIFIED: FM_MLX_MAX_TOKENS=200 ./fm-mlx --raw "Is the LFO dialog highlighted?
    #   Reconsider carefully." → stdout empty, exit 1, 964 chars filed.

  @hw-verified
  Scenario: A completed answer ships clean while its thinking is filed silently
    Given the model finishes its think block and writes a real answer
    When fm-mlx extracts the reply
    Then stdout is the answer only, with no tags and no deliberation
    And the thinking is filed as one JSONL line with finish_reason "stop"
    # VERIFIED: ./fm-mlx --raw "Answer in one sentence: what is an LFO?" → one clean
    #   sentence on stdout; 705 chars of thinking filed, nothing leaked.

  @built
  Scenario: reasoning fields are NEVER promoted to the answer
    Given a response carrying BOTH message.content and message.reasoning
    When fm_think.split() runs
    Then the answer comes from content alone
    And reasoning is collected as thinking
    # bin/fm_think.py:126-131 — the `or` chain that caused the incident is the bug;
    # answer_of reads answer-bearing fields ONLY. Unit-tested, cases 1-5.

  @built
  Scenario: An untagged trace is still caught
    Given a reply with no <think> tags that is plainly deliberation
    And it contains two or more DISTINCT backtracking tics
    When fm_think.looks_like_thinking() judges it
    Then it is reclassified as thinking and there is no answer
    But an ordinary answer that merely says "wait" once survives untouched
    # bin/fm_think.py:63-66 (_TIC), :83-90 (looks_like_thinking)
    # VERIFIED: "Press Enter and wait, then the dialog is highlighted." → kept.

  @built
  Scenario: An unclosed think tag leaves no answer behind
    Given a reply that opens "<think>" and never closes it
    When fm_think.strip_think() runs
    Then everything after the tag is thinking and the answer is empty
    # bin/fm_think.py:73-101 — _CLOSED, _STRAY_CLOSE and _OPEN, all three shapes.

  @built
  Scenario: Discord is guarded at the last mile
    Given the engine hands the bot a reply that is nothing but deliberation
    When askPaketti() peels it
    Then the trace is filed with source "pakettiaskbot" and thinking_only=true
    And the job is reported NOT ok, so the queue retries it with backoff
    And on the final attempt the user reads an honest one-liner, never the trace
    # pakettiaskbot/index.js:176-217 — posting to a public channel is irreversible,
    # so the guard exists even though fm_think already withheld it upstream.

  @built
  Scenario: The revise prompt no longer forces the model to deliberate in circles
    Given the user replies to a thread with a sentence fragment
    When the revise prompt is built
    Then the fragment is called a NOTE, not "the user's instruction"
    And an explicit fallback covers a note it cannot interpret (smallest edit, decide once)
    And the prompt forbids reasoning about the note in the output
    # pakettiaskbot/index.js:298-325 — the prompt caused the loop; the loop caused
    # the truncation; the truncation caused the leak.

  @hw-verified
  Scenario: The filed thinking is extractable and correctable from the laptop
    When Esa runs `paketti-thinking`
    Then he sees one line per trace: when, CIRCLED-or-ok, size, tic count, question
    And `--circles` shows only the traces that thought without answering
    And `--show N` prints one full trace, `--md` writing it as a markup-ready file
    And `--stats` reports what fraction circled and how much thinking was burned
    And none of it needs SSH — Syncthing already carried the file
    # bin/paketti-thinking · VERIFIED live: 3 traces listed, 1 CIRCLED, --md emitted
    #   a Question/Thinking/Correction file.

  @built
  Scenario: The 14B reasoner gets a budget it can actually finish in
    Given Qwen3-14B needs far more tokens to think than Qwen3-4B did
    When fm-mlx builds the request
    Then max_tokens defaults to 4096, not the 1024 that guaranteed truncation
    # bin/fm-mlx:58 — restores the committed default; FM_MLX_MAX_TOKENS overrides.

  @todo
  Scenario: The circling rate is watched, not just recorded
    Given traces accumulate with a truncated_in_think flag
    Then a rising CIRCLED rate should surface on the fleet card as a prompt-quality signal
    # Not built. `paketti-thinking --stats` is the manual version today.
