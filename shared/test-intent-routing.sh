#!/usr/bin/env bash
# test-intent-routing.sh — assert apple-intent routes key phrases to the right action.
# The executable half of features/me-address.feature (and a guard for the whole
# catalog): pure NLEmbedding routing, no mic, no Contacts, no Mini. Runs on any Mac.
# Exit 0 = all mappings correct.
set -uo pipefail
INTENT="$(cd "$(dirname "$0")/../bin" && pwd)/apple-intent"
fail=0
expect() {  # <phrase> <expected-action>
  local got
  got=$("$INTENT" --json "$1" 2>/dev/null | grep -o '"action":"[^"]*"' | head -1 | cut -d'"' -f4)
  if [ "$got" = "$2" ]; then printf '  ok  %-28s → %s\n' "\"$1\"" "$2"
  else printf 'FAIL  %-28s → got "%s", want "%s"\n' "\"$1\"" "$got" "$2"; fail=1; fi
}
# the disambiguation this card exists for: "home" the place vs "home" the thermostat
expect "where is my home"        address
expect "where do i live"         address
expect "what is my home address" address
expect "home temperature"        home
expect "how warm is it at home"  home
expect "is it humid at home"     home
# the rest of the catalog stays correctly separated
expect "what time is it"         now
expect "is the mini busy"        fleet
expect "find my notes on tesla"  search
[ $fail -eq 0 ] && { echo; echo "✅ ALL INTENT-ROUTING TESTS PASS"; } || { echo; echo "❌ routing failures"; exit 1; }
