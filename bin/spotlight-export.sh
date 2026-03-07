#!/bin/bash
# spotlight-export.sh — Compile workflow scripts to Spotlight-reachable .app bundles
#
# Usage:
#   ./bin/spotlight-export.sh                  # Export all workflows
#   ./bin/spotlight-export.sh finder            # Export one app's workflows
#   ./bin/spotlight-export.sh finder music      # Export specific apps
#   ./bin/spotlight-export.sh --dry-run         # Show what would be exported
#   ./bin/spotlight-export.sh --clean           # Remove all exported apps
#   ./bin/spotlight-export.sh --list            # List currently exported apps
#
# Output: ~/Applications/Apple-Workflows/<App-Action>.app
# Each .app is Spotlight-indexed automatically — Cmd+Space to find and run.
#
# Sal's rule: one button = one action = one result.
# Spotlight's rule: one thought = one search = one launch.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
WORKFLOWS_DIR="$REPO_DIR/scripts/workflows"
EXPORT_DIR="/Applications/Apple-Workflows"

# ─── Helpers ──────────────────────────────────────────────────────────────────

slugToAppName() {
    # finder-copy-path → Finder-Copy-Path
    echo "$1" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1' | sed 's/ /-/g'
}

countApps() {
    if [[ -d "$EXPORT_DIR" ]]; then
        find "$EXPORT_DIR" -name "*.app" -maxdepth 1 | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# ─── Commands ─────────────────────────────────────────────────────────────────

if [[ "${1:-}" == "--clean" ]]; then
    count=$(countApps)
    if [[ "$count" -eq 0 ]]; then
        echo "Nothing to clean — $EXPORT_DIR has no apps"
        exit 0
    fi
    echo "Removing $count apps from $EXPORT_DIR..."
    rm -rf "$EXPORT_DIR"
    echo "Done. Spotlight will de-index them automatically."
    exit 0
fi

if [[ "${1:-}" == "--list" ]]; then
    if [[ ! -d "$EXPORT_DIR" ]]; then
        echo "No exported apps yet. Run: ./bin/spotlight-export.sh"
        exit 0
    fi
    echo "Exported apps in $EXPORT_DIR:"
    for app in "$EXPORT_DIR"/*.app; do
        [[ -e "$app" ]] || continue
        echo "  $(basename "$app" .app)"
    done
    echo ""
    echo "Total: $(countApps) apps"
    exit 0
fi

DRY_RUN=false
if [[ "${1:-}" == "--dry-run" ]]; then
    DRY_RUN=true
    shift
fi

# ─── Filter apps ──────────────────────────────────────────────────────────────

FILTER_APPS=()
for arg in "$@"; do
    FILTER_APPS+=("$(echo "$arg" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')")
done

# ─── Export ───────────────────────────────────────────────────────────────────

if [[ "$DRY_RUN" == false ]]; then
    mkdir -p "$EXPORT_DIR"
fi

echo "═══ Spotlight Export ═══"
echo "Source:  $WORKFLOWS_DIR"
echo "Target:  $EXPORT_DIR"
echo ""

total=0
errors=0

for app_dir in "$WORKFLOWS_DIR"/*/; do
    [[ -d "$app_dir" ]] || continue
    app_slug=$(basename "$app_dir")

    # Filter if specific apps requested
    if [[ ${#FILTER_APPS[@]} -gt 0 ]]; then
        match=false
        for f in "${FILTER_APPS[@]}"; do
            if [[ "$app_slug" == "$f" ]]; then
                match=true
                break
            fi
        done
        [[ "$match" == true ]] || continue
    fi

    app_display=$(echo "$app_slug" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    echo "  $app_display:"

    for script in "$app_dir"/*.applescript; do
        [[ -f "$script" ]] || continue
        basename_no_ext=$(basename "$script" .applescript)
        app_name=$(slugToAppName "$basename_no_ext")
        target="$EXPORT_DIR/$app_name.app"

        if [[ "$DRY_RUN" == true ]]; then
            echo "    [dry-run] $app_name.app"
        else
            if osacompile -o "$target" "$script" 2>/dev/null; then
                # Inject shared CFBundleIdentifier — all apps share one ID so a single
                # TCC "Allow" approval grants Apple Events permission to ALL workflows
                bundle_id="com.esaruoho.apple-workflows"
                /usr/libexec/PlistBuddy -c "Add :CFBundleIdentifier string $bundle_id" "$target/Contents/Info.plist" 2>/dev/null || \
                /usr/libexec/PlistBuddy -c "Set :CFBundleIdentifier $bundle_id" "$target/Contents/Info.plist" 2>/dev/null
                # Set Spotlight comment with keywords for better searchability
                comment=$(head -1 "$script" | sed 's/^-- //')
                osascript -e "tell application \"Finder\" to set comment of (POSIX file \"$target\" as alias) to \"$comment\"" 2>/dev/null || true
                # Register with LaunchServices so Spotlight picks it up
                /System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f "$target" 2>/dev/null || true
                echo "    $app_name.app"
            else
                echo "    $app_name.app [COMPILE ERROR]"
                ((errors++))
            fi
        fi
        ((total++))
    done
done

echo ""
if [[ "$DRY_RUN" == true ]]; then
    echo "═══ Dry run: $total scripts would be exported ═══"
else
    echo "═══ Exported: $total apps ($errors errors) ═══"
    echo "Spotlight will index them within seconds."
    echo "Try: Cmd+Space → type any workflow name"
fi
