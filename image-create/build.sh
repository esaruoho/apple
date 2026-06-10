#!/bin/bash
# build.sh — compile image-create as BOTH a .app bundle and a CLI wrapper.
#
# Why a bundle? Apple's ImageCreator refuses to render unless its host process is
# a genuine foreground app — and a bare terminal binary (no bundle id) is never
# treated as foreground by the WindowServer. So the real worker is a tiny .app
# (ImageCreate.app); the `image-create` CLI just `open`s it with --args and waits.
#
# Apple-native: xcrun swiftc only. Runtime needs macOS 15.4+, Apple Silicon,
# Apple Intelligence enabled + the Image Playground model downloaded.
#
#   ./build.sh            build into ./build, install CLI to ~/work/apple/bin
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
SRC="$HERE/../bin/image-create.swift"
APP="ImageCreate"
BUILD="$HERE/build"
BUNDLE="$BUILD/$APP.app"

rm -rf "$BUNDLE"
mkdir -p "$BUNDLE/Contents/MacOS"

cat > "$BUNDLE/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleName</key><string>$APP</string>
  <key>CFBundleDisplayName</key><string>Image Create</string>
  <key>CFBundleIdentifier</key><string>com.esaruoho.imagecreate</string>
  <key>CFBundleExecutable</key><string>$APP</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <key>LSMinimumSystemVersion</key><string>15.4</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.graphics-design</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
</dict>
</plist>
PLIST

echo "compiling …"
xcrun swiftc -O -target arm64-apple-macos15.4 "$SRC" \
  -o "$BUNDLE/Contents/MacOS/$APP" \
  -framework Foundation -framework AppKit -framework CoreGraphics \
  -framework ImageIO -framework UniformTypeIdentifiers -framework ImagePlayground

codesign -s - --force --deep "$BUNDLE" >/dev/null 2>&1 || true
echo "Built: $BUNDLE"
