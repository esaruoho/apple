import Foundation
import CoreImage
import AppKit

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write("usage: swift invert-images.swift <inDir> <outDir> [gamma=6.0] [contrast=2.0]\n".data(using: .utf8)!)
    exit(2)
}
let inDir = args[1]
let outDir = args[2]
let gamma = args.count >= 4 ? (Double(args[3]) ?? 6.0) : 6.0
let contrast = args.count >= 5 ? (Double(args[4]) ?? 2.0) : 2.0
let fm = FileManager.default
try? fm.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let ctx = CIContext()

let exts: Set<String> = ["png", "jpg", "jpeg", "tiff", "heic"]
let files = (try fm.contentsOfDirectory(atPath: inDir))
    .filter { exts.contains(($0 as NSString).pathExtension.lowercased()) }
    .sorted()

var ok = 0, fail = 0
for name in files {
    let inPath = (inDir as NSString).appendingPathComponent(name)
    let outPath = (outDir as NSString).appendingPathComponent(name)
    guard var img = CIImage(contentsOf: URL(fileURLWithPath: inPath)) else {
        fail += 1; print("FAIL load: \(name)"); continue
    }
    let inv = CIFilter(name: "CIColorInvert")!
    inv.setValue(img, forKey: kCIInputImageKey)
    img = inv.outputImage!

    let gam = CIFilter(name: "CIGammaAdjust")!
    gam.setValue(img, forKey: kCIInputImageKey)
    gam.setValue(NSNumber(value: gamma), forKey: "inputPower")
    img = gam.outputImage!

    let con = CIFilter(name: "CIColorControls")!
    con.setValue(img, forKey: kCIInputImageKey)
    con.setValue(NSNumber(value: contrast), forKey: kCIInputContrastKey)
    con.setValue(NSNumber(value: 1.0), forKey: kCIInputSaturationKey)
    con.setValue(NSNumber(value: 0.0), forKey: kCIInputBrightnessKey)
    img = con.outputImage!

    let cs = CGColorSpace(name: CGColorSpace.sRGB)!
    do {
        try ctx.writePNGRepresentation(of: img, to: URL(fileURLWithPath: outPath), format: .RGBA8, colorSpace: cs)
        ok += 1
    } catch {
        fail += 1; print("FAIL write \(name): \(error)")
    }
}
print("done: \(ok) ok, \(fail) fail, gamma=\(gamma) contrast=\(contrast) -> \(outDir)")
