// Draws the LiveEnvelopePanel app icon: a dark squircle (echoing Ableton Live's own
// icon proportions and palette, without reproducing its actual wordmark/logo) with an
// original teal step-envelope curve across the middle -- the same shape as the
// breakpoint curves the app itself edits.
//
// usage: swiftc -O -o icongen main.swift && ./icongen /path/to/icon-1024.png

import AppKit

let size = 1024
let outputPath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "icon-1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()
guard let context = NSGraphicsContext.current?.cgContext else { fatalError("no context") }

let canvas = CGRect(x: 0, y: 0, width: size, height: size)

//--------------------------------------------------------------------------------
// Background: a dark squircle, roughly matching Apple's Big Sur+ icon corner radius
// convention (about 22.5% of the edge), filled with a subtle vertical gradient so it
// doesn't read as flat.
//--------------------------------------------------------------------------------
let cornerRadius = CGFloat(size) * 0.225
let backgroundPath = NSBezierPath(roundedRect: canvas, xRadius: cornerRadius, yRadius: cornerRadius)
backgroundPath.addClip()

let gradient = NSGradient(colors: [
    NSColor(calibratedWhite: 0.13, alpha: 1.0),
    NSColor(calibratedWhite: 0.06, alpha: 1.0),
])
gradient?.draw(in: canvas, angle: -90)

//--------------------------------------------------------------------------------
// The step-envelope curve: a horizontal zig-zag of flat segments joined by short
// verticals, exactly the shape Ableton Live draws for a stepped clip envelope. Teal
// against near-black is the same palette this app's own status/curve colours use.
//--------------------------------------------------------------------------------
let margin = CGFloat(size) * 0.18
let curveRect = canvas.insetBy(dx: margin, dy: margin * 1.35)
let steps: [CGFloat] = [0.35, 0.72, 0.5, 0.2, 0.6, 0.42, 0.8]
let stepWidth = curveRect.width / CGFloat(steps.count)

let curve = NSBezierPath()
curve.lineWidth = CGFloat(size) * 0.045
curve.lineCapStyle = .round
curve.lineJoinStyle = .round

func point(_ index: Int, _ level: CGFloat) -> NSPoint {
    NSPoint(x: curveRect.minX + CGFloat(index) * stepWidth,
            y: curveRect.minY + level * curveRect.height)
}

curve.move(to: point(0, steps[0]))
for i in 0..<steps.count {
    let x = curveRect.minX + CGFloat(i + 1) * stepWidth
    curve.line(to: NSPoint(x: x, y: point(i, steps[i]).y))
    if i + 1 < steps.count {
        curve.line(to: NSPoint(x: x, y: point(i + 1, steps[i + 1]).y))
    }
}

//--------------------------------------------------------------------------------
// A soft glow behind the stroke, then the crisp stroke itself on top.
//--------------------------------------------------------------------------------
context.saveGState()
context.setShadow(offset: .zero, blur: CGFloat(size) * 0.05,
                   color: NSColor(calibratedRed: 0.25, green: 0.95, blue: 0.85, alpha: 0.55).cgColor)
NSColor(calibratedRed: 0.30, green: 0.95, blue: 0.85, alpha: 1.0).setStroke()
curve.stroke()
context.restoreGState()

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    fatalError("could not render PNG")
}
try! png.write(to: URL(fileURLWithPath: outputPath))
print("wrote \(outputPath)")
