// AppleToolbox.swift
//
// Apple-native menu-bar toolbox. NSStatusItem + NSMenu, no third-party deps.
// Compile: xcrun swiftc -O AppleToolbox.swift -o AppleToolbox -framework Cocoa
// Bundle into AppleToolbox.app with Info.plist LSUIElement=true.
//
// Sections:
//   Live status   — HomePod climate, battery, Sal archive, disk, WiFi, Mail, Now Playing, Whisp queue
//   Quick actions — Stop Voicebox, Empty Trash, Hide/Show Desktop, Hide-Others
//   System ▸      — Dark mode toggle, Lock screen, Sleep, Screenshot ▸, Snap Windows ▸
//   Audio ▸       — Mute / Unmute / Volume presets
//   Finder ▸      — Kill / Show-Hidden / Hide-Hidden / Restart Menu Bar
//   Slashes ▸     — Hey Sal… / Grand Search… / QR… / Wi-Fi QR… / Apple Report / Webcam Photo / Grand Export
//   Refresh, Quit
//
// Refreshes every 5 minutes. Click-prompts via NSAlert (Apple-native input).

import Cocoa
import Foundation

let HOME = NSHomeDirectory()
let TOPBAR = "\(HOME)/work/apple/topbar"
let APPLE_DIR = "\(HOME)/work/apple"
let SCRIPTS = "\(APPLE_DIR)/scripts/workflows/system-events/compiled"

// ─── shell helpers ─────────────────────────────────────────────────────────

@discardableResult
func run(_ path: String, _ args: [String] = [], timeout: TimeInterval = 5) -> String {
    let p = Process()
    p.launchPath = path
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = Pipe()
    do { try p.run() } catch { return "" }
    let group = DispatchGroup()
    group.enter()
    DispatchQueue.global().async {
        p.waitUntilExit()
        group.leave()
    }
    if group.wait(timeout: .now() + timeout) == .timedOut {
        p.terminate()
        return ""
    }
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

func runDetached(_ path: String, _ args: [String] = []) {
    let p = Process()
    p.launchPath = path
    p.arguments = args
    do { try p.run() } catch {}
}

func openFile(_ path: String) {
    runDetached("/usr/bin/open", [path])
}

func notify(_ title: String, _ body: String) {
    runDetached("/usr/bin/osascript", ["-e",
        "display notification \"\(body.replacingOccurrences(of: "\"", with: "\\\""))\" with title \"\(title)\""])
}

// ─── live status readers ───────────────────────────────────────────────────

func climateRead() -> String {
    let dir = "\(HOME)/work/homepod-watcher/climate-logs"
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return "—" }
    let jsonl = files.filter { $0.hasSuffix(".jsonl") }.sorted().reversed()
    guard let latest = jsonl.first,
          let data = try? String(contentsOfFile: "\(dir)/\(latest)", encoding: .utf8),
          let last = data.split(separator: "\n").last else { return "—" }
    let s = String(last)
    func num(_ key: String) -> Double? {
        guard let r = s.range(of: "\"\(key)\":") else { return nil }
        let tail = s[r.upperBound...].drop(while: { $0 == " " })
        let chars = tail.prefix(while: { ("0"..."9").contains($0) || $0 == "." })
        return Double(chars)
    }
    let t = num("temperature_cal") ?? num("temperature_c")
    let h = num("humidity_cal") ?? num("humidity_pct")
    if let t = t, let h = h { return String(format: "%.1f°C  %.0f%% RH", t, h) }
    return "—"
}

func batteryRead() -> String {
    let out = run("/usr/bin/pmset", ["-g", "batt"])
    let pct = out.range(of: #"\d+%"#, options: .regularExpression).map { String(out[$0]) } ?? "—"
    let state = ["charged", "charging", "discharging", "AC attached"].first(where: { out.contains($0) }) ?? ""
    let timeLeft = out.range(of: #"\d+:\d+ remaining"#, options: .regularExpression).map { String(out[$0]) }
    var s = "\(pct) · \(state)"
    if let t = timeLeft { s += "  ·  \(t)" }
    return s
}

func salRead() -> String {
    let status = "\(APPLE_DIR)/analysis/sal/current-status.md"
    runDetached("/usr/bin/python3", ["\(APPLE_DIR)/bin/sal-archive-status.py", "--write", status])
    Thread.sleep(forTimeInterval: 0.3)
    guard let data = try? String(contentsOfFile: status, encoding: .utf8) else { return "—" }
    func first(_ pattern: String) -> String? {
        for line in data.split(separator: "\n").map(String.init) where line.contains(pattern) {
            if let r = line.range(of: #"`\d+`"#, options: .regularExpression) {
                return String(line[r]).replacingOccurrences(of: "`", with: "")
            }
        }
        return nil
    }
    let rec = first("recovered") ?? "?"
    let total = first("targets indexed") ?? "?"
    let miss = first("missing") ?? "0"
    return "\(rec) / \(total) recovered  ·  \(miss) missing"
}

func diskRead() -> String {
    let out = run("/bin/df", ["-h", "/"])
    let lines = out.split(separator: "\n")
    guard lines.count >= 2 else { return "—" }
    let cols = lines[1].split(separator: " ", omittingEmptySubsequences: true).map(String.init)
    guard cols.count >= 5 else { return "—" }
    return "\(cols[3]) free of \(cols[1])  ·  \(cols[4]) used"
}

func wifiRead() -> String {
    let out = run("/usr/sbin/networksetup", ["-getairportnetwork", "en0"])
    if out.contains("not associated") || out.contains("Wi-Fi power is currently off") {
        return out.contains("off") ? "off" : "disconnected"
    }
    if let r = out.range(of: ": ") {
        return String(out[r.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    return out.trimmingCharacters(in: .whitespacesAndNewlines)
}

func mailUnreadRead() -> String? {
    // Read Mail's Envelope Index SQLite directly — works without launching Mail.
    // Path: ~/Library/Mail/V<n>/MailData/Envelope Index. V-number changes across
    // macOS releases, so glob it.
    let mailDir = "\(HOME)/Library/Mail"
    guard let versions = try? FileManager.default.contentsOfDirectory(atPath: mailDir) else { return nil }
    let v = versions.filter { $0.hasPrefix("V") }.sorted().last
    guard let v = v else { return nil }
    let db = "\(mailDir)/\(v)/MailData/Envelope Index"
    guard FileManager.default.fileExists(atPath: db) else { return nil }
    let out = run("/usr/bin/sqlite3", ["-readonly", db,
        "SELECT COALESCE(SUM(unread_count), 0) FROM mailboxes WHERE url LIKE '%INBOX%' OR url LIKE '%inbox%';"], timeout: 2)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let count = Int(out) else { return nil }
    let fmt = NumberFormatter()
    fmt.numberStyle = .decimal
    fmt.groupingSeparator = ","
    return "\(fmt.string(from: NSNumber(value: count)) ?? "\(count)") unread"
}

func nowPlayingRead() -> String? {
    let running = run("/usr/bin/pgrep", ["-x", "Music"]).trimmingCharacters(in: .whitespacesAndNewlines)
    if running.isEmpty { return nil }  // hide the row entirely
    let out = run("/usr/bin/osascript",
        ["-e", "tell application \"Music\" to if player state is playing then return (name of current track) & \" — \" & (artist of current track)"],
        timeout: 3).trimmingCharacters(in: .whitespacesAndNewlines)
    return out.isEmpty ? nil : out
}

func whispQueueRead() -> String {
    let dir = "\(HOME)/work/whisp-transcripts/queue/events"
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return "—" }
    let pending = files.filter { !$0.hasPrefix(".") }.count
    return "\(pending) pending"
}

// ─── menu plumbing ─────────────────────────────────────────────────────────

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            if #available(macOS 11.0, *) {
                button.image = NSImage(systemSymbolName: "wrench.and.screwdriver",
                                       accessibilityDescription: "Apple Toolbox")
            } else {
                button.title = "🧰"
            }
        }
        rebuildMenu()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.rebuildMenu()
        }
    }

    // ─── action dispatch ───────────────────────────────────────────────────

    @objc func runAction(_ sender: NSMenuItem) {
        guard let p = sender.representedObject as? [String: Any],
              let cmd = p["cmd"] as? String else { return }
        let args = p["args"] as? [String] ?? []
        runDetached(cmd, args)
    }

    @objc func runPromptAction(_ sender: NSMenuItem) {
        guard let p = sender.representedObject as? [String: Any],
              let msg = p["message"] as? String,
              let cmd = p["cmd"] as? String else { return }
        let prefix = p["argsPrefix"] as? [String] ?? []
        let suffix = p["argsSuffix"] as? [String] ?? []
        guard let input = promptForText(message: msg), !input.isEmpty else { return }
        runDetached(cmd, prefix + [input] + suffix)
        if let toast = p["toast"] as? String { notify("Apple Toolbox", toast) }
    }

    @objc func runQR(_ sender: NSMenuItem) {
        guard let input = promptForText(message: "QR contents:"), !input.isEmpty else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let out = "\(HOME)/Desktop/qr-\(ts).png"
        runDetached("\(APPLE_DIR)/bin/sal-qr", [input, out])
        Thread.sleep(forTimeInterval: 0.4)
        openFile(out)
    }

    @objc func runWiFiQR(_ sender: NSMenuItem) {
        guard let ssid = promptForText(message: "Wi-Fi SSID:"), !ssid.isEmpty,
              let pw = promptForText(message: "Wi-Fi password (for \(ssid)):"), !pw.isEmpty else { return }
        let ts = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let out = "\(HOME)/Desktop/wifi-\(ssid)-\(ts).png"
        let payload = "WIFI:T:WPA;S:\(ssid);P:\(pw);;"
        runDetached("\(APPLE_DIR)/bin/sal-qr", [payload, out])
        Thread.sleep(forTimeInterval: 0.4)
        openFile(out)
    }

    @objc func runWebcamPhoto(_ sender: NSMenuItem) {
        let ts = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let out = "\(HOME)/Desktop/photo-\(ts).jpg"
        runDetached("\(APPLE_DIR)/bin/sal-take-photo", [out])
        Thread.sleep(forTimeInterval: 1.5)
        openFile(out)
    }

    @objc func runAppleReport(_ sender: NSMenuItem) {
        let ts = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let out = "\(HOME)/Desktop/apple-report-\(ts).txt"
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", "\(APPLE_DIR)/bin/apple-report > \(out) 2>&1"]
        do { try task.run() } catch {}
        DispatchQueue.global().async {
            task.waitUntilExit()
            openFile(out)
        }
    }

    @objc func toggleDarkMode(_ sender: NSMenuItem) {
        runDetached("/usr/bin/osascript", ["-e",
            "tell application \"System Events\" to tell appearance preferences to set dark mode to not dark mode"])
    }

    @objc func screenshotFull(_ sender: NSMenuItem) {
        let out = "\(HOME)/Desktop/screen-\(Int(Date().timeIntervalSince1970)).png"
        runDetached("/usr/sbin/screencapture", [out])
        Thread.sleep(forTimeInterval: 0.5); openFile(out)
    }
    @objc func screenshotSelection(_ sender: NSMenuItem) {
        let out = "\(HOME)/Desktop/screen-\(Int(Date().timeIntervalSince1970)).png"
        runDetached("/usr/sbin/screencapture", ["-i", out])
    }
    @objc func screenshotWindow(_ sender: NSMenuItem) {
        let out = "\(HOME)/Desktop/screen-\(Int(Date().timeIntervalSince1970)).png"
        runDetached("/usr/sbin/screencapture", ["-iW", out])
    }

    @objc func refresh() { rebuildMenu() }
    @objc func quit() { NSApp.terminate(nil) }

    // ─── menu builders ─────────────────────────────────────────────────────

    func action(_ title: String, cmd: String, args: [String] = []) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(runAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = ["cmd": cmd, "args": args]
        return item
    }

    func promptAction(_ title: String, message: String, cmd: String,
                      argsPrefix: [String] = [], argsSuffix: [String] = [], toast: String? = nil) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(runPromptAction(_:)), keyEquivalent: "")
        item.target = self
        var rep: [String: Any] = ["message": message, "cmd": cmd, "argsPrefix": argsPrefix, "argsSuffix": argsSuffix]
        if let toast = toast { rep["toast"] = toast }
        item.representedObject = rep
        return item
    }

    func customAction(_ title: String, selector: Selector) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: selector, keyEquivalent: "")
        item.target = self
        return item
    }

    func header(_ title: String, body: String) -> NSMenuItem {
        let item = NSMenuItem(title: "\(title): \(body)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    func submenu(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let root = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for i in items { sub.addItem(i) }
        root.submenu = sub
        return root
    }

    // ─── NSAlert text prompt ───────────────────────────────────────────────

    func promptForText(message: String) -> String? {
        let alert = NSAlert()
        alert.messageText = "Apple Toolbox"
        alert.informativeText = message
        alert.addButton(withTitle: "OK")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        alert.accessoryView = input
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { alert.window.makeFirstResponder(input) }
        let response = alert.runModal()
        return response == .alertFirstButtonReturn ? input.stringValue : nil
    }

    // ─── the menu ──────────────────────────────────────────────────────────

    func rebuildMenu() {
        let menu = NSMenu()

        // Live status — readers that return nil get their row skipped entirely
        // (no "—" placeholders cluttering the menu).
        func addIf(_ title: String, _ body: String?) {
            if let b = body, !b.isEmpty, b != "—" {
                menu.addItem(header(title, body: b))
            }
        }
        addIf("🌡 Climate", climateRead())
        addIf("🔋 Battery", batteryRead())
        addIf("🗂 Sal",     salRead())
        addIf("💿 Disk",    diskRead())
        addIf("📶 Wi-Fi",   wifiRead())
        addIf("📬 Mail",    mailUnreadRead())
        addIf("🎵 Music",   nowPlayingRead())
        addIf("🎙 Whisp",   whispQueueRead())
        menu.addItem(.separator())

        // Quick actions
        menu.addItem(action("🔇 Stop Voicebox", cmd: "\(HOME)/bin/voicebox-stop"))
        menu.addItem(action("🗑 Empty Trash",
            cmd: "/usr/bin/osascript",
            args: ["-e", "tell application \"Finder\" to empty trash"]))
        menu.addItem(action("👁 Hide Desktop Icons", cmd: "\(TOPBAR)/scripts/hide-desktop.sh"))
        menu.addItem(action("👀 Show Desktop Icons", cmd: "\(TOPBAR)/scripts/show-desktop.sh"))
        menu.addItem(action("🙈 Hide All Other Apps",
            cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/HideAllOthers.scpt"]))
        menu.addItem(.separator())

        // System submenu
        menu.addItem(submenu("System", items: [
            customAction("🌓 Toggle Dark / Light Mode", selector: #selector(toggleDarkMode(_:))),
            action("🔒 Lock Screen", cmd: "/usr/bin/pmset", args: ["displaysleepnow"]),
            action("😴 Sleep Mac",   cmd: "/usr/bin/pmset", args: ["sleepnow"]),
            NSMenuItem.separator(),
            submenu("📸 Screenshot", items: [
                customAction("Full screen → Desktop", selector: #selector(screenshotFull(_:))),
                customAction("Selection (interactive)", selector: #selector(screenshotSelection(_:))),
                customAction("Window (click to choose)", selector: #selector(screenshotWindow(_:))),
            ]),
            submenu("🪟 Snap Windows", items: [
                action("Mosaic (all of front app)",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/MosaicWindows.scpt"]),
                action("Mosaic +1 window",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/MosaicKnob.scpt", "more"]),
                action("Mosaic −1 window",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/MosaicKnob.scpt", "less"]),
            ]),
            action("📋 Restart Menu Bar", cmd: "/usr/bin/killall", args: ["SystemUIServer"]),
        ]))

        // Audio submenu
        menu.addItem(submenu("Audio", items: [
            action("🔇 Mute",       cmd: "/usr/bin/osascript", args: ["-e", "set volume with output muted"]),
            action("🔊 Unmute",     cmd: "/usr/bin/osascript", args: ["-e", "set volume without output muted"]),
            action("🔉 Volume 25%", cmd: "/usr/bin/osascript", args: ["-e", "set volume output volume 25"]),
            action("🔉 Volume 50%", cmd: "/usr/bin/osascript", args: ["-e", "set volume output volume 50"]),
            action("🔊 Volume 75%", cmd: "/usr/bin/osascript", args: ["-e", "set volume output volume 75"]),
        ]))

        // Finder submenu
        menu.addItem(submenu("Finder", items: [
            action("💀 Kill Finder",       cmd: "/usr/bin/killall", args: ["Finder"]),
            action("🫥 Show Hidden Files", cmd: "\(TOPBAR)/scripts/show-hidden.sh"),
            action("🙈 Hide Hidden Files", cmd: "\(TOPBAR)/scripts/hide-hidden.sh"),
        ]))

        // Slashes submenu — Apple-skill verbs as menu items with prompts
        menu.addItem(submenu("Slashes", items: [
            promptAction("🔡 Hey Sal…",
                message: "What do you want?",
                cmd: "\(APPLE_DIR)/bin/hey-sal",
                toast: "Hey Sal routed"),
            promptAction("🔍 Grand Search…",
                message: "Search across all bulk-exporter vaults:",
                cmd: "\(APPLE_DIR)/bin/apple-grand-search"),
            customAction("📷 QR…",                selector: #selector(runQR(_:))),
            customAction("📶 Wi-Fi QR…",          selector: #selector(runWiFiQR(_:))),
            customAction("📸 Webcam Photo",       selector: #selector(runWebcamPhoto(_:))),
            customAction("📊 Apple Report",       selector: #selector(runAppleReport(_:))),
            action("📋 Grand Export (--quick)",
                cmd: "\(APPLE_DIR)/bin/apple-grand-export", args: ["--quick"]),
            action("🔄 Refresh Sal Status",
                cmd: "/usr/bin/python3",
                args: ["\(APPLE_DIR)/bin/sal-archive-status.py", "--write",
                       "\(APPLE_DIR)/analysis/sal/current-status.md"]),
        ]))

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "🔄 Refresh menu", action: #selector(refresh), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let quitItem = NSMenuItem(title: "Quit AppleToolbox", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
    }
}

// ─── entry point ───────────────────────────────────────────────────────────

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)  // no Dock icon — menu bar only
app.run()
