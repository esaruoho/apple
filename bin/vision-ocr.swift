// vision-ocr — on-device OCR via Apple's Vision framework (Neural Engine).
//
// No pipeline, no network, no third-party deps: the same OCR macOS uses for
// "Live Text", running on the Apple Silicon Neural Engine. Reads an image or a
// PDF (rendered page-by-page) and prints the recognized text to stdout.
//
// Apple-native: Vision + CoreGraphics + ImageIO + Foundation. Built with
// xcrun swiftc (see the `vision-ocr` wrapper). macOS 13+.
//
// Usage:
//   vision-ocr <file> [--lang en,fi,…] [--fast] [--pages N] [--langs]
//     --lang    comma-separated recognition languages (default: auto)
//     --fast    recognitionLevel .fast (default .accurate)
//     --pages N OCR only the first N pages of a PDF
//     --langs   print the languages Vision supports, then exit

import Foundation
import Vision
import CoreGraphics
import ImageIO

func supportedLanguages() -> [String] {
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .accurate
    return (try? req.supportedRecognitionLanguages()) ?? []
}

func cgImage(fromImageFile url: URL) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func cgImages(fromPDF url: URL, scale: CGFloat, maxPages: Int) -> [CGImage] {
    guard let doc = CGPDFDocument(url as CFURL) else { return [] }
    var out: [CGImage] = []
    let n = maxPages > 0 ? min(maxPages, doc.numberOfPages) : doc.numberOfPages
    for i in 1...max(1, n) {
        guard i <= doc.numberOfPages, let page = doc.page(at: i) else { continue }
        let box = page.getBoxRect(.mediaBox)
        let w = Int(box.width * scale), h = Int(box.height * scale)
        guard w > 0, h > 0,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { continue }
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.scaleBy(x: scale, y: scale)
        ctx.drawPDFPage(page)
        if let img = ctx.makeImage() { out.append(img) }
    }
    return out
}

func recognize(_ image: CGImage, languages: [String], fast: Bool) -> String {
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = fast ? .fast : .accurate
    req.usesLanguageCorrection = !fast
    if !languages.isEmpty { req.recognitionLanguages = languages }
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    do { try handler.perform([req]) } catch { return "" }
    let obs = req.results ?? []
    return obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

// ── args ──
var args = Array(CommandLine.arguments.dropFirst())
func popValue(_ flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i + 1)); return v
}
let wantLangs = args.contains("--langs"); args.removeAll { $0 == "--langs" }
let fast = args.contains("--fast"); args.removeAll { $0 == "--fast" }
let langs = (popValue("--lang") ?? "").split(separator: ",").map { String($0) }
let maxPages = Int(popValue("--pages") ?? "") ?? 0

if wantLangs {
    print(supportedLanguages().joined(separator: "\n"))
    exit(0)
}
guard let path = args.first else {
    FileHandle.standardError.write(Data("usage: vision-ocr <file> [--lang en,fi] [--fast] [--pages N] [--langs]\n".utf8))
    exit(2)
}
let url = URL(fileURLWithPath: path)
let ext = url.pathExtension.lowercased()

var images: [CGImage] = []
if ext == "pdf" {
    images = cgImages(fromPDF: url, scale: 2.0, maxPages: maxPages)   // 2× ≈ 144 dpi
} else if let img = cgImage(fromImageFile: url) {
    images = [img]
}
if images.isEmpty {
    FileHandle.standardError.write(Data("vision-ocr: could not read an image from \(path)\n".utf8))
    exit(1)
}

var pageNo = 0
for img in images {
    pageNo += 1
    if images.count > 1 { print("──── page \(pageNo) ────") }
    print(recognize(img, languages: langs, fast: fast))
}
