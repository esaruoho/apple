# ============================================================================
# REPORT CARD — "How do I get home" → Apple Maps directions  (a "Convey")
# ============================================================================
#
# THE CONVEY
#   Convey the human idea "how to get home / how far am I from home" by MAPPING it
#   to the Apple mechanism that already answers it: Maps Directions. The idea is
#   conveyed = routed to `directions`, which opens Maps with a route from your
#   current location to your home address. Distance/ETA come for free from Maps.
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/maps-directions   (builds the maps.apple.com URL, opens it)
#               bin/apple-do          (capability `directions` → maps-directions)
#               bin/apple-intent      (CATALOG "directions" intent; climate narrowed)
#               shared/test-intent-routing.sh (the routing guard)
#   Thinkspace: features/directions-home.session.md (+ the session's transcript)
#   Areaspace : OWNS = turning "get home / how far home" into a Maps directions URL.
#               MUST NOT TOUCH = the climate `home` action, the `address` action.
#
# WHY THIS CARD EXISTS
#   "how far away am i from home" was returning the HOUSE TEMPERATURE — the climate
#   `home` action was greedy on the word "home". Fix: (a) narrow climate to temp/heat/
#   humidity ONLY, (b) add `directions` for the navigation sense. Three "home" senses
#   now separate cleanly: thermostat (home), address (address), destination (directions).
#
# REPORT-CARD LEGEND
#   @verified  passes shared/test-intent-routing.sh on a real Mac (headless)
#   @built     wired + working, hand-verified
#   @note      context, not a claim
#
# RESULT
#   Direct-push to main, no PR. Files: bin/maps-directions (new), bin/apple-do
#   (+directions), bin/apple-intent (+directions intent, climate narrowed, +template),
#   shared/test-intent-routing.sh (+cases), this card + session.
#   Reuse: the Maps URL pattern is lifted from ~/work/ray-graph
#   (js/dashboard/dashboard-ui.js getDirectionsUrl) — not re-invented.
# ============================================================================

Feature: Directions home via Apple Maps
  Asking how to get home (or how far it is) opens Maps with a route home.

  @verified
  Scenario: Navigation phrases route to directions, not the thermostat
    Given the apple-intent catalog
    When I ask "how far away am i from home" / "how do i get home" / "navigate home"
    Then the matched action is `directions`
    # cite: bin/apple-intent CATALOG "directions" intent (~34); test shared/test-intent-routing.sh

  @verified
  Scenario: Temperature words ONLY hit the climate sensor (narrowed)
    Given the climate `home` intent now lists temp/heat/humidity phrasings only
    When I ask "temperature" / "is it hot" / "how warm is it" / "humidity"
    Then the matched action is `home`
    And bare "home" location/destination phrases do NOT reach it
    # cite: bin/apple-intent CATALOG "home" intent narrowed (~26); test shared/test-intent-routing.sh

  @built
  Scenario: directions opens Maps from current location to home
    Given a resolved home address (me-address, cached)
    When `apple-do directions` runs
    Then it opens https://maps.apple.com/?daddr=<home>&dirflg=<mode> in Maps,
      with no saddr so Maps routes from the current location (giving distance + ETA)
    And the transport mode is auto-detected from the phrase: walk→w, transit→r, else driving→d
    # cite: bin/maps-directions (mode case + open); door-code lines stripped from the address
    # hand-verified 2026-06-03: built https://maps.apple.com/?daddr=Inkiväärikuja%206%20B20…&dirflg=d

  @note
  Scenario: The Maps URL pattern is reused from ray-graph, not re-invented
    Given ~/work/ray-graph/js/dashboard/dashboard-ui.js getDirectionsUrl
    Then maps-directions uses the same dirflg map (w=walking d=driving r=transit) and
      maps.apple.com/?daddr=…&dirflg=… form
    # cite: ray-graph getDirectionsUrl (~1841); honors the reuse-before-rerolling rule
