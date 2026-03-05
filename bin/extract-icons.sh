#!/bin/bash
# Extract Apple app icons as PNG for Loupedeck Live
# Usage: ./bin/extract-icons.sh [options]
#
# Options:
#   --all           Extract all 64 Apple app icons (default)
#   --app NAME      Extract a single app icon by name (e.g. "Photos", "finder", "mail")
#   --open          Open the icons folder in Finder after extraction
#   --size N        Icon size in pixels (default: 256)
#   --dir PATH      Output directory (default: icons)
#
# Examples:
#   ./bin/extract-icons.sh                    # Extract all 64 icons
#   ./bin/extract-icons.sh --app Photos       # Extract just Photos icon
#   ./bin/extract-icons.sh --app mail --open  # Extract Mail icon and open folder
#   ./bin/extract-icons.sh --size 512         # Extract all at 512x512
#
# Two extraction methods:
#   1. sips: For apps with .icns files (most apps)
#   2. Swift/NSWorkspace: For apps using Asset Catalogs (Calendar, System Settings, etc.)

set -euo pipefail

# ─── Defaults ───
OUTPUT_DIR="icons"
ICON_SIZE=256
MODE="all"
TARGET_APP=""
OPEN_AFTER=false

# ─── Parse args ───
while [[ $# -gt 0 ]]; do
    case "$1" in
        --all) MODE="all"; shift ;;
        --app) MODE="single"; TARGET_APP="$2"; shift 2 ;;
        --open) OPEN_AFTER=true; shift ;;
        --size) ICON_SIZE="$2"; shift 2 ;;
        --dir) OUTPUT_DIR="$2"; shift 2 ;;
        *) echo "Unknown option: $1"; exit 1 ;;
    esac
done

mkdir -p "$OUTPUT_DIR"

# ─── App Registry ───
# Format: "output-name|/path/to/App.app|method"
# method: icns (default) or asset (Asset Catalog, needs Swift)
APPS=(
    # System Apps (40)
    "app-store|/System/Applications/App Store.app|icns"
    "automator|/System/Applications/Automator.app|icns"
    "books|/System/Applications/Books.app|icns"
    "calculator|/System/Applications/Calculator.app|icns"
    "calendar|/System/Applications/Calendar.app|asset"
    "chess|/System/Applications/Chess.app|icns"
    "clock|/System/Applications/Clock.app|icns"
    "contacts|/System/Applications/Contacts.app|icns"
    "dictionary|/System/Applications/Dictionary.app|icns"
    "facetime|/System/Applications/FaceTime.app|icns"
    "find-my|/System/Applications/FindMy.app|icns"
    "font-book|/System/Applications/Font Book.app|icns"
    "freeform|/System/Applications/Freeform.app|icns"
    "home|/System/Applications/Home.app|icns"
    "image-capture|/System/Applications/Image Capture.app|icns"
    "launchpad|/System/Applications/Launchpad.app|icns"
    "mail|/System/Applications/Mail.app|icns"
    "maps|/System/Applications/Maps.app|icns"
    "messages|/System/Applications/Messages.app|icns"
    "mission-control|/System/Applications/Mission Control.app|icns"
    "music|/System/Applications/Music.app|icns"
    "news|/System/Applications/News.app|icns"
    "notes|/System/Applications/Notes.app|icns"
    "passwords|/System/Applications/Passwords.app|icns"
    "photo-booth|/System/Applications/Photo Booth.app|asset"
    "photos|/System/Applications/Photos.app|icns"
    "podcasts|/System/Applications/Podcasts.app|icns"
    "preview|/System/Applications/Preview.app|icns"
    "quicktime-player|/System/Applications/QuickTime Player.app|icns"
    "reminders|/System/Applications/Reminders.app|icns"
    "shortcuts|/System/Applications/Shortcuts.app|icns"
    "stickies|/System/Applications/Stickies.app|icns"
    "stocks|/System/Applications/Stocks.app|icns"
    "system-settings|/System/Applications/System Settings.app|asset"
    "textedit|/System/Applications/TextEdit.app|icns"
    "time-machine|/System/Applications/Time Machine.app|icns"
    "tips|/System/Applications/Tips.app|icns"
    "tv|/System/Applications/TV.app|icns"
    "voice-memos|/System/Applications/VoiceMemos.app|asset"
    "weather|/System/Applications/Weather.app|icns"
    # Utilities (16)
    "activity-monitor|/System/Applications/Utilities/Activity Monitor.app|icns"
    "airport-utility|/System/Applications/Utilities/AirPort Utility.app|icns"
    "audio-midi-setup|/System/Applications/Utilities/Audio MIDI Setup.app|icns"
    "bluetooth-file-exchange|/System/Applications/Utilities/Bluetooth File Exchange.app|icns"
    "colorsync-utility|/System/Applications/Utilities/ColorSync Utility.app|icns"
    "console|/System/Applications/Utilities/Console.app|icns"
    "digital-color-meter|/System/Applications/Utilities/Digital Color Meter.app|icns"
    "disk-utility|/System/Applications/Utilities/Disk Utility.app|icns"
    "grapher|/System/Applications/Utilities/Grapher.app|icns"
    "migration-assistant|/System/Applications/Utilities/Migration Assistant.app|asset"
    "screen-sharing|/System/Applications/Utilities/Screen Sharing.app|icns"
    "screenshot|/System/Applications/Utilities/Screenshot.app|icns"
    "script-editor|/System/Applications/Utilities/Script Editor.app|icns"
    "system-information|/System/Applications/Utilities/System Information.app|asset"
    "terminal|/System/Applications/Utilities/Terminal.app|icns"
    "voiceover-utility|/System/Applications/Utilities/VoiceOver Utility.app|icns"
    # Pro Apps + Core (8)
    "finder|/System/Library/CoreServices/Finder.app|icns"
    "safari|/Applications/Safari.app|icns"
    "keynote|/Applications/Keynote.app|icns"
    "numbers|/Applications/Numbers.app|icns"
    "pages|/Applications/Pages.app|icns"
    "final-cut-pro|/Applications/Final Cut Pro.app|icns"
    "logic-pro|/Applications/Logic Pro.app|icns"
    "imovie|/Applications/iMovie.app|icns"
)

# ─── Extract via .icns + sips ───
extract_icns() {
    local app_path="$1"
    local output_name="$2"

    if [ ! -d "$app_path" ]; then
        echo "  SKIP: $output_name (app not found)"
        return 1
    fi

    local icon_file
    icon_file=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIconFile" "$app_path/Contents/Info.plist" 2>/dev/null)
    [ -z "$icon_file" ] && icon_file="AppIcon"
    [[ "$icon_file" != *.icns ]] && icon_file="${icon_file}.icns"

    local icns_path="$app_path/Contents/Resources/$icon_file"
    [ ! -f "$icns_path" ] && icns_path="$app_path/Contents/Resources/AppIcon.icns"

    if [ ! -f "$icns_path" ]; then
        echo "  SKIP: $output_name (no .icns file)"
        return 1
    fi

    local output_path="$OUTPUT_DIR/${output_name}.png"
    sips -s format png -z "$ICON_SIZE" "$ICON_SIZE" "$icns_path" --out "$output_path" > /dev/null 2>&1

    if [ $? -eq 0 ] && [ -f "$output_path" ]; then
        echo "  OK:   $output_name.png"
        return 0
    else
        echo "  FAIL: $output_name (sips conversion failed)"
        return 1
    fi
}

# ─── Extract via NSWorkspace (Asset Catalog apps) ───
extract_asset() {
    local app_path="$1"
    local output_name="$2"
    local output_path="$OUTPUT_DIR/${output_name}.png"

    if [ ! -d "$app_path" ]; then
        echo "  SKIP: $output_name (app not found)"
        return 1
    fi

    swift -e "
import AppKit
let icon = NSWorkspace.shared.icon(forFile: \"$app_path\")
icon.size = NSSize(width: $ICON_SIZE, height: $ICON_SIZE)
guard let cgImage = icon.cgImage(forProposedRect: nil, context: nil, hints: nil) else { exit(1) }
let bitmap = NSBitmapImageRep(cgImage: cgImage)
bitmap.size = icon.size
guard let pngData = bitmap.representation(using: .png, properties: [:]) else { exit(1) }
try! pngData.write(to: URL(fileURLWithPath: \"$output_path\"))
" 2>/dev/null

    if [ $? -eq 0 ] && [ -f "$output_path" ]; then
        echo "  OK:   $output_name.png (asset catalog)"
        return 0
    else
        echo "  FAIL: $output_name (Swift extraction failed)"
        return 1
    fi
}

# ─── Single app mode ───
if [ "$MODE" = "single" ]; then
    # Normalize: lowercase, strip spaces, strip .app
    search=$(echo "$TARGET_APP" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | sed 's/\.app$//')

    found=false
    for entry in "${APPS[@]}"; do
        IFS='|' read -r name path method <<< "$entry"
        # Match against output name or app basename
        app_basename=$(basename "$path" .app | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
        if [[ "$name" == "$search" ]] || [[ "$app_basename" == "$search" ]]; then
            echo "Extracting: $name"
            if [ "$method" = "asset" ]; then
                extract_asset "$path" "$name"
            else
                extract_icns "$path" "$name"
            fi
            found=true
            if [ "$OPEN_AFTER" = true ]; then
                open "$OUTPUT_DIR"
            fi
            break
        fi
    done

    if [ "$found" = false ]; then
        echo "App not found in registry: $TARGET_APP"
        echo "Available apps:"
        for entry in "${APPS[@]}"; do
            IFS='|' read -r name _ _ <<< "$entry"
            echo "  $name"
        done
        exit 1
    fi
    exit 0
fi

# ─── All apps mode ───
echo "=== Extracting Apple App Icons (${ICON_SIZE}x${ICON_SIZE}) ==="
echo "Output: $OUTPUT_DIR/"
echo ""

count=0
fail=0

for entry in "${APPS[@]}"; do
    IFS='|' read -r name path method <<< "$entry"
    if [ "$method" = "asset" ]; then
        extract_asset "$path" "$name" && ((count++)) || ((fail++))
    else
        extract_icns "$path" "$name" && ((count++)) || ((fail++))
    fi
done

echo ""
echo "=== Done: $count extracted, $fail skipped ==="

if [ "$OPEN_AFTER" = true ]; then
    open "$OUTPUT_DIR"
fi
