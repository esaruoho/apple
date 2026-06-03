# ============================================================================
# REPORT CARD — "Where is my home" → home address from the Contacts me-card
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/me-address           (reads the "me" card via Contacts AppleScript)
#               bin/apple-do             (exposes capability `address` → me-address)
#               bin/apple-intent         (CATALOG "address" intent + {raw} template)
#               shared/test-intent-routing.sh (the executable routing guard)
#   Thinkspace: features/me-address.session.md (+ the session's bundled transcript)
#   Areaspace : OWNS = resolving the user's postal address from their Contacts me-card.
#               MUST NOT TOUCH = the HomePod climate `home` action (the collision this
#               fixes), the network, any contact other than the me-card.
#
# WHY THIS CARD EXISTS
#   "where is my home" was matching the `home` CLIMATE action and returning the
#   temperature. It's a location question. This adds an address lookup AND a routing
#   disambiguation so the place-question and the thermostat-question stop colliding.
#
# REPORT-CARD LEGEND
#   @verified  passes shared/test-intent-routing.sh on a real Mac (headless)
#   @built     wired + working, but not auto-tested
#   @untested  needs a one-time Contacts permission grant — human-verifiable, not headless
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main, no PR. Files: bin/me-address (new), bin/apple-do (+address),
#   bin/apple-intent (+address intent +template), shared/test-intent-routing.sh (new),
#   this card + session.
# ============================================================================

Feature: Home address from the Contacts me-card
  Asking where my home is returns my address, not the room temperature.

  @verified
  Scenario: "where is my home" routes to the address lookup, not the thermostat
    Given the apple-intent catalog
    When I ask "where is my home" (or "where do i live", "what is my home address")
    Then the matched action is `address`, not `home`
    # cite: bin/apple-intent CATALOG "address" intent (~33); test shared/test-intent-routing.sh

  @verified
  Scenario: Climate questions still route to the HomePod sensor
    Given the same catalog
    When I ask "home temperature" / "how warm is it at home" / "is it humid at home"
    Then the matched action is `home` (climate), unaffected by the new intent
    # cite: bin/apple-intent CATALOG "home" intent (~26); test shared/test-intent-routing.sh

  @built
  Scenario: The address resolves from the me-card, or by name if none is set
    Given Contacts has either a "me" card OR a contact matching the account full name
    When `apple-do address` runs
    Then it returns the home-labelled postal address (falling back to the first address)
    And if no "me" card is designated it finds the contact whose name contains the first
      and last word of `id -F` (e.g. "Esa Ruoho" → matches "Esa Juhani Ruoho")
    And Contacts.app is auto-launched hidden+background (open -gj) if not running (else -600)
    # cite: bin/me-address (pgrep guard + open -gja; `my card` else name match); apple-do "address)"
    # hand-verified 2026-06-03: returned "Inkiväärikuja 6 B 20 …" cold + warm via the name fallback
    # (no headless test — needs Contacts data + a permission grant; verified on the real target)

  @built
  Scenario: The address reads through unstyled (whitelabel passthrough)
    Given the reports whitelabel
    Then action `address` uses the "{raw}" template (the formatted address is already human)
    # cite: bin/apple-intent loadTemplates() defaults "address": "{raw}"

  @note
  Scenario: It uses Contacts AppleScript, not the network
    Given bin/me-address
    Then it asks Contacts.app for `formatted address of (... of my card)` — on-device,
      no API, no third-party deps; first use prompts once for Automation access.
    # cite: bin/me-address osascript `tell application "Contacts"`
