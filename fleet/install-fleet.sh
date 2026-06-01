#!/bin/bash
# install-fleet.sh — put this on any Mac, run it, and that Mac joins the Fleet.
#
#   bash install-fleet.sh
#
# Or, since the repo is public, the no-file version (paste in Terminal):
#   curl -fsSL https://raw.githubusercontent.com/esaruoho/apple/main/fleet/install-fleet.sh | bash
#
# It auto-picks the right mode for THIS Mac:
#   • macOS 13+ with Xcode tools → builds & opens Fleet.app (renders the fleet
#     window AND answers peers).
#   • older macOS (no SwiftUI/Network) → runs the lightweight Python responder
#     (fleet-serve.py): no window, but this Mac still appears LIVE with full
#     data in every modern Mac's Fleet window on the LAN.
#
# Either way: allow the one-time "Local Network" prompt and this Mac is in the
# fleet (auto-trust same-LAN, full data). Safe to re-run.

set -u
REPO="https://github.com/esaruoho/apple"
DIR="$HOME/work/apple"
say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m  ! %s\033[0m\n' "$*"; }
die()  { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

# 1. Common prerequisites ---------------------------------------------------
say "Checking $(hostname -s) — macOS $(sw_vers -productVersion) ($(uname -m))…"
command -v git     >/dev/null 2>&1 || die "git not found (install Xcode command-line tools: xcode-select --install)."
command -v python3 >/dev/null 2>&1 || die "python3 not found (install Xcode command-line tools: xcode-select --install)."
ok "git, python3 present"

# 2. Source -----------------------------------------------------------------
if [ -d "$DIR/.git" ]; then
  say "Updating $DIR…"
  git -C "$DIR" pull --ff-only --autostash 2>&1 | tail -2 || warn "pull skipped — using what's on disk"
else
  say "Cloning $REPO → $DIR …"
  mkdir -p "$(dirname "$DIR")"
  git clone --depth 1 "$REPO" "$DIR" || die "clone failed (network?)."
fi
ok "source ready at $DIR"

MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
HAVE_SWIFTC=0; xcrun -f swiftc >/dev/null 2>&1 && HAVE_SWIFTC=1

# 3a. Modern Mac → build + open the GUI -------------------------------------
if [ "${MACOS_MAJOR:-0}" -ge 13 ] 2>/dev/null && [ "$HAVE_SWIFTC" = 1 ]; then
  say "macOS 13+ with swiftc → building Fleet.app for $(uname -m)…"
  bash "$DIR/fleet/build.sh" || die "build failed (see output above)."
  say "Launching Fleet…"
  open "$DIR/fleet/Fleet.app"
  echo
  ok "Fleet.app is open on $(hostname -s)."
  echo "   • Allow the one-time 'Local Network' prompt — without it, peers stay hidden."
  echo "   • Other Macs on this LAN (Fleet.app or the responder) appear automatically."

# 3b. Older Mac → headless Python responder ---------------------------------
else
  if [ "${MACOS_MAJOR:-0}" -lt 13 ] 2>/dev/null; then
    say "macOS $(sw_vers -productVersion) is pre-13 → using the version-independent responder."
  else
    warn "swiftc not found → using the responder instead of the GUI (run xcode-select --install for the window)."
  fi
  command -v dns-sd >/dev/null 2>&1 || die "dns-sd not found — cannot advertise on this macOS."
  pkill -f "$DIR/fleet/fleet-serve.py" 2>/dev/null || true
  sleep 1
  nohup python3 "$DIR/fleet/fleet-serve.py" > "$HOME/.fleet-serve.log" 2>&1 &
  disown
  sleep 2
  if pgrep -f "$DIR/fleet/fleet-serve.py" >/dev/null; then
    echo
    ok "Responder running on $(hostname -s) — it now appears LIVE in every modern Mac's Fleet window."
    echo "   • Log: ~/.fleet-serve.log"
    echo "   • This Mac has no window (too old for the GUI), but it's a full peer."
    echo "   • Re-run this script anytime to update + restart the responder."
  else
    die "responder failed to start — see ~/.fleet-serve.log"
  fi
fi
