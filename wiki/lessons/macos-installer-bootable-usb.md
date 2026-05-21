# macOS Installer Download & Bootable USB

Procedure for downloading a full macOS installer (Tahoe / Sequoia / Sonoma) and writing it to a bootable USB **without ever risking the host Mac upgrading itself**.

### Why this is safe
`softwareupdate --fetch-full-installer` writes `Install macOS <Name>.app` to `/Applications/` and stops. macOS does **not** auto-launch installers. Only three actions actually upgrade the host: double-clicking the .app, clicking "Upgrade Now" in System Settings → Software Update, or clicking Install on a banner. The procedure below avoids all three and removes the .app once the USB is written.

### Discovery
```bash
softwareupdate --list-full-installers
```
Lists every installer Apple is currently serving (Title / Version / Size / Build). Pick the version string for `--full-installer-version`.

### Step 1 — Lock down auto-update (defensive, run once)
```bash
sudo softwareupdate --schedule off
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticallyInstallMacOSUpdates -bool false
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdateRestartRequired -bool false
```
Belt-and-suspenders: System Settings → General → Software Update → Automatic Updates → ⓘ → toggle all five switches off.

### Step 2 — Download in a new Terminal window with live progress
```bash
osascript -e 'tell application "Terminal" to activate' \
         -e 'tell application "Terminal" to do script "sudo softwareupdate --fetch-full-installer --full-installer-version 26.4.1"'
```
The new window prompts for sudo password, then shows `PercentComplete=NN` updates. ~10–60 minutes depending on connection. Pattern: spawning the long task in Terminal.app via `osascript` so the user can watch — same idiom as `bin/ask` and the dictation flow.

### Step 3 — Verify host did not upgrade
```bash
ls -la "/Applications/Install macOS Tahoe.app"
sw_vers   # must still show YOUR version, not the new one
```

### Step 4 — Erase the USB
USB needs ≥16 GB. Identify it with `diskutil list external` — confirm size and name before erasing. Then:
```bash
diskutil eraseDisk JHFS+ Tahoe GPT /dev/diskN
```
- Format **must** be JHFS+ (Mac OS Extended Journaled), **not** APFS — `createinstallmedia` rejects APFS.
- Scheme **must** be GPT (GUID Partition Map), **not** MBR — required for boot.

### Step 5 — Write installer to USB (new window, watchable)
```bash
osascript -e 'tell application "Terminal" to activate' \
         -e 'tell application "Terminal" to do script "sudo /Applications/Install\\ macOS\\ Tahoe.app/Contents/Resources/createinstallmedia --volume /Volumes/Tahoe --nointeraction"'
```
20–45 minutes. Volume auto-renames from `Tahoe` to `Install macOS Tahoe`.

### Step 6 — Eject and reclaim disk space
```bash
diskutil eject "/Volumes/Install macOS Tahoe"
sudo rm -rf "/Applications/Install macOS Tahoe.app"
```
After this, the only installer on the host lives on the USB. Software Update may still *show* the version as available (it's a current release) but nothing installs without a click.

### Booting the USB on the target Mac
- **Apple Silicon:** Shut down → hold Power until "Loading startup options" appears → pick the USB → Continue.
- **Intel:** Shut down → power on while holding **⌥ Option** → pick the USB.

### Stopping a download mid-fetch
The foreground `softwareupdate --fetch-full-installer` process responds to Ctrl-C in its Terminal window. Background `softwareupdated` daemons (CoreServices + MobileSoftwareUpdate) are normal system helpers, not the user's fetch — leave them alone. After abort, check `ls /Applications/Install\ macOS*.app` — if absent, no partial state to clean up.

### Sal-like principle
Six-phase manual procedure (lockdown → fetch → verify → erase → write → cleanup) collapsed into a runbook. Each step is a single command or a single GUI toggle; nothing in between. The pattern: **identify the dangerous default (auto-upgrade), neutralize it explicitly, then run the safe verb (`fetch-full-installer`), then verify**. Same shape as `spotlight-export.sh` (compile → inject CFBundleIdentifier → codesign → done) — declare intent, neutralize the gotcha, ship.

