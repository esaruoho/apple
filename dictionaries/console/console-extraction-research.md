# Console — Extraction Research

> 2026-05-08. Generated from live probe on Esa's Mac (macOS 15.6.1).

## TL;DR

Console.app is **Tier 5 dark** — no AppleScript dictionary, no App Intents, no URL scheme. The back-door is the **`log` CLI** that ships with macOS, which is strictly more powerful than the GUI: predicate filtering, time windows, signposts, streaming, and offline `.logarchive` analysis.

## Surfaces

| Surface | Available | Tool |
|---------|-----------|------|
| AppleScript sdef | ❌ error -192 | — |
| App Intents | ❌ | — |
| URL scheme | ❌ | — |
| Unified log query | ✅ | `log show` (predicate filtering) |
| Live log stream | ✅ | `log stream` |
| Diagnostic reports (crashes / panics / spindumps) | ✅ | `~/Library/Logs/DiagnosticReports/` + `/Library/Logs/DiagnosticReports/` |
| User app logs | ✅ | `~/Library/Logs/<App>/...` per-app dirs |
| Offline log archive | ✅ | `sudo log collect --output X.logarchive` |
| Console.app saved searches | partial | inside Console's prefs plist (sandboxed) |

## `log show` predicate language

Apple's NSPredicate syntax. Common keys:

- `process == "Safari"` — process name
- `subsystem == "com.apple.bluetooth"` — log subsystem
- `category == "BluetoothManager"` — sub-category within a subsystem
- `messageType >= 16` — errors + faults (level 16 = error, 17 = fault)
- `eventMessage CONTAINS[c] "panic"` — case-insensitive substring
- AND / OR / NOT compose

## Diagnostic reports anatomy

Two locations:

- `~/Library/Logs/DiagnosticReports/` — user-facing crashes the user can read
- `/Library/Logs/DiagnosticReports/` — kernel panics, system-level crashes, requires admin to read fully

Filename suffixes encode the kind:
- `.crash` / `.ips` — application crash
- `.panic` — kernel panic
- `.diag` — diagnostic snapshot (SFA-*, proactive_event_tracker-*, etc.)
- `.spin` — spindump
- `.hang` — UI hang report

Apple's modern format is `.ips` (JSON-wrapped binary plist). The older `.crash` is plain text.

## Live numbers on this Mac

```
~/Library/Logs/DiagnosticReports        30 entries
/Library/Logs/DiagnosticReports         136 entries
log volume (last 5 min)                 ~193,000 lines
```

## Implementation in `console-exporter`

- `status` — counts both diag dirs + sample log volume
- `show` — wraps `log show` with --last / --start / --end + predicate flags
- `subsystems` — counts distinct subsystem:category pairs to help discover what's emitting
- `diag-list` / `diag-export` — walks both diag dirs; symlink default
- `export` — writes a timestamped markdown query page to `exported/console/queries/<stamp>__<label>.md` with the matched lines in a fenced block (great for filing bug reports)

## Phase 2 candidates

- `watch` — wrap `log stream` with the same predicate flags + a notification hook
- `collect` — `sudo log collect --output X.logarchive` for offline cross-day analysis
- `parse-ips` — decode modern `.ips` files into a readable summary
