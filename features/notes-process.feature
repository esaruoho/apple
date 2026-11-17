# Report card: bin/notes-process — #process tag in Apple Notes → Cloudcity LLM reply, APPEND-ONLY
# RESULT: 33e9dee9, direct-push to main, no PR; fast-forward deployed on Cloudcity.
# RESULT: 11 tests pass on Mini Python 3.9; live ledger loads all 33 original keys.
# RESULT: d9992580 + 139fd5b9, direct-push main, no PR; deployed and Boot-reloaded on Cloudcity.
# RESULT: live run NP-20261115T060856Z-43018e9b80fc verified in reply p12498; 15 Mini tests pass.
# Session: features/notes-process.session.md
Feature: a #process tag in a note gets an LLM reply added as rich text, never by rewriting the note

  @built @hw-verified
  Scenario: A real orange Notes tag is found (2026-11-08, note p13544)
    Given Esa typed "hey i want you to tell me about electricity #process" in Notes.app
    Then find_occurrences() finds it in NoteStore.sqlite opened read-only (hashtag UTI, ZALTTEXT)
    And the complete stored note text is included in the audited model input

  @built @hw-verified
  Scenario: Fallback — reply as a linked rich-text note (note p13583)
    Given the Shortcut "notes-process-append" is not installed
    Then the reply is created as "Re: <title>" via bin/notes-new (markdown → rich text)
    And the original note is not modified at all

  @todo
  # generated Shortcut FAILED (dialogs) 2026-11-08; disabled. Hand-built variant documented, unverified.
  Scenario: True append via Shortcut (wiki/concepts/notes-process-append-shortcut.md)
    Given the Shortcut is installed and the note title is unique (title_count() == 1)
    Then the markdown reply is appended with Make Rich Text from Markdown + Append to Note

  @built @hw-verified
  Scenario: No feedback loop
    Then the second pass reports "nothing new for #process"
    And the ledger is keyed by the tag object's ZIDENTIFIER
    And the reply ends with "#done" and is sanitised so it never contains the trigger

  @built @sim-verified
  Scenario: Never rewrites a note (test_notes_process.py)
    Then the source contains no "set body"

  @built @designed
  Scenario: Guards
    Then locked notes, Recently Deleted, and notes edited < 15s ago are skipped

  @untested
  Scenario: Running on the Mini under Cloudcity-Boot via systems.yaml

  @built
  Scenario: Notes.app self-heals on the unattended Mini
    Given Notes is not running, or 2 Notes requests in a row time out (Notes wedged)
    Then notes-process starts Notes in the background (open -g -a Notes), restarting it first if wedged
    # bin/notes-process heal_notes(); 2026-11-09 Mini Notes was stuck 16 days at 76% CPU

  @built
  Scenario: iCloud sync is forced on the Mini
    Given a backgrounded Notes is slow to pull new notes from iCloud
    Then notes-process relaunches Notes in the background every --refresh seconds (default 60)
    # bin/notes-process one_pass(); 2026-11-09 a note sat unsynced >2 min, restart synced in 4s

  @sim-verified
  Scenario: LaTeX in replies is rendered as Unicode math (Notes can't show TeX)
    Given an LLM reply containing \( L \), \[ L = \frac{|\mathcal{E}|}{\frac{dI}{dt}} \], $E = \frac{1}{2} L I^2$
    When sanitize() runs bin/latex2unicode convert()
    Then the note shows "L = |ℰ|/(dI/dt)" on its own line and "E = 1/2 L I²"
    And plain dollar amounts like "$5 and $10" are left alone
    # verified 2026-11-11 under /usr/bin/python3 (the Cloudcity-Boot interpreter)

  @built @sim-verified
  # WATCH: bin/notes-process ledger ledger_add main
  # cite: bin/notes-process ledger(), ledger_add(), main(); test_notes_process.py
  Scenario: Unicode separators and damaged ledger records cannot cause a restart loop
    Given ledger titles contain U+2028, U+2029 or NEL, or a record is truncated
    When the worker reads its ledger
    Then only LF separates records and valid completed keys remain remembered
    And damaged bytes are preserved in a content-addressed backup without rewriting the ledger
    And a complete leading key in a torn record remains remembered to prevent duplicate replies
    And concurrent ledger reads and appends use file locks and writes are flushed to disk
    And the watcher logs unexpected pass errors and retries after its configured interval

  @built @sim-verified @hw-verified
  # WATCH: bin/notes_input.py snapshot vision_images make_prompt start_run call_llm handle
  # cite: bin/notes-process handle(), call_llm(); bin/notes_input.py; bin/notes-brain audit()
  Scenario: Complete source text and image evidence enter an auditable request
    Given a tagged note whose first paragraph is its entire description and which contains an image
    When Cloudcity processes it
    Then the first paragraph is preserved in the prompt and the rich-text reply
    And Apple Vision recognized text and classification labels are included as image evidence
    And source bytes, image hashes, Vision results, exact model requests and responses are saved
    And a unique Processing ID appears in the reply, ledger and run directory
    And missing or failed image processing and model failures remain visible in the saved records
    And the original note is never rewritten and OCR does not run on the laptop

  @built @sim-verified
  # cite: bin/notes-process main(), handle(), one_pass()
  Scenario: Delivery failure stays visible and is not reported as a successful one-shot command
    Given Notes rejects a write or times out after delivery has started
    Then the run is marked delivery_uncertain with the saved reply and error
    And the one-shot command exits nonzero
    And the default watcher does not force-restart Notes during another worker's delivery

  @built @sim-verified
  # cite: bin/notes_input.py make_prompt(); test_notes_process.py test_text_only_prompt_never_mentions_images
  # cite: bin/notes-reprocess-runs (batch redo of 2026-11-15 runs)
  Scenario: Text-only notes get no image instructions
    Given a #process note with no image attachments
    Then the model prompt never mentions images or image evidence
    And the reply answers the note instead of reporting "no image evidence"

  @built
  # cite: comms/scripts/repo-puller.sh apple post-pull (pkill 'MacOS/Python …/apple/bin/notes-process --watch' — must not match the pane-wrapper argv)
  # 2026-11-16: NP-20261115T191432Z ran OLD prompt 4 min after the Mini pulled the fix —
  # the --watch worker had imported notes_input before the pull and was never restarted.
  Scenario: A pulled fix reaches the running watchers
    Given the Mini pulls a new apple commit
    Then the notes-process --watch panes are killed and pane-wrapper relaunches them on new code

  @built @sim-verified
  # cite: bin/notes_input.py make_prompt(); test_notes_process.py test_image_prompt_is_conversation_not_report
  # 2026-11-17 NP-20261117T054235Z "Tesla induction" + diagram → evidence report, not a conversation.
  Scenario: A note with a picture gets a conversation, not a pipeline report
    Given a #process note with text and an image
    Then the prompt is the note verbatim plus the picture's read text
    And it carries no "process/evidence/report/classification label" framing
    And the reply above the answer shows no per-image processing summary

  @built
  # cite: bin/notes-voices (imports bin/freellmask-mail: route_space, wiki_context, fm_research)
  # cite: bin/notes-process main() — #process → notes-voices, #consensus → notes-brain
  # local run 2026-11-17: "Tesla induction" → Thought/Answer + 11 voice tones + skeptic, 13.7 kB
  Scenario: #process notes get the voices
    Given a #process note
    Then it is answered by the same ledger-grounded voice brain as freellmask-mail
    And it routes to free-energy unless an explicit [space:x] tag or a keyword match says otherwise
    And the disabled hyp space is never chosen
