# Compatibility Notes

## Tested Environment

- **macOS**: Sequoia 15.x
- **Architecture**: Apple Silicon (M3)
- **Shell**: bash / zsh

All 288 workflows in this repo were developed and tested on this configuration.

## macOS Version Requirements

| Feature | Minimum macOS | Notes |
|---------|:------------:|-------|
| AppleScript workflows | Any | Core AppleScript has been stable for decades |
| `shortcuts` CLI | Ventura 13.0+ | The `shortcuts run` command was introduced in macOS Monterey 12.0, but the CLI stabilized in Ventura |
| `shortcuts sign` | Ventura 13.0+ | Required for distributing `.shortcut` files |
| Shortcut Siri phrases | Ventura 13.0+ | Siri integration with custom Shortcuts |
| `osacompile` apps | Any | Compiling AppleScript to `.app` bundles |
| TCC shared bundle ID trick | Sequoia 15.0+ | Earlier macOS versions may handle TCC consent differently |
| Spotlight for `.app` bundles | Any | Requires `CFBundleIdentifier` in `Info.plist` |

## Apple Silicon vs Intel

### Universal Scripts (work on both architectures)

The vast majority of scripts in this repo are **universal** and work identically on Intel and Apple Silicon:

- All AppleScript workflows (`scripts/workflows/`) -- these use the AppleScript runtime which is architecture-independent
- All Shortcuts CLI commands (`shortcuts run`, `shortcuts list`, `shortcuts sign`)
- All `osascript` invocations
- All `do shell script` calls to standard Unix tools (`sed`, `awk`, `grep`, `curl`, etc.)
- Finder, Mail, Music, Safari, Calendar, Reminders, Notes, Photos, Messages, TextEdit, Terminal, QuickTime, Contacts, System Events scripts
- HomePod climate scripts (use Shortcuts bridge)
- Spotlight export pipeline (`bin/spotlight-export.sh`)
- Workflow generator (`bin/workflow-gen.py`)
- Shortcut generator (`bin/shortcut-gen.py`)

### Platform-Specific: IOKit Hardware Queries

The `scripts/workflows/hardware/` directory and `bin/app-probe.py` contain IOKit queries that reference architecture-specific classes:

#### Apple Silicon (ARM) IOKit Classes
- `AppleARMBacklight` -- display backlight control
- `AppleCLPC` -- Cluster Power Controller (performance/efficiency cores)
- `AppleARMIODevice` -- ARM I/O device tree
- `AppleT8103` / `AppleT6000` etc. -- SoC-specific drivers

#### Intel IOKit Classes
- `AppleACPIPlatformExpert` -- ACPI platform driver
- `AppleIntelFramebuffer` -- Intel integrated graphics
- `AppleIntelCPUPowerManagement` -- Intel CPU power states
- `AppleSMC` -- System Management Controller (present on both, but different keys)
- `AppleHDA` -- Intel High Definition Audio
- `AppleThunderboltNHI` -- Thunderbolt host interface

#### What This Means in Practice

If you run `ioreg` queries from a script that references ARM-specific classes on an Intel Mac (or vice versa), the query will return empty results rather than error. The scripts won't crash, but they won't find the expected hardware.

### SIP (System Integrity Protection) Differences

- **Intel**: Historically allowed more third-party kernel extensions (kexts). SIP can be partially disabled to load unsigned kexts.
- **Apple Silicon**: Full Security mode is the default. Reduced Security requires booting into recoveryOS. Kernel extensions are being replaced by System Extensions and DriverKit.
- **Impact on this repo**: None. These scripts don't use kernel extensions. All automation goes through AppleScript, Shortcuts, and standard shell commands.

### Rosetta 2 Note

On Apple Silicon, if any tool used by these scripts were Intel-only, Rosetta 2 would handle translation transparently. In practice, all tools used (`osascript`, `shortcuts`, `osacompile`, `codesign`, `mdfind`, `mdutil`, `PlistBuddy`) are universal binaries on macOS Ventura and later.

## Community Testing

This repo has only been tested on Apple Silicon (M3). If you run these scripts on Intel hardware, please report your results:

1. **Open an issue** at [github.com/esaruoho/apple](https://github.com/esaruoho/apple) with:
   - Your Mac model and chip (e.g., MacBook Pro 2019, Intel i9)
   - macOS version
   - Which scripts worked / failed
   - Any error messages

2. **Known areas to test on Intel**:
   - `bin/app-probe.py` IOKit layer results
   - `system-events-battery-status.applescript` (power management queries)
   - `bin/spotlight-export.sh` code signing behavior
   - Any script using `do shell script` with hardware-specific paths

## Summary

| Category | Intel | Apple Silicon |
|----------|:-----:|:------------:|
| AppleScript workflows | Yes | Yes |
| Shortcuts CLI | Yes (Ventura+) | Yes (Ventura+) |
| Spotlight export | Yes | Yes |
| Shortcut generator | Yes | Yes |
| IOKit hardware queries | Different classes | Different classes |
| TCC shared bundle ID | Untested | Yes |
| Siri phrases | Yes (Ventura+) | Yes (Ventura+) |
