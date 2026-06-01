#!/bin/bash
# Build Fleet.app — the side-by-side Machine Card window app.
# Apple-native: SwiftUI + AppKit + Network, compiled with xcrun swiftc, no Xcode.
# Safe to re-run.

set -e
cd "$(dirname "$0")"
APP="Fleet.app"
NAME="Fleet"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift (SwiftUI + Network)..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O -parse-as-library Fleet.swift -o "$APP/Contents/MacOS/$NAME" \
    -framework SwiftUI \
    -framework AppKit \
    -framework Network

echo "==> Writing Info.plist (Local Network + Bonjour service)..."
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundleDisplayName</key><string>Fleet</string>
    <key>CFBundleIdentifier</key><string>com.esaruoho.fleet</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Apple skill — esaruoho/apple</string>
    <key>NSLocalNetworkUsageDescription</key><string>Fleet discovers other Macs on your local network that are running Fleet, so it can show their Machine Cards side-by-side with this one.</string>
    <key>NSBonjourServices</key>
    <array>
        <string>_machinecard._tcp</string>
    </array>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Stable signing identity if available (keeps Local Network grant across
# rebuilds — TCC keys ad-hoc binaries by cdhash, which changes every build).
SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null \
    | awk '/Apple Development:|Developer ID Application:|AppleToolbox Local Signing/ {print $2; exit}')
if [ -n "$SIGN_ID" ]; then
    echo "==> Codesigning with stable identity: $SIGN_ID"
    codesign --force --sign "$SIGN_ID" "$APP" 2>&1 | sed 's/^/    /'
else
    echo "==> Ad-hoc codesign (Local Network prompt will reappear on each rebuild)"
    codesign --force --sign - "$APP" 2>&1 | sed 's/^/    /'
fi

echo "==> Built: $(pwd)/$APP"
echo "    Binary: $(du -h "$APP/Contents/MacOS/$NAME" | cut -f1)"
echo
echo "Run it:  open $(pwd)/$APP"
echo "(First launch prompts for Local Network access — allow it so peers appear.)"
