# ============================================================================
# REPORT CARD — "Find my wife" → Find My, the right tab + the right person
# ============================================================================
#
# THE CONVEY
#   Convey "where is my wife / find my phone" by routing it through AppleBar's one
#   pipeline to Find My. "find" (bare) and "wife"/"where's my wife" mean the wife
#   (Olga); "find devices" means the Devices tab; "find my phone" means the iPhone
#   16 Pro. One tool, three thin capability bindings — not three copies (DRY).
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/find-my                 (open Find My on a tab + best-effort select)
#               bin/apple-do                (findwife / finddevices / findphone cases)
#               shared/intents.json         (the three intents — NL routing + suggestions)
#   Thinkspace: features/find-my.session.md (+ this session's transcript)
#   Areaspace : OWNS = turning "find/where is X" into Find My on the right tab+row.
#               MUST NOT TOUCH = the routing brain (apple-intent) or maps-directions.
#
# WHY THIS CARD EXISTS — AND THE HONEST LIMIT
#   Find My has NO person/device deep-link URL (its schemes findmy://, fmf1://, … only
#   open the app), NO AppleScript dictionary, and a sidebar AX tree too slow to traverse
#   (repeated AppleEvent timeouts probing it). So the automation splits cleanly:
#     • RELIABLE  — CLICK the View ▸ People/Devices/Items menu item. (The equivalent
#                   ⌘1/⌘2/⌘3 chord gets SWALLOWED when a device/person row has focus —
#                   it switched on a cold launch but not when Find My was already open on
#                   another tab. The menu click invokes the tab action regardless of focus.)
#                   First WAIT (poll, re-activating) until Find My is truly frontmost, or a
#                   slow cold launch makes the click no-op before the app is up.
#     • BEST-EFFORT — selecting the SPECIFIC row, via list type-select (type the name with
#                   Find My frontmost). Works when the list has focus; otherwise the row
#                   is one tap away. Frontmost-guarded: if Find My isn't active we send NO
#                   keystrokes (the 2026-05-26 iMessage/iTerm leak lesson).
#
# REPORT-CARD LEGEND
#   @verified  reproduced on a real Mac (screenshot/dry-run cited)
#   @built     wired + runs; the row-highlight is inherently best-effort (see WHY)
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main. New: bin/find-my, this card + session. Changed: bin/apple-do
#   (+3 caps), shared/intents.json (+3 intents). AppleBar unchanged (it reads intents.json;
#   restarted to refresh its suggestion catalog). The wife's name (Olga) + the phone model
#   (iPhone 16 Pro) live in the apple-do bindings, not hardcoded in the tool.
# ============================================================================

Feature: Find My — open the right tab and surface the right person/device

  @verified
  Scenario: "find" and the wife phrasings all route to the wife (Olga)
    Given the apple-intent catalog
    When I say "find" / "wife" / "where's my wife" / "where is olga"
    Then the matched action is `findwife` → `apple-do findwife` → find-my people "Olga"
    # cite: shared/intents.json findwife examples; bin/apple-do findwife case
    # hand-verified 2026-06-04: apple-intent --dry-run for all four → "apple-do findwife"

  @verified
  Scenario: devices and phone phrasings route distinctly
    When I say "find devices" → `finddevices` (Devices tab, no specific row)
    And I say "find my phone" / "find my iphone" → `findphone` → find-my devices "iPhone 16 Pro"
    # cite: shared/intents.json finddevices/findphone; bin/apple-do cases
    # hand-verified 2026-06-04: dry-run → "apple-do finddevices" / "apple-do findphone"

  @verified
  Scenario: it RELIABLY switches tab even when Find My is already open on another tab
    Given Find My's View menu has People/Devices/Items (⌘1/⌘2/⌘3)
    When `apple-do finddevices` runs, then `apple-do findwife` runs
    Then find-my polls until Find My is frontmost, then CLICKS the View ▸ <tab> item
    And the tab switches both ways: People→Devices→People (the keystroke did NOT — it was
      swallowed by the focused device row; the click is focus-independent)
    # cite: bin/find-my (click menu item <menu> of menu bar item "View"; frontmost poll)
    # hand-verified 2026-06-04 (screenshots): Devices→"find wife"→People list shown;
    #   and the earlier keystroke build left it stuck on Devices (the bug this fixes)

  @built
  Scenario: selecting the specific row is best-effort type-select, frontmost-guarded
    Given Find My has no API to select a person/device
    When find-my has switched tab and Find My is frontmost
    Then it types the name so AppKit list type-select highlights the match
    And if Find My is NOT frontmost it sends nothing (no keystroke leak)
    And it is hard-bounded (timeout + with-timeout) so it can never hang
    # cite: bin/find-my (frontmost guard + keystroke; timeout 8 / with timeout 5)
    # hand-verified 2026-06-04: ran in <4s, no hang, no osascript orphans

  @note
  Scenario: one tool, three bindings — DRY, not three near-copies
    Given people/devices/items differ only by which View item to click
    Then bin/find-my <tab> [name] is the single mechanism; findwife/finddevices/findphone
      are thin apple-do bindings that pin the tab + the name (Olga / iPhone 16 Pro)
    # echoes the reuse-before-rerolling rule raised earlier this session
