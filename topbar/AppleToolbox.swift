// AppleToolbox.swift
//
// Apple-native menu-bar toolbox. NSStatusItem + NSMenu, no third-party deps.
// Compile: xcrun swiftc AppleToolbox.swift -o AppleToolbox -framework Cocoa
// Bundle into AppleToolbox.app with Info.plist LSUIElement=true (no Dock icon).
//
// One 🧰 in the menu bar. Dropdown shows:
//   - HomePod climate (read from ~/work/homepod-watcher/climate-logs/*.jsonl)
//   - Battery (pmset -g batt)
//   - Sal archive (regenerate current-status.md + parse)
//   - Stop Voicebox, Empty Trash, Desktop Icons, Audio ▸, Finder ▸
//   - Refresh, Quit
//
// Refreshes every 5 minutes. No external runtime — just /usr/bin/swift.

import Cocoa
import Foundation

let HOME = NSHomeDirectory()
let TOPBAR = "\(HOME)/work/apple/topbar"
let APPLE_DIR = "\(HOME)/work/apple"

// ─── shell helpers ─────────────────────────────────────────────────────────

@discardableResult
func run(_ path: String, _ args: [String] = []) -> String {
    let p = Process()
    p.launchPath = path
    p.arguments = args
    let pipe = Pipe()
    p.standardOutput = pipe
    p.standardError = Pipe()
    do { try p.run() } catch { return "" }
    p.waitUntilExit()
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}

func runDetached(_ path: String, _ args: [String] = []) {
    let p = Process()
    p.launchPath = path
    p.arguments = args
    do { try p.run() } catch {}
}

// ─── data readers ──────────────────────────────────────────────────────────

func climateRead() -> String {
    let dir = "\(HOME)/work/homepod-watcher/climate-logs"
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return "—" }
    let jsonl = files.filter { $0.hasSuffix(".jsonl") }.sorted().reversed()
    guard let latest = jsonl.first else { return "—" }
    let path = "\(dir)/\(latest)"
    guard let data = try? String(contentsOfFile: path, encoding: .utf8) else { return "—" }
    let lines = data.split(separator: "\n")
    guard let last = lines.last else { return "—" }
    let s = String(last)
    func num(_ key: String) -> Double? {
        guard let r = s.range(of: "\"\(key)\":") else { return nil }
        let tail = s[r.upperBound...].drop(while: { $0 == " " })
        let numChars = tail.prefix(while: { ("0"..."9").contains($0) || $0 == "." })
        return Double(numChars)
    }
    let t = num("temperature_cal") ?? num("temperature_c")
    let h = num("humidity_cal") ?? num("humidity_pct")
    if let t = t, let h = h {
        return String(format: "%.1f°C  %.0f%% RH", t, h)
    }
    return "—"
}

func batteryRead() -> String {
    let out = run("/usr/bin/pmset", ["-g", "batt"])
    let pct = out.range(of: #"\d+%"#, options: .regularExpression).map { String(out[$0]) } ?? "—"
    let state = ["charged", "charging", "discharging", "AC attached"]
        .first(where: { out.contains($0) }) ?? ""
    let timeLeft = out.range(of: #"\d+:\d+ remaining"#, options: .regularExpression)
        .map { String(out[$0]) }
    var s = "\(pct) · \(state)"
    if let t = timeLeft { s += "  ·  \(t)" }
    return s
}

func salRead() -> String {
    let status = "\(APPLE_DIR)/analysis/sal/current-status.md"
    runDetached("/usr/bin/python3", ["\(APPLE_DIR)/bin/sal-archive-status.py", "--write", status])
    // Give it a moment to write
    Thread.sleep(forTimeInterval: 0.3)
    guard let data = try? String(contentsOfFile: status, encoding: .utf8) else { return "—" }
    func first(_ pattern: String) -> String? {
        let lines = data.split(separator: "\n").map(String.init)
        for line in lines where line.contains(pattern) {
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

// ─── menu plumbing ─────────────────────────────────────────────────────────

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var refreshTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "🧰"
        rebuildMenu()
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { [weak self] _ in
            self?.rebuildMenu()
        }
    }

    @objc func runAction(_ sender: NSMenuItem) {
        guard let payload = sender.representedObject as? [String: Any],
              let cmd = payload["cmd"] as? String else { return }
        let args = payload["args"] as? [String] ?? []
        runDetached(cmd, args)
    }

    @objc func refresh() { rebuildMenu() }
    @objc func quit() { NSApp.terminate(nil) }

    func action(_ title: String, cmd: String, args: [String] = []) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: #selector(runAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = ["cmd": cmd, "args": args]
        return item
    }

    func header(_ title: String, body: String) -> NSMenuItem {
        let item = NSMenuItem(title: "\(title): \(body)", action: nil, keyEquivalent: "")
        item.isEnabled = false
        return item
    }

    func rebuildMenu() {
        let menu = NSMenu()

        // Live status (top, disabled — informational)
        menu.addItem(header("🌡 Climate", body: climateRead()))
        menu.addItem(header("🔋 Battery", body: batteryRead()))
        menu.addItem(header("🗂 Sal", body: salRead()))
        menu.addItem(.separator())

        // Click-to-run actions
        menu.addItem(action("🔇 Stop Voicebox", cmd: "\(HOME)/bin/voicebox-stop"))
        menu.addItem(action("🗑 Empty Trash",
            cmd: "/usr/bin/osascript",
            args: ["-e", "tell application \"Finder\" to empty trash"]))
        menu.addItem(action("👁 Hide Desktop Icons", cmd: "\(TOPBAR)/scripts/hide-desktop.sh"))
        menu.addItem(action("👀 Show Desktop Icons", cmd: "\(TOPBAR)/scripts/show-desktop.sh"))

        // Audio submenu
        let audioRoot = NSMenuItem(title: "Audio", action: nil, keyEquivalent: "")
        let audioSub = NSMenu()
        audioSub.addItem(action("🔇 Mute",   cmd: "/usr/bin/osascript", args: ["-e", "set volume with output muted"]))
        audioSub.addItem(action("🔊 Unmute", cmd: "/usr/bin/osascript", args: ["-e", "set volume without output muted"]))
        audioSub.addItem(action("🔉 Volume 25%", cmd: "/usr/bin/osascript", args: ["-e", "set volume output volume 25"]))
        audioSub.addItem(action("🔉 Volume 50%", cmd: "/usr/bin/osascript", args: ["-e", "set volume output volume 50"]))
        audioSub.addItem(action("🔊 Volume 75%", cmd: "/usr/bin/osascript", args: ["-e", "set volume output volume 75"]))
        audioRoot.submenu = audioSub
        menu.addItem(audioRoot)

        // Finder submenu
        let finderRoot = NSMenuItem(title: "Finder", action: nil, keyEquivalent: "")
        let finderSub = NSMenu()
        finderSub.addItem(action("💀 Kill Finder",        cmd: "/usr/bin/killall", args: ["Finder"]))
        finderSub.addItem(action("🫥 Show Hidden Files",  cmd: "\(TOPBAR)/scripts/show-hidden.sh"))
        finderSub.addItem(action("🙈 Hide Hidden Files",  cmd: "\(TOPBAR)/scripts/hide-hidden.sh"))
        finderSub.addItem(action("📋 Restart Menu Bar",   cmd: "/usr/bin/killall", args: ["SystemUIServer"]))
        finderRoot.submenu = finderSub
        menu.addItem(finderRoot)

        menu.addItem(.separator())

        let refreshItem = NSMenuItem(title: "🔄 Refresh", action: #selector(refresh), keyEquivalent: "r")
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
