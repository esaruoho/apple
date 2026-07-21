// html-to-png — render an HTML file to a crisp PNG via WKWebView's takeSnapshot
// (real CSS, at the screen's backing scale → Retina 2x on a laptop). Sibling of
// html-to-pdf.swift; same load-then-size-to-content structure, but snapshots a
// bitmap instead of a PDF. One image sized to the full content height. Needs a
// logged-in GUI session. Self-built by the html-to-png wrapper.
//
//   html-to-png <input.html> <output.png>
import Foundation
import WebKit
import AppKit

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: html-to-png <in.html> <out.png>\n".utf8)); exit(2)
}
let html = (try? String(contentsOfFile: args[1], encoding: .utf8)) ?? ""
let outURL = URL(fileURLWithPath: args[2])

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let PAGE_W: CGFloat = 860   // match the report's max-width so nothing is cropped/letterboxed

final class Driver: NSObject, WKNavigationDelegate {
    let web = WKWebView(frame: NSRect(x: 0, y: 0, width: PAGE_W, height: 792))
    let out: URL
    init(out: URL) { self.out = out; super.init(); web.navigationDelegate = self }
    func load(_ html: String) { web.loadHTMLString(html, baseURL: nil) }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            webView.evaluateJavaScript("Math.ceil(document.body.scrollHeight)") { result, _ in
                let h = CGFloat((result as? NSNumber)?.doubleValue ?? 792).clamped(64, 20000)
                webView.frame = NSRect(x: 0, y: 0, width: PAGE_W, height: h)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    let cfg = WKSnapshotConfiguration()
                    cfg.rect = CGRect(x: 0, y: 0, width: PAGE_W, height: h)
                    webView.takeSnapshot(with: cfg) { image, _ in
                        guard let image = image,
                              let tiff = image.tiffRepresentation,
                              let rep = NSBitmapImageRep(data: tiff),
                              let png = rep.representation(using: .png, properties: [:]) else { exit(1) }
                        do { try png.write(to: self.out); exit(0) } catch { exit(1) }
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
DispatchQueue.main.asyncAfter(deadline: .now() + 25) { exit(1) }   // hard timeout — never hang
app.run()
