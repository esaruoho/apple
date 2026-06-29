// text-to-pdf — render UTF-8 text (markdown lightly cleaned to readable text) into a
// paginated US-Letter PDF using PURE Core Text + Core Graphics. No WebKit, no AppKit,
// no GUI session — so it works headless in a Cloudcity-Boot pane. Monospace (Menlo)
// keeps tables and code aligned. Self-built by the `text-to-pdf` wrapper (like vision-ocr).
//
//   text-to-pdf <input.txt> <output.pdf> [--title "..."]
import Foundation
import CoreGraphics
import CoreText

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: text-to-pdf <in.txt> <out.pdf> [--title T]\n".utf8)); exit(2)
}
var text = (try? String(contentsOfFile: args[1], encoding: .utf8)) ?? ""
var title = ""
if let ti = args.firstIndex(of: "--title"), ti+1 < args.count { title = args[ti+1] }
if !title.isEmpty { text = title + "\n" + String(repeating: "=", count: min(title.count, 72)) + "\n\n" + text }

let pageW: CGFloat = 612, pageH: CGFloat = 792, margin: CGFloat = 50
let textRect = CGRect(x: margin, y: margin, width: pageW - 2*margin, height: pageH - 2*margin)

let font = CTFontCreateWithName("Menlo" as CFString, 9.5, nil)
// PURE Core Text attributes only — no NSParagraphStyle (that would pull in AppKit/GUI).
let attrs: [NSAttributedString.Key: Any] = [
    NSAttributedString.Key(kCTFontAttributeName as String): font,
    NSAttributedString.Key(kCTForegroundColorAttributeName as String): CGColor(gray: 0.0, alpha: 1.0)
]
let attr = NSAttributedString(string: text.isEmpty ? "(empty)" : text, attributes: attrs)

let pdf = NSMutableData()
var box = CGRect(x: 0, y: 0, width: pageW, height: pageH)
guard let consumer = CGDataConsumer(data: pdf as CFMutableData),
      let ctx = CGContext(consumer: consumer, mediaBox: &box, nil) else { exit(1) }
let fs = CTFramesetterCreateWithAttributedString(attr)
let total = attr.length
var loc = 0
repeat {
    ctx.beginPDFPage(nil)
    let path = CGPath(rect: textRect, transform: nil)
    let frame = CTFramesetterCreateFrame(fs, CFRange(location: loc, length: 0), path, nil)
    CTFrameDraw(frame, ctx)
    let vis = CTFrameGetVisibleStringRange(frame)
    if vis.length <= 0 { ctx.endPDFPage(); break }   // safety: avoid infinite loop
    loc += vis.length
    ctx.endPDFPage()
} while loc < total
ctx.closePDF()
do { try (pdf as Data).write(to: URL(fileURLWithPath: args[2])) } catch { exit(1) }
