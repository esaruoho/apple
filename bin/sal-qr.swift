// Native QR code generator using Core Image's CIQRCodeGenerator.
// Apple-shipped, no dependencies.
//
// Usage: sal-qr "<text>" /path/to/output.png
//
// Reads text as first argument, writes a high-resolution PNG to the second.

import Foundation
import CoreImage
import CoreImage.CIFilterBuiltins
import AppKit

guard CommandLine.arguments.count >= 3 else {
    FileHandle.standardError.write("usage: sal-qr <text> <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let text = CommandLine.arguments[1]
let outURL = URL(fileURLWithPath: CommandLine.arguments[2])

guard let data = text.data(using: .utf8) else {
    FileHandle.standardError.write("text encoding failed\n".data(using: .utf8)!)
    exit(2)
}

let filter = CIFilter.qrCodeGenerator()
filter.message = data
filter.correctionLevel = "M"  // L=7%, M=15%, Q=25%, H=30% — M is the sweet spot

guard let ciImage = filter.outputImage else {
    FileHandle.standardError.write("filter produced no output\n".data(using: .utf8)!)
    exit(3)
}

// Scale up. CIQRCode default output is tiny; scale 10x for crisp PNG.
let scaled = ciImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))

let context = CIContext()
guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else {
    FileHandle.standardError.write("createCGImage failed\n".data(using: .utf8)!)
    exit(4)
}

let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
guard let tiff = nsImage.tiffRepresentation,
      let bitmap = NSBitmapImageRep(data: tiff),
      let png = bitmap.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("png encoding failed\n".data(using: .utf8)!)
    exit(5)
}

do {
    try png.write(to: outURL)
} catch {
    FileHandle.standardError.write("write failed: \(error)\n".data(using: .utf8)!)
    exit(6)
}
