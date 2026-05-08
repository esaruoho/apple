# audio-midi-exporter

Audio MIDI Setup data without launching Audio MIDI Setup. Tier 5 dark
app — no AppleScript dictionary, no App Intents, no URL scheme — but
the **`system_profiler`** CLI exposes all the Core Audio + Core MIDI
state, and saved MIDI Studio configurations live as `.mcfg` plist
files in `~/Library/Audio/MIDI Configurations/`.

Apple-native only. No `pip`, no `brew`.

## Install

```bash
cd ~/work/apple/audio-midi-exporter
cp .env.example .env
chmod +x scripts/audio-midi-exporter
```

## Commands

### `status` — quick overview

```bash
audio-midi-exporter status
```

Per device summary line for every audio + MIDI device.

### `audio` — list audio devices

```bash
audio-midi-exporter audio
audio-midi-exporter audio --json
```

Per device: transport (Built-in / USB / Bluetooth / Aggregate), input
channels, output channels, current sample rate, default-in / default-
out / default-system flags.

### `midi` — list MIDI devices

```bash
audio-midi-exporter midi
audio-midi-exporter midi --json
```

Per device: name, manufacturer, model, online status, embedded
entities/ports (cables, virtual sources).

### `configurations` — saved MIDI Studio configs

```bash
audio-midi-exporter configurations
```

Lists `.mcfg` files at `~/Library/Audio/MIDI Configurations/`. These
hold the user's saved Studio layouts (cabling, virtual MIDI sources,
labels, positions). They're plist files — `plutil -p <file>.mcfg`
prints their contents.

### `export` — full markdown vault

```bash
audio-midi-exporter export
```

Writes:

```
~/work/apple/exported/audio-midi/
├── INDEX.md
├── audio.md                          per-device sections
├── midi.md
└── configurations/
    ├── _index.md
    └── Default.mcfg                  symlink to live config file
```

## Why this exists

Audio MIDI Setup is one of the most useful Apple utilities — it tells
the system what your audio interfaces and MIDI devices are doing. But
the GUI only shows current state, has no scripting interface, and you
can't grep across a session of devices, sample-rate changes, etc.

The CLI back-door (`system_profiler SPAudioDataType -xml` +
`SPMIDIDataType -xml`) returns the full Core Audio / Core MIDI state
as a structured plist. Parsing it lets us:

- catalog devices in markdown for browsing or grepping
- diff sessions ("what changed when I plugged in the M-Audio?")
- feed device names into Loupedeck button labels
- automate sample-rate / device-default switching (Phase 2)

## Phase 2 (deliberately omitted)

- `set-default-output <device>` / `set-default-input <device>` — would
  use `defaults` and the `audio` command-line tool (or
  `SwitchAudioSource` if installed; we'd write our own AVFoundation
  shim to stay Apple-native).
- `change-sample-rate 48000` — same idea via Core Audio API + Swift
  one-liner.
- `watch` — fswatch on the MIDI Configurations dir + a Core Audio
  notifications observer to log every device change.

These need explicit confirmation prompts; current scope is read-only.
