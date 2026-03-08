# HomePod Climate Sensor

Read temperature and humidity from a HomePod via macOS Shortcuts CLI, log to JSONL, and view in a live dashboard.

## How It Works

```
HomePod sensor → Shortcuts app → shortcuts run CLI → bash script → JSONL log → live graph
```

1. A Shortcut called **"HomePod Sensors"** reads the HomePod's built-in temperature/humidity sensor
2. `homepod-climate.sh` calls it via `shortcuts run "HomePod Sensors"`, parses the output, applies calibration offsets, and logs a JSON entry
3. `climate-server.py` serves a live dashboard with day-by-day graphs
4. A LaunchAgent can run it automatically every 10 minutes

## Prerequisites

Create a Shortcut in Shortcuts.app called **"HomePod Sensors"** that:
1. Gets the current temperature from your HomePod (Home app action)
2. Gets the current humidity from your HomePod (Home app action)
3. Outputs them as text (e.g. `16, 23,2°C`)

## Usage

```bash
# Single reading — logs + updates status + opens graph
./homepod-climate.sh

# Print JSON to stdout only (no logging)
./homepod-climate.sh --stdout

# Show all of today's readings
./homepod-climate.sh --dump

# Log without opening browser
./homepod-climate.sh --nograph

# Daily summary (today or specific date)
./climate-summary.sh
./climate-summary.sh 2026-02-07

# Start continuous logger + dashboard server
./start.sh
```

## Calibration

Measured Feb 13, 2026 against a professional indoor climate sensor (olosuhdemittaus = conditions measurement, Finnish):
- Temperature: HomePod reads **0.45°C low** — script adds +0.45°C
- Humidity: HomePod reads **4.5% low** — script adds +4.5%

## Auto-run with LaunchAgent

```bash
# Install (reads every 10 minutes)
cp com.esa.homepod-climate.plist ~/Library/LaunchAgents/
launchctl load ~/Library/LaunchAgents/com.esa.homepod-climate.plist

# Check status
launchctl list | grep homepod

# Uninstall
launchctl unload ~/Library/LaunchAgents/com.esa.homepod-climate.plist
```

## Files

| File | Purpose |
|------|---------|
| `homepod-climate.sh` | Main script: read sensor, log, update status |
| `climate-summary.sh` | Daily summary with min/max/avg |
| `climate-server.py` | Local dashboard server (port 3007) |
| `climate-graph.html` | Live graph UI |
| `com.esa.homepod-climate.plist` | LaunchAgent for automatic readings |
| `start.sh` | Combined server + logger launcher |

## Why This Matters

This is a real example of the Apple automation pipeline:
- **Shortcuts** bridges to HomeKit sensors (no API needed)
- **`shortcuts run`** CLI makes it scriptable from bash
- **LaunchAgent** makes it a background service
- **JSONL + Python** turns readings into a dashboard

The HomePod's sensor is hidden — Apple doesn't expose it in any app. Shortcuts is the only way to access it programmatically.
