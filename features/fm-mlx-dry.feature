# =============================================================================
# REPORT CARD: fm-mlx-dry — fm-mlx reuses Say + Karaoke + Markdown instead of
#                           re-implementing them
# Skin: CLI tool (claim = a prompt in → the Mini's MLX reply, rendered and/or spoken)
# Convention: ~/.claude/skills/report-card/SKILL.md
# SESSION >> features/fm-mlx-dry.session.md   (the vibe diff that spawned this)
#
# STATUS OF THIS CARD: born of Esa's DRY directive (2026-06-10):
#   "the fm-mlx should be DRY principle. 1. Say says it. 2. Karaoke is used.
#    3. Markdown is exists."
#   then: "fm-mlx should be automatic talk. the response ... shown the same way
#    as fm-chat response, in richtext. if not, then whats the point."
#   then: "continue the conversation from the command line ... do we have the FM
#    MLX round table in the same way ... a dry principal whether FM MLX roundtable
#    works in the exact same way." → Round 3: `fm-mlx --raw` (the shared brain
#    interface), `fm-chat --mlx` (live REPL, speaks), and MLX as the DEFAULT brain
#    of `convey roundtable` (--fm falls back to FoundationModels).
# fm-mlx was a bare curl-and-print; the capabilities it should lean on all already
# existed (the say skill's Eddy voice, bin/say-karaoke, fm-converse's inline
# Markdown renderer, and fm-chat's `fm ›` framing). This change makes fm-mlx REUSE
# them: the Markdown renderer is lifted into a shared module, fm-chat's reply
# framing is factored into a shared format_reply() that BOTH fm-chat and fm-mlx now
# call (so they look identical, in richtext), and fm-mlx speaks by default
# (TTY-gated). Built + verified live against the Mini THIS session; card in the
# same motion.
#
# ── WHAT THIS CARD SPAWNS ───────────────────────────────────────────────────
#   Codespace : bin/fm-mlx        (this unit — MLX round-trip + flags + wiring)
#               bin/fm_render.py   (shared: md_to_ansi / md_to_plain / emit_reply /
#                                   format_reply — Markdown home + fm-chat framing)
#               bin/fm-converse    (imports fm_render; inline renderer deleted)
#               bin/fm-chat        (now calls the shared format_reply too)
#               reuses: bin/say-karaoke (unchanged), the `say` skill's Eddy voice
#   Thinkspace: features/fm-mlx-dry.session.md
#   Areaspace : fm-mlx OWNS the MLX HTTP round-trip + flag parsing + wiring the
#               reused capabilities + the auto-talk TTY gate. It MUST NOT own:
#               Markdown/framing rules (fm_render, shared), speech synthesis
#               (say-karaoke owns AVSpeechSynthesizer + per-word highlight), or the
#               MLX server (mlx_lm.server on the Mini). DRY: re-implements none.
#
# ── report-card legend (grades in use) ──────────────────────────────────────
#   @built          - code exists
#   @verified-live  - exercised against the real Mini this session
#   @self-test      - verified by a standalone deterministic check (no Mini)
#
# ── innards cited by this card ──────────────────────────────────────────────
#   bin/fm_render.py    md_to_ansi(), md_to_plain(), emit_reply(), format_reply()
#                       (fm-chat framing: green `fm ›` + Markdown + stats); CLI
#                       main() handles --plain (speech) and --chat (framed richtext)
#   bin/fm-mlx          flags --say/--quiet/--voice/--system (~28); MLX POST + parse
#                       (~50); show via fm_render --chat (~78); auto-talk TTY gate +
#                       say-karaoke (~83)
#   bin/fm-converse     `from fm_render import emit_reply` (inline copy removed)
#   bin/fm-chat         `from fm_render import format_reply, md_to_plain` (~35);
#                       --mlx flag + ask_mlx() (shells `fm-mlx --raw`) + speak_reply()
#                       (say-karaoke); loop branches brain by flag; reply via format_reply
#   bin/fm-mlx          --raw flag (brain interface: reply text only, no framing/speech)
#   reused (not ours)   bin/say-karaoke (speak + JSON word-range highlight);
#                       say skill voice "Eddy" (~/.claude/skills/say/SKILL.md)
#   convey/convey/cli.py  cmd_roundtable: brain = fm-mlx by DEFAULT (was fm-submit);
#                       --fm restores FoundationModels; backend-agnostic Popen builds
#                       `fm-mlx --raw --system S prompt`; brain_fails guard (down-MLX
#                       no-hot-loop). CONVEY-CARD >> convey-roundtable-live.feature
#
# ── RESULT (third leg: spec + session + what shipped) ────────────────────────
#   Feature delivery : (commit pending at authoring time — direct to esaruoho/apple
#                       main, no PR; apple does not Syncthing-sync)
#   Files changed    : bin/fm_render.py (new), bin/fm-mlx (rewrite), bin/fm-converse
#                      (import the shared module), bin/INDEX.md (regenerated),
#                      features/fm-mlx-dry.feature + .session.md (this triad)
#   Triad status     : .feature = THIS · .session = present · RESULT = here. COMPLETE.
# =============================================================================

Feature: fm-mlx reuses Say, Karaoke, and Markdown (DRY)
  As the operator of the fm-* family
  I want fm-mlx to lean on the capabilities that already exist
  So that Markdown rendering, speech, and voice live in ONE place each

  Background:
    Given the Mini's mlx_lm.server (Qwen3-4B) is reachable over Tailscale
    And bin/fm_render.py is the single Markdown renderer
    And bin/say-karaoke is the single speak+highlight tool
    And the `say` skill's chosen voice is "Eddy"

  @verified-live
  Scenario: the reply is shown the SAME way as fm-chat, in richtext
    When I run `fm-mlx "Reply with exactly: **Hello** from MLX"`
    Then it is framed by the shared format_reply: a green `fm  ›` label,
      the Markdown rendered as ANSI richtext on a TTY (plain when piped),
      and a dim `[host · MLX/Qwen3-4B · round-trip Ns]` stats line
    And fm-chat prints with the exact same format_reply
    # verified live 2026-06-10: framed "fm  › … [cloudcitymacmini · MLX/Qwen3-4B · round-trip 0.5s]"

  @verified-live
  Scenario: it speaks by default (automatic talk), TTY-gated
    Given an interactive terminal
    When I run `fm-mlx "Reply with exactly: **DRY** works"`
    Then the framed reply is shown AND spoken via say-karaoke in the "Eddy" voice
    And md_to_plain strips the markers so it is not read as "asterisk asterisk"
    # auto-talk is gated to a TTY

  @verified-live
  Scenario: a captured/piped call stays silent (roundtable safety)
    When fm-mlx's stdout is piped (e.g. the MLX roundtable captures it)
    Then it does NOT speak, but still emits the framed reply
    And `--say` forces speech even when piped; `--quiet` suppresses it
    # verified live 2026-06-10: piped default = silent; --say piped = spoke "forced speech"

  @self-test
  Scenario: nothing is duplicated — one renderer, one framer
    When I read bin/fm-converse, bin/fm-chat, bin/fm-mlx
    Then fm-converse imports emit_reply, fm-chat imports format_reply, and fm-mlx
      shows via `fm_render.py --chat` — none carry their own copy
    # verified: fm-converse --help and fm-chat --help both exec cleanly with the imports

  # ── Round 3: continue-the-conversation + the MLX roundtable (DRY brain) ──────

  @verified-live
  Scenario: --raw is the shared brain interface
    When I run `fm-mlx --raw --system "be a pirate" "say hello"`
    Then it prints ONLY the reply text — no `fm ›` framing, no stats, no speech
    # verified live 2026-06-10: "Arrr! Hello, matey! …" with no framing

  @verified-live
  Scenario: fm-chat --mlx is a live REPL that prints AND says each reply
    When I run `fm-chat --mlx` and type a line
    Then ask_mlx shells `fm-mlx --raw` (one shared MLX transport), the reply is
      shown via the same format_reply framing, and spoken via say-karaoke (Eddy)
    And `--quiet` mutes the speech; `--voice NAME` picks the voice
    # verified live 2026-06-10 (piped, --quiet): "fm  › … [cloudcitymacmini · round-trip 0.7s]"

  @verified-live
  Scenario: convey roundtable uses the MLX brain BY DEFAULT, the same way
    When I run `convey roundtable "<topic>"`
    Then the banner shows `brain: MLX/Qwen3-4B` and the loop spawns
      `fm-mlx --raw --system <persona> <transcript>` per turn — same loop, same
      karaoke, same per-voice `say`, same kb/dreamgraph feed as the FM table
    And `convey roundtable --fm` falls back to on-device FoundationModels
    And if MLX is down, 3 consecutive brain errors stop the table (no hot-loop)
    # verified live 2026-06-10: 3-turn table, MLX brain, transcript + dreamgraph +3 claims

  @self-test
  Scenario: md_to_plain strips markers for speech; md_to_ansi styles for the terminal
    When I pipe "# T\n- **b** with `c`\n```\nfenced\n```" through fm_render.py --plain
    Then headings/bullets/bold/code markers and fenced blocks are removed
    # verified live 2026-06-10
