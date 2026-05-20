#!/bin/bash
# Apple Toolbox — SwiftBar install + setup
# Safe to re-run.
#
# Sandboxing reality: SwiftBar is sandboxed and stores plugin-folder access
# as a security-scoped bookmark. `defaults write PluginDirectory` alone does
# not grant read access — only the Finder folder-picker dialog does.
#
# Workaround: SwiftBar's first-launch default is ~/Documents/swiftbar, and it
# auto-bookmarks that location. We create that folder and SYMLINK our plugin
# into it, so SwiftBar can read it without us ever needing the picker.

set -e

TOPBAR_DIR="$HOME/work/apple/topbar"
SWIFTBAR_DIR="$HOME/Documents/swiftbar"

echo "==> Apple Toolbox installer"

# 1. Install SwiftBar if missing
if [ ! -d "/Applications/SwiftBar.app" ]; then
  echo "==> Installing SwiftBar via Homebrew..."
  brew install --cask swiftbar
else
  echo "==> SwiftBar already installed."
fi

# 2. Make plugin + scripts executable
echo "==> Making plugin + helper scripts executable..."
chmod +x "$TOPBAR_DIR"/plugins/*.sh
chmod +x "$TOPBAR_DIR"/scripts/*.sh

# 3. Create SwiftBar's default plugin folder + symlink our plugin in
echo "==> Wiring symlink into $SWIFTBAR_DIR/"
mkdir -p "$SWIFTBAR_DIR"
for plugin in "$TOPBAR_DIR"/plugins/*.sh; do
  ln -sf "$plugin" "$SWIFTBAR_DIR/$(basename "$plugin")"
done
ls -la "$SWIFTBAR_DIR"

# 4. Launch SwiftBar (it'll appear in menu bar)
echo "==> Launching SwiftBar..."
open -a /Applications/SwiftBar.app
sleep 2

# 5. Refresh plugins (in case SwiftBar was already running)
open "swiftbar://refreshallplugins" 2>/dev/null || true

echo ""
echo "✅ Done. Look for 🧰 in your menu bar."
echo ""
echo "If SwiftBar's first-launch dialog appears asking to choose a plugin"
echo "folder, accept the default (~/Documents/swiftbar). The symlink above"
echo "already lives there."
echo ""
echo "To add new entries: edit $TOPBAR_DIR/plugins/Apple.5m.sh"
echo "Or drop a new <Name>.<interval>.sh into $TOPBAR_DIR/plugins/ and"
echo "re-run this script to add the symlink."
