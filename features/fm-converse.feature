t w# =============================================================================
# REPORT CARD: fm-converse — stateful sender to Apple FoundationModels on the Mini
# Skin: API / pipeline (claim = input → assembled prompt → reply artifact)
# Convention: ~/.claude/skills/report-card/SKILL.md  ·  GHERKIN-FEATURE-WIKI-PATTERN.md
# SESSION >> features/fm-converse.session.md   (the vibe diff that spawned this — TODO, see gaps)
#
# STATUS OF THIS CARD: a STUDY of the current state. fm-converse shipped over three
# commits WITHOUT a card. This card is being authored after the fact, so it grades
# what exists today and flags every place the unit fails the four report-card
# properties. Born-with-a-card it was NOT; this is the retrofit.
#
# ── WHAT THIS CARD SPAWNS ───────────────────────────────────────────────────
#   Codespace : bin/fm-converse (this unit) → bin/fm-submit (Syncthing round-trip)
#               → [Mini] fm-worker → bin/fm + bin/fm.swift (FoundationModels).
#               State: ~/.cache/fm-converse/<session-key>.json {system, turns[]}.
#   Thinkspace: held in features/fm-converse.session.md — MISSING (gap G2 below).
#   Areaspace : OWNS the stateful replay + prompt assembly + terminal rendering.
#               MUST NOT own: the model itself (fm.swift), the transport (fm-submit),
#               or the tool preamble (fm.swift --tools). Stateless one-shots = fm-submit.
#
# ── report-card legend (grades in use) ──────────────────────────────────────
#   @built          - code exists and is committed
#   @verified-live  - exercised end-to-end against the real Mini this session
#   @self-test      - verified by a standalone deterministic check (no Mini)
#   @untested       - code path exists but was never exercised
#   @caveat         - works but has a known sharp edge
#
# ── innards cited by this card ───────────────────────────────────────────────
#   bin/fm-converse  current_session_key (79), store_path (90), load/save (96/106),
#                    maybe_file_to_text (110), build_replay (136), md_to_ansi (45),
#                    emit_reply (63), main (154), call_fm (216), self-heal (228-235)
#   bin/fm-submit    Syncthing fm-inbox/fm-outbox round-trip
#   bin/fm.swift     useTools (22), session build (516-520) — tools opt-in
#
# ── RESULT (third leg: spec + session + what shipped) ────────────────────────
#   Feature delivery : 408a628 (initial), b66f39d (budget+tools fix), c122a61 (md render)
#                      — all pushed direct to esaruoho/apple main, no PR.
#   This card authored: (pending commit of features/fm-converse.feature)
#   Triad status     : .feature = THIS (partial) · .session = MISSING · RESULT = here.
# =============================================================================

Feature: fm-converse — a remembering conversation with the on-device LLM
  As someone talking to Apple's FoundationModels model on the Mac Mini,
  I want each message to carry the prior dialogue and come back rendered,
  So that Converse's Cmd-1 is a real conversation, not unrelated one-shots.

  @built @verified-live
  Scenario: A follow-up question keeps the prior context
    # cite: bin/fm-converse build_replay (136) replays turns newest→oldest under budget
    # cite: bin/fm-converse main (252-254) persists [user,assistant] to the store
    Given a session whose store already holds "what is a tiger" + its answer
    When the user sends "and how big do they get"
    Then the replay includes the tiger turns and the reply is about tiger size
    # verified-live 2026-06-03: reply was "up to ~10 feet, 220-660 pounds"

  @built @verified-live
  Scenario: Replay stays inside the 4096-token FoundationModels window
    # cite: bin/fm-converse REPLAY_BUDGET=6000, FILE_CAP=5000, MAX_INPUT_CHARS=9000 (74-76)
    # cite: bin/fm-converse main (224-226) trims to just-the-question if over ceiling
    # cite: bin/fm.swift useTools (22) — tools OFF by default removes the ~4600-token preamble
    Given prior dialogue larger than the model window
    When a new turn is assembled
    Then the assembled prompt is capped so a trivial question no longer overflows
    # was the 4685>4096 bug; root cause was fm.swift forcing 16 tools (b66f39d)

  @built @self-test
  Scenario: Markdown renders as ANSI on a terminal, plain when piped
    # cite: bin/fm-converse md_to_ansi (45) bold/italic/code/headings/bullets/links/fences
    # cite: bin/fm-converse emit_reply (63) styles only when sys.stdout.isatty()
    Given the model replies with **bold**, # headings and - bullets
    When the reply is printed to a TTY
    Then it shows ANSI styling; when piped (Converse capture) it stays plain text
    # self-test 2026-06-03: standalone md_to_ansi over a mixed sample rendered correctly

  @built @verified-live
  Scenario: A worker/guardrail/timeout error is surfaced, not swallowed
    # cite: bin/fm-converse main (242-247) prints fm-submit's last stderr line as the reply
    Given fm-submit returns non-zero (worker down, guardrail, or overflow)
    When fm-converse finishes
    Then the user sees "[FM-on-Mini] <reason>" instead of a silent empty reply
    # verified-live: the 4685-token error surfaced verbatim before the fix

  @built @untested
  Scenario: A file path is read and summarised instead of sent literally
    # cite: bin/fm-converse maybe_file_to_text (110) → bin/file-to-text, FILE_CAP cap (131)
    # cite: bin/fm-converse main (209-214) neutral "here is some text…" framing
    Given the message is a path to a txt/md/rtf/pdf/image file
    When fm-converse runs
    Then the file's extracted text (capped) is sent with a summarise instruction
    # UNTESTED this session — no file-path round-trip was run

  @built @untested
  Scenario: Context-overflow self-heal retries without history
    # cite: bin/fm-converse self-heal (228-235) re-calls fm with build_replay([], turn)
    Given fm-submit reports exceededContextWindowSize despite the budget caps
    When fm-converse detects an overflow marker in stderr
    Then it retries once with only the new question (no replayed history)
    # UNTESTED-in-anger: the one time it fired, the real cause was fm.swift tools,
    # so the retry ALSO failed; never re-exercised after the fm.swift fix. Suspect-but-unproven.

  @built @caveat
  Scenario: The conversation is keyed to the newest Converse session dir
    # cite: bin/fm-converse current_session_key (79) = max(sessions/*, key=mtime)
    Given no explicit --session is passed
    When fm-converse resolves which conversation to continue
    Then it uses the most-recently-modified ~/work/converse/sessions/ dir
    # CAVEAT: if another session dir was touched more recently than the one you're
    # actually typing in, the wrong conversation is continued. Mtime ≠ "the window I'm in".

  @built @caveat
  Scenario: Stored conversation is volatile and reportcard-less
    # cite: bin/fm-converse STORE = ~/.cache/fm-converse (69), save (106)
    Given any fm-converse exchange completes
    When you look for a durable record of it
    Then there is only a flat ~/.cache JSON buffer — not dated, not titled, not in the
    vault, not synced, no per-conversation transcript, no grade, no event log
    # this is the "reportcard-less RESULT" Esa flagged: the TOOL has no card AND its
    # OUTPUTS have no durable card either.

# ── WHERE fm-converse FAILS THE FOUR PROPERTIES (the point of the study) ──────
# P1 verifiable claims : ✗ until this file — behaviour lived only as code + comments.
# P2 linked to innards : ✗ — no citation structure existed before this card.
# P3 honestly graded   : ✗ — nothing recorded what was tested vs assumed.
# P4 two-way back-link  : ✗ — fm-converse / fm-submit / fm.swift carry NO
#                         "# FEATURE-CARD >> features/fm-converse.feature" marker.
# Triad                : .feature partial (this) · .session MISSING · RESULT present.
# ⇒ fm-converse is, by the report-card definition, an INCOMPLETE unit: it shipped
#   without its card, and three of four properties are unmet until this retrofit
#   is finished (back-links added + session captured + committed).
