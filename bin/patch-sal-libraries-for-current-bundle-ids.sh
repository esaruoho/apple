#!/usr/bin/env bash
# Patch Sal's installed .scptd libraries to use current Apple bundle IDs.
# Apple changed iWork bundle IDs (com.apple.iWork.* → com.apple.*) at some
# point post-2016. Sal's 2016 libraries hardcoded the old IDs and now error
# with -1728 "Can't get application id" on current macOS.
#
# This script: for each affected library, decompile → search/replace bundle
# IDs → recompile → install to ~/Library/Script Libraries/.
#
# Idempotent. Safe to re-run.
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
DECOMPILED="$REPO_ROOT/scripts/sal/dictation-commands/decompiled"
LIB_DST="$HOME/Library/Script Libraries"

# Affected libraries — anything that hardcodes old iWork bundle IDs
LIBRARIES=(DC-Keynote DC-Pages DC-Numbers DC-Assistive-Keynote DC-Keynote-Objects DC-Workspace)

# sed replacements
SUBST=(
  's|com\.apple\.iWork\.Keynote|com.apple.Keynote|g'
  's|com\.apple\.iWork\.Pages|com.apple.Pages|g'
  's|com\.apple\.iWork\.Numbers|com.apple.Numbers|g'
)

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "Patching Sal libraries for current iWork bundle IDs..."
for lib in "${LIBRARIES[@]}"; do
  src="$DECOMPILED/$lib.applescript"
  if [[ ! -f "$src" ]]; then
    echo "  skip: $lib (no decompiled source at $src)"
    continue
  fi

  patched="$TMP/$lib.applescript"
  cp "$src" "$patched"
  for s in "${SUBST[@]}"; do
    sed -i '' "$s" "$patched"
  done

  # Show diff size for sanity
  changes=$(diff -u "$src" "$patched" | grep -c '^[+-]' || true)
  if [[ "$changes" -eq 0 ]]; then
    echo "  $lib: no bundle-id references, skipping"
    continue
  fi

  # Compile to .scpt
  out_scpt="$TMP/$lib.scpt"
  if ! osacompile -o "$out_scpt" "$patched"; then
    echo "  $lib: COMPILE FAILED — leaving original in place"
    continue
  fi

  # Install — replace main.scpt inside the .scptd bundle in ~/Library/Script Libraries/
  target_main="$LIB_DST/$lib.scptd/Contents/Resources/Scripts/main.scpt"
  if [[ ! -f "$target_main" ]]; then
    echo "  $lib: not installed at $target_main — run bin/dictation-commands-install.sh first"
    continue
  fi

  # Backup once
  if [[ ! -f "$target_main.original-2016" ]]; then
    cp "$target_main" "$target_main.original-2016"
  fi
  cp "$out_scpt" "$target_main"
  echo "  $lib: patched ($changes diff lines)"
done

echo ""
echo "Done. Verify with:"
echo "  osascript -e 'use script \"DC-Keynote\"' -e 'tell script \"DC-Keynote\" to newDefaultDocument()'"
