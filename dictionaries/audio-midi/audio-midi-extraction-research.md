# Audio MIDI Setup — Extraction Research

> 2026-05-08. Live probe on Esa's Mac (macOS 15.6.1).

## TL;DR

Audio MIDI Setup is **Tier 5 dark** — no sdef, no App Intents, no URL scheme. Two back-doors:

1. `system_profiler SPAudioDataType -xml` and `SPMIDIDataType -xml` for live device state.
2. `~/Library/Audio/MIDI Configurations/*.mcfg` plist files for saved Studio layouts.

## SPAudioDataType row shape

Each device returned by `system_profiler SPAudioDataType -xml` exposes:

- `_name` — device label ("CalDigit Thunderbolt 3 Audio")
- `coreaudio_device_input` / `coreaudio_device_output` — channel counts
- `coreaudio_device_srate` — current sample rate (Hz)
- `coreaudio_device_transport` — `coreaudio_device_type_usb` / `_builtin` / `_virtual` / `_unknown`
- `coreaudio_device_manufacturer` — manufacturer name
- `coreaudio_default_audio_input_device` — bool flag for user's default input
- `coreaudio_default_audio_output_device` — same for output
- `coreaudio_default_audio_system_device` — system-events sounds output

## SPMIDIDataType row shape

- `_name` — device label
- `midi_manufacturer`, `midi_model`
- `midi_is_online` — bool
- nested `midi_entities` — embedded entities/ports under each device

## `.mcfg` Studio configurations

Plain plist files in `~/Library/Audio/MIDI Configurations/`. Each `.mcfg` records a saved MIDI Studio layout: cabling, virtual MIDI sources, labels, positions. Plutil prints them straight (`plutil -p Default.mcfg`).

## Live numbers on this Mac

```
Audio devices:    8
MIDI devices:     0   (nothing currently plugged in)
.mcfg configs:    1   (Default.mcfg)
```

The 8 audio devices include physical (CalDigit Thunderbolt 3, MacBook Pro Speakers/Mic), virtual (Microsoft Teams Audio, LoomAudioDevice, Audio Hijack to Loopback), and an Aggregate Device. Default system output is MacBook Pro Speakers; default input is the CalDigit dock.

## Implementation in `audio-midi-exporter`

- `status` — single-line summary per device
- `audio` — full device dump with sample rates + channels + transport
- `midi` — same for MIDI
- `configurations` — list `.mcfg` files
- `export` — markdown vault with `audio.md`, `midi.md`, `configurations/` (symlinks)

## Phase 2 candidates

- `set-default-output <device>` / `set-default-input <device>` — Core Audio + Swift one-liner
- `change-sample-rate <hz>` — `kAudioDevicePropertyNominalSampleRate` set via Swift
- `watch` — Core Audio property listener for device add/remove + sample-rate change events
- network MIDI (Bonjour) discovery via `dns-sd -B _apple-midi._udp`

## Why this matters

Loupedeck buttons want labels. If you bind a button to "swap to monitor speakers", you want the label to say "Genelec" not "device 7". Auto-rendering button labels from `audio-midi-exporter audio --json` keeps them in sync as gear changes.
