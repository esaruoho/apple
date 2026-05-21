#!/bin/bash
# Generate AppleToolbox.icns — black background, white Apple-logo glyph.
#
# Uses U+F8FF (the Apple-logo character in San Francisco / system fonts) drawn
# via AppKit, then iconutil to compile the .iconset into a real .icns. Pure
# Apple-native pipeline — xcrun swift + iconutil, both shipped with the OS.
#
# Safe to re-run. Output: topbar/AppleToolbox.icns

set -e
cd "$(dirname "$0")/.."
ICONSET="AppleToolbox.iconset"
OUT="AppleToolbox.icns"

rm -rf "$ICONSET" "$OUT"
mkdir -p "$ICONSET"

render() {
    local size=$1
    local out=$2
    xcrun swift - "$size" "$out" <<'SWIFT'
import Cocoa
let size = CGFloat(Int(CommandLine.arguments[1])!)
let outPath = CommandLine.arguments[2]

let img = NSImage(size: NSSize(width: size, height: size))
img.lockFocus()

// Transparent canvas + inset shape — matches the macOS Big Sur+ icon spec
// (icon body sits in ~80% of the canvas with rounded corners), so this icon
// lines up visually with System Settings, Safari, Mail, etc. in the Dock.
let inset = size * 0.098                         // ~10% padding around the shape
let shape = NSRect(x: inset, y: inset,
                   width: size - 2 * inset,
                   height: size - 2 * inset)
let radius = shape.width * 0.2237                // standard macOS corner radius

// Subtle vertical gradient: pure black at top, very slight grey lift at the
// bottom. Gives the badge a hint of depth without crushing the white logo.
let bg = NSBezierPath(roundedRect: shape, xRadius: radius, yRadius: radius)
bg.addClip()
let gradient = NSGradient(colors: [
    NSColor.black,
    NSColor(white: 0.08, alpha: 1.0),
])!
gradient.draw(in: shape, angle: -90)

// Apple-logo glyph U+F8FF, drawn via CoreText so we can measure the *inked*
// glyph bounds (not the font's line box) and place the optical centre at the
// shape's midpoint. Two-pass sizing: probe glyph at size 100, then scale the
// font so the glyph height fills ~78% of the shape.
let chars: [UniChar] = Array("\u{F8FF}".utf16)
let probeFont = NSFont.systemFont(ofSize: 100) as CTFont
var probeGlyph: CGGlyph = 0
CTFontGetGlyphsForCharacters(probeFont, chars, &probeGlyph, 1)
var probeRect = CGRect.zero
CTFontGetBoundingRectsForGlyphs(probeFont, .default, &probeGlyph, &probeRect, 1)

let targetHeight = shape.height * 0.78
let pointSize = targetHeight * 100 / probeRect.height

let font = NSFont.systemFont(ofSize: pointSize) as CTFont
var glyph: CGGlyph = 0
CTFontGetGlyphsForCharacters(font, chars, &glyph, 1)
var glyphRect = CGRect.zero
CTFontGetBoundingRectsForGlyphs(font, .default, &glyph, &glyphRect, 1)

// CTFontDrawGlyphs takes baseline-origin positions; we solve for the baseline
// such that glyphRect's centre lands exactly on shape's centre.
let drawX = shape.midX - glyphRect.midX
let drawY = shape.midY - glyphRect.midY

let ctx = NSGraphicsContext.current!.cgContext
ctx.saveGState()
ctx.setFillColor(NSColor.white.cgColor)
var glyphArr = [glyph]
var positions = [CGPoint(x: drawX, y: drawY)]
CTFontDrawGlyphs(font, &glyphArr, &positions, 1, ctx)
ctx.restoreGState()

img.unlockFocus()

guard let tiff = img.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let data = rep.representation(using: .png, properties: [:]) else {
    fputs("PNG encode failed at \(Int(size))px\n", stderr)
    exit(2)
}
try data.write(to: URL(fileURLWithPath: outPath))
SWIFT
}

render 16   "$ICONSET/icon_16x16.png"
render 32   "$ICONSET/icon_16x16@2x.png"
render 32   "$ICONSET/icon_32x32.png"
render 64   "$ICONSET/icon_32x32@2x.png"
render 128  "$ICONSET/icon_128x128.png"
render 256  "$ICONSET/icon_128x128@2x.png"
render 256  "$ICONSET/icon_256x256.png"
render 512  "$ICONSET/icon_256x256@2x.png"
render 512  "$ICONSET/icon_512x512.png"
render 1024 "$ICONSET/icon_512x512@2x.png"

iconutil -c icns "$ICONSET" -o "$OUT"
rm -rf "$ICONSET"

echo "Built: $(pwd)/$OUT ($(du -h "$OUT" | cut -f1))"
