#!/bin/bash
# Apple Toolbox — Apple-native install. NO HOMEBREW.
#
# 1. Compile AppleToolbox.swift via xcrun (Apple Developer Tools).
# 2. Bundle into AppleToolbox.app with LSUIElement=true.
# 3. Move bundle to /Applications/Apple-Workflows/.
# 4. Install LaunchAgent so it auto-starts at login.
# 5. Launch.
#
# Safe to re-run. Quits any running instance first.

set -e

TOPBAR_DIR="$HOME/work/apple/topbar"
INSTALL_DIR="/Applications/Apple-Workflows"
APP_PATH="$INSTALL_DIR/AppleToolbox.app"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/com.esaruoho.appletoolbox.plist"

echo "==> Apple Toolbox installer (Apple-native, no Homebrew)"

# Quit any running instance + unload LaunchAgent
osascript -e 'tell application "AppleToolbox" to quit' 2>/dev/null || true
launchctl bootout "gui/$UID/com.esaruoho.appletoolbox" 2>/dev/null || true
sleep 0.5

# Build
echo "==> Building..."
bash "$TOPBAR_DIR/build.sh"

# Move into place
echo "==> Installing into $INSTALL_DIR/"
mkdir -p "$INSTALL_DIR"
rm -rf "$APP_PATH"
mv "$TOPBAR_DIR/AppleToolbox.app" "$APP_PATH"

# Make helper scripts executable
chmod +x "$TOPBAR_DIR"/scripts/*.sh

# Install LaunchAgent (auto-start at login)
echo "==> Installing LaunchAgent at $LAUNCH_AGENT_PLIST"
mkdir -p "$LAUNCH_AGENT_DIR"
cp "$TOPBAR_DIR/launchagent.plist" "$LAUNCH_AGENT_PLIST"
launchctl bootstrap "gui/$UID" "$LAUNCH_AGENT_PLIST" 2>&1 | grep -v "already loaded" || true

# Launch immediately (in case LaunchAgent doesn't fire until next login)
echo "==> Launching..."
open "$APP_PATH"
sleep 1

echo ""
echo "✅ Done. Look for 🧰 in your menu bar."
echo ""
echo "Bundle:        $APP_PATH"
echo "Source:        $TOPBAR_DIR/AppleToolbox.swift"
echo "LaunchAgent:   $LAUNCH_AGENT_PLIST  (auto-start at login)"
echo ""
echo "Edit AppleToolbox.swift then re-run this script to apply changes."
echo "Uninstall: launchctl bootout gui/$UID/com.esaruoho.appletoolbox && rm \"$LAUNCH_AGENT_PLIST\""
