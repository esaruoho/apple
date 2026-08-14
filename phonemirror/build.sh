#!/bin/bash
# Build PhoneMirror.app — live ROTATED mirror of a USB iPhone/iPad screen.
# Apple-native: AppKit + AVFoundation + CoreMediaIO via xcrun swiftc. No Xcode, no Homebrew.
# Safe to re-run.

set -e
cd "$(dirname "$0")"
APP="PhoneMirror.app"
NAME="PhoneMirror"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O -parse-as-library PhoneMirror.swift ../shared/SupportHelp.swift -o "$APP/Contents/MacOS/$NAME" \
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
    <key>CFBundleName</key>              <string>PhoneMirror</string>
    <key>CFBundleDisplayName</key>       <string>PhoneMirror</string>
    <key>CFBundleExecutable</key>        <string>PhoneMirror</string>
    <key>CFBundleIdentifier</key>        <string>org.esaruoho.phonemirror</string>
    <key>CFBundleVersion</key>           <string>1.0</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundlePackageType</key>       <string>APPL</string>
    <key>CFBundleIconFile</key>          <string>AppIcon</string>
    <key>LSMinimumSystemVersion</key>    <string>13.0</string>
    <key>NSHighResolutionCapable</key>   <true/>
    <key>NSCameraUsageDescription</key>
    <string>PhoneMirror shows the screen of an iPhone or iPad connected over USB, so it can be rotated live and screen-recorded in one pass.</string>
</dict>
</plist>
PLIST

echo "==> Signing (ad-hoc, so TCC can attach a stable identity)..."
codesign --force --deep --sign - "$APP"

echo "==> Refreshing Launch Services..."
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
    -f "$PWD/$APP" >/dev/null 2>&1 || true

echo "==> Installing CLI shim -> bin/phonemirror"
cat > ../bin/phonemirror <<SHIM
#!/bin/bash
# Launch PhoneMirror.app's binary directly so CLI flags and stdout work.
exec "$PWD/$APP/Contents/MacOS/$NAME" "\$@"
SHIM
chmod +x ../bin/phonemirror

echo
echo "Built $APP"
echo "  phonemirror              # just works: auto-rotate + crop Camera controls out"
echo "  phonemirror --borderless # cleanest for screen recording"
echo "  phonemirror --no-crop    # show the phone's whole screen"
echo "  phonemirror --help       # all flags"
echo "  Live keys: ⇧⌘L / ⇧⌘R rotate · ⇧⌘H flip · ⌘D re-detect · ⌘0 uncropped · ⌘F full screen"
