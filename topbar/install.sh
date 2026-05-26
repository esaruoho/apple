#!/bin/bash
# Apple Toolbox — first-time install. Apple-native, no Homebrew.
#
# This script is only needed ONCE per machine. After that, every change
# (Swift edit, helper-script edit, etc.) is applied by re-running
# `bash build.sh` — which compiles AND syncs the running binary AND
# relaunches it. There is no "did you also run install.sh" footgun.
#
# What this script does that build.sh doesn't:
#   - Creates /Applications/AppleToolbox/Apple-Workflows/
#   - Installs the LaunchAgent so AppleToolbox auto-starts at login
#
# Then it calls build.sh to do the actual build + deploy + launch.

set -e

TOPBAR_DIR="$HOME/work/apple/topbar"
INSTALL_DIR="/Applications/AppleToolbox/Apple-Workflows"
LAUNCH_AGENT_DIR="$HOME/Library/LaunchAgents"
LAUNCH_AGENT_PLIST="$LAUNCH_AGENT_DIR/com.esaruoho.appletoolbox.plist"

echo "==> Apple Toolbox first-time install"

# Quit any existing instance + unload the LaunchAgent before we touch files.
osascript -e 'tell application "AppleToolbox" to quit' 2>/dev/null || true
launchctl bootout "gui/$UID/com.esaruoho.appletoolbox" 2>/dev/null || true
sleep 0.5

# Ensure the install location exists so build.sh's sync step has somewhere
# to copy to.
mkdir -p "$INSTALL_DIR"

# Install LaunchAgent (auto-start at login).
echo "==> Installing LaunchAgent at $LAUNCH_AGENT_PLIST"
mkdir -p "$LAUNCH_AGENT_DIR"
cp "$TOPBAR_DIR/launchagent.plist" "$LAUNCH_AGENT_PLIST"
launchctl bootstrap "gui/$UID" "$LAUNCH_AGENT_PLIST" 2>&1 \
    | grep -v "already loaded" || true

# Everything else (compile, sync, restart, launch) is build.sh's job.
echo ""
bash "$TOPBAR_DIR/build.sh"

echo ""
echo "✅ First-time install complete."
echo ""
echo "From now on, after any edit just run:"
echo "    bash $TOPBAR_DIR/build.sh"
echo ""
echo "Uninstall: launchctl bootout gui/$UID/com.esaruoho.appletoolbox && rm \"$LAUNCH_AGENT_PLIST\""
