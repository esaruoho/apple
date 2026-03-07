#!/bin/bash
# batch-import.sh — Import all .shortcut files into Shortcuts.app
#
# Uses AppleScript to:
# 1. Create an "Apple Workflows" folder (or custom name)
# 2. Open each .shortcut file (triggers import dialog)
# 3. Click "Add Shortcut" via UI scripting
# 4. Move each imported shortcut into the folder
#
# Usage:
#   ./bin/batch-import.sh                    # Import all shortcuts
#   ./bin/batch-import.sh finder             # Import one app's shortcuts
#   ./bin/batch-import.sh --dry-run          # Show what would be imported
#   ./bin/batch-import.sh --count            # Count available shortcuts
#   ./bin/batch-import.sh --folder "My Name" # Custom folder name
#
# Prerequisites:
#   - Shortcuts must be generated first: python3 bin/shortcut-gen.py
#   - Shortcuts.app → Settings → Advanced → Allow Running Scripts
#   - Terminal/iTerm MUST have Accessibility permission:
#     System Settings → Privacy & Security → Accessibility → add Terminal.app (or iTerm.app)

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SHORTCUTS_DIR="$REPO_DIR/shortcuts"
FOLDER_NAME="Apple Workflows"

if [[ ! -d "$SHORTCUTS_DIR" ]]; then
    echo "No shortcuts directory. Run: python3 bin/shortcut-gen.py"
    exit 1
fi

# ─── Parse args ───────────────────────────────────────────────────────────────

FILTER_APPS=()
DRY_RUN=false
COUNT_ONLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dry-run)  DRY_RUN=true; shift ;;
        --count)    COUNT_ONLY=true; shift ;;
        --folder)   FOLDER_NAME="$2"; shift 2 ;;
        *)          FILTER_APPS+=("$(echo "$1" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')"); shift ;;
    esac
done

# ─── Count mode ───────────────────────────────────────────────────────────────

if $COUNT_ONLY; then
    total=$(find "$SHORTCUTS_DIR" -name "*.shortcut" ! -name "*.unsigned*" | wc -l | tr -d ' ')
    echo "$total shortcuts available for import"
    for app_dir in "$SHORTCUTS_DIR"/*/; do
        [[ -d "$app_dir" ]] || continue
        count=$(find "$app_dir" -name "*.shortcut" ! -name "*.unsigned*" | wc -l | tr -d ' ')
        [[ "$count" -gt 0 ]] && echo "  $(basename "$app_dir"): $count"
    done
    exit 0
fi

# ─── Dry run mode ─────────────────────────────────────────────────────────────

if $DRY_RUN; then
    echo "Would import into folder '$FOLDER_NAME':"
    for app_dir in "$SHORTCUTS_DIR"/*/; do
        [[ -d "$app_dir" ]] || continue
        app_slug=$(basename "$app_dir")
        if [[ ${#FILTER_APPS[@]} -gt 0 ]]; then
            match=false
            for f in "${FILTER_APPS[@]}"; do [[ "$app_slug" == "$f" ]] && match=true && break; done
            $match || continue
        fi
        for sc in "$app_dir"/*.shortcut; do
            [[ -f "$sc" ]] || continue
            [[ "$sc" == *".unsigned."* ]] && continue
            echo "  $(basename "$sc" .shortcut)"
        done
    done
    total=$(find "$SHORTCUTS_DIR" -name "*.shortcut" ! -name "*.unsigned*" | wc -l | tr -d ' ')
    echo ""
    echo "Total: $total shortcuts"
    exit 0
fi

# ─── Import ───────────────────────────────────────────────────────────────────

echo "═══ Batch Shortcut Import ═══"
echo ""
echo "Folder:  $FOLDER_NAME"
echo ""

# Create the folder in Shortcuts.app (idempotent)
echo "Creating folder '$FOLDER_NAME'..."
osascript -e "
tell application \"Shortcuts\"
    try
        get folder \"$FOLDER_NAME\"
    on error
        make new folder with properties {name:\"$FOLDER_NAME\"}
    end try
end tell
" 2>/dev/null || true

# Get list of already-imported shortcuts
existing_shortcuts=$(shortcuts list 2>/dev/null || true)

total=0
imported=0
skipped=0
errors=0
moved=0

for app_dir in "$SHORTCUTS_DIR"/*/; do
    [[ -d "$app_dir" ]] || continue
    app_slug=$(basename "$app_dir")

    if [[ ${#FILTER_APPS[@]} -gt 0 ]]; then
        match=false
        for f in "${FILTER_APPS[@]}"; do [[ "$app_slug" == "$f" ]] && match=true && break; done
        $match || continue
    fi

    app_display=$(echo "$app_slug" | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)}1')
    echo ""
    echo "  $app_display:"

    for sc in "$app_dir"/*.shortcut; do
        [[ -f "$sc" ]] || continue
        [[ "$sc" == *".unsigned."* ]] && continue
        ((total++))

        name=$(basename "$sc" .shortcut)

        # Check if already imported
        if echo "$existing_shortcuts" | grep -qi "^${name}$"; then
            echo "    $name [already imported]"
            ((skipped++))
            # Still move to folder in case it's not there yet
            osascript -e "
tell application \"Shortcuts\"
    try
        set folder of shortcut \"$name\" to folder \"$FOLDER_NAME\"
    end try
end tell
" 2>/dev/null || true
            ((moved++))
            continue
        fi

        # Open the .shortcut file — triggers import dialog
        open "$sc"
        sleep 2

        # UI script: click "Add Shortcut" button, or "Replace" if duplicate
        click_result=$(osascript -e '
tell application "Shortcuts"
    activate
end tell
delay 0.5
tell application "System Events"
    tell process "Shortcuts"
        set frontmost to true
        delay 0.3
        -- First try the normal "Add Shortcut" button in import preview
        try
            click button 2 of scroll area 1 of group 1 of window 1
            delay 1
            -- Check if a "Replace" dialog appeared (for duplicates)
            try
                click button "Replace" of window 1
                return "replaced"
            end try
            return "ok"
        on error
            try
                click button 1 of scroll area 1 of group 1 of window 1
                delay 1
                try
                    click button "Replace" of window 1
                    return "replaced"
                end try
                return "ok"
            on error
                -- Maybe the Replace dialog is already showing
                try
                    click button "Replace" of window 1
                    return "replaced"
                on error
                    try
                        -- Look through all windows for Replace or Add
                        repeat with w in windows
                            try
                                click (first button whose name contains "Replace") of w
                                return "replaced"
                            end try
                            try
                                click (first button whose name contains "Add") of w
                                return "ok"
                            end try
                        end repeat
                        return "no-button"
                    on error errMsg
                        return "error: " & errMsg
                    end try
                end try
            end try
        end try
    end tell
end tell
' 2>/dev/null || echo "error")

        if [[ "$click_result" == "ok" ]]; then
            sleep 0.5
            # Move to folder
            osascript -e "
tell application \"Shortcuts\"
    try
        set folder of shortcut \"$name\" to folder \"$FOLDER_NAME\"
    end try
end tell
" 2>/dev/null || true
            echo "    $name"
            ((imported++))
            ((moved++))
        else
            echo "    $name [IMPORT ERROR: $click_result]"
            ((errors++))
        fi

        sleep 0.3
    done
done

echo ""
echo "═══ Import complete ═══"
echo "  Imported: $imported"
echo "  Skipped:  $skipped (already existed)"
echo "  Moved:    $moved (to '$FOLDER_NAME')"
echo "  Errors:   $errors"
echo "  Total:    $total"
