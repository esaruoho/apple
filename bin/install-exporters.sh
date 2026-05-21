#!/usr/bin/env bash
# install-exporters.sh — symlink every apple/<name>-exporter/scripts/<name>
# into ~/bin/ so they're callable from any directory. Also symlinks the
# top-level scripts in ~/work/apple/bin/ that are user-facing.
#
# Safe to re-run. Replaces existing symlinks; refuses to overwrite real files.
# ~/bin is already on $PATH via ~/.zshrc.
#
# Usage:
#   ./install-exporters.sh         # install everything
#   ./install-exporters.sh --list  # show what would be linked, don't link
#   ./install-exporters.sh --prune # remove links whose targets no longer exist

set -euo pipefail

APPLE_ROOT="${APPLE_ROOT:-$HOME/work/apple}"
DEST="$HOME/bin"

mkdir -p "$DEST"

mode="${1:-install}"

declare -a TARGETS=()

# Per-exporter packages: <name>-exporter/scripts/<name>-exporter
for dir in "$APPLE_ROOT"/*-exporter; do
    [ -d "$dir" ] || continue
    name="$(basename "$dir")"
    bin="$dir/scripts/$name"
    if [ -x "$bin" ]; then
        TARGETS+=("$bin")
    fi
done

# Top-level user-facing bin/ tools — anything executable that doesn't look
# like a build artifact or a library. Curated rather than auto-discovered
# so we don't shadow common utility names.
USER_FACING_BIN=(
    apple-grand-export
    apple-grand-search
    apple-bootstrap
    apple-report
    apple-summarize
    ask
    hey-sal
    ghc
    invert
    loom-status
    mini-up
    md-to-clipboard
    qr-wifi
    read-aloud
    renoise
    smart
    show
    voicebox-submit
)
for n in "${USER_FACING_BIN[@]}"; do
    bin="$APPLE_ROOT/bin/$n"
    [ -x "$bin" ] && TARGETS+=("$bin")
done

# Mode dispatch -----------------------------------------------------------

if [ "$mode" = "--list" ]; then
    printf 'Would link %d targets into %s/:\n\n' "${#TARGETS[@]}" "$DEST"
    for t in "${TARGETS[@]}"; do
        printf '  %s\n' "$(basename "$t")  →  $t"
    done
    exit 0
fi

if [ "$mode" = "--prune" ]; then
    pruned=0
    for link in "$DEST"/*; do
        [ -L "$link" ] || continue
        target="$(readlink "$link")"
        case "$target" in
            "$APPLE_ROOT"/*)
                if [ ! -e "$target" ]; then
                    echo "prune: $(basename "$link") (target gone)"
                    rm "$link"
                    pruned=$((pruned + 1))
                fi
                ;;
        esac
    done
    echo "pruned $pruned"
    exit 0
fi

# install
installed=0
skipped=0

for t in "${TARGETS[@]}"; do
    name="$(basename "$t")"
    dest="$DEST/$name"
    if [ -L "$dest" ]; then
        rm "$dest"
    elif [ -e "$dest" ]; then
        echo "skip $name (real file exists at $dest)" >&2
        skipped=$((skipped + 1))
        continue
    fi
    ln -s "$t" "$dest"
    installed=$((installed + 1))
done

echo
echo "installed $installed, skipped $skipped → $DEST"
echo "($DEST should already be in PATH via ~/.zshrc:21)"
echo "Open a new shell, or 'hash -r', then try: apps-exporter status"
