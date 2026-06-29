// html-to-pdf — render an HTML file to a properly-formatted PDF via WKWebView's
// createPDF (real CSS: styled headings, bordered tables, fonts — like a browser/Claude,
// NOT monospace). Produces ONE page sized to the content. Uses createPDF (snapshot),
// NOT the print system (which hung + exploded to 520MB). Needs a logged-in GUI session,
// which the Mini's Cloudcity-Boot pane has. Self-built by the html-to-pdf wrapper.
//
//   html-to-pdf <input.html> <output.pdf>
import Foundation
import WebKit
import AppKit

let args = CommandLine.arguments
guard args.count >= 3 else {
    FileHandle.standardError.write(Data("usage: html-to-pdf <in.html> <out.pdf>\n".utf8)); exit(2)
}
let html = (try? String(contentsOfFile: args[1], encoding: .utf8)) ?? ""
let outURL = URL(fileURLWithPath: args[2])

let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let PAGE_W: CGFloat = 612   // US-Letter width (points)

final class Driver: NSObject, WKNavigationDelegate {
    let web = WKWebView(frame: NSRect(x: 0, y: 0, width: PAGE_W, height: 792))
    let out: URL
    init(out: URL) { self.out = out; super.init(); web.navigationDelegate = self }
    func load(_ html: String) { web.loadHTMLString(html, baseURL: nil) }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            // size the page to the full rendered content height, then snapshot to PDF
            webView.evaluateJavaScript("Math.ceil(document.body.scrollHeight)") { result, _ in
                let h = CGFloat((result as? NSNumber)?.doubleValue ?? 792).clamped(64, 20000)
                webView.frame = NSRect(x: 0, y: 0, width: PAGE_W, height: h)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
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
