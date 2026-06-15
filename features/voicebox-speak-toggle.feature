# ============================================================================
# REPORT CARD — Voicebox speak toggle (local "let Claude talk to me / don't")
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/voicebox-speak                 (the switch: enable/disable/toggle/status)
#               ~/.claude/hooks/voicebox_speak.py  (the chokepoint: bails when off)
#               topbar/AppleToolbox.swift          (the menu row + claudeSpeechEnabled())
#               commands/voicebox-speak.md         (the /voicebox-speak slash)
#   Thinkspace: features/voicebox-speak-toggle.session.md
#   Areaspace : OWNS = the local on/off state at ~/.config/voicebox/speak.state and
#               every reader/writer of it. MUST NOT TOUCH = the server-side
#               speaker-claim gate (voicebox-on/voicebox-off → /speak/claim,
#               /speak/release), the TTS synthesis path, profile/engine choice,
#               or voicebox-stop's kill behaviour (it only CALLS voicebox-stop).
#
# WHY THIS CARD EXISTS
#   Esa wanted to set Voicebox up when he wants it and "shut it up" when he doesn't
#   want Claude speaking. The Claude Code Stop hook (voicebox_speak.py) is the single
#   point all spoken responses flow through, so the kill-switch lives THERE, fed by a
#   state file that a one-line CLI and an AppleToolbox menu row both flip. Default
#   (state file absent) == ON, preserving the prior always-speak behaviour.
#
# REPORT-CARD LEGEND (grade tags in use)
#   @verified  exercised on this Mac and observed to behave as written
#   @built     compiled + wired into the running app, not separately auto-tested
#   @untested  needs a live Voicebox + a real Claude turn to confirm end-to-end audio
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main (no PR). Files:
#     bin/voicebox-speak                (new — the CLI)
#     ~/.claude/hooks/voicebox_speak.py (patched — speech_enabled() gate; lives in
#                                        ~/.claude, NOT this repo, so not in the commit)
#     topbar/AppleToolbox.swift         (claudeSpeechEnabled() + toggle menu row)
#     commands/voicebox-speak.md        (new — slash)
#     features/voicebox-speak-toggle.{feature,session.md} (this card)
#   AppleToolbox rebuilt + relaunched via topbar/build.sh.
# ============================================================================

Feature: Local on/off switch for Claude speaking aloud
  As Esa, I can silence Claude's spoken responses on this Mac when I don't want it
  talking, and switch speech back on when I do — from a CLI, a slash, or the 🧰 menu.
  The switch is a single state file; the Stop hook is the one place that honours it.

  @verified
  Scenario: Default is ON when no state file exists
    Given ~/.config/voicebox/speak.state does not exist
    When the Stop hook checks speech_enabled()
    Then it returns true and Claude speech behaves exactly as before
    # cite: ~/.claude/hooks/voicebox_speak.py speech_enabled() (~90); bin/voicebox-speak current()

  @verified
  Scenario: Disabling silences future responses and cuts current playback
    Given Claude speech is ON
    When I run `voicebox-speak disable` (or click "Claude Speech: ON" in 🧰)
    Then the state file holds "off"
    And voicebox-stop is invoked so anything playing right now goes quiet
    And the next Stop hook fire returns early without synthesising
    # cite: bin/voicebox-speak disable(); ~/.claude/hooks/voicebox_speak.py main() early-return

  @verified
  Scenario: Enabling restores spoken responses
    Given Claude speech is OFF
    When I run `voicebox-speak enable` (or click "Claude Speech: OFF" in 🧰)
    Then the state file holds "on"
    And the next Stop hook fire proceeds to synthesise + play
    # cite: bin/voicebox-speak enable(); speech_enabled() returns true

  @verified
  Scenario: Toggle flips whichever state is current
    Given any current state
    When I run `voicebox-speak toggle`
    Then ON becomes OFF and OFF becomes ON
    # cite: bin/voicebox-speak toggle case

  @verified
  Scenario: status reports state and exit code
    When I run `voicebox-speak status`
    Then it prints ON/OFF and exits 0 when on, 1 when off
    # cite: bin/voicebox-speak status case

  @built
  Scenario: The 🧰 menu shows a live, self-relabelling toggle row
    Given AppleToolbox is running
    When I open the 🧰 menu under "Stop Voicebox"
    Then I see "🗣️ Claude Speech: ON — click to disable" when speech is on,
      or "🤫 Claude Speech: OFF — click to enable" when off
    And clicking it runs `bin/voicebox-speak toggle --quiet`
    And the label updates on the next menu refresh tick
    # cite: topbar/AppleToolbox.swift claudeSpeechEnabled() + rebuildMenu() row (~3806)

  @note
  Scenario: This is NOT the server-side speaker-claim gate
    Given ~/bin/voicebox-on and ~/bin/voicebox-off already exist
    Then those POST /speak/claim and /speak/release (which client may speak)
    And this switch is independent: a purely local "should Claude speak at all" flag
    # cite: ~/bin/voicebox-on, ~/bin/voicebox-off vs ~/.config/voicebox/speak.state

  @untested
  Scenario: End-to-end audio confirmation
    Given Voicebox is running and speech is ON
    When Claude finishes a turn
    Then a WAV is synthesised and played; disabling mid-turn stops it
    # verifiable only with a live Voicebox backend + a real Claude turn
