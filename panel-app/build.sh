#!/bin/bash
# Build ApplePanel.app — the Apple Panel as a native WKWebView window app.
# Apple-native: AppKit + WebKit, compiled with xcrun swiftc, no Xcode. Re-runnable.

set -e
cd "$(dirname "$0")"
APP="ApplePanel.app"
NAME="ApplePanel"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift (AppKit + WebKit)..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O PanelApp.swift -o "$APP/Contents/MacOS/$NAME" \
    -framework AppKit \
    -framework WebKit

echo "==> Writing Info.plist..."
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundleDisplayName</key><string>Apple Panel</string>
    <key>CFBundleIdentifier</key><string>com.esaruoho.applepanel</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Apple skill — esaruoho/apple</string>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Stable signing identity if available (keeps any TCC grants across rebuilds).
SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null \
    | awk '/Apple Development:|Developer ID Application:|AppleToolbox Local Signing/ {print $2; exit}')
if [ -n "$SIGN_ID" ]; then
    echo "==> Codesigning with stable identity: $SIGN_ID"
    codesign --force --sign "$SIGN_ID" "$APP" 2>&1 | sed 's/^/    /'
else
    echo "==> Ad-hoc codesign"
    codesign --force --sign - "$APP" 2>&1 | sed 's/^/    /'
fi

echo "==> Built: $(pwd)/$APP"
echo "    Binary: $(du -h "$APP/Contents/MacOS/$NAME" | cut -f1)"
echo
echo "Run it:  open $(pwd)/$APP"
