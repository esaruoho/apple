---
description: apple-energy — the Activity Monitor "Energy" tab (and more) from the CLI; per-process "what it is" annotator, Claude Code session identifier, and iTerm2 Cmd-clickable jump-to-tab.
---

# apple-energy

`bin/apple-energy` reads macOS energy/power from the command line — the data behind
Activity Monitor's **Energy** tab, which is just a front-end over Apple-shipped tools
(`powermetrics`, `top`, `system_profiler`, `pmset`, `lsof`). No Homebrew, no pip: two
files, `bin/apple-energy` (bash) + `bin/_apple_energy.py` (stdlib helper).

Also published as the standalone public repo **[esaruoho/apple-energy](https://github.com/esaruoho/apple-energy)**
(`~/work/apple-energy`) — keep both copies in sync; see memory `apple_energy_standalone.md`.

## Verbs

| Verb | What it does |
|---|---|
| `now [N]` | No-sudo snapshot: top N processes by energy impact, as a box table (PID · Process · **What it is** · Power). Daemons are explained (`fileproviderd` → "File Provider", `trustd` → "certificate trust", …); claude rows show version/session/age/project/tty. |
| `watch [mins] [secs]` | Sample `powermetrics` over a window and rank per-process energy (sudo). Fills the gap: macOS keeps **no** queryable historical per-app energy store. |
| `power [N]` | System CPU/GPU/package watts (sudo). Watts drawn == heat produced. |
| `heat [N]` | Heat = watts: package power + thermal pressure + throttle + fans (sudo where available). |
| `adapter` | Adapter wattage + battery state (no sudo). Superset of `system_profiler SPPowerDataType \| grep Wattage`. |
| `claude` | Every running **Claude Code** session: version, OLD-vs-current, readable age, %CPU, TERM, TTY, project, **session name**. |
| `jump <pid\|tty\|version\|project\|name>` | Focus that Claude session's terminal window/tab via the terminal's own AppleScript verbs. |
| `install-jump` | Register the `aejump://` scheme so `claude`/`now` TTYs are Cmd-clickable (**iTerm2 only** — see below). |
| `kill <name\|pid>` | SIGTERM a hog now (a launchd-kept process respawns). |
| `off <name> [--yes]` | Stop + `launchctl disable` so it stays dead (dry-run by default). |

## Claude Code session identifier

Claude Code installs each version as a binary named after its version
(`~/.local/share/claude/versions/2.1.197`), so `top` shows "2.1.193" as a process name.
`claude` resolves each running instance's real version (via `lsof` txt), age, %CPU,
terminal, tty, project (cwd), and **session name**. The name comes from the transcript
(`customTitle` → `summary` → first user-message snippet, same rule as `bin/sessions`);
PID→session is paired by matching the process start time to the session's first-message
timestamp (a `~` prefix marks an inferred/resumed match).

## Clickable TTYs — iTerm2 only

`claude`/`now` wrap each session's TTY in an **OSC 8 terminal hyperlink** to
`aejump://<pid>`. `install-jump` builds `~/Applications/AppleEnergyJump.app` — an
AppleScript `on open location` handler that sends the focus AppleEvent to
iTerm2/Terminal **directly** (so macOS attributes it and shows the one-time Automation
prompt; burying it in shell→osascript caused a silent `-1743` deny). Stable
`CFBundleIdentifier` + ad-hoc codesign + `tccutil reset AppleEvents` keep the grant clean.

- **iTerm2**: Cmd-click a TTY → that tab comes forward (allow the one-time prompt on the
  first click).
- **Terminal.app**: does **not** support OSC 8 hyperlinks, so Cmd-click can't fire there —
  use `apple-energy jump <pid|name>` instead. Footers state this per `TERM_PROGRAM`.

## DRY

`now`, `claude`, and `jump` share one helper (`bin/_apple_energy.py`): `render_table`
(box-drawing, escape/width-aware), `describe`/`claude_row`/`session_map`,
`terminal_of`, `hyperlink`, and `action_footer`. Report card:
[`features/apple-energy.feature`](../../features/apple-energy.feature).
