# console-exporter

Console.app catalog + filtered-query exporter. Console has no
AppleScript dictionary, no App Intents, no URL scheme. The back-door
is the **`log` CLI** that ships with macOS — strictly more powerful
than the GUI (streaming, predicate filtering, time windows,
signposts).

No third-party dependencies. Apple-native `log show` + filesystem.

## Install

```bash
cd ~/work/apple/console-exporter
cp .env.example .env
chmod +x scripts/console-exporter
```

Reading the unified log normally requires no special permissions.
Reading other users' diagnostic reports needs admin.

## Commands

### `status`

```bash
console-exporter status
```

Counts diagnostic reports + sample log volume.

### `show` — `log show` wrapper

```bash
console-exporter show --last 1h --error
console-exporter show --last 5m --process Safari
console-exporter show --last 1d --subsystem com.apple.bluetooth
console-exporter show --last 1h --match 'panic|crash|fault'
console-exporter show --last 6h --process VoiceMemos --error --limit 100
```

Available filter flags:
- `--last 5m / 1h / 6h / 1d` — time window
- `--start` / `--end` — explicit ISO datetimes
- `--process NAME` — limit to one process
- `--subsystem ID` — limit to one subsystem (e.g. `com.apple.bluetooth`)
- `--category NAME` — limit to one category
- `--error` — errors + faults only
- `--match REGEX` — regex post-filter on each line
- `--limit N` — cap output

Filters compose. Internally builds a `--predicate` string for `log
show` plus a Python regex post-filter for `--match`.

### `subsystems` — what's noisy right now

```bash
console-exporter subsystems
console-exporter subsystems --last 6h --top 50
```

Counts distinct `subsystem:category` pairs across the time window.
Use this to discover which subsystems are emitting and pick a
specific one for `show --subsystem`.

### `diag-list` — diagnostic reports

```bash
console-exporter diag-list
console-exporter diag-list --match 'Spotlight|kernel'
```

Walks `~/Library/Logs/DiagnosticReports/` and `/Library/Logs/DiagnosticReports/`,
sorted newest-first.

### `diag-export` — copy / symlink reports into vault

```bash
console-exporter diag-export --match Safari
console-exporter diag-export --copy            # default is symlink
```

Lands files at `$VAULT_PATH/diagnostic-reports/`.

### `export` — save a filtered query as a markdown page

```bash
console-exporter export --last 1h --error --label "errors-1h"
console-exporter export --last 1d --process Mail --match 'fail|error' \
                        --label "mail-failures-1d"
```

Writes to `$VAULT_PATH/queries/<timestamp>__<label>.md` with full
frontmatter (predicate, match regex, line count) plus the matched
log lines in a fenced block. Each export is a permanent timestamped
record — useful for filing bug reports or tracking down regressions.

## Vault layout

```
~/work/apple/exported/console/
├── diagnostic-reports/        symlinks/copies of crash reports
└── queries/
    └── 2026-05-08__091234__errors-1h.md
```

## What's not here

- **Live `log stream`** — interactive streaming (`console-exporter
  watch`) coming when needed; the current scope is point-in-time
  catalog + saved queries.
- **`log collect`** for diagnostic archive bundles. The CLI exists
  natively (`sudo log collect --output /path/to.logarchive`) and is
  the right tool for cross-day / cross-boot exports.
- **Console.app's user-saved searches** — those live in
  Console.app's prefs. Not part of this catalog tool.

## See also

`bin/app-plist-probe.py` — meta-tool that scans every Apple app's
plist user data. Console.app's own UI prefs (saved filters, etc.)
show up there.
