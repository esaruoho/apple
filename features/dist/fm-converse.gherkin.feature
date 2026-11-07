# Pure Gherkin test extracted from features/fm-converse.feature
# (report-card banner stripped; inline # cite: traceability kept)
# Regenerate: python3 print-card.py features/fm-converse.feature

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

# ── WHERE fm-converse FAILS THE FOUR PROPERTIES (the point of the study) ──────
# P1 verifiable claims : ✗ until this file — behaviour lived only as code + comments.
# P2 linked to innards : ✗ — no citation structure existed before this card.
# P3 honestly graded   : ✗ — nothing recorded what was tested vs assumed.
# P4 two-way back-link  : partial — bin/fm-converse now carries the feature-card marker;
#                         fm-submit / fm.swift are still separate units.
# Triad                : .feature present · .session present · RESULT present.
