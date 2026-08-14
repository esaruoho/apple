// Generates phonemirror/AppIcon.icns — a landscape phone with a rotation arc, which is what the
// app does: takes a portrait mirror and turns it the right way up.
// Apple-native: AppKit drawing + iconutil. Run: xcrun swift make-icon.swift

import AppKit

func drawIcon(size S: CGFloat) -> NSBitmapImageRep {
    let px = Int(S)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
                              bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
                              isPlanar: false, colorSpaceName: .deviceRGB,
                              bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let ctx = NSGraphicsContext.current!.cgContext
    ctx.setShouldAntialias(true)

    // macOS app-icon grid: the rounded square is NOT full-bleed. Apple's template puts an
    // 824x824 shape on a 1024x1024 canvas, leaving transparent margin (and room for the shadow).
    // Filling the whole canvas makes the icon read as oversized next to every other Dock icon.
    let M = S * 0.0977                  // 100/1024
    let A = S - 2 * M                   // 824/1024 of the canvas
    let art = NSRect(x: M, y: M, width: A, height: A)
    let cx = art.midX, cy = art.midY

    // Soft contact shadow, as Apple's own icons carry.
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -A * 0.012), blur: A * 0.045,
                  color: NSColor(calibratedWhite: 0, alpha: 0.35).cgColor)
    let shape = NSBezierPath(roundedRect: art, xRadius: A * 0.2248, yRadius: A * 0.2248)
    NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.20, alpha: 1).setFill()
    shape.fill()
    ctx.restoreGState()

    // Background: rounded square, deep slate → blue, like a darkened viewfinder.
    let bg = NSBezierPath(roundedRect: art, xRadius: A * 0.2248, yRadius: A * 0.2248)
    bg.addClip()
    let grad = NSGradient(colors: [NSColor(calibratedRed: 0.10, green: 0.12, blue: 0.20, alpha: 1),
                                   NSColor(calibratedRed: 0.16, green: 0.35, blue: 0.62, alpha: 1)])!
    grad.draw(in: art, angle: 78)

    // Rotation arc, top-left — the gesture of turning the picture upright.
    let arcR = A * 0.40
    let arc = NSBezierPath()
    arc.appendArc(withCenter: NSPoint(x: cx, y: cy),
                  radius: arcR, startAngle: 112, endAngle: 208)
    arc.lineWidth = A * 0.050
    arc.lineCapStyle = .round
    NSColor(calibratedWhite: 1, alpha: 0.80).setStroke()
    arc.stroke()
    // Arrowhead at the arc's end.
    let a = CGFloat(208.0 * .pi / 180.0)
    let tip = NSPoint(x: cx + cos(a) * arcR, y: cy + sin(a) * arcR)
    let head = NSBezierPath()
    head.move(to: NSPoint(x: tip.x - A * 0.070, y: tip.y - A * 0.010))
    head.line(to: NSPoint(x: tip.x + A * 0.025, y: tip.y + A * 0.070))
    head.line(to: NSPoint(x: tip.x + A * 0.040, y: tip.y - A * 0.055))
    head.close()
    NSColor(calibratedWhite: 1, alpha: 0.80).setFill()
    head.fill()

    // The phone, LANDSCAPE — the whole point of the app.
    let pw = A * 0.58, ph = A * 0.375
    let body = NSRect(x: cx - pw / 2, y: cy - ph / 2, width: pw, height: ph)
    let phone = NSBezierPath(roundedRect: body, xRadius: A * 0.055, yRadius: A * 0.055)
    NSColor(calibratedWhite: 0.08, alpha: 0.92).setFill()
    phone.fill()
    NSColor.white.setStroke()
    phone.lineWidth = A * 0.032
    phone.stroke()

    // Screen: a bright viewfinder inset.
    let inset = A * 0.055
    let screen = NSBezierPath(roundedRect: body.insetBy(dx: inset, dy: inset),
                              xRadius: A * 0.022, yRadius: A * 0.022)
    NSGradient(colors: [NSColor(calibratedRed: 0.85, green: 0.90, blue: 0.97, alpha: 1),
                        NSColor(calibratedRed: 0.55, green: 0.68, blue: 0.85, alpha: 1)])!
        .draw(in: screen.bounds, angle: 90)

    NSGraphicsContext.restoreGraphicsState()
    return rep
}

let fm = FileManager.default
let setDir = "AppIcon.iconset"
try? fm.removeItem(atPath: setDir)
try! fm.createDirectory(atPath: setDir, withIntermediateDirectories: true)

// The sizes iconutil expects, including @2x variants.
let specs: [(name: String, px: CGFloat)] = [
    ("icon_16x16.png", 16), ("icon_16x16@2x.png", 32),
    ("icon_32x32.png", 32), ("icon_32x32@2x.png", 64),
    ("icon_128x128.png", 128), ("icon_128x128@2x.png", 256),
    ("icon_256x256.png", 256), ("icon_256x256@2x.png", 512),
    ("icon_512x512.png", 512), ("icon_512x512@2x.png", 1024),
]
for s in specs {
    let rep = drawIcon(size: s.px)
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: URL(fileURLWithPath: "\(setDir)/\(s.name)"))
}
print("wrote \(specs.count) PNGs into \(setDir)")
