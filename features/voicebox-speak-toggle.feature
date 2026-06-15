# ============================================================================
# REPORT CARD — Voicebox speak toggle (one button: "Claude talks to me")
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/voicebox-speak                 (the switch: enable/disable/toggle/status)
#               ~/.claude/hooks/voicebox_speak.py  (the chokepoint: bails when off)
#               topbar/AppleToolbox.swift          (menu row + probe + toggleClaudeSpeech)
#               commands/voicebox-speak.md         (the /voicebox-speak slash)
#   Thinkspace: features/voicebox-speak-toggle.session.md
#   Areaspace : OWNS = the local on/off intent at ~/.config/voicebox/speak.state,
#               and "make speech work" = ensuring the Voicebox API server is up via
#               ~/bin/voicebox-start. MUST NOT TOUCH = the server-side speaker-claim
#               gate (voicebox-on/voicebox-off -> /speak/claim, /speak/release), the
#               TTS synthesis internals, or profile/engine choice.
#
# WHY THIS CARD EXISTS
#   Esa wanted ONE control: enabling Claude speech in AppleToolbox must mean it both
#   WORKS and is ON — he should never have to think about whether the Voicebox server
#   is running. So "enable" is a single source of truth: it flips the intent flag ON
#   AND starts the Voicebox server if it's down (waits for health). Two conditions gate
#   actual speech: (1) server up, (2) flag on. The Claude Code Stop hook
#   (voicebox_speak.py) is the single point all spoken responses flow through; it
#   checks the flag (server-up is implied by enable, and the hook no-ops if the
#   server is unreachable). The menu row shows the COMBINED truth. Default (state
#   file absent) == ON, preserving the prior always-speak behaviour.
#
#   v2 (2026-06-15): the first cut only flipped a flag and lied "ON" when the server
#   was down. Corrected so enable GUARANTEES the server, the CLI/menu report the real
#   end-to-end state, and the menu has a 3rd "ON but server down" state.
#
# REPORT-CARD LEGEND (grade tags in use)
#   @verified  exercised on this Mac this session and observed to behave as written
#   @built     compiled + wired into the running app, not separately auto-tested
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main (no PR). Files:
#     bin/voicebox-speak                (CLI — enable starts the server)
#     ~/.claude/hooks/voicebox_speak.py (speech_enabled() gate; lives in ~/.claude,
#                                        NOT this repo, so not in the commit)
#     topbar/AppleToolbox.swift         (voiceboxServerUp cache, probeVoiceboxServer,
#                                        toggleClaudeSpeech, 3-state menu row)
#     commands/voicebox-speak.md        (slash)
#     features/voicebox-speak-toggle.{feature,session.md} (this card)
#   AppleToolbox rebuilt + relaunched via topbar/build.sh.
# ============================================================================

Feature: One button for "Claude talks to me" (server + speech together)
  As Esa, when I enable Claude speech in AppleToolbox it both works and is on — the
  Voicebox server is started for me if it was down, and Claude is set to talk. I never
  have to check whether the server is running. Disabling silences Claude.

  @verified
  Scenario: Default is ON when no state file exists
    Given ~/.config/voicebox/speak.state does not exist
    Then the intent flag reads ON and Claude speech behaves exactly as before
    # cite: bin/voicebox-speak flag(); ~/.claude/hooks/voicebox_speak.py speech_enabled()

  @verified
  Scenario: Enabling starts the server if it is down, then sets Claude talking
    Given the Voicebox server is down and the flag is OFF
    When I run `voicebox-speak enable` (or click the AppleToolbox row)
    Then ~/bin/voicebox-start is invoked and we wait for /health
    And the flag is set ON
    And status reports "flag ON | server up | Effective: WILL SPEAK"
    # PROVEN 2026-06-15: killed server (PID 15784) -> enable booted a new server in
    # ~4s -> a subsequent Stop-hook fire played audio (afplay PID 19405).
    # cite: bin/voicebox-speak enable()/start_server()

  @verified
  Scenario: Enabling when the server is already up just sets the flag
    Given the Voicebox server is up and the flag is OFF
    When I run `voicebox-speak enable`
    Then the flag is set ON and no second server is started
    # cite: bin/voicebox-speak start_server() early-returns when server_up

  @verified
  Scenario: Disabling silences Claude and cuts current playback
    Given Claude speech is ON
    When I run `voicebox-speak disable` (or click the row when it shows ON)
    Then the flag is OFF, voicebox-stop cuts anything playing, and the next Stop
      hook fire returns early without synthesising
    And the server is left running (re-enabling is then instant)
    # cite: bin/voicebox-speak disable()/stop_playback(); hook main() early-return

  @verified
  Scenario: status reports both halves and the effective outcome
    When I run `voicebox-speak status`
    Then it prints the flag, the server up/down, and Effective WILL SPEAK/SILENT,
      exiting 0 only when speech will actually happen
    # cite: bin/voicebox-speak status()

  @verified
  Scenario: toggle does the sensible thing from any state
    Given any state
    When I run `voicebox-speak toggle`
    Then effective-ON (flag on AND server up) -> disable; anything else -> enable
      (which flips the flag on and boots the server if needed)
    # cite: bin/voicebox-speak toggle case

  @built
  Scenario: The AppleToolbox row shows the COMBINED truth in three states
    Given AppleToolbox is running and probes the server off the main thread
    When I open the menu under "Stop Voicebox"
    Then I see one of:
      "🗣️ Claude Speech: ON — click to disable"          (flag on + server up)
      "⚠️ Claude Speech: ON but server down — click to start" (flag on + server down)
      "🤫 Claude Speech: OFF — click to enable"            (flag off)
    And clicking runs `voicebox-speak disable` when effectively on, else `enable`
    And after a click the app re-probes a few times so the label catches the
      server coming up
    # cite: topbar/AppleToolbox.swift rebuildMenu() row (~3825), toggleClaudeSpeech(),
    #       probeVoiceboxServer(), voiceboxServerUp cache

  @note
  Scenario: This is NOT the server-side speaker-claim gate
    Given ~/bin/voicebox-on and ~/bin/voicebox-off already exist
    Then those POST /speak/claim and /speak/release (which client may speak)
    And this switch is the independent end-to-end "should Claude speak at all" control
    # cite: ~/bin/voicebox-on, ~/bin/voicebox-off vs ~/.config/voicebox/speak.state
