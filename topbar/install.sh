#!/bin/bash
# Apple Toolbox — SwiftBar install + setup
# Idempotent: safe to re-run.

set -e

TOPBAR_DIR="$HOME/work/apple/topbar"

echo "==> Apple Toolbox installer"

# 1. Install SwiftBar if missing
if [ ! -d "/Applications/SwiftBar.app" ]; then
  echo "==> Installing SwiftBar via Homebrew..."
  brew install --cask swiftbar
else
  echo "==> SwiftBar already installed."
fi

# 2. Make plugin + scripts executable
echo "==> Making plugin scripts executable..."
chmod +x "$TOPBAR_DIR"/plugins/*.sh
chmod +x "$TOPBAR_DIR"/scripts/*.sh

# 3. Point SwiftBar at our plugin folder
echo "==> Pointing SwiftBar plugin folder at $TOPBAR_DIR/plugins"
defaults write com.ameba.SwiftBar PluginDirectory -string "$TOPBAR_DIR/plugins"
defaults write com.ameba.SwiftBar PluginDirectoryResolvedBookmark -data "" 2>/dev/null || true

# 4. Launch SwiftBar (it'll appear in menu bar)
echo "==> Launching SwiftBar..."
open -a SwiftBar

echo ""
echo "✅ Done. Look for 🧰 in your menu bar."
echo ""
echo "First launch: SwiftBar will ask permission to access the folder."
echo "Grant it, then the toolbox appears."
echo ""
echo "To add new entries: edit $TOPBAR_DIR/plugins/Toolbox.1d.sh"
echo "Or drop a new <Name>.<interval>.sh into $TOPBAR_DIR/plugins/"
echo "SwiftBar picks up changes automatically (or click 🧰 → 🔄 Refresh)."
