#!/usr/bin/env bash
# build.sh — compile AppleBar.app (the toolbox command bar). Apple-native, no deps.
# Runs on any Mac (NLEmbedding routing happens in apple-intent). LSUIElement agent:
# menu-bar icon + global ⌥Space hotkey, no Dock icon.
#
#   ./build.sh            build into ./build and launch
#   ./build.sh --install  also copy to /Applications
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="AppleBar"
BUILD="$HERE/build"
BUNDLE="$BUILD/$APP.app"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS" "$BUNDLE/Contents/Resources"

cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP</string>
  <key>CFBundleDisplayName</key><string>AppleBar</string>
  <key>CFBundleIdentifier</key><string>com.applebar.commandbar</string>
  <key>CFBundleExecutable</key><string>$APP</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>10.15</string>
  <key>LSUIElement</key><true/>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

echo "compiling …"
xcrun swiftc -O -target arm64-apple-macos11.0 "$HERE/AppleBar.swift" \
  -o "$BUNDLE/Contents/MacOS/$APP" \
  -framework Cocoa -framework Carbon

codesign -s - --force --deep "$BUNDLE" >/dev/null 2>&1 || true
# Launch Services must re-cache the Info.plist or the agent/hotkey misbehaves.
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f "$BUNDLE" >/dev/null 2>&1 || true
echo "Built: $BUNDLE"

if [ "${1:-}" = "--install" ]; then
  rm -rf "/Applications/$APP.app"
  cp -R "$BUNDLE" /Applications/
  /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "/Applications/$APP.app" >/dev/null 2>&1 || true
  echo "Installed: /Applications/$APP.app"
  open "/Applications/$APP.app"
else
  open "$BUNDLE"
fi
