// Renders the 📱 app icon → AppIcon.iconset (run by build.sh when AppIcon.icns missing)
import Cocoa
let dir = CommandLine.arguments[1]
try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
for (px, name) in [(16,"16x16"),(32,"16x16@2x"),(32,"32x32"),(64,"32x32@2x"),(128,"128x128"),(256,"128x128@2x"),(256,"256x256"),(512,"256x256@2x"),(512,"512x512"),(1024,"512x512@2x")] {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    NSGraphicsContext.saveGraphicsState(); NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    let r = NSRect(x: s*0.06, y: s*0.06, width: s*0.88, height: s*0.88)
    let g = NSGradient(starting: NSColor(calibratedRed: 0.20, green: 0.55, blue: 1.0, alpha: 1), ending: NSColor(calibratedRed: 0.45, green: 0.25, blue: 0.95, alpha: 1))!
    g.draw(in: NSBezierPath(roundedRect: r, xRadius: s*0.2, yRadius: s*0.2), angle: -90)
    let str = NSAttributedString(string: "📲", attributes: [.font: NSFont.systemFont(ofSize: s*0.58)])
    let sz = str.size(); str.draw(at: NSPoint(x: (s-sz.width)/2, y: (s-sz.height)/2 - s*0.02))
    NSGraphicsContext.restoreGraphicsState()
    try! rep.representation(using: .png, properties: [:])!.write(to: URL(fileURLWithPath: "\(dir)/icon_\(name).png"))
}
