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
//   vision-ocr <file> [--lang en,fi,…] [--fast] [--pages N] [--langs] [--barcodes]
//     --barcodes  detect QR / barcodes (VNDetectBarcodes) instead of text; prints
//                 "<symbology>\t<payload>" per code. Same owned Vision capability.
//     --lang    comma-separated recognition languages (default: auto)
//     --fast    recognitionLevel .fast (default .accurate)
//     --pages N OCR only the first N pages of a PDF
//     --langs   print the languages Vision supports, then exit

import Foundation
import Vision
import CoreGraphics
import ImageIO

func supportedLanguages() -> [String] {
    // The deprecated instance method returns [] on recent macOS; the static
    // per-revision API is the current one.
    return (try? VNRecognizeTextRequest.supportedRecognitionLanguages(
        for: .accurate, revision: VNRecognizeTextRequest.currentRevision)) ?? []
}

func cgImage(fromImageFile url: URL) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func cgImages(fromPDF url: URL, minScale: CGFloat, maxPages: Int) -> [CGImage] {
    guard let doc = CGPDFDocument(url as CFURL) else { return [] }
    var out: [CGImage] = []
    let n = maxPages > 0 ? min(maxPages, doc.numberOfPages) : doc.numberOfPages
    for i in 1...max(1, n) {
        guard i <= doc.numberOfPages, let page = doc.page(at: i) else { continue }
        let box = page.getBoxRect(.mediaBox)
        // Render to a TARGET resolution, not a fixed multiple of the page's
        // points: small-page PDFs (e.g. a 363pt Dover book) come out too low-res
        // for OCR at a flat 2×. Scale so the long edge is ~2200px.
        let target: CGFloat = 2200
        let scale = max(minScale, target / max(box.width, box.height))
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

// Some macOS builds (e.g. 27 beta with un-activated E5 model assets) print Vision
// model-loading errors to STDOUT ("Unable to find a valid E5 in provided path …"),
// which would corrupt our text output. Run the request with fd 1 redirected to
// /dev/null, then restore it — so only OUR print of the recognized text reaches stdout.
func suppressingStdout<T>(_ body: () -> T) -> T {
    fflush(stdout)
    let saved = dup(1)
    let devnull = open("/dev/null", O_WRONLY)
    if devnull >= 0 { dup2(devnull, 1); close(devnull) }
    let r = body()
    fflush(stdout)
    if saved >= 0 { dup2(saved, 1); close(saved) }
    return r
}

func recognize(_ image: CGImage, languages: [String], fast: Bool) -> String {
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = fast ? .fast : .accurate
    req.usesLanguageCorrection = !fast
    if !languages.isEmpty { req.recognitionLanguages = languages }
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    let ok = suppressingStdout { (try? handler.perform([req])) != nil }
    if !ok { return "" }
    let obs = req.results ?? []
    return obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

func detectBarcodes(_ image: CGImage) -> String {
    let req = VNDetectBarcodesRequest()              // all symbologies (QR, EAN, Code128, …)
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    do { try handler.perform([req]) } catch { return "" }
    return (req.results ?? []).compactMap { b -> String? in
        guard let payload = b.payloadStringValue else { return nil }
        let sym = b.symbology.rawValue.replacingOccurrences(of: "VNBarcodeSymbology", with: "")
        return "\(sym)\t\(payload)"
    }.joined(separator: "\n")
}

func classify(_ image: CGImage) -> String {
    let req = VNClassifyImageRequest()               // "what is this image" labels
    let handler = VNImageRequestHandler(cgImage: image, options: [:])
    do { try handler.perform([req]) } catch { return "" }
    let obs = (req.results ?? []).filter { $0.confidence > 0.1 }.prefix(12)
    return obs.map { String(format: "%@\t%.2f", $0.identifier, $0.confidence) }.joined(separator: "\n")
}

// ── args ──
var args = Array(CommandLine.arguments.dropFirst())
func popValue(_ flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i + 1)); return v
}
let wantLangs = args.contains("--langs"); args.removeAll { $0 == "--langs" }
let fast = args.contains("--fast"); args.removeAll { $0 == "--fast" }
let wantBarcodes = args.contains("--barcodes") || args.contains("--qr"); args.removeAll { $0 == "--barcodes" || $0 == "--qr" }
let wantClassify = args.contains("--classify"); args.removeAll { $0 == "--classify" }
let langs = (popValue("--lang") ?? "").split(separator: ",").map { String($0) }
let maxPages = Int(popValue("--pages") ?? "") ?? 0

if wantLangs {
    print(supportedLanguages().joined(separator: "\n"))
    exit(0)
}
guard let path = args.first else {
    FileHandle.standardError.write(Data("usage: vision-ocr <file> [--lang en,fi] [--fast] [--pages N] [--langs] [--barcodes] [--classify]\n".utf8))
    exit(2)
}
let url = URL(fileURLWithPath: path)
let ext = url.pathExtension.lowercased()

var images: [CGImage] = []
if ext == "pdf" {
    images = cgImages(fromPDF: url, minScale: 2.0, maxPages: maxPages)   // ≥2×, scaled up to ~2200px long edge
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
    let out: String
    if wantClassify { out = classify(img) }
    else if wantBarcodes { out = detectBarcodes(img) }
    else { out = recognize(img, languages: langs, fast: fast) }
    print(out)
}
