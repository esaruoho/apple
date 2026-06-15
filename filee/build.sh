#!/bin/bash
# Build Filee.app — the files-as-boxes folder viewer (bottom rung of the convey ladder).
# "Filee" (Finnish): a fish fillet AND "lots of files". Apple-native: SwiftUI + AppKit,
# compiled with xcrun swiftc, no Xcode, no Homebrew. Safe to re-run.
#
# Boot into a folder:    ./Filee.app/Contents/MacOS/Filee <folder>   (or: filee <folder>)
# Default (cwd):         ./Filee.app/Contents/MacOS/Filee
#
# NOTE: launch the bare binary (the `filee` shim does this), not `open` — and verify a
# window with CGWindowListCopyWindowInfo, never System Events `count windows`.

set -e
cd "$(dirname "$0")"
APP="Filee.app"
NAME="Filee"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift (SwiftUI + AppKit)..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O -parse-as-library Filee.swift -o "$APP/Contents/MacOS/$NAME" \
    -framework SwiftUI \
    -framework AppKit

echo "==> Writing Info.plist..."
cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${NAME}</string>
    <key>CFBundleDisplayName</key><string>Filee</string>
    <key>CFBundleIdentifier</key><string>com.esaruoho.filee</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.2</string>
    <key>CFBundleVersion</key><string>2</string>
    <key>LSMinimumSystemVersion</key><string>13.0</string>
    <key>NSHighResolutionCapable</key><true/>
    <key>NSHumanReadableCopyright</key><string>Apple skill — esaruoho/apple · convey ladder, rung one</string>
</dict>
</plist>
PLIST
plutil -lint "$APP/Contents/Info.plist" >/dev/null

# Stable signing identity if available (keeps any future TCC grants across rebuilds).
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
echo "Boot into a folder:"
echo "    $(pwd)/Filee.app/Contents/MacOS/Filee /Users/esaruoho/work/convey"
