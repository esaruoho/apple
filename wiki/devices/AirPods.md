# AirPods

> Head-gesture trigger surface + audio routing target. The smallest Apple "device" with its own automation behaviors. No screen, no app — but yes, a real trigger surface.

## Role

Three roles, all relevant to the apple skill:

1. **Audio sink** — every Mac/iPhone/iPad/Watch can route audio here; scripted audio-routing must know AirPods state
2. **Trigger surface** — head gestures, stem squeezes, "Hey Siri" without a phone visible
3. **Spatial audio + head tracking** — App Intents and visionOS interactions can use head-tracking state

## Automation surface

AirPods don't run code — they expose state and events to the connected device. Automation lives on the host.

- **Stem squeeze / press** (Pro / Max) — single, double, triple, long; configurable per side in Bluetooth settings; can be bound to Siri, ANC mode cycling, transport controls
- **Head gestures** (Pro 2 / 4 with Active Noise Cancellation) — nod / shake to accept/decline calls and Siri suggestions
- **"Hey Siri"** — voice surface, works without phone in pocket if AirPods are connected
- **In-ear detection** — auto-pause / auto-play on removal/insertion; visible as a state change to the host
- **Spatial Audio + head tracking** — orientation data stream available to apps via Core Motion
- **Conversation Boost** (Pro / Max, Accessibility) — automation around hearing-assist mode
- **Personal Automations on iPhone** can trigger on "Bluetooth → AirPods connected/disconnected"

## Cross-device fabric

- **Automatic Switching** — AirPods follow which device is producing audio: Mac → iPhone call comes in → AirPods switch to iPhone → call ends → switch back to Mac (sometimes; Apple's heuristic is fallible)
- **Audio Sharing** — two AirPods can pair to one iPhone (parent + kid scenario)
- **Find My** — AirPods Pro case has U1 chip in recent generations; visible to Find My
- **Mac audio output picker** — AirPods show up as a CoreAudio device when paired; scriptable via `SwitchAudioSource` or AppleScript's Audio MIDI Setup driver

## Trigger surface — what fires on AirPods

- Stem squeeze → Siri / next track / play-pause / ANC cycle
- Head nod / shake → accept/decline call
- "Hey Siri" → Siri
- Removed from ear → auto-pause
- Reinserted → auto-resume
- Connect / disconnect Bluetooth → host-side Personal Automation
- Find My ping → audible chime
- Low battery alert → notification on host

## Painpoints specific to AirPods

- **Automatic Switching** is heuristic and frequently picks the wrong device; scripted audio-routing should explicitly set output, not assume AirPods stay on the Mac
- **No granular API to read button events on Mac** — Mac sees them only as media keys; iOS exposes more
- **"Hey Siri" target disambiguation** — Mac, iPhone, AirPods, Watch, HomePod can all hear "Hey Siri"; settings let you suppress per-device
- **Firmware updates require iOS device** — no Mac path
- **Conversation Awareness / spatial features** keep being added in OS updates; capability per AirPods generation drifts

## Cross-refs

- Audio device automation: see Audio MIDI Setup notes in `feedback_check_audio_input_first.md`
- "Hey Siri" target collisions: [HomePod.md](HomePod.md), [AppleWatch.md](AppleWatch.md)
- Voicebox routing on Mac (when audio comes out of AirPods, the `voiceboxstop` skill is what kills it): see `voicebox` skill
