#!/bin/bash
# Build DualCam, and install it to a connected iPhone if one is attached.
set -euo pipefail
cd "$(dirname "$0")"

echo "==> building…"
xcodebuild -project DualCam.xcodeproj -scheme DualCam -sdk iphoneos \
  -configuration Release -destination 'generic/platform=iOS' \
  -derivedDataPath build build | grep -E "error:|BUILD" || true

APP="build/Build/Products/Release-iphoneos/DualCam.app"
[ -d "$APP" ] || { echo "no app at $APP"; exit 1; }
echo "==> built: $APP"

# Install only if a device is actually connected — a rig gets plugged and unplugged, and this
# script should be safe to run either way.
DEV=$(xcrun devicectl list devices 2>/dev/null | awk '/connected/ {print $NF; exit}')
if [ -n "${DEV:-}" ]; then
  echo "==> installing to $DEV"
  xcrun devicectl device install app --device "$DEV" "$APP"
  echo "✓ installed — open DualCam on the phone, then: iphonemirror --rig"
else
  echo "• no iPhone connected; plug one in and re-run to install"
fi
