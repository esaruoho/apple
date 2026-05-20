# Apple Toolbox — Menu Bar Script Launcher & Live Dashboard

A 🧰 icon in the macOS menu bar with a dropdown of one-click scripts, **plus**
extra status items that show live data (HomePod temp, Sal archive recovery,
battery). Built on [SwiftBar](https://github.com/swiftbar/SwiftBar) — native
Swift, free, open-source. Zero roundtrip: click → script runs. No LLM, no
Shortcuts engine warm-up, no Terminal flash.

## Install (once)

```bash
bash ~/work/apple/topbar/install.sh
```

Or use the slash: `/topbar`.

This installs SwiftBar via Homebrew (if missing), points it at the `plugins/`
folder, and launches it. SwiftBar is **sandboxed**, so on first launch it
shows a folder picker — choose `/Users/esaruoho/work/apple/topbar/plugins/`
and click Open. Then the menu-bar items appear.

## What's in the toolbox

One unified status item in the bar combining live data + click-to-run actions:

```
🧰 23.9° 40% ⚡96% · Sal 235/359
```

Refreshes every 5 minutes. Click it for the dropdown.

**Live status (top of dropdown):**

| Section | Shows |
|---|---|
| 🌡 HomePod Climate | latest temp + humidity from `~/work/homepod-watcher/climate-logs/` |
| 🔋/⚡ Battery | % + state + time remaining (`pmset`) |
| 🗂 Sal Archive | recovered / total / missing (regenerates `current-status.md` on every refresh) |

**Click-to-run actions (below):**

| Entry | What it does |
|---|---|
| 🔇 Stop Voicebox | runs `voicebox-stop` (same as `vstop` alias) |
| 🗑 Empty Trash | tells Finder to empty trash |
| 👁 / 👀 Desktop Icons | hide / show desktop icons |
| Audio ▸ | mute / unmute / volume presets (25/50/75) |
| Finder ▸ | kill Finder, show/hide hidden files, restart menu bar |
| Edit Toolbox… | opens the plugin script in TextEdit |
| 🔄 Refresh | re-reads the plugin immediately |

## Adding a new entry to the toolbox dropdown

Edit `plugins/Apple.5m.sh` — scroll to the "Toolbox quick actions" section.
The format is one line per entry:

```
Label here | shell="/path/to/script" terminal=false
```

For a one-liner shell command, call any binary directly:

```
🎵 Pause Music | shell="/usr/bin/osascript" param1="-e" param2='tell app "Music" to pause' terminal=false
```

For multi-command actions, drop a script into `scripts/`, `chmod +x` it, and
point at it:

```
🌑 Dark Mode | shell="$TB/dark-mode.sh" terminal=false
```

Save the file. SwiftBar picks it up automatically.

### Submenus

Indent submenu items with `--`:

```
Audio
-- 🔇 Mute | shell="/usr/bin/osascript" param1="-e" param2='set volume with output muted' terminal=false
-- 🔊 Unmute | shell="/usr/bin/osascript" param1="-e" param2='set volume without output muted' terminal=false
```

## Splitting out a separate status item

Apple.5m.sh combines four sections into one bar item. If you want one section
on its own refresh cadence (e.g. Sal hourly, Renoise BPM every second), drop
a new file into `plugins/` with the pattern `<Name>.<interval>.sh`:

- `5s` / `30s` / `5m` / `1h` / `1d` — how often SwiftBar re-runs the script
- the script's stdout becomes the menu structure: first chunk = bar label,
  lines after `---` = dropdown items

Example: a Renoise BPM display refreshing every second:

```bash
# plugins/RenoiseBPM.1s.sh
#!/bin/bash
BPM=$(curl -s localhost:19714/bpm)
echo "♫ ${BPM}"
echo "---"
echo "Renoise BPM: ${BPM}"
```

`chmod +x` it. Done.

## Files

```
topbar/
├── plugins/                # SwiftBar reads this folder ONLY
│   └── Apple.5m.sh         # the one unified bar item
├── scripts/                # multi-line helper scripts (called by Toolbox)
│   ├── hide-desktop.sh
│   ├── show-desktop.sh
│   ├── show-hidden.sh
│   └── hide-hidden.sh
├── install.sh              # installer / re-runner
└── README.md               # this file
```

The filename suffix `.5m` tells SwiftBar to refresh every 5 minutes. Other
intervals: `5s`, `30s`, `1h`, `1d`. Pick the cadence of the freshest data
you're surfacing in that plugin.

`install.sh` and `README.md` live OUTSIDE `plugins/` deliberately — SwiftBar
loads every file in its plugin folder, so these would otherwise try to run
as plugins.

## Why SwiftBar (not Shortcuts pinned to menu bar)

- One icon with a dropdown vs. one icon per Shortcut (top bar gets crowded fast)
- Submenus → grouping (Audio, Finder, …)
- Click → script runs immediately. No Shortcuts engine warm-up (~0.5s/click).
- Plugin = a plain shell script you can edit in any editor. No Shortcuts.app UI.
- Folder-mirrored, so this is version-controlled in the apple repo.
- Refresh-driven status items: the bar becomes a live heads-up display.

## Pattern: the third channel

This is the third zero-roundtrip channel alongside slash commands and
Loupedeck buttons:

| Channel | Strength | Best for |
|---|---|---|
| Slash (`/qr`) | keyboard, instant, scriptable | text input, batch jobs |
| Loupedeck button | physical, hands-free | DAW workflow, single verbs |
| SwiftBar menu | mouse, glanceable, *live* | quick actions + status display |

Anything you currently run via slash or Loupedeck has a 1-line SwiftBar
plugin equivalent. Pick the channel that fits the moment.
