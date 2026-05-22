#!/bin/bash
# Build + deploy AppleToolbox — Apple-native, no third-party deps.
#
# This is THE rebuild command. Single shot:
#   1. Compile AppleToolbox.swift to a fresh .app bundle
#   2. Sync to /Applications/Apple-Workflows/ (the installed/running location)
#   3. Restart the menu-bar process so the new binary is what you see
#   4. (The --live floating panel auto-rebuilds via its own mtime watcher,
#       triggered by the source edit you just made — no extra step needed.)
#
# Safe to re-run. Idempotent. No "did you also run install.sh" footgun.
# First-time setup (LaunchAgent registration) lives in install.sh, which
# calls this script.

set -e

cd "$(dirname "$0")"
APP="AppleToolbox.app"
NAME="AppleToolbox"
INSTALL_DIR="/Applications/Apple-Workflows"
INSTALL_APP="$INSTALL_DIR/$APP"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O AppleToolbox.swift -o "$APP/Contents/MacOS/$NAME" \
    -framework Cocoa \
    -framework Speech \
    -framework AVFoundation \
    -framework Carbon \
    -framework EventKit \
    -framework Contacts \
    -framework Photos

echo "==> Generating icon if missing..."
if [ ! -f "AppleToolbox.icns" ]; then
    bash scripts/make-icon.sh
fi
cp AppleToolbox.icns "$APP/Contents/Resources/AppleToolbox.icns"

# Bundled icon assets used by the file-browser row glyphs (Copilot SVG,
# any future per-provider art). Loaded at runtime from Bundle.main.
if [ -d "icons" ]; then
    cp -R icons "$APP/Contents/Resources/icons"
fi

echo "==> Writing Info.plist (LSUIElement=true, bundle id, usage strings)..."
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundleDisplayName</key><string>Apple Toolbox</string>
    <key>CFBundleIdentifier</key><string>com.esaruoho.appletoolbox</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundleIconFile</key><string>AppleToolbox</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSUIElement</key><true/>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
    <key>NSHumanReadableCopyright</key><string>Apple skill — esaruoho/apple</string>
    <key>NSMicrophoneUsageDescription</key><string>AppleToolbox uses the microphone for smart dictation — partial transcripts appear live in the chat composer so you can edit while you speak.</string>
    <key>NSSpeechRecognitionUsageDescription</key><string>AppleToolbox uses on-device speech recognition for smart dictation; nothing leaves your Mac.</string>
    <key>NSCameraUsageDescription</key><string>AppleToolbox uses the camera for the /photo webcam snap action.</string>
    <key>NSAppleEventsUsageDescription</key><string>AppleToolbox sends Apple Events to Finder, Mail, Music, Safari, System Events and other apps to drive the Sal-style automations in the menu.</string>
    <key>NSSystemAdministrationUsageDescription</key><string>AppleToolbox runs system-administration tasks for window-snap, Dock, Wi-Fi, screenshot and Audio MIDI workflows.</string>
    <key>NSCalendarsUsageDescription</key><string>AppleToolbox reads Calendar events for the /grand-search and Hey-Sal cross-vault index.</string>
    <key>NSRemindersUsageDescription</key><string>AppleToolbox reads Reminders for the /grand-search and Hey-Sal cross-vault index.</string>
    <key>NSContactsUsageDescription</key><string>AppleToolbox reads Contacts for the /grand-search and Hey-Sal cross-vault index.</string>
    <key>NSPhotoLibraryUsageDescription</key><string>AppleToolbox reads Photos for the /grand-search photos-by-date subcommand.</string>
    <key>NSDesktopFolderUsageDescription</key><string>AppleToolbox writes screenshots and exports into the Desktop folder when you trigger Screenshot actions.</string>
    <key>NSDocumentsFolderUsageDescription</key><string>AppleToolbox reads and writes Documents for the bulk-exporter vaults under exported/.</string>
    <key>NSDownloadsFolderUsageDescription</key><string>AppleToolbox reads Downloads for the screenshot inversion and Grand Search workflows.</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key><string>Any file</string>
            <key>CFBundleTypeRole</key><string>Viewer</string>
            <key>LSHandlerRank</key><string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
                <string>public.item</string>
                <string>public.folder</string>
            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Prefer a stable signing identity over ad-hoc so TCC permissions (FDA, Apple
# Events, etc.) survive rebuilds. TCC keys ad-hoc binaries by cdhash — which
# changes on every build — but keys signed binaries by designated requirement
# (TeamID + bundle ID), which stays stable.
SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null \
    | awk '/Apple Development:|Developer ID Application:|AppleToolbox Local Signing/ {print $2; exit}')
if [ -n "$SIGN_ID" ]; then
    echo "==> Codesigning with stable identity: $SIGN_ID"
    codesign --force --sign "$SIGN_ID" "$APP" 2>&1 | sed 's/^/    /'
else
    echo "==> Ad-hoc codesign (no stable identity found — FDA will be lost on every rebuild)"
    codesign --force --sign - "$APP" 2>&1 | sed 's/^/    /'
fi

echo "==> Built: $(pwd)/$APP"
echo "    Binary: $(du -h "$APP/Contents/MacOS/$NAME" | cut -f1)"

# Helper scripts must be executable for the icon-strip launchers to work.
chmod +x scripts/*.sh 2>/dev/null || true

# ─── Sync to installed location + restart menu-bar ─────────────────────────
# The menu-bar process runs from /Applications/Apple-Workflows/AppleToolbox.app
# (installed by install.sh, kept alive by the LaunchAgent). Without this step
# the source change is built but invisible — that was the historical footgun.
# Skip silently if the install location doesn't exist yet (first-time setup
# is install.sh's job).
if [ -d "$INSTALL_DIR" ]; then
    echo "==> Syncing to $INSTALL_APP..."
    # Quit any running instance (menu-bar AND --live) so file replacement
    # doesn't race against the running binary. AppleScript quit is graceful;
    # pkill is the fallback for the --live process that may not respond to
    # the Quit Apple Event.
    osascript -e 'tell application "AppleToolbox" to quit' 2>/dev/null || true
    pkill -x AppleToolbox 2>/dev/null || true
    # Brief settle so file handles release before rm.
    sleep 0.4

    rm -rf "$INSTALL_APP"
    cp -R "$APP" "$INSTALL_APP"

    echo "==> Relaunching menu-bar..."
    /usr/bin/open "$INSTALL_APP"
    echo "    🧰 menu-bar is up with the new binary."

    # The --live process, if it was running, will be restarted by whoever
    # wants it (it's an opt-in cockpit, not always-on). Tell the user.
    if pgrep -lf "AppleToolbox --live" >/dev/null 2>&1; then
        echo "    Note: --live was running — relaunch with: open -a AppleToolbox --args --live"
    fi
else
    echo "==> Install dir $INSTALL_DIR missing — run install.sh once for first-time setup."
fi
