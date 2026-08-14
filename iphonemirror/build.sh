#!/bin/bash
# Build iPhoneMirror.app — live ROTATED mirror of a USB iPhone/iPad screen.
# Apple-native: AppKit + AVFoundation + CoreMediaIO via xcrun swiftc. No Xcode, no Homebrew.
# Safe to re-run.

set -e
cd "$(dirname "$0")"
APP="iPhoneMirror.app"
APP_REL="iPhoneMirror.app/Contents/MacOS/iPhoneMirror"
NAME="iPhoneMirror"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O -parse-as-library iPhoneMirror.swift ../shared/SupportHelp.swift -o "$APP/Contents/MacOS/$NAME" \
    -framework AppKit \
    -framework SwiftUI \
    -framework AVFoundation \
    -framework CoreMediaIO \
    -framework Vision \
    -framework CoreImage

echo "==> Generating app icon (AppIcon.icns)..."
if [ ! -f AppIcon.icns ] || [ make-icon.swift -nt AppIcon.icns ]; then
    xcrun swift make-icon.swift >/dev/null
    iconutil -c icns AppIcon.iconset -o AppIcon.icns
    rm -rf AppIcon.iconset
fi
command cp AppIcon.icns "$APP/Contents/Resources/AppIcon.icns"

echo "==> Writing Info.plist..."
# NSCameraUsageDescription is REQUIRED: a CoreMediaIO iOS screen-capture device is gated by the
# Camera TCC class. Without this key the app is killed the instant it opens the device.
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key>              <string>iPhoneMirror</string>
    <key>CFBundleDisplayName</key>       <string>iPhoneMirror</string>
    <key>CFBundleExecutable</key>        <string>iPhoneMirror</string>
    <key>CFBundleIdentifier</key>        <string>org.esaruoho.iphonemirror</string>
    <key>CFBundleVersion</key>           <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleIconFile</key>          <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>NSHighResolutionCapable</key>   <true/>
    <key>NSCameraUsageDescription</key>
    <string>iPhoneMirror shows the screen of an iPhone or iPad connected over USB, so it can be rotated live and screen-recorded in one pass.</string>
</dict>
</plist>
PLIST

echo "==> Signing (ad-hoc, so TCC can attach a stable identity)..."
codesign --force --deep --sign - "$APP"

# ONE canonical copy lives in /Applications, so Spotlight, the Dock, Launch Services and the CLI
# shim all resolve to the same bundle. Building in the repo and running it from there means every
# rebuild is a different app to macOS — different TCC identity, stale Dock entries, two icons.
INSTALLED="/Applications/$APP"

echo "==> Installing to $INSTALLED ..."
if pgrep -f "$APP/Contents/MacOS/$NAME" >/dev/null 2>&1; then
    echo "    (quitting the running copy first)"
    osascript -e "tell application \"$NAME\" to quit" >/dev/null 2>&1 || true
    sleep 2
fi
# ditto, not cp: it copies bundles faithfully and preserves the code signature.
command rm -rf "$INSTALLED"
ditto "$APP" "$INSTALLED"

echo "==> Refreshing Launch Services (both copies)..."
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
"$LSREG" -f "$PWD/$APP" >/dev/null 2>&1 || true
"$LSREG" -f "$INSTALLED" >/dev/null 2>&1 || true

echo "==> Installing CLI shim -> bin/iphonemirror"
cat > ../bin/iphonemirror <<SHIM
#!/bin/bash
# Launch the INSTALLED iPhoneMirror.app's binary directly, so CLI flags and stdout work while
# still being the same bundle the Dock and Spotlight launch.
APP="/Applications/iPhoneMirror.app/Contents/MacOS/iPhoneMirror"
[ -x "\$APP" ] || APP="$PWD/$APP_REL"
exec "\$APP" "\$@"
SHIM
chmod +x ../bin/iphonemirror

echo
echo "Built and installed → $INSTALLED"
echo "  iphonemirror              # just works: auto-rotate + crop Camera controls out"
echo "  iphonemirror --borderless # cleanest for screen recording"
echo "  iphonemirror --no-crop    # show the phone's whole screen"
echo "  iphonemirror --help       # all flags"
echo "  Live keys: ⇧⌘L / ⇧⌘R rotate · ⇧⌘H flip · ⌘D re-detect · ⌘0 uncropped · ⌘F full screen"
