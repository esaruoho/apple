// REPORT-CARD >> features/aimeat-email-pdf.feature
// Read every PDF page, streaming one rendered page at a time for bounded memory.
import Foundation
import PDFKit
import Vision
import AppKit

do {
    guard CommandLine.arguments.count == 2 else { throw NSError(domain: "PDF path required", code: 1) }
    let path = CommandLine.arguments[1]
    guard let doc = PDFDocument(url: URL(fileURLWithPath: path)), !doc.isLocked, doc.pageCount > 0 else {
        throw NSError(domain: "Unreadable, locked or empty PDF", code: 2)
    }
    var pages: [[String: Any]] = []
    for index in 0..<doc.pageCount {
        let result: [String: Any] = try autoreleasepool {
            guard let page = doc.page(at: index) else { throw NSError(domain: "Missing PDF page", code: index+1) }
            let native = (page.string ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            if native.count >= 40 && !native.contains("\u{FFFD}") {
                return ["number": index+1, "method": "embedded-text", "text": native]
            }
            let box = page.bounds(for: .mediaBox)
            let scale = min(4.0, 2400 / max(box.width, box.height))
            let image = page.thumbnail(of: NSSize(width: box.width*scale, height: box.height*scale), for: .mediaBox)
            guard let cg = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
                throw NSError(domain: "Page rendering failed", code: index+1)
            }
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            try VNImageRequestHandler(cgImage: cg).perform([request])
            let text = (request.results ?? []).compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
            return ["number": index+1, "method": "vision-ocr", "text": text.isEmpty ? native : text]
        }
        pages.append(result)
    }
    let data = try JSONSerialization.data(withJSONObject: ["page_count": doc.pageCount, "pages": pages], options: [.prettyPrinted, .sortedKeys])
    try data.write(to: URL(fileURLWithPath: path+".pages.json"), options: .atomic)
} catch {
    FileHandle.standardError.write(Data("mail-pdf-text: \(error)\n".utf8))
    exit(1)
}
