# Session — Where am I? Device-presence geolocation for Directions

Faithful, not flattering. Audit trail for `me-location.feature` and the saddr change in `directions-home.feature`.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/e08dfd73-b702-44ad-9f8b-e58f14614d0f.jsonl`
- Session ID: `e08dfd73-b702-44ad-9f8b-e58f14614d0f`
- Resume: `claude --resume e08dfd73-b702-44ad-9f8b-e58f14614d0f`
- When: Thursday, 4 June 2026, ~14:00–14:15 EEST

## The request

Esa, verbatim: *"so i just used 'Hey Sal' and said Directions. the only thing that is missing, is for the directions to have been ingested with my location. in this case, it is possible to deduce that i am at Workspace, because theres the presence of esarMBP and other such devices. that means im at Sahaajankatu 20-22 E, Helsinki 00880. That means the Directions should adhere to that."*

The diagnosis, in his own framing: **the origin is deducible from device presence.** esarMBP + other devices on the LAN ⇒ I'm at Workspace ⇒ Sahaajankatu 20-22 E.

## What I found (the gap)

`bin/maps-directions` set only `daddr=<home>` and deliberately omitted `saddr`, with the comment "so Maps routes from the current location." That assumption holds on a phone (GPS) but **not on a desktop Mac on Ethernet** — Maps has no current location to route from, so the route opens with no real origin. The old `directions-home.feature` even encoded the wrong assumption: *"with no saddr so Maps routes from the current location."*

## The signals I actually probed (not guessed)

- Wi-Fi was OFF; on Ethernet (`en19`), so SSID is useless here — confirms why a network *fingerprint* beats SSID.
- `route -n get default` → gateway `192.168.32.1`; `arp -n` → gateway MAC `b0:0a:d5:4c:e2:03`.
- `arp -a` named peers (minus self `raymac`): `cloudcitymacmini`, `esarmbp`, `re305`.
- `me-address` (home/destination) = Inkiväärikuja 6 B20, 00990 Helsinki — distinct from the Workspace origin. This is *why* me-location must be a separate thing from me-address: home is a constant, here is a variable.

I chose **gateway MAC as the anchor signal** (one physical router = one place; survives DHCP and Wi-Fi-off), with peers as corroboration and SSID as a weak fallback.

## Build, and the bugs along the way (faithful)

1. First `me-location` normalized MACs with awk `strtonum` → **macOS awk has no strtonum** (a known repo gotcha for bash, here it bit awk). Fell back to a pure string left-pad instead. Until fixed, gateway_mac came back empty and it matched on *peers* — still correct answer, weaker signal.
2. `mdns.mcast.net` leaked through the peer filter (my `$` anchor only caught trailing "mcast"). Widened the exclude to `mcast|mdns|.255`.
3. awk parsed `s(...)` as a function call → "undefined function s". Needed spaces around string concatenation: `s = s (...) o`.

After fixes: `me-location --why` → `Workspace  gateway_mac  Sahaajankatu 20-22 E, 00880 Helsinki, Finland`. Then wired `saddr` into maps-directions and ran it for real:

> `Opening directions home in Maps (driving) from Workspace → Inkiväärikuja 6 B20,00990 Helsinki Finland` — Maps.app running (pgrep ✓).

## Decisions / rejected alternatives

- **places.json lives in `~/.config/apple-bar/`, not the repo** — same as `home-address.txt`. Personal addresses don't get committed.
- **Did NOT hardcode "Workspace" into maps-directions.** A config + resolver generalizes: add `--learn "Cafe"` anywhere, fill the address, and Directions adapts. The one thing the network genuinely can't know is the postal address, so that stays hand-entered.
- **Graceful fallback preserved:** unknown network ⇒ me-location exits 1 ⇒ saddr omitted ⇒ exactly the old behaviour. No regression for places not yet learned.

## Follow-up worth noting

Only the Workspace signature is learned so far. Home, and any other place, get added by running `me-location --learn <name>` while standing there (then editing in the address). me-location is also a reusable primitive for anything else that wants "which place is this Mac at" (Fleet attribution, context-aware automations).
