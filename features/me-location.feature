# ============================================================================
# REPORT CARD — "Where am I right now?" → device-presence geolocation
# ============================================================================
#
# THE CONVEY
#   A phone knows where it is from GPS. A desktop Mac on Ethernet does NOT — yet it
#   sits on a network that is itself a location fingerprint. Convey "where am I" by
#   MAPPING the live LAN signature (the router's MAC, the subnet, which peers are
#   reachable — esarMBP, cloudcitymacmini, …) to a named place + its postal address.
#   This is the desktop counterpart to GPS: presence-based, not satellite-based.
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/me-location                      (the resolver)
#               ~/.config/apple-bar/places.json      (name → address + match signals)
#               bin/maps-directions                  (consumes it as the route saddr)
#   Thinkspace: features/me-location.session.md (+ this session's transcript)
#   Areaspace : OWNS = turning the live network into "which named place am I at".
#               MUST NOT TOUCH = me-address (that's HOME, the destination — a constant);
#               me-location is the VARIABLE origin. Two different "where" questions.
#
# WHY THIS CARD EXISTS
#   "Hey Sal → Directions" opened Maps with the destination (home) but no origin, so
#   on a GPS-less desktop the route had no real starting point. Esa: the directions
#   should be ingested with my location — deducible from the presence of esarMBP and
#   other devices = I'm at Workspace = Sahaajankatu 20-22 E, 00880 Helsinki. me-location
#   makes that deduction explicit and reusable, and Directions pins it as saddr.
#
# THE SIGNAL PRIORITY (strongest first)
#   gateway_mac  the default router's MAC — one physical box = one place. Survives DHCP
#                lease changes, survives Wi-Fi-off/Ethernet. The anchor signal.
#   peers_any    any listed Bonjour/arp host present (corroborated by subnet when given)
#   ssid         the Wi-Fi network name (only meaningful when on Wi-Fi)
#
# REPORT-CARD LEGEND
#   @verified  reproduced on a real Mac with live network signals
#   @built     wired + working, hand-verified
#   @note      context, not a claim
#
# RESULT
#   New: bin/me-location, ~/.config/apple-bar/places.json (Workspace entry, personal —
#   lives in $HOME beside home-address.txt, NOT committed). Changed: bin/maps-directions
#   (+saddr from me-location), features/directions-home.feature (saddr scenario). Direct
#   to main. Reuse: leans on the same arp/route signals machine-card already reads; no
#   new dependency, Apple-native (route/arp/networksetup + python3 stdlib json).
# ============================================================================

Feature: Where am I right now — device-presence geolocation for a desktop Mac

  @verified
  Scenario: the Workspace LAN fingerprint resolves to the Workspace address
    Given the Mac is on the Workspace Ethernet (gateway b0:0a:d5:4c:e2:03, subnet 192.168.32.)
    And peers esarMBP + cloudcitymacmini + re305 are reachable
    When `me-location` runs
    Then it prints "Sahaajankatu 20-22 E, 00880 Helsinki, Finland"
    And `me-location --why` reports the match came from `gateway_mac` (the strongest signal)
    # cite: bin/me-location score(); ~/.config/apple-bar/places.json "Workspace"
    # hand-verified 2026-06-04: --why → "Workspace  gateway_mac  Sahaajankatu 20-22 E, …"

  @built
  Scenario: no known place → print nothing, exit 1 (caller falls back gracefully)
    Given the live network matches no place in places.json
    When `me-location` runs
    Then it prints nothing and exits 1
    And maps-directions therefore omits saddr and lets Maps use whatever origin it has
    # cite: bin/me-location (sys.exit(1) on no match); bin/maps-directions (if -n "$src")

  @built
  Scenario: gateway_mac beats peers beats ssid
    Given a place keyed on gateway_mac and another that would match only on a shared peer
    When both could match
    Then the gateway_mac place wins (score 3 > 2 > 1)
    And a peer match is only accepted when the configured subnet also matches (anti-collision)
    # cite: bin/me-location score() priority + subnet corroboration

  @built
  Scenario: --learn captures the current signature into a named place
    Given I am standing in a new place
    When `me-location --learn "Cafe"` runs
    Then the current gateway_mac/subnet/peers/ssid are appended to a "Cafe" entry in places.json
    And I then fill in its postal address by hand (the one thing the network can't know)
    # cite: bin/me-location (--learn block writes places.json)

  @note
  Scenario: home is a constant, here is a variable — they are different questions
    Given me-address answers "what is my HOME address" (the Directions destination)
    Then me-location answers "what place am I AT right now" (the Directions origin)
    And conflating them is the bug this card fixes
