#!/bin/bash
# Build + install + launch iPhoneLatest.app (own 📱 menu-bar icon).
# FEATURE-CARD >> features/iphone-latest.feature
set -e; cd "$(dirname "$0")"
APP=iPhoneLatest.app; DEST="/Applications/AppleToolbox/$APP"
rm -rf "$APP"; mkdir -p "$APP/Contents/MacOS"
xcrun swiftc -O main.swift ../shared/SupportHelp.swift -o "$APP/Contents/MacOS/iPhoneLatest" -framework Cocoa -framework SwiftUI
cat > "$APP/Contents/Info.plist" <<P
<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleIdentifier</key><string>org.esaruoho.iphonelatest</string>
<key>CFBundleName</key><string>iPhoneLatest</string><key>CFBundleExecutable</key><string>iPhoneLatest</string>
<key>CFBundlePackageType</key><string>APPL</string><key>LSUIElement</key><true/></dict></plist>
P
codesign -s "Apple Development: esa Ruoho (X5RGX55QYU)" --force "$APP" >/dev/null 2>&1 || true
pkill -x iPhoneLatest || true
rm -rf "$DEST"; /bin/cp -R "$APP" "$DEST"; rm -rf "$APP"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$DEST"
open "$DEST"; echo "📱 iPhoneLatest running: $DEST"
