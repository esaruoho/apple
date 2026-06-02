// pdf-textlen — print the extractable text-layer length of each PDF, via PDFKit
// (Apple-native, on-device, no third-party deps). Used by ocr-triage to find
// image-only PDFs (little/no text layer) that need OCR.
//
// For image-only DETECTION we don't need the whole text — just whether a text
// layer exists — so we sample only the first few pages. This avoids PDFKit
// ballooning memory on 700–1000-page scans (which was killing batch runs).
//
// Output, one tab-separated line per input path:
//   OK\t<pages>\t<sampledPages>\t<chars>\t<path>     parsed
//   ERR\t0\t0\t0\t<path>                             could not open
import Foundation
import PDFKit

let SAMPLE = 5   // pages to read for text

for path in CommandLine.arguments.dropFirst() {
    guard let doc = PDFDocument(url: URL(fileURLWithPath: path)) else {
        print("ERR\t0\t0\t0\t\(path)")
        continue
    }
    let pages = doc.pageCount
    let sampled = min(SAMPLE, pages)
    var chars = 0
    for i in 0..<sampled {
        if let s = doc.page(at: i)?.string {
            chars += s.trimmingCharacters(in: .whitespacesAndNewlines).count
        }
    }
    print("OK\t\(pages)\t\(sampled)\t\(chars)\t\(path)")
}
