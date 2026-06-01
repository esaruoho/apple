# Apple Panel — the browser control surface

> *A "what can I do" page you open locally, where every capability is a card with a real button. Click it, the tool runs on this Mac, output renders inline.* Source: `bin/apple-panel`, slash `/apple-panel`.

This is the **fifth control channel** for the Apple skill, alongside the zero-roundtrip slash, the AppleToolbox menu bar, global keyboard shortcuts, and the Finder-tag / Stickies / Mail-flag triggers. Where those are launch surfaces, the panel is a *catalog* surface — it shows you what exists and runs it without you remembering a command name.

## Live system dashboard

The top of the page is a **live system monitor** that auto-refreshes every 4 s (toggle off with the *live* checkbox). It polls `GET /stats`, which runs `mac-stats --json --fast`, and renders gauges:

- **CPU** — load-per-core %, load average, core count
- **Memory** — % used, used/total, pressure (Normal / Warning / Critical)
- **Battery** — charge %, **temperature °C**, state, cycle count, health %
- **Thermal** — pressure (Nominal / Throttled) + CPU speed-limit %
- **Disk** — every mounted volume with a usage bar
- **Top CPU** — the 5 hungriest processes
- **Network** — interface, IP, Wi-Fi SSID, router

All of that is readable **without a password**, from Apple-shipped tools (`pmset`, `ioreg`, `vm_stat`, `sysctl`, `df`, `ps`, `route`, `ipconfig`, `networksetup`). The friendly model name ("MacBook Pro") comes from `system_profiler`, which is slow, so the page fetches it once via `/stats?full=1` and then polls the cheap `--fast` path (~0.6 s) thereafter.

### Live die temperature in °C — no sudo

The Thermal gauge shows the **actual hottest die temperature in °C**, refreshed every 4 s without a password. The source is `bin/mac-temps`, a compiled-Swift tool that reads the Apple Silicon HID thermal sensors via `IOHIDEventSystemClient` (HID page `0xff00` / usage `0x0005`, ~45 sensors on an M3 Pro; the SoC die ones are named `PMU tdie…`). Those symbols live in IOKit.framework but aren't in the public SDK, so they're resolved with `dlsym` — an Apple framework reached from compiled Swift, which is precisely the tier the skill reserves for a domain no AppleScript / ASObjC / Python stdlib can touch. The `.swift` is compiled once to `~/Library/Caches/apple-skill/mac-temps` (~22 s first time, then ~0.1 s); the panel pre-warms that cache in a background thread at startup so the first poll never stalls.

`pmset` thermal pressure ("Nominal") and CPU speed-limit % move to the gauge subtitle — they're *pressure*, not heat.

### Fans — the sudo boundary

Fan RPM (and powermetrics' own die-temp read) require root. Rather than run the server as root, the **Fans & die temps** button runs `mac-thermals`, which wraps `powermetrics` in `osascript … with administrator privileges` — the standard macOS password dialog, once. No Homebrew temp tools, no persistent root.

## Dynamic drill-in — the panel investigates

Every gauge is clickable. Clicking one opens a detail box that *studies that metric and explains it in plain English*, recomputed each tick:

- **Memory** → pressure verdict + swap used / compressed / wired + largest resident processes. When pressure is Warning/Critical the verdict names the bottleneck (e.g. "8.2 GB pushed to swap — RAM is the bottleneck").
- **CPU** → top processes by %CPU.
- **Battery** → health %, cycle count, temperature, voltage, design capacity.
- **Thermal** → the hottest named sensors + a hot/warm/cool verdict.

Gauges in a concern state (memory pressure ≠ Normal, die temp ≥ 95 °C, battery ≥ 42 °C, CPU ≥ 90%/core) get an amber border to pull the eye. This is the "it knows what to study" behaviour: the worry surfaces *with* its diagnosis, not as a bare label.

## Companion tools

| Tool | Role |
|---|---|
| `bin/mac-stats` | Fast, no-sudo JSON snapshot of the whole machine (CPU, memory + swap + top-RSS, battery, thermal °C, disk, network, top procs). `mac-stats` (human) / `mac-stats --json [--fast]`. The dashboard's data source. |
| `bin/mac-temps` | No-sudo die temperatures in °C via IOKit HID sensors (compiled Swift, cached). `mac-temps` / `mac-temps --json`. |
| `bin/mac-thermals` | Fan RPM + die temps via the GUI admin prompt (powermetrics). `mac-thermals` / `mac-thermals --json`. |

## Why a local server, not a file

A `file://` HTML page can't run shell commands — the browser sandbox forbids it. So buttons that *do* things need something on the other end. The Apple-native answer (no Homebrew, no pip) is python3 stdlib `http.server` bound to `127.0.0.1`. The page is served from that server; each button POSTs to `/run`; the server executes the tool and returns stdout/stderr/exit-code as JSON, which the page renders in the card. This is the *viewport, not launcher* principle — output comes back to you on the page, you're never thrown into a blank browser tab.

## Safety model

- **Bound to 127.0.0.1 only** — not reachable from the network.
- **Closed registry** — the server runs *only* the curated `ACTIONS` list in `bin/apple-panel`. There is no "run arbitrary command" endpoint.
- **No shell** — arguments from the page are passed as discrete `argv` elements (`subprocess.run([...])`, never `shell=True`), so there's no command-injection surface. Args are length-capped and newline-stripped.
- **Per-action 120 s timeout**, ANSI colour codes stripped server-side.
- Each card is tagged 🟢 read-only or 🟠 makes-a-change so you know before you click.

## Running it

```
apple-panel                 # start, open the panel in your browser
apple-panel --port 9000     # choose a port (auto-bumps if busy; default 8787)
apple-panel --no-open       # don't auto-open the browser
apple-panel --print         # print the URL + registry, don't serve
```

It serves until you press Ctrl-C or click **Stop server** on the page.

## Extending it — the whole point

The registry is a plain list of dicts at the top of `bin/apple-panel`. To add a capability, append one entry:

```python
{"id": "my_thing", "group": "This Mac", "kind": "safe",
 "label": "Human label", "desc": "What it does, in a sentence.",
 "cmd": ["{BIN}/my-tool", "--flag"], "arg": None},
```

- `{BIN}` → the `bin/` dir, `PYTHON` → the running interpreter, `{arg}` → the value typed in the card's input box (omit `arg`/use `None` for no input).
- `kind`: `"safe"` (read-only) or `"action"` (writes / side effects).

This is the apple-skill core principle again: a manual capability, organized into a registry row, becomes a button anyone can press — no token spent at click time.

## Current actions

| Group | Action | Kind | Runs |
|---|---|---|---|
| Disks & Drives | Diagnose drives that won't mount | 🟢 | `why-no-mount` → see [why-drive-wont-mount](why-drive-wont-mount.md) |
| Disks & Drives | List external volumes + mount state | 🟢 | `why-no-mount --list` |
| Disks & Drives | Diagnose a specific disk | 🟢 | `why-no-mount --probe-only <id>` |
| This Mac | Mac capability report | 🟢 | `apple-report` |
| This Mac | Fans & die temps (asks for password) | 🟠 | `mac-thermals` (powermetrics via admin prompt) |
| This Mac | List Dock items | 🟢 | `dock list` → see [dock-management](dock-management.md) |
| Windows | Tile windows into a grid | 🟠 | `snap` |
| Search your data | Search everything you've exported | 🟢 | `apple-grand-search <term>` |
| Maintenance | Rebuild the wiki index | 🟠 | `wiki-index.py` |
| Maintenance | Lint the wiki | 🟢 | `wiki-lint.py` |
| Maintenance | Rebuild all skill indexes | 🟠 | `gen-skill-indexes.py` |

## Discoverability triggers

When the user says any of:
- "what can I do" / "show me what's possible" / "control panel" / "dashboard of tools"
- "a page with buttons" / "automated buttons" / "local web page that runs things"

→ this is the entry point. `apple-panel` then `/apple-panel`.
