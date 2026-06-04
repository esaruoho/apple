#!/bin/bash
# Build iPhonePhoto.app — a faceless .app bundle so Bundle.main carries
# NSCameraUseContinuityCameraDeviceType and AVCapturePhotoOutput's KVO works.
# Apple-native: /usr/bin/swiftc only. No Homebrew, no third-party deps.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
APP="$HERE/iPhonePhoto.app"
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

# Ad-hoc sign so TCC tracks a stable identity across rebuilds.
/usr/bin/codesign --force --sign - "$APP" >/dev/null 2>&1 || true

# Refresh Launch Services so the bundle's Info.plist (and its keys) is seen.
/System/Library/Frameworks/CoreServices.framework/Versions/A/Frameworks/LaunchServices.framework/Versions/A/Support/lsregister \
  -f "$APP" >/dev/null 2>&1 || true

echo "built: $APP"
