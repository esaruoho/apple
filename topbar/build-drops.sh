#!/bin/bash
# Build the Finder-toolbar drop-target wrapper apps. Each wrapper is a
# regular (NON-LSUIElement) Cocoa app that exists only to be dragged into
# the Finder toolbar — its single job is to receive a file drop via
# application(_:open:) and forward to a downstream pipeline.
#
# Why wrappers exist: AppleToolbox.app is LSUIElement=true (menu-bar agent,
# no Dock icon). macOS LaunchServices refuses to let LSUIElement apps be
# Finder-toolbar drop targets — drops show the (X) no-drop cursor. The
# wrappers don't set LSUIElement, so they accept drops.
#
# Wrappers built here:
#   - AppleToolboxDrop.app  → forwards path to running AppleToolbox via `open -a`
#   - CloudcityOCRDrop.app  → submits PDF to ~/.claude/skills/bbs/bin/bbs-ocr-submit.sh
#                             (Syncthing route to remote OCR worker)
#
# Apple-native: xcrun swiftc + Cocoa. No Homebrew, no third-party deps.
# Safe to re-run.

set -e

cd "$(dirname "$0")"
INSTALL_DIR="/Applications/AppleToolbox/Apple-Workflows"
LSREG=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister

build_wrapper() {
    local NAME="$1"          # e.g. AppleToolboxDrop
    local BUNDLE_ID="$2"     # e.g. com.esaruoho.appletoolboxdrop
    local DISPLAY="$3"       # e.g. "AppleToolbox Drop"
    local DOC_TYPE_NAME="$4" # e.g. "Any file"
    local DOC_UTIS="$5"      # newline-separated UTIs (rendered into <array>)
    local SRC="drops/${NAME}.swift"
    local APP="${NAME}.app"

    echo "==> Building $NAME ..."
    rm -rf "$APP"
    mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

    xcrun swiftc -O "$SRC" -o "$APP/Contents/MacOS/$NAME" -framework Cocoa

    # Reuse the AppleToolbox icon so the toolbar button is recognisable.
    if [ -f AppleToolbox.icns ]; then
        cp AppleToolbox.icns "$APP/Contents/Resources/${NAME}.icns"
    fi

    local UTI_XML=""
    while IFS= read -r uti; do
        [ -z "$uti" ] && continue
        UTI_XML+="                <string>${uti}</string>
"
    done <<< "$DOC_UTIS"

    cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleName</key><string>${DISPLAY}</string>
    <key>CFBundleDisplayName</key><string>${DISPLAY}</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_ID}</string>
    <key>CFBundleExecutable</key><string>${NAME}</string>
    <key>CFBundleIconFile</key><string>${NAME}</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>12.0</string>
    <key>NSAppleEventsUsageDescription</key><string>${DISPLAY} forwards dropped files to a downstream automation pipeline.</string>
    <key>CFBundleDocumentTypes</key>
    <array>
        <dict>
            <key>CFBundleTypeName</key><string>${DOC_TYPE_NAME}</string>
            <key>CFBundleTypeRole</key><string>Viewer</string>
            <key>LSHandlerRank</key><string>Alternate</string>
            <key>LSItemContentTypes</key>
            <array>
${UTI_XML}            </array>
        </dict>
    </array>
</dict>
</plist>
PLIST
    plutil -lint "$APP/Contents/Info.plist" >/dev/null

    # Stable signing identity preferred; fall back to ad-hoc.
    local SIGN_ID
    SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null \
        | awk '/Apple Development:|Developer ID Application:|AppleToolbox Local Signing/ {print $2; exit}')
    if [ -n "$SIGN_ID" ]; then
        codesign --force --sign "$SIGN_ID" "$APP" 2>&1 | sed 's/^/    /'
    else
        codesign --force --sign - "$APP" 2>&1 | sed 's/^/    /'
    fi

    # Install + LaunchServices refresh so Finder toolbar accepts drops without
    # a stale-cache (X).
    if [ -d "$INSTALL_DIR" ]; then
        local INSTALL_APP="$INSTALL_DIR/$APP"
        rm -rf "$INSTALL_APP"
        cp -R "$APP" "$INSTALL_APP"
        "$LSREG" -f "$APP" >/dev/null 2>&1 || true
        "$LSREG" -f "$INSTALL_APP" >/dev/null 2>&1 || true
        echo "    installed: $INSTALL_APP"
    else
        echo "    install dir missing — built locally only: $(pwd)/$APP"
    fi
}

# ── AppleToolboxDrop: accepts anything, forwards to AppleToolbox ──
build_wrapper \
    "AppleToolboxDrop" \
    "com.esaruoho.appletoolboxdrop" \
    "AppleToolbox Drop" \
    "Any file" \
    "public.item
public.folder"

# ── CloudcityOCRDrop: PDFs only, submits to Cloudcity Syncthing OCR ──
build_wrapper \
    "CloudcityOCRDrop" \
    "com.esaruoho.cloudcityocrdrop" \
    "Cloudcity OCR Drop" \
    "PDF document" \
    "com.adobe.pdf"

echo ""
echo "==> Done. Drag each .app from $INSTALL_DIR into your Finder toolbar (⌘-drag)."
