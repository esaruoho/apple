#!/bin/bash
# Build Overlay.app — the spatial overlay canvas (P0).
# Apple-native: AppKit + Carbon (hotkey) + SwiftUI (shared Help only), compiled with
# xcrun swiftc. No Xcode project, no Homebrew, no pip. Safe to re-run.
#
# The headless core tests run FIRST and the app is not built if any fail
# (feedback_test_renderers_headlessly).

set -e
cd "$(dirname "$0")"
APP="Overlay.app"
NAME="Overlay"

echo "==> Running headless core tests..."
TESTBIN="$(mktemp -d)/overlay-tests"
xcrun swiftc -O OverlayCore.swift overlay-tests.swift -o "$TESTBIN"
if ! "$TESTBIN"; then
    echo ""
    echo "!! Core tests failed — refusing to build Overlay.app."
    exit 1
fi

echo ""
echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O -parse-as-library \
    OverlayCore.swift Overlay.swift OverlayInbox.swift OverlaySelfTest.swift ../shared/SupportHelp.swift \
    -o "$APP/Contents/MacOS/$NAME" \
    -framework Cocoa \
    -framework SwiftUI \
    -framework Carbon

echo "==> Writing Info.plist..."
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundleDisplayName</key><string>Overlay</string>
    <key>CFBundleIdentifier</key><string>com.esaruoho.overlay</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Apple skill — esaruoho/apple</string>
    <!-- Menu-bar only: an overlay must not hold a Dock tile or a Cmd-Tab slot. -->
    <key>LSUIElement</key><true/>
</dict>
</plist>
PLIST

echo "==> Ad-hoc signing..."
codesign --force --deep --sign - "$APP" 2>/dev/null || \
    echo "   (codesign skipped — unsigned build still runs locally)"

# Launch Services caches Info.plist; without this the old bundle's metadata sticks
# around (feedback_lsregister_after_app_bundle_changes).
echo "==> Refreshing Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$PWD/$APP" 2>/dev/null || true

echo ""
echo "Built $PWD/$APP"
echo "Run it:   open $PWD/$APP        (or: bin/overlay open)"
echo "Draw:     ⌃⌥⌘D toggles draw mode, esc leaves it"
