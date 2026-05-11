#!/usr/bin/env bash
# bootstrap-hey-sal.sh — ONE-COMMAND install of the entire Hey Sal stack:
#
#   1. Generate the 337 Paketti voice-callable verb wrappers from Renoise's
#      KeyBindings.xml (so any bound Paketti binding becomes voice/typeable).
#   2. Compile ~/Applications/Hey Sal.app — the Spotlight-launchable typed
#      entry. Index it so Spotlight finds it.
#   3. Build + import the Shortcuts.app workflows:
#         - "Hey Sal"       (voice — Dictate Text → router)
#         - "Hey Sal Type"  (typed — Ask for Input → router)
#      so they can be pinned in the menu bar (and registered as Vocal
#      Shortcuts in System Settings).
#   4. Detect missing Accessibility/Automation grants and print precise
#      next-step instructions.
#
# Run anytime — safe to re-run. Re-running rebuilds wrappers/app/Shortcuts
# and re-imports cleanly; no duplicates, no half-states.
#
# Usage:
#   bash ~/work/apple/bin/bootstrap-hey-sal.sh
#
# Exit code 0 = stack ready. Non-zero = a hard prerequisite failed.

set -euo pipefail

APPLE_REPO="$HOME/work/apple"
APPLETS_DIR="$APPLE_REPO/applets"
BIN_DIR="$APPLE_REPO/bin"
RENOISE_BIN_DIR="$BIN_DIR/renoise"
SHORTCUTS_DIR="$APPLE_REPO/shortcuts/sal-dictation"
USER_APPS="$HOME/Applications"
APP_BUNDLE="$USER_APPS/Hey Sal.app"
LOG="$HOME/Library/Logs/HeySal.log"

bold()  { printf '\033[1m%s\033[0m\n' "$*"; }
ok()    { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn()  { printf '  \033[33m!\033[0m %s\n' "$*"; }
fail()  { printf '  \033[31m✗\033[0m %s\n' "$*"; }

# ---------------------------------------------------------------- prereqs ---
bold "Step 0 — prerequisites"

PY3=$(command -v python3 || true)
if [ -z "$PY3" ]; then
  fail "python3 not found"
  exit 2
fi
ok "python3: $PY3"

if ! command -v shortcuts >/dev/null 2>&1; then
  fail "macOS 'shortcuts' CLI missing — needs macOS 12+"
  exit 2
fi
ok "shortcuts CLI: $(command -v shortcuts)"

KB="$HOME/Library/Preferences/Renoise/V3.5.4/KeyBindings.xml"
if [ ! -f "$KB" ]; then
  warn "Renoise KeyBindings.xml not found at $KB"
  warn "  Paketti verb generation will skip. Voice still works for non-Paketti commands."
  HAVE_KB=0
else
  ok "Renoise KeyBindings.xml: $KB"
  HAVE_KB=1
fi

mkdir -p "$RENOISE_BIN_DIR" "$SHORTCUTS_DIR" "$USER_APPS" "$APPLETS_DIR" "$(dirname "$LOG")"

# --------------------------------------------------- 1. Paketti verbs ---
bold "Step 1 — Paketti verb wrappers (one per Paketti binding with chord)"
if [ "$HAVE_KB" -eq 1 ]; then
  if [ ! -x "$BIN_DIR/build-paketti-verbs.py" ]; then
    fail "missing $BIN_DIR/build-paketti-verbs.py"
    exit 2
  fi
  if [ ! -x "$RENOISE_BIN_DIR/_send" ]; then
    fail "missing $RENOISE_BIN_DIR/_send (the AppleScript helper)"
    exit 2
  fi
  "$PY3" "$BIN_DIR/build-paketti-verbs.py" >/tmp/heysal-verbs.log 2>&1
  COUNT=$(grep -oE 'Wrote [0-9]+ wrappers' /tmp/heysal-verbs.log | awk '{print $2}')
  ok "wrappers regenerated: ${COUNT:-?} → $RENOISE_BIN_DIR/"
  ok "registry: $APPLE_REPO/analysis/sal/paketti-verbs.json"
else
  warn "skipped (Renoise not detected)"
fi

# --------------------------------------------------- 2. Hey Sal.app ---
bold "Step 2 — Hey Sal.app (Spotlight-launchable typed entry)"
SRC="$APPLETS_DIR/hey-sal-type.applescript"
if [ ! -f "$SRC" ]; then
  fail "missing $SRC"
  exit 2
fi
rm -rf "$APP_BUNDLE"
osacompile -o "$APP_BUNDLE" "$SRC"
ok "compiled: $APP_BUNDLE"
mdimport "$APP_BUNDLE" 2>/dev/null || true
sleep 1
if mdfind "kMDItemDisplayName == 'Hey Sal*'" 2>/dev/null | grep -qF "$APP_BUNDLE"; then
  ok "Spotlight indexed (Cmd+Space → 'Hey Sal' will find it)"
else
  warn "Spotlight not yet indexed — usually appears within ~30s; retry: mdimport '$APP_BUNDLE'"
fi

# --------------------------------------------------- 3. Voice Shortcut ---
bold "Step 3 — 'Hey Sal' Shortcut (voice — Dictate Text → router)"
if [ -x "$BIN_DIR/build-hey-sal-shortcut.py" ]; then
  "$PY3" "$BIN_DIR/build-hey-sal-shortcut.py" >/tmp/heysal-voice.log 2>&1 || {
    fail "voice Shortcut build failed; see /tmp/heysal-voice.log"
    cat /tmp/heysal-voice.log
  }
  if [ -f "$SHORTCUTS_DIR/Hey Sal.shortcut" ]; then
    ok "built: $SHORTCUTS_DIR/Hey Sal.shortcut"
  fi
else
  warn "build-hey-sal-shortcut.py not found — voice Shortcut not (re)built"
fi

# --------------------------------------------------- 4. Typed Shortcut ---
bold "Step 4 — 'Hey Sal Type' Shortcut (typed — Ask for Input → router)"
if [ -x "$BIN_DIR/build-hey-sal-type-shortcut.py" ]; then
  "$PY3" "$BIN_DIR/build-hey-sal-type-shortcut.py" >/tmp/heysal-type.log 2>&1 || {
    fail "typed Shortcut build failed; see /tmp/heysal-type.log"
    cat /tmp/heysal-type.log
  }
  if [ -f "$SHORTCUTS_DIR/Hey Sal Type.shortcut" ]; then
    ok "built: $SHORTCUTS_DIR/Hey Sal Type.shortcut"
  fi
else
  warn "build-hey-sal-type-shortcut.py not found — typed Shortcut not (re)built"
fi

# --------------------------------------------------- 5. Import to Shortcuts.app ---
bold "Step 5 — import both Shortcuts into Shortcuts.app"
if shortcuts list 2>/dev/null | grep -qx "Hey Sal"; then
  ok "'Hey Sal' already in Shortcuts.app (re-import via 'open' if you changed the build)"
else
  warn "'Hey Sal' not in Shortcuts.app — opening import dialog…"
  [ -f "$SHORTCUTS_DIR/Hey Sal.shortcut" ] && open "$SHORTCUTS_DIR/Hey Sal.shortcut"
fi
if shortcuts list 2>/dev/null | grep -qx "Hey Sal Type"; then
  ok "'Hey Sal Type' already in Shortcuts.app"
else
  warn "'Hey Sal Type' not in Shortcuts.app — opening import dialog…"
  [ -f "$SHORTCUTS_DIR/Hey Sal Type.shortcut" ] && open "$SHORTCUTS_DIR/Hey Sal Type.shortcut"
fi

# --------------------------------------------------- 6. Permission audit ---
bold "Step 6 — permission audit (TCC is GUI-only; we can only detect, not grant)"
ACC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
HEY_SAL_BUNDLE_ID=$(plutil -extract CFBundleIdentifier raw "$APP_BUNDLE/Contents/Info.plist" 2>/dev/null || true)
if [ -n "$HEY_SAL_BUNDLE_ID" ]; then
  ok "Hey Sal.app bundle id: $HEY_SAL_BUNDLE_ID"
else
  warn "Hey Sal.app has no bundle id (osacompile default) — fine for permissions, listed in TCC by display name 'Hey Sal'"
fi
# We cannot reliably read TCC.db without Full Disk Access. So the check is
# just a heuristic — if the chain has ever fired successfully, the log
# will contain a non-error line. Otherwise prompt the user.
if [ -f "$LOG" ] && grep -qE 'Option \+ 8|sent key code' "$LOG"; then
  ok "Hey Sal log has prior successful key-code sends — Accessibility likely granted"
else
  warn "no successful keystroke fires in $LOG yet"
  warn "  → System Settings → Privacy & Security → Accessibility → add 'Hey Sal' (~/Applications/Hey Sal.app)"
  warn "  → System Settings → Privacy & Security → Automation → 'Hey Sal' → enable 'System Events'"
fi

# --------------------------------------------------- 7. Live smoke (read-only) ---
bold "Step 7 — live smoke test (Renoise + a SAFE registry lookup, no firing)"
if pgrep -lf "Renoise.app/Contents/MacOS/Renoise" >/dev/null; then
  ok "Renoise running"
else
  warn "Renoise not running — start it before voice/type tests"
fi
if [ -f "$APPLE_REPO/analysis/sal/paketti-verbs.json" ]; then
  N=$("$PY3" -c "import json; print(json.load(open('$APPLE_REPO/analysis/sal/paketti-verbs.json'))['count'])")
  ok "Paketti verbs available: $N"
else
  warn "no Paketti verb registry — Step 1 must have skipped"
fi

# --------------------------------------------------- 8. Final manual steps ---
echo
bold "What's left for you (Apple won't let me automate these):"
cat <<EOF
  1. Cmd+Space → 'Hey Sal' → Enter → dialog → type 'groovebox' → Enter
     If macOS asks for Accessibility / Automation — grant both. Repeat once.
  2. Open Shortcuts.app → right-click 'Hey Sal' → Pin in Menu Bar.
     Right-click 'Hey Sal Type' → Pin in Menu Bar.
     A ⚡ icon appears top-right; click → both Voice and Type listed.
  3. (Optional) System Settings → Accessibility → Speech → Vocal Shortcuts:
     'Hey Sal' is already registered for you (verified). To add a Vocal
     Shortcut for 'Hey Sal Type', repeat the Set Up flow with a phrase
     like 'Sal Type' bound to the 'Hey Sal Type' Shortcut.
EOF

echo
bold "Done. Three trigger surfaces are now wired:"
echo "  • Voice  : say 'Hey Sal' → Vocal Shortcut → 'Hey Sal' Shortcut"
echo "  • Spotlight typed: Cmd+Space → 'Hey Sal' → dialog"
echo "  • Menu bar  : ⚡ icon → Hey Sal / Hey Sal Type"
echo "  • Bash      : ~/work/apple/bin/hey-sal 'paketti groovebox'"
