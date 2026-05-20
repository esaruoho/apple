#!/bin/bash
# Apple Toolbox — Apple-native install. NO HOMEBREW.
#
# 1. Compile AppleToolbox.swift via xcrun (Apple Developer Tools — ships
#    with macOS / Command Line Tools).
# 2. Bundle into AppleToolbox.app with LSUIElement=true (menu bar only,
#    no Dock icon).
# 3. Move bundle to /Applications/Apple-Workflows/ (matches the existing
#    spotlight-export pattern from the apple skill).
# 4. Launch.
#
# Safe to re-run. Quits any running instance first.

set -e

TOPBAR_DIR="$HOME/work/apple/topbar"
INSTALL_DIR="/Applications/Apple-Workflows"
APP_PATH="$INSTALL_DIR/AppleToolbox.app"

echo "==> Apple Toolbox installer (Apple-native, no Homebrew)"

# Quit any running instance
osascript -e 'tell application "AppleToolbox" to quit' 2>/dev/null || true
sleep 0.5

# Build
echo "==> Building..."
bash "$TOPBAR_DIR/build.sh"

# Move into place
echo "==> Installing into $INSTALL_DIR/"
mkdir -p "$INSTALL_DIR"
rm -rf "$APP_PATH"
mv "$TOPBAR_DIR/AppleToolbox.app" "$APP_PATH"

# Make helper scripts executable (the menu items call them)
chmod +x "$TOPBAR_DIR"/scripts/*.sh

# Launch
echo "==> Launching..."
open "$APP_PATH"
sleep 1

echo ""
echo "✅ Done. Look for 🧰 in your menu bar."
echo ""
echo "Bundle: $APP_PATH"
echo "Source: $TOPBAR_DIR/AppleToolbox.swift"
echo "Edit + rerun this script to apply changes."
