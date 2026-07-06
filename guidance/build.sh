#!/bin/bash
# Build Guidance.app — the live agent-board window.
# Apple-native: SwiftUI + AppKit, compiled with xcrun swiftc, no Xcode.
# Renders `bin/guidance --json`. Safe to re-run.

set -e
cd "$(dirname "$0")"
APP="Guidance.app"
NAME="Guidance"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift (SwiftUI + AppKit)..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O -parse-as-library Guidance.swift ../shared/SupportHelp.swift -o "$APP/Contents/MacOS/$NAME" \
    -framework SwiftUI \
    -framework AppKit

echo "==> Icon..."
if [ ! -f "Guidance.icns" ]; then bash scripts/make-icon.sh; fi
cp Guidance.icns "$APP/Contents/Resources/Guidance.icns"

echo "==> Writing Info.plist..."
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundleDisplayName</key><string>Guidance</string>
    <key>CFBundleIdentifier</key><string>com.esaruoho.guidance</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>CFBundleIconFile</key><string>Guidance</string>
    <key>NSHumanReadableCopyright</key><string>Apple skill — esaruoho/apple</string>
    <key>NSAppleEventsUsageDescription</key><string>Guidance uses AppleEvents only to bring a chosen iTerm2 session to the front. It never reads or automates your terminals.</string>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Stable signing identity if available (keeps the Automation grant across
# rebuilds — TCC keys ad-hoc binaries by cdhash, which changes every build).
SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null \
    | awk '/Apple Development:|Developer ID Application:|AppleToolbox Local Signing/ {print $2; exit}')
if [ -n "$SIGN_ID" ]; then
    echo "==> Codesigning with stable identity: $SIGN_ID"
    codesign --force --sign "$SIGN_ID" "$APP" 2>&1 | sed 's/^/    /'
else
    echo "==> Ad-hoc codesign (Automation prompt may reappear on each rebuild)"
    codesign --force --sign - "$APP" 2>&1 | sed 's/^/    /'
fi

echo "==> Built: $(pwd)/$APP"
echo "    Binary: $(du -h "$APP/Contents/MacOS/$NAME" | cut -f1)"
echo
echo "Run it:  open $(pwd)/$APP"
echo "(Reads = ps + local transcripts, no prompt. Fronting a terminal may show a one-time Automation prompt: Guidance → iTerm2.)"
