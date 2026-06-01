// PanelApp — the Apple Panel as a native Mac app, not a browser tab.
//
// It launches the existing `bin/apple-panel` HTTP server (python stdlib, the
// single source of truth for the capability registry) with --no-open, reads
// the port it actually bound from the server's own stdout, and shows that page
// inside a WKWebView window. So the panel renders as a dedicated .app — a
// webview, not Safari — and the server dies when you close the app.
//
// Apple-native: AppKit + WebKit, compiled with xcrun swiftc, no Xcode, no deps.
// Loopback (127.0.0.1) needs no Local Network entitlement.

import AppKit
import WebKit

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate {
    var window: NSWindow!
    var webView: WKWebView!
    var server: Process?
    private var serverLog = ""
    private var loaded = false

    // Same convention Fleet uses to find the skill's bin/.
    let panelBin = "\(NSHomeDirectory())/work/apple/bin/apple-panel"

    func applicationDidFinishLaunching(_ note: Notification) {
        buildMenu()
        buildWindow()
        startServer()
    }

    // ── window + webview ──
    func buildWindow() {
        let rect = NSRect(x: 0, y: 0, width: 1040, height: 820)
        window = NSWindow(contentRect: rect,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "Apple Panel"
        window.center()
        window.setFrameAutosaveName("ApplePanelWindow")

        webView = WKWebView(frame: rect, configuration: WKWebViewConfiguration())
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")  // match page bg
        window.contentView = webView
        showMessage("Starting Apple Panel…")
        window.makeKeyAndOrderFront(nil)
    }

    func showMessage(_ msg: String) {
        let html = """
        <html><body style="font:15px -apple-system,system-ui;color:#888;
        background:Canvas;display:flex;align-items:center;justify-content:center;
        height:100vh;margin:0"><div>\(msg)</div></body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }

    // ── the panel server as a child process ──
    func startServer() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", panelBin, "--no-open"]
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        server = p

        let handle = pipe.fileHandleForReading
        handle.readabilityHandler = { [weak self] h in
            let data = h.availableData
            guard let self = self, !data.isEmpty,
                  let chunk = String(data: data, encoding: .utf8) else { return }
            self.serverLog += chunk
            if let url = Self.firstLoopbackURL(in: self.serverLog) {
                handle.readabilityHandler = nil  // found it — stop scanning
                DispatchQueue.main.async { self.load(url) }
            }
        }
        do {
            try p.run()
        } catch {
            showMessage("Couldn't start apple-panel:<br>\(error.localizedDescription)")
        }
    }

    /// Pull http://127.0.0.1:PORT/ out of the server's startup banner.
    static func firstLoopbackURL(in s: String) -> URL? {
        guard let r = s.range(of: "http://127.0.0.1:") else { return nil }
        let urlStr = s[r.lowerBound...].prefix { !$0.isWhitespace }
        return URL(string: String(urlStr))
    }

    func load(_ url: URL) {
        loaded = true
        window.title = "Apple Panel — 127.0.0.1:\(url.port ?? 0)"
        webView.load(URLRequest(url: url))
    }

    func reload() { if loaded { webView.reload() } }

    // ── lifecycle ──
    func applicationWillTerminate(_ note: Notification) {
        server?.terminate()
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // ── a minimal menu so ⌘Q / ⌘R / ⌘W work ──
    func buildMenu() {
        let main = NSMenu()

        let appItem = NSMenuItem()
        main.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "About Apple Panel",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Apple Panel",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        let viewItem = NSMenuItem()
        main.addItem(viewItem)
        let viewMenu = NSMenu(title: "View")
        viewItem.submenu = viewMenu
        let reloadItem = NSMenuItem(title: "Reload", action: #selector(reloadAction), keyEquivalent: "r")
        reloadItem.target = self
        viewMenu.addItem(reloadItem)
        let closeItem = NSMenuItem(title: "Close Window",
                                   action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        viewMenu.addItem(closeItem)

        NSApplication.shared.mainMenu = main
    }

    @objc func reloadAction() { reload() }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.activate(ignoringOtherApps: true)
app.run()
