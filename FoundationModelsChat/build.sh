#!/bin/bash
# build.sh — compile FoundationModelsChat.app. Apple-native, no third-party deps.
# Requires: macOS 26 (Tahoe) SDK + Xcode command line tools. At RUNTIME the app
# needs an Apple Silicon Mac on macOS 26 with Apple Intelligence enabled (that's
# where the on-device FoundationModels LLM lives).
#
#   ./build.sh            build into ./build and launch
#   ./build.sh --install  also copy to /Applications
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="FoundationModelsChat"
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
  <key>CFBundleDisplayName</key><string>FoundationModels Chat</string>
  <key>CFBundleIdentifier</key><string>com.foundationmodelschat.app</string>
  <key>CFBundleExecutable</key><string>$APP</string>
  <key>CFBundlePackageType</key><string>APPL</string>
  <key>CFBundleShortVersionString</key><string>1.0</string>
  <key>CFBundleVersion</key><string>1</string>
  <!-- Launches on macOS 14+ and reports the macOS-26 FoundationModels
       requirement at runtime (friendlier than Finder refusing to open it). -->
  <key>LSMinimumSystemVersion</key><string>14.0</string>
  <key>LSApplicationCategoryType</key><string>public.app-category.productivity</string>
  <key>NSHighResolutionCapable</key><true/>
  <key>NSPrincipalClass</key><string>NSApplication</string>
  <key>NSHumanReadableCopyright</key><string>On-device. Local. Yours.</string>
</dict>
</plist>
PLIST

# Gate: the Markdown renderer must pass its headless tests before we build the
# app. A render regression (e.g. ordered lists not counting) fails here, loudly,
# instead of in a screenshot. Pure Foundation — runs anywhere swiftc does.
echo "testing Markdown renderer …"
"$HERE/test-markdown.sh"

echo "compiling …"
# Deployment target 14.0 so the app LAUNCHES on older macOS and reports the
# FoundationModels requirement gracefully (FM calls are #available-gated to 26).
xcrun swiftc -O -target arm64-apple-macos14.0 "$HERE/main.swift" "$HERE/Markdown.swift" \
  -o "$BUNDLE/Contents/MacOS/$APP" \
  -framework AppKit -framework WebKit -framework FoundationModels \
  -framework PDFKit -framework Vision -framework UniformTypeIdentifiers \
  -framework ImageIO -framework ImagePlayground \
  -framework Foundation

codesign -s - --force --deep "$BUNDLE" >/dev/null 2>&1 || true
echo "Built: $BUNDLE"

if [ "${1:-}" = "--install" ]; then
  rm -rf "/Applications/$APP.app"
  cp -R "$BUNDLE" /Applications/
  echo "Installed: /Applications/$APP.app"
  open "/Applications/$APP.app"
else
  open "$BUNDLE"
fi
