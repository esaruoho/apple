#!/bin/bash
# Build AppleToolbox.app — Apple-native, no third-party deps.
# Compiles AppleToolbox.swift with /usr/bin/swift (via xcrun), bundles into
# a proper .app structure with LSUIElement=true (no Dock icon), ad-hoc signs.
#
# Safe to re-run.

set -e

cd "$(dirname "$0")"
APP="AppleToolbox.app"
NAME="AppleToolbox"

echo "==> Cleaning previous build..."
rm -rf "$APP"

echo "==> Compiling Swift..."
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
xcrun swiftc -O AppleToolbox.swift -o "$APP/Contents/MacOS/$NAME" -framework Cocoa

echo "==> Writing Info.plist (LSUIElement=true, bundle id, etc.)..."
/usr/libexec/PlistBuddy -c "Add :CFBundleName string $NAME" \
                       -c "Add :CFBundleDisplayName string Apple Toolbox" \
                       -c "Add :CFBundleIdentifier string com.esaruoho.appletoolbox" \
                       -c "Add :CFBundleExecutable string $NAME" \
                       -c "Add :CFBundlePackageType string APPL" \
                       -c "Add :CFBundleShortVersionString string 1.0" \
                       -c "Add :CFBundleVersion string 1" \
                       -c "Add :LSUIElement bool true" \
                       -c "Add :LSMinimumSystemVersion string 12.0" \
                       -c "Add :NSHumanReadableCopyright string Apple skill — esaruoho/apple" \
                       "$APP/Contents/Info.plist"

echo "==> Ad-hoc codesign..."
codesign --force --sign - "$APP" 2>&1 | sed 's/^/    /'

echo "==> Built: $(pwd)/$APP"
echo "    Binary: $(du -h "$APP/Contents/MacOS/$NAME" | cut -f1)"
