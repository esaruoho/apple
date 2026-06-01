#!/bin/bash
# install-fleet.sh — put this on any Mac, run it, and that Mac joins the Fleet.
#
#   bash install-fleet.sh
#
# Or, since the repo is public, the no-file version (paste in Terminal):
#   curl -fsSL https://raw.githubusercontent.com/esaruoho/apple/main/fleet/install-fleet.sh | bash
#
# What it does, on THIS machine:
#   1. checks prerequisites (macOS 13+, git, Xcode command-line tools, python3)
#   2. gets the apple repo at ~/work/apple (clone if missing, pull if present)
#   3. builds Fleet.app for THIS Mac's chip (swiftc, native arch — Intel or ARM)
#   4. opens Fleet.app
#
# Then allow the one-time "Local Network" prompt and this Mac shows up — live,
# full data — in every other Mac's Fleet window on the same LAN (auto-trust),
# and they show up in this one. Safe to re-run (it just updates + rebuilds).

set -u
REPO="https://github.com/esaruoho/apple"
DIR="$HOME/work/apple"
say()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[1;32m  ✓\033[0m %s\n' "$*"; }
die()  { printf '\033[1;31m  ✗ %s\033[0m\n' "$*" >&2; exit 1; }

# 1. Prerequisites ----------------------------------------------------------
say "Checking this Mac…"
MACOS_MAJOR=$(sw_vers -productVersion | cut -d. -f1)
[ "${MACOS_MAJOR:-0}" -ge 13 ] 2>/dev/null \
  || die "Fleet needs macOS 13 (Ventura) or newer — this is $(sw_vers -productVersion). This Mac can't run it."
ok "macOS $(sw_vers -productVersion) ($(uname -m))"

command -v git >/dev/null 2>&1 || die "git not found."
command -v python3 >/dev/null 2>&1 || die "python3 not found."
if ! xcrun -f swiftc >/dev/null 2>&1; then
  die "Xcode command-line tools missing. Install with:  xcode-select --install   (then re-run this)."
fi
ok "git, python3, swiftc present"

# 2. Source -----------------------------------------------------------------
if [ -d "$DIR/.git" ]; then
  say "Updating $DIR…"
  git -C "$DIR" pull --ff-only --autostash 2>&1 | tail -2 || say "(pull skipped — using what's on disk)"
else
  say "Cloning $REPO → $DIR …"
  mkdir -p "$(dirname "$DIR")"
  git clone --depth 1 "$REPO" "$DIR" || die "clone failed (network?)."
fi
ok "source ready at $DIR"

# 3. Build ------------------------------------------------------------------
[ -x "$DIR/fleet/build.sh" ] || die "fleet/build.sh missing in the repo."
say "Building Fleet.app for $(uname -m)…"
bash "$DIR/fleet/build.sh" || die "build failed (see output above)."

# 4. Launch -----------------------------------------------------------------
say "Launching Fleet…"
open "$DIR/fleet/Fleet.app"
echo
ok "Fleet is open on $(hostname -s)."
echo "   • Allow the one-time 'Local Network' prompt — without it, peers stay hidden."
echo "   • Other Macs on this LAN running Fleet appear automatically (live green dot)."
echo "   • Re-run this script anytime to update + rebuild."
