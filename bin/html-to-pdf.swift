// html-to-pdf — render an HTML file to a properly-formatted PDF via WKWebView's
// createPDF (real CSS: styled headings, bordered tables, fonts — like a browser/Claude,
// NOT monospace). Default: one content-sized page; --paginate: Letter pages for email.
// Uses createPDF (snapshot),
// NOT the print system (which hung + exploded to 520MB). Needs a logged-in GUI session,
// which the Mini's Cloudcity-Boot pane has. Self-built by the html-to-pdf wrapper.
//
//   html-to-pdf <input.html> <output.pdf> [--paginate]
import Foundation
import WebKit
import AppKit
import CoreGraphics

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: html-to-pdf <in.html> <out.pdf>\n".utf8)); exit(2)
}
let html = (try? String(contentsOfFile: args[1], encoding: .utf8)) ?? ""
let outURL = URL(fileURLWithPath: args[2])
let paginate = args.dropFirst(3).contains("--paginate")

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let PAGE_W: CGFloat = 612   // US-Letter width (points)

// REPORT-CARD >> ~/work/convey/features/mail-consolidation.feature
final class Driver: NSObject, WKNavigationDelegate {
    let web = WKWebView(frame: NSRect(x: 0, y: 0, width: PAGE_W, height: 792))
    let out: URL
    init(out: URL) { self.out = out; super.init(); web.navigationDelegate = self }
    func load(_ html: String) { web.loadHTMLString(html, baseURL: nil) }

    // Capture each page separately so invisible off-page text is not duplicated in extraction.
    func paginatedPDF(_ webView: WKWebView, height: CGFloat, cuts: [CGFloat], lines: [CGFloat], links: [[String: Any]]) {
        guard let consumer = CGDataConsumer(url: out as CFURL) else { exit(1) }
        var box = CGRect(x: 0, y: 0, width: PAGE_W, height: 792)
        guard let context = CGContext(consumer: consumer, mediaBox: &box, nil) else { exit(1) }
        let margin: CGFloat = 36
        let capacity: CGFloat = 720
        func capture(_ start: CGFloat) {
            if start >= height { context.closePDF(); exit(0) }
            let target = min(start + capacity, height)
            let eligible = cuts.filter { $0 > start + capacity * 0.65 && $0 <= target }
            let lineEnds = lines.filter { $0 > start + capacity * 0.65 && $0 <= target }
            let end = target < height ? (eligible.max() ?? lineEnds.max() ?? target) : height
            let config = WKPDFConfiguration()
            config.rect = CGRect(x: 0, y: start, width: PAGE_W, height: end - start)
            webView.createPDF(configuration: config) { result in
                guard case .success(let data) = result,
                      let provider = CGDataProvider(data: data as CFData),
                      let document = CGPDFDocument(provider), let page = document.page(at: 1) else { exit(1) }
                context.beginPDFPage(nil)
                context.setFillColor(CGColor(gray: 1, alpha: 1))
                context.fill(box)
                context.saveGState()
                context.translateBy(x: 0, y: 792 - margin - (end - start))
                context.drawPDFPage(page)
                context.restoreGState()
                // Drawing a PDF page preserves vectors/text, but not its link annotations.
                for link in links {
                    guard let address = link["url"] as? String, let url = URL(string: address),
                          let x = (link["x"] as? NSNumber)?.doubleValue,
                          let y = (link["y"] as? NSNumber)?.doubleValue,
                          let width = (link["width"] as? NSNumber)?.doubleValue,
                          let linkHeight = (link["height"] as? NSNumber)?.doubleValue else { continue }
                    let top = max(CGFloat(y), start)
                    let bottom = min(CGFloat(y + linkHeight), end)
                    if bottom > top {
                        context.setURL(url as CFURL, for: CGRect(x: CGFloat(x), y: 792 - margin - (bottom - start),
                                                              width: CGFloat(width), height: bottom - top))
                    }
                }
                context.endPDFPage()
                capture(end)
            }
        }
        capture(0)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // size the page to the full rendered content height, then snapshot to PDF
            let measurement = paginate ? """
                (() => {
                    const body = document.body;
                    const height = Math.ceil(Math.max(body.scrollHeight,
                        body.getBoundingClientRect().bottom + scrollY + parseFloat(getComputedStyle(body).marginBottom)));
                    const cuts = Array.from(body.querySelectorAll('p,li,pre,tr,blockquote')).map(
                        el => Math.ceil(el.getBoundingClientRect().bottom + scrollY) + 1);
                    const lines = [];
                    const walker = document.createTreeWalker(body, NodeFilter.SHOW_TEXT);
                    while (walker.nextNode()) {
                        const range = document.createRange();
                        range.selectNodeContents(walker.currentNode);
                        for (const rect of range.getClientRects()) lines.push(Math.ceil(rect.bottom + scrollY) + 1);
                    }
                    const links = Array.from(body.querySelectorAll('a[href]')).flatMap(a =>
                        Array.from(a.getClientRects()).map(rect => ({url: a.href, x: rect.x, y: rect.y + scrollY,
                            width: rect.width, height: rect.height})));
                    const contentBottom = Math.max(64, ...cuts, ...lines);
                    return { height: Math.min(height, contentBottom + 1), cuts, lines, links };
                })()
                """ : "Math.ceil(document.body.scrollHeight)"
            webView.evaluateJavaScript(measurement) { result, _ in
                let measured = result as? [String: Any]
                let rawHeight = CGFloat((measured?["height"] as? NSNumber)?.doubleValue ?? (result as? NSNumber)?.doubleValue ?? 792)
                // Never truncate a long email PDF silently. Failure becomes an explicit caller notice.
                if paginate && rawHeight > 20000 { exit(1) }
                let h = rawHeight.clamped(64, 20000)
                let cuts = (measured?["cuts"] as? [NSNumber] ?? []).map { CGFloat($0.doubleValue) }
                let lines = (measured?["lines"] as? [NSNumber] ?? []).map { CGFloat($0.doubleValue) }
                let links = measured?["links"] as? [[String: Any]] ?? []
                webView.frame = NSRect(x: 0, y: 0, width: PAGE_W, height: h)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                    if paginate {
                        self.paginatedPDF(webView, height: h, cuts: cuts, lines: lines, links: links)
                        return
                    }
                    let cfg = WKPDFConfiguration()
                    cfg.rect = CGRect(x: 0, y: 0, width: PAGE_W, height: h)
                    webView.createPDF(configuration: cfg) { res in
                        switch res {
                        case .success(let data):
                            do { try data.write(to: self.out); exit(0) } catch { exit(1) }
                        case .failure:
                            exit(1)
                        }
                    }
                }
            }
        }
    }
    func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) { exit(1) }
}
extension CGFloat { func clamped(_ lo: CGFloat, _ hi: CGFloat) -> CGFloat { Swift.min(Swift.max(self, lo), hi) } }

let driver = Driver(out: outURL)
driver.load(html)
DispatchQueue.main.asyncAfter(deadline: .now() + 25) { exit(1) }   // hard timeout — never hang a pane
app.run()
