t w# =============================================================================
# REPORT CARD: fm-converse — stateful sender to Apple FoundationModels on the Mini
# Skin: API / pipeline (claim = input → assembled prompt → reply artifact)
# Convention: ~/.claude/skills/report-card/SKILL.md  ·  GHERKIN-FEATURE-WIKI-PATTERN.md
# SESSION >> features/fm-converse.session.md   (the vibe diff that spawned this — TODO, see gaps)
#
# STATUS OF THIS CARD: a retrofit that is now active again. fm-converse shipped
# originally without a card; on 2026-09-22 it gained livefile capture and Scaff
# push so its outputs are no longer only volatile cache state.
#
# ── WHAT THIS CARD SPAWNS ───────────────────────────────────────────────────
#   Codespace : bin/fm-converse (this unit) → bin/fm-submit (Syncthing round-trip)
#               → [Mini] fm-worker → bin/fm + bin/fm.swift (FoundationModels).
#               State: ~/.cache/fm-converse/<session-key>.json {system, turns[]}.
#   Thinkspace: held in features/fm-converse.session.md.
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
#   2026-09-22       : bin/fm-converse now captures successful turns into
#                      ~/work/converse/sessions/<key>/livefile.jsonl and pushes
#                      them to ~/work/scaff/ConverseInbox via Scaff converse-push.
#   2026-09-24       : added --flubuild as a transcript-compatible remote chat
#                      backend. It shares the same session memory and livefile
#                      capture shape as --mlx / FoundationModels.
#   Triad status     : .feature = THIS · .session = present · RESULT = here.
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
  Scenario: Stored conversation remains replay memory while the livefile is the durable artifact
    # cite: bin/fm-converse STORE = ~/.cache/fm-converse, save()
    # cite: bin/fm-converse _append_capture_turn writes livefile.jsonl
    Given any fm-converse exchange completes
    When you look for a durable record of it
    Then ~/.cache/fm-converse still holds replay memory and livefile.jsonl holds the capturable record
    # caveat: cache remains the model-memory store; livefile is the semantic/audit surface.

  @built @self-test
  Scenario: A terminal fm-converse turn becomes a Converse-shaped livefile
    # cite: bin/fm-converse _append_capture_turn creates manifest.json + livefile.jsonl
    # cite: test_fm_converse.py test_successful_turn_writes_livefile_pair
    Given fm-converse gets a successful answer outside Converse.app
    When the turn is persisted
    Then it writes session.created, talk.heard and agent.responded events with one request_id
    # self-test 2026-09-22: python3 test_fm_converse.py

  @built @self-test
  Scenario: Converse.app-owned turns are not duplicated by fm-converse
    # cite: bin/fm-converse _recent_app_already_owns_turn checks recent talk.heard
    # cite: test_fm_converse.py test_existing_converse_app_turn_is_not_duplicated
    Given Converse.app already wrote the user turn to livefile.jsonl
    When its fm-converse child returns the answer
    Then fm-converse does not write another copy of that same turn
    # self-test 2026-09-22: python3 test_fm_converse.py

  @built @self-test
  Scenario: Captured fm-converse turns are pushed to Scaff
    # cite: bin/fm-converse _push_capture_to_scaff shells into semantic-convey-file converse-push
    Given a successful fm-converse turn was appended to a livefile
    When ~/work/scaff has semantic-convey-file available
    Then Scaff receives linked session and turn Markdown under ConverseInbox
    # self-test scope: the capture function is unit-tested; the Scaff receiver itself
    # was verified separately by swift test --filter ConveyBridgeTests.

  @built @verified-live
  Scenario: A flubuild turn uses the same replay memory and livefile transcript shape
    # cite: bin/fm-converse call_flubuild sends messages[] to the remote OpenAI-compatible port over SSH
    # cite: bin/fm-converse _brain_capture maps --flubuild to agent_type=flubuild
    # cite: test_fm_converse.py test_flubuild_turn_records_flubuild_agent_type
    Given a Converse session calls fm-converse with --flubuild
    When the remote model returns a reply
    Then fm-converse appends talk.heard and agent.responded events with agent_type flubuild
    And the same ~/.cache/fm-converse/<session>.json replay memory is updated
    And the flubuild default generation cap is 2048 tokens unless FM_FLUBUILD_MAX_TOKENS overrides it
    # verified-live 2026-09-24: fm-converse --flubuild --session flubuild-smoke-20260924
    # returned "flubuild-ok" and wrote the expected livefile pair.

# ── WHERE fm-converse FAILS THE FOUR PROPERTIES (the point of the study) ──────
# P1 verifiable claims : ✗ until this file — behaviour lived only as code + comments.
# P2 linked to innards : ✗ — no citation structure existed before this card.
# P3 honestly graded   : ✗ — nothing recorded what was tested vs assumed.
# P4 two-way back-link  : partial — bin/fm-converse now carries the feature-card marker;
#                         fm-submit / fm.swift are still separate units.
# Triad                : .feature present · .session present · RESULT present.

  @build-verified @runtime-verified
  Scenario: Flubuild budgets input with the server tokenizer and exposes HTTP failures
    # cite: bin/fm-converse call_flubuild ; bin/flubuild-request.py prepare main
    # companion: /Users/esaruoho/work/FinderSearch/features/flubuild-context.feature
    Given Flubuild serves an 8192-token context model
    When input plus reply allowance exceeds the model context
    Then old conversation messages are omitted before the current document is shortened
    And any context reduction is disclosed in the returned answer
    And HTTP failures include the server response body
