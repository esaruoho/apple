#!/bin/bash
# Build Snapshot.app — a faceless .app bundle hosting every sensor-snapshot tool
# (iphone-photo, iphone-import, audio-snippets, iphone-screen). The bundle is
# what carries NSCameraUseContinuityCameraDeviceType + the Camera/Microphone TCC
# identity. Apple-native: /usr/bin/swiftc only. No Homebrew, no third-party deps.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/Snapshot.app"
MACOS="$APP/Contents/MacOS"

rm -rf "$APP"
mkdir -p "$MACOS"
cp "$HERE/Info.plist" "$APP/Contents/Info.plist"

/usr/bin/swiftc -O \
  -framework AVFoundation -framework CoreImage -framework ImageIO \
  "$HERE/iphone-photo.swift" -o "$MACOS/iphone-photo"

/usr/bin/swiftc -O \
  -framework ImageCaptureCore \
  "$HERE/iphone-import.swift" -o "$MACOS/iphone-import"

/usr/bin/swiftc -O \
  -framework AVFoundation \
  "$HERE/audio-snippets.swift" -o "$MACOS/audio-snippets"

/usr/bin/swiftc -O \
  -framework AVFoundation -framework CoreMediaIO -framework CoreImage -framework ImageIO \
  "$HERE/iphone-screen.swift" -o "$MACOS/iphone-screen"

# Ad-hoc sign so TCC tracks a stable identity across rebuilds.
/usr/bin/codesign --force --sign - "$APP" >/dev/null 2>&1 || true

# Refresh Launch Services so the bundle's Info.plist (and its keys) is seen.
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
  -f "$APP" >/dev/null 2>&1 || true

echo "built: $APP"
