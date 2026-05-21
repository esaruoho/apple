// AppleToolbox.swift
//
// Apple-native menu-bar toolbox. NSStatusItem + NSMenu, no third-party deps.
// Compile: xcrun swiftc -O AppleToolbox.swift -o AppleToolbox -framework Cocoa
// Bundle into AppleToolbox.app with Info.plist LSUIElement=true.
//
// Two modes:
//   (default) menu-bar  — NSStatusItem with the full menu tree below.
//   --live              — borderless always-on-top NSPanel showing the live
//                         status rows; hot-reloads when AppleToolbox.swift is
//                         saved (stat-poll → build.sh → execv self).
//
// Sections:
//   Live status   — HomePod climate, battery, disk, WiFi, Mail, Now Playing, Whisp queue
//   Quick actions — Stop Voicebox, Empty Trash, Hide/Show Desktop, Hide-Others
//   System ▸      — Dark mode toggle, Lock screen, Sleep, Screenshot ▸, Snap Windows ▸
//   Audio ▸       — Mute / Unmute / Volume presets
//   Finder ▸      — Kill / Show-Hidden / Hide-Hidden / Restart Menu Bar
//   Slashes ▸     — Hey Sal… / Grand Search… / QR… / Wi-Fi QR… / Apple Report / Webcam Photo / Grand Export
//   Refresh, Quit
//
// Menu refresh every 5 minutes; live-viewport status every 5 sec, source-watcher every 1 sec.

import Cocoa
import Foundation
import Speech                // SFSpeechRecognizer — partial-results dictation
import AVFoundation          // AVAudioEngine — mic input tap for the speech recognizer
import Carbon.HIToolbox      // RegisterEventHotKey — global hotkey (Apple-shipped, no permission)
import EventKit              // Calendar + Reminders pre-auth
import Contacts              // Contacts pre-auth
import Photos                // Photos pre-auth
import ApplicationServices   // AXIsProcessTrustedWithOptions — accessibility prompt
import UniformTypeIdentifiers // UTType — classify files for type-aware clipboard copy

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

/// Resolve an app by name (e.g. "DaisyDisk") to its full bundle path, searching
/// /Applications and /System/Applications/Utilities. Returns nil if not found.
func appPath(_ name: String) -> String? {
    let candidates = [
        "/Applications/\(name).app",
        "/System/Applications/\(name).app",
        "/System/Applications/Utilities/\(name).app",
    ]
    return candidates.first { FileManager.default.fileExists(atPath: $0) }
}

func notify(_ title: String, _ body: String) {
    runDetached("/usr/bin/osascript", ["-e",
        "display notification \"\(body.replacingOccurrences(of: "\"", with: "\\\""))\" with title \"\(title)\""])
}

// ─── permissions: one-shot grant flow ──────────────────────────────────────
//
// macOS TCC (Transparency / Consent / Control) is user-mediated by design —
// there's no API or signing trick to silently grant Accessibility / FDA /
// Screen Recording. What we CAN do is fire every privacy-API request once at
// a known moment so the dialogs queue up in a single burst instead of
// ambushing you mid-task. After the user clicks through, AppleToolbox stops
// asking. Triggerable via the "Grant All Permissions…" menu item, the
// /grant-perms slash, or `AppleToolbox --grant-permissions` on the CLI.
//
// Per-API behaviour:
//   Microphone, Camera, Speech, Calendar, Reminders, Contacts, Photos →
//     fire the AppKit/AVKit/EventKit request API; dialog appears.
//   Accessibility →
//     AXIsProcessTrustedWithOptions(prompt: true) opens System Settings →
//     Privacy → Accessibility (cannot be auto-granted; user toggles switch).
//   Screen Recording →
//     CGRequestScreenCaptureAccess() shows the modal (same caveat).
//   Apple Events / Automation (per-target) →
//     Fire a no-op AppleScript "tell application X to return name" against
//     each common target so the per-target Automation prompt queues now
//     instead of when you first click a row that uses that app.
//   Full Disk Access →
//     No API exists. We deep-link to the System Settings pane and let the
//     user drag AppleToolbox.app into the list manually.

func requestAllPermissions() {
    fputs("==> AppleToolbox: requesting all privacy permissions\n", stderr)

    // 1. Microphone — async dialog, harmless to call again later.
    AVCaptureDevice.requestAccess(for: .audio) { granted in
        fputs("[mic] granted=\(granted)\n", stderr)
    }

    // 2. Camera — same.
    AVCaptureDevice.requestAccess(for: .video) { granted in
        fputs("[camera] granted=\(granted)\n", stderr)
    }

    // 3. Speech recognition.
    if #available(macOS 10.15, *) {
        SFSpeechRecognizer.requestAuthorization { status in
            fputs("[speech] status=\(status.rawValue)\n", stderr)
        }
    }

    // 4. Accessibility — opens the prompt; user must toggle the switch.
    let promptKey = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as NSString
    _ = AXIsProcessTrustedWithOptions([promptKey: true] as CFDictionary)

    // 5. Screen Recording — shows modal if not already granted.
    if #available(macOS 10.15, *) {
        _ = CGRequestScreenCaptureAccess()
    }

    // 6. Calendar (full access on Sonoma+).
    let evStore = EKEventStore()
    if #available(macOS 14.0, *) {
        evStore.requestFullAccessToEvents { _, _ in }
        evStore.requestFullAccessToReminders { _, _ in }
    } else {
        evStore.requestAccess(to: .event)    { _, _ in }
        evStore.requestAccess(to: .reminder) { _, _ in }
    }

    // 7. Contacts.
    CNContactStore().requestAccess(for: .contacts) { _, _ in }

    // 8. Photos.
    if #available(macOS 11.0, *) {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { _ in }
    } else {
        PHPhotoLibrary.requestAuthorization { _ in }
    }

    // 9. Apple Events / Automation — pre-prompt each common target so the
    //    per-target Automation dialogs queue now. Done off the main thread
    //    so the modal dialogs don't deadlock each other.
    DispatchQueue.global(qos: .userInitiated).async {
        let targets = [
            "Finder", "System Events", "Mail", "Music", "Safari",
            "Calendar", "Contacts", "Reminders", "Notes", "Photos",
            "Messages", "TextEdit",
        ]
        for app in targets {
            let scr = NSAppleScript(source: "tell application \"\(app)\" to return name")
            var err: NSDictionary?
            _ = scr?.executeAndReturnError(&err)
            Thread.sleep(forTimeInterval: 0.15)  // let each dialog appear cleanly
        }
        DispatchQueue.main.async {
            // 10. Full Disk Access — no API to request; open the pane and
            //     prompt the user to drag AppleToolbox.app in.
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles") {
                NSWorkspace.shared.open(url)
            }
            notify("AppleToolbox",
                   "Click through the queued permission dialogs, then drag AppleToolbox.app into the Full Disk Access list.")
        }
    }
}

// ─── live status readers ───────────────────────────────────────────────────

func climateRead() -> String {
    let dir = "\(HOME)/work/comms/queue/homepod-climate"
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

func mailDataDir() -> String? {
    let mailDir = "\(HOME)/Library/Mail"
    guard let versions = try? FileManager.default.contentsOfDirectory(atPath: mailDir) else { return nil }
    guard let v = versions.filter({ $0.hasPrefix("V") }).sorted().last else { return nil }
    return "\(mailDir)/\(v)/MailData"
}

func formatUnread(_ n: Int) -> String {
    let fmt = NumberFormatter()
    fmt.numberStyle = .decimal
    fmt.groupingSeparator = ","
    return "\(fmt.string(from: NSNumber(value: n)) ?? "\(n)") unread"
}

func mailUnreadRead() -> String? {
    guard let data = mailDataDir() else { return nil }
    let db = "\(data)/Envelope Index"
    guard FileManager.default.fileExists(atPath: db) else { return nil }
    let out = run("/usr/bin/sqlite3", ["-readonly", db,
        "SELECT COALESCE(SUM(unread_count), 0) FROM mailboxes WHERE url LIKE '%INBOX%' OR url LIKE '%inbox%';"], timeout: 2)
        .trimmingCharacters(in: .whitespacesAndNewlines)
    guard let count = Int(out) else { return nil }
    return formatUnread(count)
}

/// VIP total unread = sum across every VIP UUID in VIPMailboxes.plist.
func mailVIPUnreadRead() -> String? {
    guard let data = mailDataDir(),
          let dict = NSDictionary(contentsOfFile: "\(data)/VIPMailboxes.plist") as? [String: Any]
    else { return nil }
    var total = 0
    for (_, v) in dict {
        if let entry = v as? [String: Any], let n = entry["MailboxUnreadCount"] as? Int {
            total += n
        }
    }
    return formatUnread(total)
}

/// Look up a Smart Mailbox by display name in SyncedSmartMailboxes.plist, then
/// read its cached MailboxUnreadCount from SmartMailboxesLocalProperties.plist.
func mailSmartMailboxUnreadRead(_ name: String) -> String? {
    guard let data = mailDataDir(),
          let synced = NSArray(contentsOfFile: "\(data)/SyncedSmartMailboxes.plist") as? [[String: Any]],
          let entry = synced.first(where: { ($0["MailboxName"] as? String) == name }),
          let id = entry["MailboxID"] as? String,
          let local = NSDictionary(contentsOfFile: "\(data)/SmartMailboxesLocalProperties.plist") as? [String: Any],
          let perBox = local[id] as? [String: Any],
          let n = perBox["MailboxUnreadCount"] as? Int
    else { return nil }
    return formatUnread(n)
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
    // Read live heartbeat written by the Mini's whisp-worker via Syncthing.
    // Shape mirrors ocr-heartbeat.json — status + queue counts + current job.
    let path = "\(HOME)/work/comms/queue/whisp-heartbeat.json"
    guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
          let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
    else {
        // Fallback to the legacy file-count if no heartbeat exists yet.
        let dir = "\(HOME)/work/whisp-transcripts/queue/pending"
        if let files = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            let n = files.filter { $0.hasSuffix(".url") }.count
            return n > 0 ? "\(n) pending (no heartbeat)" : "—"
        }
        return "—"
    }

    let status = obj["status"] as? String ?? "?"
    let queue = obj["queue"] as? [String: Any] ?? [:]
    let pending = queue["pending"] as? Int ?? 0

    // Heartbeat staleness: if older than 2 min, the worker may be down.
    var staleHint = ""
    if let ts = obj["ts"] as? Double {
        let age = Date().timeIntervalSince1970 - ts
        if age > 120 { staleHint = " (stale \(Int(age))s)" }
    }

    switch status {
    case "processing":
        if let cur = obj["current"] as? [String: Any] {
            let title = (cur["title"] as? String ?? "?")
            let dur = cur["duration_seconds"] as? Int ?? 0
            let elapsed = cur["elapsed_seconds"] as? Int ?? 0
            let eta = cur["eta_seconds"] as? Int ?? 0
            func fmt(_ s: Int) -> String {
                if s <= 0 { return "?" }
                if s < 60 { return "\(s)s" }
                return "\(s/60)m\(s%60)s"
            }
            return "▶ \(title) · \(fmt(elapsed))/\(fmt(dur/3)) (ETA \(fmt(eta))) · \(pending) queued\(staleHint)"
        }
        return "▶ processing · \(pending) queued\(staleHint)"
    case "idle":
        return "💤 idle · \(pending) queued\(staleHint)"
    case "between_jobs":
        return "⏳ between jobs · \(pending) queued\(staleHint)"
    default:
        return "\(status) · \(pending) queued\(staleHint)"
    }
}

func vaultStatusRead() -> String? {
    // Lightweight count of derivative artifacts. Reads dir listings only — no
    // file parsing. Shows N transcripts / C concepts / F figures and whether
    // the derivatives loop has run recently.
    let fm = FileManager.default
    let vault = "\(HOME)/work/cc/vault"
    func count(_ rel: String, suffix: String = "") -> Int {
        guard let entries = try? fm.contentsOfDirectory(atPath: "\(vault)/\(rel)") else { return 0 }
        return suffix.isEmpty ? entries.count : entries.filter { $0.hasSuffix(suffix) }.count
    }
    let transcripts = count("sources/transcripts")
    let concepts    = count("concepts", suffix: ".md")
    let figures     = count("_router/figure-inboxes", suffix: ".md")
    let dupesPath   = "\(vault)/_index/transcripts-duplicates.md"

    var staleHint = ""
    let byDate = "\(vault)/_index/transcripts-by-date.md"
    if let attrs = try? fm.attributesOfItem(atPath: byDate),
       let mtime = attrs[.modificationDate] as? Date {
        let mins = Int(Date().timeIntervalSince(mtime) / 60)
        if mins > 30 { staleHint = " · stale \(mins)m" }
    } else {
        staleHint = " · never built"
    }

    var dupes = 0
    if let txt = try? String(contentsOfFile: dupesPath, encoding: .utf8) {
        dupes = txt.components(separatedBy: "\n## ").count - 1
    }

    if transcripts == 0 && concepts == 0 { return nil }
    var parts: [String] = ["\(transcripts) transcripts"]
    if concepts > 0 { parts.append("\(concepts) concepts") }
    if figures > 0  { parts.append("\(figures) figures") }
    if dupes > 0    { parts.append("\(dupes) dupe-sets") }
    return parts.joined(separator: " · ") + staleHint
}

func fileerataQueueRead() -> String? {
    // Fileerata segment-extraction queue. Counts files across:
    //   ~/work/comms/queue/segment-requests/   (pending — written by tag watcher)
    //   ~/work/comms/queue/segment-outbox/     (ready clips — *.mp4/.m4a/.md)
    //   ~/work/comms/queue/segment-failed/     (errors)
    let fm = FileManager.default
    let base = "\(HOME)/work/comms/queue"
    func count(_ sub: String, suffix: String) -> Int {
        let dir = "\(base)/\(sub)"
        guard let files = try? fm.contentsOfDirectory(atPath: dir) else { return 0 }
        return files.filter { $0.hasSuffix(suffix) }.count
    }
    let pending = count("segment-requests", suffix: ".req")
    let mp4s = count("segment-outbox", suffix: ".mp4")
    let m4as = count("segment-outbox", suffix: ".m4a")
    let failed = count("segment-failed", suffix: ".req")
    let ready = max(mp4s, m4as)
    if pending == 0 && ready == 0 && failed == 0 { return nil }
    var parts: [String] = []
    if pending > 0 { parts.append("\(pending) pending") }
    if ready > 0   { parts.append("\(ready) ready") }
    if failed > 0  { parts.append("\(failed) failed") }
    return parts.joined(separator: " · ")
}

// ─── inline-detail data readers ───────────────────────────────────────────
//
// These return rich detail strings (multi-line, monospaced) that the live
// panel renders inline when the corresponding row is selected. The point is
// to STOP launching browsers for things we can show in-place. Climate first;
// Battery / Disk / Wi-Fi / Mail / Whisp can follow the same pattern.

struct ClimateSample {
    let date: Date
    let temp: Double
    let humidity: Double
}

/// Read the last `limit` climate samples by walking the most recent JSONL
/// files in homepod-watcher/climate-logs. Newest last.
func climateRecentSamples(limit: Int = 60) -> [ClimateSample] {
    let dir = "\(HOME)/work/comms/queue/homepod-climate"
    guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [] }
    let jsonl = files.filter { $0.hasSuffix(".jsonl") }.sorted()
    var samples: [ClimateSample] = []
    let iso = ISO8601DateFormatter()
    // Read from newest day backward, then reverse to chronological.
    for f in jsonl.reversed() {
        guard let txt = try? String(contentsOfFile: "\(dir)/\(f)", encoding: .utf8) else { continue }
        for line in txt.split(separator: "\n").reversed() {
            let s = String(line)
            func numField(_ key: String) -> Double? {
                guard let r = s.range(of: "\"\(key)\":") else { return nil }
                let tail = s[r.upperBound...].drop(while: { $0 == " " })
                let chars = tail.prefix(while: { ("0"..."9").contains($0) || $0 == "." || $0 == "-" })
                return Double(chars)
            }
            func strField(_ key: String) -> String? {
                guard let r = s.range(of: "\"\(key)\":\"") else { return nil }
                let tail = s[r.upperBound...]
                guard let end = tail.firstIndex(of: "\"") else { return nil }
                return String(tail[tail.startIndex..<end])
            }
            let t = numField("temperature_cal") ?? numField("temperature_c")
            let h = numField("humidity_cal") ?? numField("humidity_pct")
            let ts = strField("timestamp").flatMap { iso.date(from: $0) }
            if let t = t, let h = h, let ts = ts {
                samples.append(ClimateSample(date: ts, temp: t, humidity: h))
                if samples.count >= limit { break }
            }
        }
        if samples.count >= limit { break }
    }
    return samples.reversed()
}

/// Compact Unicode sparkline (8 levels) over `values`, padded to `width`.
func sparkline(_ values: [Double], width: Int = 24) -> String {
    let blocks: [Character] = ["▁","▂","▃","▄","▅","▆","▇","█"]
    guard !values.isEmpty, let mn = values.min(), let mx = values.max() else {
        return String(repeating: "·", count: width)
    }
    let span = max(0.01, mx - mn)
    // Resample into `width` buckets via linear index mapping.
    var out = ""
    for i in 0..<width {
        let lo = (Double(i) * Double(values.count)) / Double(width)
        let hi = (Double(i + 1) * Double(values.count)) / Double(width)
        let a = max(0, Int(lo.rounded(.down)))
        let b = min(values.count, max(a + 1, Int(hi.rounded(.up))))
        let slice = values[a..<b]
        let avg = slice.reduce(0, +) / Double(slice.count)
        let n = (avg - mn) / span
        let idx = min(blocks.count - 1, max(0, Int(n * Double(blocks.count - 1))))
        out.append(blocks[idx])
    }
    return out
}

/// Render the inline detail block for the Climate row.
func climateDetailString() -> String {
    let samples = climateRecentSamples(limit: 96)
    guard !samples.isEmpty else { return "Climate: no recent samples in comms/queue/homepod-climate." }
    let temps = samples.map { $0.temp }
    let hums = samples.map { $0.humidity }
    let tmin = temps.min() ?? 0, tmax = temps.max() ?? 0
    let hmin = hums.min() ?? 0, hmax = hums.max() ?? 0
    let tSpark = sparkline(temps, width: 28)
    let hSpark = sparkline(hums, width: 28)
    let last = samples.suffix(4).reversed()
    let tf = DateFormatter()
    tf.dateFormat = "MMM d HH:mm"
    var lines: [String] = []
    lines.append("range  \(String(format: "%.1f–%.1f°C", tmin, tmax))   \(String(format: "%.0f–%.0f%% RH", hmin, hmax))   (\(samples.count) samples)")
    lines.append("temp   \(tSpark)")
    lines.append("hum    \(hSpark)")
    for s in last {
        lines.append(String(format: "%@   %.1f°C   %.0f%% RH", tf.string(from: s.date), s.temp, s.humidity))
    }
    return lines.joined(separator: "\n")
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

    @objc func grantAllPermissions(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Grant All Permissions"
        alert.informativeText =
            "AppleToolbox will fire every privacy-API request once so all the macOS prompts queue at the same time. Click through each dialog as it appears. Full Disk Access will open in System Settings — drag AppleToolbox.app into the list to enable Mail unread counts and friends."
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        requestAllPermissions()
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
    @objc func screenshotFrontWindow(_ sender: NSMenuItem) {
        guard let front = NSWorkspace.shared.frontmostApplication else {
            NSSound.beep(); return
        }
        let pid = front.processIdentifier
        let appName = front.localizedName ?? "App"
        // On-screen windows only, excluding desktop elements; ordered front-to-back.
        let opts: CGWindowListOption = [.optionOnScreenOnly, .excludeDesktopElements]
        guard let raw = CGWindowListCopyWindowInfo(opts, kCGNullWindowID) as? [[String: Any]] else {
            NSSound.beep(); return
        }
        // Pick the topmost window owned by the frontmost app that has a real size
        // and is on the normal window layer (layer 0). Skips menu-bar overlays etc.
        let match = raw.first { info in
            guard let owner = info[kCGWindowOwnerPID as String] as? pid_t, owner == pid else { return false }
            let layer = (info[kCGWindowLayer as String] as? Int) ?? 1
            guard layer == 0 else { return false }
            if let b = info[kCGWindowBounds as String] as? [String: CGFloat],
               let w = b["Width"], let h = b["Height"], w > 50, h > 50 { return true }
            return false
        }
        guard let wid = match?[kCGWindowNumber as String] as? CGWindowID else {
            NSSound.beep(); return
        }
        let safeName = appName.replacingOccurrences(of: "/", with: "-")
        let out = "\(HOME)/Desktop/screen-\(safeName)-\(Int(Date().timeIntervalSince1970)).png"
        runDetached("/usr/sbin/screencapture", ["-o", "-x", "-l\(wid)", out])
        Thread.sleep(forTimeInterval: 0.4); openFile(out)
    }

    @objc func refresh() { rebuildMenu() }
    @objc func quit() { NSApp.terminate(nil) }

    /// Bring the floating live panel back to front. Posts a distributed
    /// notification first so an already-running `--live` process can
    /// orderFront itself without spawning a duplicate. If no `--live`
    /// process is running (the common case the first time you click this
    /// menu item), we also spawn `AppleToolbox --live` directly via the
    /// same binary path — Apple-native `Process()`, no `open -a` round-trip
    /// (since we're running .accessory and don't want LaunchServices to
    /// hijack the second instance).
    @objc func showLivePanel() {
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.esaruoho.appletoolbox.ShowLivePanel"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true)

        // Check whether a --live process is already running. ps shows
        // every AppleToolbox argv; the menu-bar instance has no `--live`
        // flag, so pgrep with -f scoped to the flag is the right probe.
        let probe = Process()
        probe.launchPath = "/usr/bin/pgrep"
        probe.arguments = ["-f", "AppleToolbox.*--live"]
        let pipe = Pipe()
        probe.standardOutput = pipe
        do { try probe.run() } catch { return }
        probe.waitUntilExit()
        let alive = !pipe.fileHandleForReading.readDataToEndOfFile().isEmpty
        guard !alive else { return }   // notification already woke it up

        // Spawn a fresh --live. ProcessInfo.processInfo.arguments[0] is
        // OUR binary path — same .app, same code, just a different
        // activation policy via the --live flag.
        let me = ProcessInfo.processInfo.arguments[0]
        runDetached(me, ["--live"])
    }

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

    /// Clickable status row — title:body label, click runs `open` + args.
    /// Pass `symbol:` to use Apple's shipping SF Symbol as the row icon
    /// (e.g. `"wifi"` for the real Wi-Fi glyph that System Settings /
    /// Control Center use, not the generic 📶 cellular-bars emoji). When
    /// `symbol:` is set, strip any leading emoji from `title` so the icon
    /// stands in for it cleanly.
    func statusRow(_ title: String, body: String, open: String, args: [String] = [],
                   symbol: String? = nil) -> NSMenuItem {
        let cleanTitle: String
        if symbol != nil {
            // Strip a leading emoji + space prefix so the SF Symbol replaces it.
            // Walk forward past non-letter scalars; stop at the first ASCII letter.
            var idx = title.startIndex
            while idx < title.endIndex, !title[idx].isLetter { idx = title.index(after: idx) }
            cleanTitle = String(title[idx...])
        } else {
            cleanTitle = title
        }
        let item = NSMenuItem(title: "\(cleanTitle): \(body)", action: #selector(runAction(_:)), keyEquivalent: "")
        item.target = self
        item.representedObject = ["cmd": open, "args": args]
        if let sym = symbol, #available(macOS 11.0, *) {
            let cfg = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            item.image = NSImage(systemSymbolName: sym, accessibilityDescription: cleanTitle)?
                .withSymbolConfiguration(cfg)
        }
        return item
    }

    /// Status row that expands into a submenu instead of firing a single action.
    /// The parent label still shows "title: body"; children are the launch options.
    func statusSubmenu(_ title: String, body: String, items: [NSMenuItem]) -> NSMenuItem {
        let root = NSMenuItem(title: "\(title): \(body)", action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for i in items { sub.addItem(i) }
        root.submenu = sub
        return root
    }

    func submenu(_ title: String, items: [NSMenuItem]) -> NSMenuItem {
        let root = NSMenuItem(title: title, action: nil, keyEquivalent: "")
        let sub = NSMenu()
        for i in items { sub.addItem(i) }
        root.submenu = sub
        return root
    }

    /// Enumerate ~/Library/Saved Searches/ and return one `action` item per
    /// `.savedSearch` file. Each click opens that smart folder in Finder.
    /// Rebuilt every time the menu opens so newly-created smart folders show
    /// up without restarting AppleToolbox.
    func smartFolderItems() -> [NSMenuItem] {
        let dir = "\(HOME)/Library/Saved Searches"
        let fm = FileManager.default
        guard let names = try? fm.contentsOfDirectory(atPath: dir) else {
            return [NSMenuItem(title: "(no Smart Folders)", action: nil, keyEquivalent: "")]
        }
        let saved = names
            .filter { $0.hasSuffix(".savedSearch") && !$0.hasPrefix(".") }
            .sorted()
        if saved.isEmpty {
            return [NSMenuItem(title: "(no Smart Folders)", action: nil, keyEquivalent: "")]
        }
        return saved.map { name -> NSMenuItem in
            let path = "\(dir)/\(name)"
            // Strip extension and pick a glyph from the leading word.
            let stem = String(name.dropLast(".savedSearch".count))
            let lc = stem.lowercased()
            let glyph: String
            if lc.contains("ocr failed") || lc.contains("engine failed") {
                glyph = "⚠️"
            } else if lc.contains("ocr") {
                glyph = "🤖"
            } else if lc.contains("corpus") {
                glyph = "📚"
            } else if lc.contains("trinity") {
                glyph = "🔗"
            } else if lc.contains("all smart folders") {
                glyph = "🗂"
            } else if lc.contains("needing") || lc.contains("needs") {
                glyph = "📋"
            } else {
                glyph = "📁"
            }
            return action("\(glyph) \(stem)", cmd: "/usr/bin/open", args: [path])
        }
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

        // Top-of-menu launcher: the most-pressed thing in this whole tree
        // lives at row 1 so it's a single click after opening the dropdown.
        let showLiveTop = NSMenuItem(title: "🪟 Show Live Panel",
                                     action: #selector(showLivePanel),
                                     keyEquivalent: "")
        showLiveTop.target = self
        menu.addItem(showLiveTop)
        menu.addItem(.separator())

        // Live status — readers that return nil get their row skipped entirely
        // (no "—" placeholders cluttering the menu). Each row is CLICKABLE and
        // opens the relevant app / file / preference pane.
        func addIf(_ title: String, _ body: String?, open: String, args: [String] = [],
                   symbol: String? = nil) {
            guard let b = body, !b.isEmpty, b != "—" else { return }
            menu.addItem(statusRow(title, body: b, open: open, args: args, symbol: symbol))
        }
        addIf("🌡 Climate", climateRead(),
              open: "/usr/bin/open", args: ["\(HOME)/work/homepod-watcher/climate-graph.html"])
        addIf("🔋 Battery", batteryRead(),
              open: "/usr/bin/open", args: ["x-apple.systempreferences:com.apple.preference.battery"])
        let disk = diskRead()
        if !disk.isEmpty, disk != "—" {
            // The Disk row's submenu already exposes the dual-scan as its
            // first option, so no separate promoted top-level item — the
            // long title was visually overwhelming next to the compact
            // status rows. Submenu structure stays consistent with
            // Battery / Wi-Fi / Mail (row + ▸ submenu, no shortcuts above).
            var diskItems: [NSMenuItem] = []
            diskItems.append(action("⊟ Scan both — side-by-side (/)",
                cmd: "\(TOPBAR)/scripts/disk-dual-scan.sh", args: ["/"]))
            diskItems.append(action("⊟ Scan both — side-by-side (Home)",
                cmd: "\(TOPBAR)/scripts/disk-dual-scan.sh", args: [HOME]))
            diskItems.append(NSMenuItem.separator())
            if let p = appPath("Disk Utility") {
                diskItems.append(action("🛠 Disk Utility",
                    cmd: "/usr/bin/open", args: [p]))
            }
            if appPath("GrandPerspective") != nil {
                diskItems.append(action("🧩 GrandPerspective (mosaic) — scan /",
                    cmd: "/usr/bin/open", args: ["-a", "GrandPerspective", "/"]))
                diskItems.append(action("🧩 GrandPerspective (mosaic) — scan Home",
                    cmd: "/usr/bin/open", args: ["-a", "GrandPerspective", HOME]))
            }
            if appPath("DaisyDisk") != nil {
                diskItems.append(action("🥧 DaisyDisk (pie chart) — scan Macintosh HD",
                    cmd: "/usr/bin/open", args: ["-a", "DaisyDisk", "/"]))
                // UI-scripted variant via Cmd+O "Scan Folder…"
                diskItems.append(action("🥧 DaisyDisk (pie chart) — scan Home (UI-scripted)",
                    cmd: "\(TOPBAR)/scripts/daisydisk-scan-folder.sh", args: [HOME]))
            }
            diskItems.append(NSMenuItem.separator())
            diskItems.append(action("⚙ System Settings → Storage",
                cmd: "/usr/bin/open", args: ["x-apple.systempreferences:com.apple.settings.Storage"]))
            menu.addItem(statusSubmenu("💿 Disk", body: disk, items: diskItems))
        }
        addIf("📶 Wi-Fi",   wifiRead(),
              open: "/usr/bin/open", args: ["x-apple.systempreferences:com.apple.Network-Settings.extension"],
              symbol: "wifi")
        addIf("📬 Mail",    mailUnreadRead(),
              open: "/usr/bin/open", args: ["-a", "Mail"])
        addIf("⭐ VIP",      mailVIPUnreadRead(),
              open: "\(TOPBAR)/scripts/mail-select-mailbox.sh", args: ["VIPs"])
        addIf("📅 Today",   mailSmartMailboxUnreadRead("Today"),
              open: "\(TOPBAR)/scripts/mail-select-mailbox.sh", args: ["Today"])
        addIf("🧑 Human Only", mailSmartMailboxUnreadRead("Human Only"),
              open: "\(TOPBAR)/scripts/mail-select-mailbox.sh", args: ["Human Only"])
        addIf("⚡ Free Energy", mailSmartMailboxUnreadRead("Free Energy"),
              open: "\(TOPBAR)/scripts/mail-select-mailbox.sh", args: ["Free Energy"])
        addIf("🎵 Music",   nowPlayingRead(),
              open: "/usr/bin/open", args: ["-a", "Music"])
        addIf("🎙 Whisp",   whispQueueRead(),
              open: "/usr/bin/open", args: ["\(HOME)/work/comms/queue/whisp-results"])
        addIf("📚 Vault",   vaultStatusRead(),
              open: "/usr/bin/open", args: ["\(HOME)/work/cc/vault/_index/transcripts-by-date.md"])
        addIf("✂️ Fileerata", fileerataQueueRead(),
              open: "/usr/bin/open", args: ["\(HOME)/work/comms/queue/segment-outbox"])
        menu.addItem(.separator())

        // Quick actions
        menu.addItem(action("🗣 Read Selection",
            cmd: "\(APPLE_DIR)/bin/read-aloud", args: ["--grab"]))
        menu.addItem(action("📋 Read Clipboard",
            cmd: "\(APPLE_DIR)/bin/read-aloud"))
        menu.addItem(action("⏹ Stop Reading",
            cmd: "\(APPLE_DIR)/bin/read-aloud", args: ["--stop"]))
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
                customAction("Frontmost app's window (no click)", selector: #selector(screenshotFrontWindow(_:))),
            ]),
            submenu("🪟 Snap Windows", items: [
                action("◧◨ Side by Side (front 2 apps)",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/SideBySide.scpt"]),
                action("⬒⬓ Top / Bottom (front 2 apps)",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/TopBottom.scpt"]),
                action("⬛⬛⬛ Thirds (front 3 apps)",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/Thirds.scpt"]),
                NSMenuItem.separator(),
                action("Mosaic (all of front app)",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/MosaicWindows.scpt"]),
                action("Mosaic +1 window",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/MosaicKnob.scpt", "more"]),
                action("Mosaic −1 window",
                    cmd: "/usr/bin/osascript", args: ["\(SCRIPTS)/MosaicKnob.scpt", "less"]),
            ]),
            action("📋 Restart Menu Bar", cmd: "/usr/bin/killall", args: ["SystemUIServer"]),
            NSMenuItem.separator(),
            customAction("🔐 Grant All Permissions…", selector: #selector(grantAllPermissions(_:))),
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
            action("🎬 Send Selection to Media Editor",
                cmd: "\(APPLE_DIR)/bin/send-to-media-editor"),
            action("🗂 Conversations for this Folder…",
                cmd: "\(APPLE_DIR)/bin/cc-here", args: ["--pick"]),
            action("🔁 Rebuild Conversation Index",
                cmd: "\(APPLE_DIR)/bin/cc-index", args: ["--stats"]),
            NSMenuItem.separator(),
            action("💀 Kill Finder",       cmd: "/usr/bin/killall", args: ["Finder"]),
            action("🫥 Show Hidden Files", cmd: "\(TOPBAR)/scripts/show-hidden.sh"),
            action("🙈 Hide Hidden Files", cmd: "\(TOPBAR)/scripts/hide-hidden.sh"),
        ]))

        // Tags submenu — Finder tag helpers acting on the current Finder selection
        menu.addItem(submenu("🏷 Tags", items: [
            action("🏷 Tag Finder Selection… (prompt)",
                cmd: "\(APPLE_DIR)/bin/tag-finder-selection"),
            action("🔗 Trinity-Link Selection… (bind related files)",
                cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["trinity"]),
            action("📋 List Tags on Selection",
                cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["list"]),
            action("🗑 Clear Tags on Selection",
                cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["clear"]),
            NSMenuItem.separator(),
            action("🔴 Red on selection",    cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["--tag", "Red:red"]),
            action("🟠 Orange on selection", cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["--tag", "Orange:orange"]),
            action("🟡 Yellow on selection", cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["--tag", "Yellow:yellow"]),
            action("🟢 Green on selection",  cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["--tag", "Green:green"]),
            action("🔵 Blue on selection",   cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["--tag", "Blue:blue"]),
            action("🟣 Purple on selection", cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["--tag", "Purple:purple"]),
            action("⚪ Gray on selection",   cmd: "\(APPLE_DIR)/bin/tag-finder-selection", args: ["--tag", "Gray:gray"]),
            NSMenuItem.separator(),
            promptAction("🔍 Find Files by Tag…",
                message: "Tag name to find:",
                cmd: "\(APPLE_DIR)/bin/tag",
                argsPrefix: ["find"]),
            promptAction("📁 Open Tag Smart Folder…",
                message: "Tag name(s), comma-separated:",
                cmd: "\(APPLE_DIR)/bin/tag-smart",
                argsPrefix: ["--tmp"]),
            NSMenuItem.separator(),
            action("🤖 Send Selection to OCR (Mac Mini)",
                cmd: "\(APPLE_DIR)/bin/tag-send-to-ocr"),
            action("▶ Run Tag Watcher Now",
                cmd: "\(APPLE_DIR)/bin/tag-watcher"),
            action("↻ Retry OCR-failed (download_failed only)",
                cmd: "\(APPLE_DIR)/bin/tag-retry-failed", args: ["--kick"]),
            action("📊 Tag Watcher Status (open log)",
                cmd: "/usr/bin/open",
                args: ["\(HOME)/work/comms/queue/tag-watcher.log"]),
            NSMenuItem.separator(),
            submenu("🗂 Smart Folders", items: smartFolderItems()),
            action("📂 Open Saved Searches folder",
                cmd: "/usr/bin/open",
                args: ["\(HOME)/Library/Saved Searches"]),
            action("📌 Pin All Smart Folders to Dock",
                cmd: "\(APPLE_DIR)/bin/dock",
                args: ["add", "\(HOME)/Library/Saved Searches/All Smart Folders.savedSearch"]),
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

// ─── live viewport ─────────────────────────────────────────────────────────
//
// `AppleToolbox --live` opens a borderless always-on-top floating panel that
// renders the same status readers as the menu, refreshed every 5 sec. While
// running, it stat-polls AppleToolbox.swift every 1 sec; if mtime advances,
// it runs build.sh and execv's the new binary in-place. Edit Swift → save →
// the panel rebuilds itself within ~1-2 sec. No manual run/view loop.

// Clickable row button — stores its own open-cmd + args so the click action
// can fire the same `open` invocations the menu uses.
/// Small clickable app-icon button used alongside a LiveRowButton — fires
/// `/usr/bin/open` with `openArgs` on click. Used for the Disk row's
/// GrandPerspective / DaisyDisk / Disk Utility shortcuts.
class LiveIconButton: NSButton {
    var cmd: String = "/usr/bin/open"
    var openArgs: [String] = []
}

class LiveRowButton: NSButton {
    var cmd: String = ""
    var args: [String] = []
}

// ─── file browser types ────────────────────────────────────────────────────

struct BrowserItem {
    let name: String
    let path: String
    let isDir: Bool
    let glyph: String
    let sessionCount: Int   // # of Claude session JSONLs in this folder's project dir (dirs only)
    let sessionId: String?  // when non-nil, this row is a Claude session — click resumes it
}

/// Map a filesystem path to the directory Claude Code stores its session
/// JSONLs in. Two transforms must happen, in this order, to match Claude:
///   1. Resolve symlinks. `~/work/paketti` may point into iCloud Drive; if
///      we use the symlink name, Claude won't recognise the sessions when
///      we hand off to `claude --resume`. Claude itself stat-resolves.
///   2. Replace every non-alphanumeric character with `-`. So `/`, `.`,
///      space, `~`, `_`, etc. all collapse to `-`. Confirmed against
///      Claude's on-disk dir names for iCloud-symlinked projects.
func claudeProjectDir(forCwd path: String) -> String {
    let resolved = URL(fileURLWithPath: path).resolvingSymlinksInPath().path
    let enc = String(resolved.unicodeScalars.map { sc -> Character in
        let a = sc.value
        let isAlphaNum = (a >= 48 && a <= 57)   // 0-9
                      || (a >= 65 && a <= 90)   // A-Z
                      || (a >= 97 && a <= 122)  // a-z
        return isAlphaNum ? Character(sc) : "-"
    })
    return "\(NSHomeDirectory())/.claude/projects/\(enc)"
}

/// Count of Claude-Code session transcripts (`*.jsonl`) for the given folder,
/// using the symlink-resolved + non-alphanumeric-encoded project dir.
func sessionCountForFolder(_ path: String) -> Int {
    let projDir = claudeProjectDir(forCwd: path)
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: projDir) else { return 0 }
    return names.filter { $0.hasSuffix(".jsonl") }.count
}

/// NSButton carrying its BrowserItem so the click handler can act on it
/// without looking up by index (which would race with filter changes).
class BrowserItemButton: NSButton {
    var item: BrowserItem?
    // Accept the first click even when the panel isn't yet key — without this,
    // opening one file makes the panel briefly resign key, and the next click
    // on a different row is absorbed by activation instead of firing the row
    // action. Result on screen: "only the first row is clickable."
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { return true }
}

/// Glyph for a file based on extension. Apple-native, no icon lookup — the
/// glyph alone is enough cue for "this is an image vs. a doc vs. a script."
func glyphForFile(name: String, isDir: Bool) -> String {
    if isDir { return "📁" }
    if name == "CLAUDE.md" { return "💬" }
    let ext = (name as NSString).pathExtension.lowercased()
    switch ext {
    case "png","jpg","jpeg","gif","heic","tiff","webp","bmp","svg": return "🖼"
    case "md","txt","rtf","org": return "📄"
    case "pdf": return "📕"
    case "mp3","m4a","wav","flac","aiff","ogg": return "🎵"
    case "mp4","mov","m4v","avi","mkv","webm": return "🎬"
    case "swift","py","lua","js","ts","tsx","jsx","sh","bash","zsh",
         "applescript","scpt","rb","go","rs","c","cpp","cc","h","hpp",
         "m","mm","java","kt","php","html","css": return "📜"
    case "json","yaml","yml","toml","plist","xml","ini","conf": return "🗃"
    case "zip","tar","gz","tgz","7z","dmg","pkg","xrnx": return "📦"
    case "app": return "🧰"
    default: return "📄"
    }
}

/// Subsequence fuzzy match — every char of `needle` must appear (in order,
/// case-insensitively) somewhere in `haystack`. Same shape as fzf's default
/// matcher without the scoring. Empty needle matches everything.
func fuzzyMatch(needle: String, haystack: String) -> Bool {
    if needle.isEmpty { return true }
    let h = haystack.lowercased()
    var hi = h.startIndex
    for nc in needle.lowercased() {
        guard let found = h.range(of: String(nc), range: hi..<h.endIndex)?.lowerBound else {
            return false
        }
        hi = h.index(after: found)
    }
    return true
}

/// NSPanel that accepts key-window status — default hudWindow panels are
/// reluctant, so arrow-key keyDown events wouldn't otherwise reach the row list.
class KeyablePanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }

    /// Yellow miniaturize button hides the panel (orderOut) instead of Dock-
    /// minimizing — AppleToolbox is LSUIElement so there's no Dock icon to
    /// restore from. Re-show via the menu-bar "Show Live Panel" item, which
    /// posts the distributed notification listened to in LiveViewportDelegate.
    override func miniaturize(_ sender: Any?) {
        orderOut(nil)
    }
}

class LiveViewportDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate, NSTextFieldDelegate {
    // Status pane
    var panel: NSPanel!
    var rowsStack: NSStackView!
    var headerLabel: NSTextField!
    var statusTimer: Timer?
    var watchTimer: Timer?
    /// Background maintenance — mirrors dictation/*.wav into cc/vault and
    /// runs `vault.py backfill` so the conversations folder stays current
    /// without the user having to run it by hand. Every 15 min, off main.
    var maintenanceTimer: Timer?
    let maintenanceInterval: TimeInterval = 900
    var sourceMtime: TimeInterval = 0
    var sourcePath: String { "\(TOPBAR)/AppleToolbox.swift" }
    var reloading: Bool = false

    // Keyboard navigation through status rows.
    var rowButtons: [LiveRowButton] = []
    var rowKinds: [String] = []   // matches rowButtons; selects detail renderer
    var selectedIndex: Int = -1   // -1 = no row selected; detail pane stays hidden
    var keyMonitor: Any?

    // Inline detail pane — first step toward "data lives in the panel, not in
    // browsers we throw the user into". Climate goes first; Battery/Disk/etc.
    // get their own renderers as priorities arise.
    var detailLabel: NSTextField!

    // Chat pane — wraps an ongoing `claude` conversation bound to chatCwd.
    // Each Send spawns `claude -p --verbose --output-format=stream-json` with
    // --resume <sid> when we have one; the session_id is captured from the
    // first system/init event so the next send picks up the same conversation.
    // State persists at <project>/.appletoolbox-state.json so the viewport can
    // be relaunched (e.g., by the source-watcher) without losing the thread.
    // Boot the browser + chat into ~/work — the portfolio of projects.
    // Single-click a child folder to dive into that project; session counts
    // shown next to each folder mark the ones with ongoing conversations.
    var chatCwd: String = "\(HOME)/work"
    var claudeBin: String = "\(HOME)/.local/bin/claude"
    /// Single source of truth for the flag(s) every claude spawn in this app
    /// must carry. DRY: every `claude` invocation — terminal handoff, in-panel
    /// Process — pulls from this. Add/change here, both call sites pick it up.
    static let claudeCommonFlags: [String] = ["--dangerously-skip-permissions"]
    static var claudeCommonFlagsCmdline: String {
        claudeCommonFlags.joined(separator: " ")
    }
    var currentSessionId: String?
    var chatProcess: Process?
    var chatBusy: Bool = false
    var chatBuffer: Data = Data()
    var chatTranscript: NSTextView!
    var chatInput: ChatInputTextView!
    var chatInputScroll: NSScrollView!
    var chatHeaderLabel: NSTextField!
    var chatSendButton: NSButton!
    var chatDictateButton: NSButton!
    var chatSmartDictateButton: NSButton!
    let smartDictation = SpeechDictationController()
    var globalHotKeyRef: EventHotKeyRef?
    var chatResetButton: NSButton!
    var chatCwdButton: NSButton!
    var chatFileButton: NSButton!
    var chatVaultButton: NSButton!
    var chatSessionsButton: NSButton!
    var chatTerminalButton: NSButton!
    var anchoredFile: String?
    var sessionNames: [String: String] = [:]  // uuid → human name (per-cwd)

    // File browser — bound to chatCwd. Navigating in here switches the chat
    // project so Sessions ▾ automatically scopes to the folder you're in.
    var browserAllItems: [BrowserItem] = []
    // path -> name of the child that was selected the last time we sat in this
    // path. Set by switchChatCwd whenever the navigation crosses a parent /
    // child boundary; read by loadBrowserItems to restore the highlighted row.
    // Result: descending into bbs and coming back leaves bbs selected.
    var browserSelectionMemo: [String: String] = [:]
    /// Items currently visible after the filter is applied. Maintained
    /// alongside the visual rows so ↑/↓/Return on the filter field has
    /// an authoritative target list.
    var browserFilteredItems: [BrowserItem] = []
    /// Spotlight-style selection within `browserFilteredItems`. Reset to
    /// 0 on every renderBrowser so the top match is always pre-armed —
    /// type a few characters, hit Return, the match opens.
    var browserSelectedIndex: Int = 0
    var isRenderingBrowser: Bool = false
    var browserFilterField: NSTextField!
    var browserPathLabel: NSTextField!
    var browserStack: NSStackView!
    var browserScroll: NSScrollView!

    /// Directory where Claude Code stores this project's session JSONLs.
    /// Uses the symlink-resolved + non-alphanumeric-encoded form so iCloud-
    /// linked projects like ~/work/paketti land on Claude's actual storage
    /// dir (otherwise --resume can't find sessions we appear to list).
    var projectDir: String {
        claudeProjectDir(forCwd: chatCwd)
    }

    var sessionStateFile: String {
        "\(projectDir)/.appletoolbox-state.json"
    }

    /// Per-project composer draft — what's in the chat input right now,
    /// whether typed or dictated. Written on every text change so a
    /// crash, accidental quit, or `--live` rebuild never loses what you
    /// were composing. Loaded back into chatInput on launch.
    var composerDraftFile: String {
        let enc = chatCwd.replacingOccurrences(of: "/", with: "-")
        return "\(HOME)/.claude/projects/\(enc)/.appletoolbox-draft.md"
    }

    /// Debounce timer for draft saves — every keystroke / partial-result
    /// mutation pings save, the timer coalesces to one disk write per
    /// 250 ms so we don't hammer the SSD during a dictation burst.
    var draftSaveTimer: Timer?

    func applicationDidFinishLaunching(_ notification: Notification) {
        loadChatState()
        buildPanel()
        loadComposerDraft()    // restore any in-progress text from last quit/crash
        sourceMtime = currentMtime()
        renderStatus()
        updateChatHeader()
        // Listen for "Show Live Panel" requests from the menu-bar process.
        // Distributed notifications cross process boundaries — the menu-bar
        // AppDelegate posts; we orderFront the hidden panel.
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(showLivePanelRequested(_:)),
            name: NSNotification.Name("com.esaruoho.appletoolbox.ShowLivePanel"),
            object: nil)
        statusTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.renderStatus()
            // Pick up names set via Claude Code's /rename or `claude -n <name>` —
            // those live in ~/.claude/sessions/<pid>.json while the session is
            // running; we mirror them into our persistent state.
            if self?.refreshNamesFromClaudeSessions() == true {
                self?.updateChatHeader()
            }
        }
        watchTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.checkSource()
        }
        // Background maintenance — first pass 30s after launch (let UI
        // settle + first paint complete), then every 15 min.
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            self?.runMaintenance()
        }
        maintenanceTimer = Timer.scheduledTimer(withTimeInterval: maintenanceInterval,
                                                repeats: true) { [weak self] _ in
            self?.runMaintenance()
        }
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self, event.window === self.panel else { return event }
            return self.handleKey(event)
        }
        registerGlobalHotKey()
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKey()
    }

    /// Carbon RegisterEventHotKey — fires `toggleSmartDictation(_:)` even
    /// when AppleToolbox isn't the focused app. Apple-shipped (no Homebrew),
    /// no Accessibility / Input Monitoring permission required. Keystroke:
    /// ⌃⌥⌘D — heavily unused triple-modifier combo that's safe against the
    /// system-reserved bindings list.
    func registerGlobalHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(),
                            { _, eventRef, userData -> OSStatus in
            guard let userData = userData, let eventRef = eventRef else { return noErr }
            var hkID = EventHotKeyID()
            GetEventParameter(eventRef,
                              EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID),
                              nil,
                              MemoryLayout<EventHotKeyID>.size,
                              nil,
                              &hkID)
            let me = Unmanaged<LiveViewportDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { me.toggleSmartDictation(nil) }
            return noErr
        }, 1, &eventType, selfPtr, nil)

        // FourCharCode 'ATBD' = "AppleToolbox Dictate"
        let hkID = EventHotKeyID(signature: OSType(0x41544244), id: 1)
        let mods: UInt32 = UInt32(controlKey | optionKey | cmdKey)
        RegisterEventHotKey(UInt32(kVK_ANSI_D), mods, hkID,
                            GetApplicationEventTarget(), 0, &globalHotKeyRef)
    }

    /// Arrow up/down → move selection; Return/Enter → fire selected row.
    /// Returns nil to swallow the event so AppKit doesn't beep.
    /// CRITICAL: bail out when focus is in any text-editing surface (the
    /// chat input's field editor or the transcript view) — otherwise Return
    /// inside "Talk to Claude…" would fire the selected status row instead
    /// of sending the message.
    func handleKey(_ event: NSEvent) -> NSEvent? {
        // In-panel smart-dictation toggle (⌘D). Works whether focus is in
        // the row list, the chat input, or the transcript.
        if event.modifierFlags.intersection(.deviceIndependentFlagsMask) == .command,
           event.keyCode == 2 /* D */ {
            toggleSmartDictation(nil)
            return nil
        }

        // Arrow keys + Return drive status-row navigation. They claim the event
        // only when status-row nav is genuinely the right destination:
        //  - if focus is in the browser filter field, arrows belong to the
        //    browser's own doCommandBy handler — never steal them.
        //  - if focus is in the chat input and it has content, arrows should
        //    move the caret. Empty chat input falls through to row nav.
        //  - any other focus state → row nav owns arrows.
        let firstResp = panel.firstResponder
        let inBrowserFilter: Bool = {
            guard let bf = browserFilterField, let fe = bf.currentEditor() else { return false }
            return (firstResp as? NSText) === fe
        }()
        let inChatInput = (firstResp as? NSText) != nil && !inBrowserFilter
        let chatInputEmpty = (chatInput?.string ?? "").isEmpty
        let isNavKey = (event.keyCode == 125 || event.keyCode == 126
                        || event.keyCode == 36 || event.keyCode == 76)
        let canNav = !rowButtons.isEmpty && !inBrowserFilter && (!inChatInput || chatInputEmpty)

        if isNavKey && canNav {
            switch event.keyCode {
            case 125: // down
                selectedIndex = (selectedIndex < 0)
                    ? 0 : min(rowButtons.count - 1, selectedIndex + 1)
                applyHighlight()
                return nil
            case 126: // up
                selectedIndex = (selectedIndex <= 0)
                    ? -1 : selectedIndex - 1     // ↑ from row 0 deselects → hides detail
                applyHighlight()
                return nil
            case 36, 76: // return / keypad enter
                // Only fire row action when a row is actually selected AND
                // focus is outside the chat input (so Return in the composer
                // continues to send the chat message via its own target).
                guard !inChatInput, !inBrowserFilter, selectedIndex >= 0, selectedIndex < rowButtons.count else {
                    return event
                }
                let btn = rowButtons[selectedIndex]
                runDetached(btn.cmd, btn.args)
                return nil
            default:
                return event
            }
        }
        return event
    }

    func applyHighlight() {
        let accent = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.40).cgColor
        let clear = NSColor.clear.cgColor
        for (i, b) in rowButtons.enumerated() {
            b.wantsLayer = true
            b.layer?.cornerRadius = 4
            b.layer?.backgroundColor = (i == selectedIndex) ? accent : clear
        }
        renderInlineDetail()
    }

    /// Populate the inline detail label based on which row is selected. The
    /// principle: data lives IN the toolbox, not in a browser tab we throw
    /// the user into. Climate is the first inhabitant; other kinds get
    /// renderers as they're prioritized.
    func renderInlineDetail() {
        guard detailLabel != nil else { return }
        // Hide entirely when no row is selected, or when the selected row has
        // no inline-detail renderer. isHidden + NSStackView's
        // `detachesHiddenViews` (the default true) collapses the row out of
        // the layout so the chat pane grows back into the space.
        guard selectedIndex >= 0, selectedIndex < rowKinds.count else {
            detailLabel.stringValue = ""
            detailLabel.isHidden = true
            return
        }
        switch rowKinds[selectedIndex] {
        case "climate":
            detailLabel.stringValue = climateDetailString()
            detailLabel.isHidden = false
        default:
            detailLabel.stringValue = ""
            detailLabel.isHidden = true
        }
    }

    func buildPanel() {
        let screen = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let w: CGFloat = 380, h: CGFloat = 920
        let rect = NSRect(x: screen.maxX - w - 20, y: screen.maxY - h - 20, width: w, height: h)

        // Opaque dark panel (no hudWindow → no translucency / wallpaper bleed).
        panel = KeyablePanel(contentRect: rect,
                             styleMask: [.titled, .closable, .miniaturizable, .resizable, .utilityWindow],
                             backing: .buffered, defer: false)
        panel.title = "AppleToolbox · Live"
        panel.titlebarAppearsTransparent = true
        // Intentionally NOT setting isFloatingPanel = true — that flag tells
        // AppKit the panel is a utility surface that should avoid taking key
        // status, which silently breaks arrow-key navigation. Always-on-top
        // is achieved by `level = .floating` alone.
        panel.isFloatingPanel = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .stationary, .fullScreenAuxiliary]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        // false = clicking anywhere on the panel makes it key (so the local
        // NSEvent monitor receives arrow-key/Return for row navigation).
        // The previous `true` meant the panel only became key when a text
        // field demanded focus, leaving clicks on rows/title bar with no
        // key-window state and the arrow keys silently dropped.
        panel.becomesKeyOnlyIfNeeded = false
        panel.appearance = NSAppearance(named: .darkAqua)
        panel.isOpaque = true
        panel.backgroundColor = NSColor(white: 0.10, alpha: 1.0)

        let content = NSView(frame: NSRect(origin: .zero, size: rect.size))
        content.autoresizingMask = [.width, .height]
        content.wantsLayer = true
        content.layer?.backgroundColor = NSColor(white: 0.10, alpha: 1.0).cgColor

        // ── Status pane (top) ──
        headerLabel = NSTextField(labelWithString: "🧰  ● live")
        headerLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        headerLabel.textColor = NSColor.secondaryLabelColor

        let statusScroll = NSScrollView()
        statusScroll.borderType = .noBorder
        statusScroll.hasVerticalScroller = true
        statusScroll.drawsBackground = false

        rowsStack = NSStackView()
        rowsStack.orientation = .vertical
        rowsStack.alignment = .leading
        rowsStack.distribution = .fill
        rowsStack.spacing = 2
        rowsStack.edgeInsets = NSEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
        rowsStack.translatesAutoresizingMaskIntoConstraints = false

        let statusFlipped = FlippedView(frame: NSRect(x: 0, y: 0, width: rect.width, height: 200))
        statusFlipped.autoresizingMask = [.width]
        statusFlipped.addSubview(rowsStack)
        NSLayoutConstraint.activate([
            rowsStack.topAnchor.constraint(equalTo: statusFlipped.topAnchor),
            rowsStack.leadingAnchor.constraint(equalTo: statusFlipped.leadingAnchor),
            rowsStack.trailingAnchor.constraint(equalTo: statusFlipped.trailingAnchor),
        ])
        statusScroll.documentView = statusFlipped

        // Inline detail label — updated by applyHighlight() based on which
        // status row is selected. Multi-line, monospaced; renders sparklines,
        // recent readings, anything else that belongs INSIDE the toolbox
        // rather than in a browser tab.
        detailLabel = NSTextField(wrappingLabelWithString: "")
        detailLabel.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        detailLabel.textColor = NSColor.secondaryLabelColor
        detailLabel.lineBreakMode = .byWordWrapping
        detailLabel.maximumNumberOfLines = 0
        detailLabel.preferredMaxLayoutWidth = rect.width - 28

        let sep = NSBox()
        sep.boxType = .separator

        // ── File browser pane (middle) ──
        // Path crumb + Up / Home buttons.
        browserPathLabel = NSTextField(labelWithString: "")
        browserPathLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        browserPathLabel.textColor = NSColor.secondaryLabelColor
        browserPathLabel.lineBreakMode = .byTruncatingMiddle

        let browserUpButton = NSButton(title: "↑", target: self, action: #selector(browserGoUp(_:)))
        browserUpButton.bezelStyle = .rounded
        browserUpButton.controlSize = .small
        browserUpButton.toolTip = "Go up one directory"

        let browserHomeButton = NSButton(title: "~/work", target: self, action: #selector(browserGoHome(_:)))
        browserHomeButton.bezelStyle = .rounded
        browserHomeButton.controlSize = .small
        browserHomeButton.toolTip = "Jump to ~/work"

        // Vault jump — flip the browser into the per-chat save folder
        // (drafts / conversation log / state JSON / audio/). Re-pressing
        // it pops back to where you were so it round-trips.
        let browserVaultButton = NSButton(title: "🗄 vault",
                                          target: self,
                                          action: #selector(browserToggleVault(_:)))
        browserVaultButton.bezelStyle = .rounded
        browserVaultButton.controlSize = .small
        browserVaultButton.toolTip = "Show this chat's save folder " +
            "(drafts, conversation log, dictation audio)"

        let browserCrumbRow = NSStackView(views: [browserPathLabel, NSView(),
                                                   browserVaultButton,
                                                   browserHomeButton, browserUpButton])
        browserCrumbRow.orientation = .horizontal
        browserCrumbRow.spacing = 6
        browserCrumbRow.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        browserFilterField = NSTextField()
        browserFilterField.placeholderString = "Filter (fuzzy)…"
        browserFilterField.font = NSFont.systemFont(ofSize: 12)
        browserFilterField.delegate = self  // → controlTextDidChange fires renderBrowser

        browserScroll = NSScrollView()
        browserScroll.borderType = .bezelBorder
        browserScroll.hasVerticalScroller = true
        browserScroll.drawsBackground = false

        browserStack = NSStackView()
        browserStack.orientation = .vertical
        browserStack.alignment = .leading
        browserStack.distribution = .fill
        browserStack.spacing = 1
        browserStack.edgeInsets = NSEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        browserStack.translatesAutoresizingMaskIntoConstraints = false

        // FlippedView so the stack lays out top-down inside the scroll view.
        // CRITICAL: the document view must grow with its content — without
        // bottomAnchor pinned to the stack, the documentView stayed at its
        // initial fixed height and scrolling died past the first ~160px.
        let browserFlipped = FlippedView()
        browserFlipped.translatesAutoresizingMaskIntoConstraints = false
        browserFlipped.addSubview(browserStack)
        browserScroll.documentView = browserFlipped
        NSLayoutConstraint.activate([
            browserStack.topAnchor.constraint(equalTo: browserFlipped.topAnchor),
            browserStack.leadingAnchor.constraint(equalTo: browserFlipped.leadingAnchor),
            browserStack.trailingAnchor.constraint(equalTo: browserFlipped.trailingAnchor),
            browserStack.bottomAnchor.constraint(equalTo: browserFlipped.bottomAnchor),
            // Match scroll view's content width — reflows on resize, never
            // produces horizontal scrolling.
            browserFlipped.widthAnchor.constraint(equalTo: browserScroll.widthAnchor),
        ])

        let sep2 = NSBox()
        sep2.boxType = .separator

        // ── Chat pane (bottom) ──
        chatHeaderLabel = NSTextField(labelWithString: "")
        chatHeaderLabel.font = NSFont.systemFont(ofSize: 11, weight: .medium)
        chatHeaderLabel.textColor = NSColor.secondaryLabelColor
        chatHeaderLabel.lineBreakMode = .byTruncatingMiddle

        chatCwdButton = NSButton(title: "📂", target: self, action: #selector(pickChatCwd(_:)))
        chatCwdButton.bezelStyle = .rounded
        chatCwdButton.controlSize = .small
        chatCwdButton.toolTip = "Switch project — popup of ~/work/ subdirs (sorted by recency)"

        chatFileButton = NSButton(title: "📄", target: self, action: #selector(pickChatFile(_:)))
        chatFileButton.bezelStyle = .rounded
        chatFileButton.controlSize = .small
        chatFileButton.toolTip = "Anchor a file — next message references it via @path"

        chatSessionsButton = NSButton(title: "Sessions ▾", target: self, action: #selector(showSessionsMenu(_:)))
        chatSessionsButton.bezelStyle = .rounded
        chatSessionsButton.controlSize = .small
        chatSessionsButton.toolTip = "Switch to another saved conversation in this folder"

        chatResetButton = NSButton(title: "New", target: self, action: #selector(resetChat(_:)))
        chatResetButton.bezelStyle = .rounded
        chatResetButton.controlSize = .small
        chatResetButton.toolTip = "Start a fresh session in this folder"

        // Vault button — reveals the per-project save folder in Finder so
        // the user can SEE everything AppleToolbox writes for this chat:
        //   .appletoolbox-draft.md         (live composer mirror)
        //   .appletoolbox-conversation.md  (chronological log)
        //   .appletoolbox-state.json       (session ids + names)
        //   audio/dictation-*.caf          (raw mic capture per session)
        // Cmd-click reveals the Finder window with the folder selected.
        chatVaultButton = NSButton(title: "🗄", target: self, action: #selector(openChatVault(_:)))
        chatVaultButton.bezelStyle = .rounded
        chatVaultButton.controlSize = .small
        chatVaultButton.toolTip = "Open this chat's save folder in Finder " +
            "(drafts, conversation log, dictation audio)"

        // Hand-off: open the same session in iTerm / Terminal as a live
        // interactive `claude --resume <uuid>`. Same JSONL, same context;
        // the panel just stops being the surface, the terminal takes over.
        chatTerminalButton = NSButton(title: "↗ Terminal",
                                       target: self, action: #selector(openInTerminal(_:)))
        chatTerminalButton.bezelStyle = .rounded
        chatTerminalButton.controlSize = .small
        chatTerminalButton.toolTip = "Open this session in iTerm/Terminal — same conversation, interactive"

        let chatHeaderRow = NSStackView(views: [chatHeaderLabel, NSView(),
            chatTerminalButton, chatVaultButton, chatCwdButton, chatFileButton,
            chatSessionsButton, chatResetButton])
        chatHeaderRow.orientation = .horizontal
        chatHeaderRow.spacing = 8
        chatHeaderRow.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
        chatHeaderRow.setHuggingPriority(.defaultLow, for: .horizontal)

        let chatScroll = NSScrollView()
        chatScroll.borderType = .bezelBorder
        chatScroll.hasVerticalScroller = true
        chatScroll.drawsBackground = true
        chatScroll.autohidesScrollers = false

        chatTranscript = NSTextView(frame: chatScroll.bounds)
        chatTranscript.autoresizingMask = [.width]
        chatTranscript.isEditable = false
        chatTranscript.isSelectable = true
        // Make programmatically-added .link attributes clickable — NSTextView
        // hands clicks to NSWorkspace.open by default when the view is
        // non-editable + selectable. The dict here just paints them blue +
        // underlined + pointing-hand-cursor so they look obviously clickable.
        chatTranscript.linkTextAttributes = [
            .foregroundColor: NSColor.systemBlue,
            .underlineStyle: NSUnderlineStyle.single.rawValue,
            .cursor: NSCursor.pointingHand,
        ]
        chatTranscript.drawsBackground = false
        chatTranscript.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        chatTranscript.textContainerInset = NSSize(width: 6, height: 6)
        chatScroll.documentView = chatTranscript

        // Multi-line composer — NSTextView wrapped in NSScrollView so the
        // user gets full Apple key primitives (arrow / Opt+arrow / Cmd+arrow
        // for char/word/line nav, shift-extend selection, Cmd+A/C/V/Z, emacs
        // bindings, find bar, spellcheck). Return = send; Shift+Return =
        // newline. Dictation lands here directly because NSTextView is the
        // responder that owns `startDictation:`.
        chatInputScroll = NSScrollView()
        chatInputScroll.hasVerticalScroller = true
        chatInputScroll.borderType = .bezelBorder
        chatInputScroll.autohidesScrollers = true
        chatInputScroll.translatesAutoresizingMaskIntoConstraints = false

        let inputTextContainer = NSTextContainer(
            containerSize: NSSize(width: 0, height: CGFloat.greatestFiniteMagnitude))
        inputTextContainer.widthTracksTextView = true
        let inputLayout = NSLayoutManager()
        inputLayout.addTextContainer(inputTextContainer)
        let inputStorage = NSTextStorage()
        inputStorage.addLayoutManager(inputLayout)

        chatInput = ChatInputTextView(frame: .zero, textContainer: inputTextContainer)
        chatInput.placeholderString =
            "Talk to Claude in \((chatCwd as NSString).lastPathComponent)…  (Return to send · Shift+Return for newline)"
        chatInput.delegate = self
        chatInput.font = NSFont.systemFont(ofSize: 12)
        chatInput.isEditable = true
        chatInput.isSelectable = true
        chatInput.isRichText = false
        chatInput.allowsUndo = true
        chatInput.isAutomaticQuoteSubstitutionEnabled = false
        chatInput.isAutomaticDashSubstitutionEnabled = false
        chatInput.isAutomaticTextReplacementEnabled = false
        chatInput.isContinuousSpellCheckingEnabled = true
        chatInput.usesFindBar = true
        chatInput.textContainerInset = NSSize(width: 2, height: 4)
        chatInput.autoresizingMask = [.width]
        chatInput.isVerticallyResizable = true
        chatInput.isHorizontallyResizable = false
        chatInput.minSize = NSSize(width: 0, height: 0)
        chatInput.maxSize = NSSize(width: CGFloat.greatestFiniteMagnitude,
                                   height: CGFloat.greatestFiniteMagnitude)
        chatInputScroll.documentView = chatInput

        chatSendButton = NSButton(title: "Send", target: self, action: #selector(sendChat(_:)))
        chatSendButton.bezelStyle = .rounded
        chatSendButton.keyEquivalent = "\r"

        // Native-style dictation button — SF Symbol mic on a borderless square
        // bezel, exactly the affordance Mail / Notes / Messages put next to
        // their compose fields. Click → focus chat input → invoke the
        // standard `startDictation:` responder action, which AppKit walks
        // up the responder chain to the field editor (NSTextView) that owns
        // the actual dictation pipeline.
        chatDictateButton = NSButton(title: "", target: self, action: #selector(startDictationInChat(_:)))
        if #available(macOS 11.0, *) {
            chatDictateButton.image = NSImage(systemSymbolName: "mic.fill",
                                              accessibilityDescription: "Start Dictation")
        } else {
            chatDictateButton.title = "🎙"
        }
        chatDictateButton.bezelStyle = .accessoryBarAction
        chatDictateButton.isBordered = false
        chatDictateButton.imageScaling = .scaleProportionallyDown
        chatDictateButton.setButtonType(.momentaryChange)
        chatDictateButton.toolTip = "Start Dictation (system)"
        chatDictateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatDictateButton.widthAnchor.constraint(equalToConstant: 22),
            chatDictateButton.heightAnchor.constraint(equalToConstant: 22),
        ])

        // Smart dictation button — SFSpeechRecognizer with cursor-aware
        // partials. Sits next to the system mic so both flavors are
        // available: classic startDictation: for one-shot bursts, smart
        // dictation when you want to speak-edit-resume from the cursor.
        chatSmartDictateButton = NSButton(title: "", target: self,
                                          action: #selector(toggleSmartDictation(_:)))
        if #available(macOS 11.0, *) {
            chatSmartDictateButton.image = NSImage(systemSymbolName: "waveform.circle",
                                                   accessibilityDescription: "Smart Dictation")
        } else {
            chatSmartDictateButton.title = "〰"
        }
        chatSmartDictateButton.bezelStyle = .accessoryBarAction
        chatSmartDictateButton.isBordered = false
        chatSmartDictateButton.imageScaling = .scaleProportionallyDown
        chatSmartDictateButton.setButtonType(.momentaryChange)
        chatSmartDictateButton.toolTip = "Smart Dictation (⌘D · global ⌃⌥⌘D · speak + edit + resume)"
        chatSmartDictateButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chatSmartDictateButton.widthAnchor.constraint(equalToConstant: 22),
            chatSmartDictateButton.heightAnchor.constraint(equalToConstant: 22),
        ])

        // Repaint the smart-dictation button + header line on state flip.
        // Three visual states: OFF (hollow waveform, no tint), LIVE (filled
        // waveform, red), PAUSED while running (hollow waveform, amber —
        // mic is held while the user is editing with the keyboard).
        smartDictation.onStateChange = { [weak self] running in
            guard let self = self else { return }
            self.paintSmartDictateButton()
            self.updateChatHeader()
        }
        smartDictation.onPauseChange = { [weak self] _ in
            self?.paintSmartDictateButton()
            self?.updateChatHeader()
        }

        let inputRow = NSStackView(views: [chatInputScroll,
                                           chatSmartDictateButton,
                                           chatDictateButton,
                                           chatSendButton])
        inputRow.orientation = .horizontal
        inputRow.spacing = 8
        inputRow.alignment = .top   // buttons pin to top as composer grows
        inputRow.edgeInsets = NSEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)

        // Outer vertical layout
        let outer = NSStackView(views: [headerLabel, statusScroll, detailLabel, sep,
                                         browserCrumbRow, browserFilterField, browserScroll, sep2,
                                         chatHeaderRow, chatScroll, inputRow])
        outer.orientation = .vertical
        outer.alignment = .leading
        outer.distribution = .fill
        outer.spacing = 6
        outer.edgeInsets = NSEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        outer.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(outer)

        NSLayoutConstraint.activate([
            outer.topAnchor.constraint(equalTo: content.topAnchor),
            outer.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            outer.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            outer.bottomAnchor.constraint(equalTo: content.bottomAnchor),

            headerLabel.heightAnchor.constraint(equalToConstant: 20),
            headerLabel.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 12),
            headerLabel.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -12),

            statusScroll.heightAnchor.constraint(equalToConstant: 200),
            statusScroll.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 8),
            statusScroll.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -8),

            detailLabel.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 14),
            detailLabel.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -14),

            sep.heightAnchor.constraint(equalToConstant: 1),
            sep.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            sep.trailingAnchor.constraint(equalTo: outer.trailingAnchor),

            browserCrumbRow.heightAnchor.constraint(equalToConstant: 22),
            browserCrumbRow.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            browserCrumbRow.trailingAnchor.constraint(equalTo: outer.trailingAnchor),

            browserFilterField.heightAnchor.constraint(equalToConstant: 24),
            browserFilterField.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 8),
            browserFilterField.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -8),

            browserScroll.heightAnchor.constraint(equalToConstant: 180),
            browserScroll.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 8),
            browserScroll.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -8),

            sep2.heightAnchor.constraint(equalToConstant: 1),
            sep2.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            sep2.trailingAnchor.constraint(equalTo: outer.trailingAnchor),

            chatHeaderRow.heightAnchor.constraint(equalToConstant: 22),
            chatHeaderRow.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            chatHeaderRow.trailingAnchor.constraint(equalTo: outer.trailingAnchor),

            chatScroll.leadingAnchor.constraint(equalTo: outer.leadingAnchor, constant: 8),
            chatScroll.trailingAnchor.constraint(equalTo: outer.trailingAnchor, constant: -8),

            // Composer: 3 lines minimum (~58pt @ 12pt system font), grows
            // up to ~8 lines before scrolling kicks in inside chatInputScroll.
            chatInputScroll.heightAnchor.constraint(greaterThanOrEqualToConstant: 58),
            chatInputScroll.heightAnchor.constraint(lessThanOrEqualToConstant: 140),
            inputRow.leadingAnchor.constraint(equalTo: outer.leadingAnchor),
            inputRow.trailingAnchor.constraint(equalTo: outer.trailingAnchor),
        ])

        panel.contentView = content
        panel.makeKeyAndOrderFront(nil)
        loadBrowserItems()  // populate the file browser with the initial cwd
        // Initial focus = file browser so cursor keys immediately navigate the
        // project list. Switch to chat composer with Tab / by clicking it.
        panel.makeFirstResponder(browserFilterField)
    }

    func currentMtime() -> TimeInterval {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: sourcePath),
              let date = attrs[.modificationDate] as? Date else { return 0 }
        return date.timeIntervalSince1970
    }

    func checkSource() {
        guard !reloading else { return }
        // Defer rebuild while a chat is streaming — relaunching would kill it.
        // The mtime check fires every 1s so we'll catch up immediately when
        // the response completes.
        guard !chatBusy else { return }
        let m = currentMtime()
        guard m > 0, m != sourceMtime else { return }
        sourceMtime = m
        reloading = true
        headerLabel.stringValue = "🧰  ● rebuilding…"
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let out = run("/bin/bash", ["\(TOPBAR)/build.sh"], timeout: 60)
            DispatchQueue.main.async {
                if out.contains("error:") || out.lowercased().contains("error") && !out.contains("Built:") {
                    self.headerLabel.stringValue = "🧰  ✗ build failed (see console)"
                    fputs("[AppleToolbox --live] build output:\n\(out)\n", stderr)
                    self.reloading = false
                    return
                }
                self.headerLabel.stringValue = "🧰  ↻ relaunching…"
                self.relaunchSelf()
            }
        }
    }

    func relaunchSelf() {
        let bin = "\(TOPBAR)/AppleToolbox.app/Contents/MacOS/AppleToolbox"
        guard FileManager.default.isExecutableFile(atPath: bin) else {
            headerLabel.stringValue = "🧰  ✗ binary missing: \(bin)"
            reloading = false
            return
        }
        let argv: [UnsafeMutablePointer<CChar>?] = [strdup(bin), strdup("--live"), nil]
        execv(bin, argv)
        // execv only returns on failure
        headerLabel.stringValue = "🧰  ✗ execv failed"
        reloading = false
    }

    func renderStatus() {
        struct Row {
            let title: String
            let body: String
            let cmd: String
            let args: [String]
            /// Optional small clickable icons attached to the right side of the
            /// row — each one fires its own `open` invocation when clicked.
            let icons: [IconStripLaunch]
            /// Identifier for the inline-detail renderer (e.g. "climate").
            let kind: String
            /// SF Symbol name used as the row's leading icon. Apple-shipping
            /// glyphs (`wifi`, `battery.100`, `envelope`, …) replace the
            /// generic emoji prefixes — same visual language as Control
            /// Centre / System Settings.
            let symbol: String
        }
        var rows: [Row] = []
        func add(_ title: String, _ body: String?, _ cmd: String, _ args: [String] = [],
                 icons: [IconStripLaunch] = [], kind: String = "", symbol: String = "") {
            guard let b = body, !b.isEmpty, b != "—" else { return }
            rows.append(Row(title: title, body: b, cmd: cmd, args: args, icons: icons, kind: kind, symbol: symbol))
        }
        add("Climate", climateRead(),
            "/usr/bin/open", ["\(HOME)/work/homepod-watcher/climate-graph.html"], kind: "climate",
            symbol: "thermometer.medium")
        add("Battery", batteryRead(),
            "/usr/bin/open", ["x-apple.systempreferences:com.apple.preference.battery"],
            symbol: "battery.100")

        // 3 icons only — GrandPerspective, DaisyDisk, composite. All scan
        // $HOME via UI-scripting (both apps are sandboxed App Store builds,
        // so paths must be user-selected through their File → Scan Folder
        // NSOpenPanel). Icons render on a SECOND row below the disk text.
        var diskIcons: [IconStripLaunch] = []
        if let p = appPath("GrandPerspective") {
            diskIcons.append(IconStripLaunch(iconSource: p,
                openArgs: [HOME],
                tooltip: "GrandPerspective — mosaic, scan Home",
                cmd: "\(TOPBAR)/scripts/grandperspective-scan-folder.sh"))
        }
        if let p = appPath("DaisyDisk") {
            diskIcons.append(IconStripLaunch(iconSource: p,
                openArgs: [HOME],
                tooltip: "DaisyDisk — pie chart, scan Home",
                cmd: "\(TOPBAR)/scripts/daisydisk-scan-folder.sh"))
        }
        if let gp = appPath("GrandPerspective"), let dd = appPath("DaisyDisk") {
            let composite = compositeAppIcons([gp, dd])
            diskIcons.append(IconStripLaunch(
                iconSource: gp,
                openArgs: [HOME],
                tooltip: "Scan both — GrandPerspective + DaisyDisk side-by-side, Home",
                cmd: "\(TOPBAR)/scripts/disk-dual-scan.sh",
                iconImage: composite))
        }
        add("Disk",    diskRead(),
            "/usr/bin/open", ["x-apple.systempreferences:com.apple.settings.Storage"],
            icons: diskIcons, symbol: "externaldrive")
        add("Wi-Fi",   wifiRead(),
            "/usr/bin/open", ["x-apple.systempreferences:com.apple.Network-Settings.extension"],
            symbol: "wifi")
        add("Mail",    mailUnreadRead(),
            "/usr/bin/open", ["-a", "Mail"], symbol: "envelope")
        if let v = mailVIPUnreadRead() {
            add("VIP",   v,
                "\(TOPBAR)/scripts/mail-select-mailbox.sh", ["VIPs"], symbol: "star.fill")
        }
        if let v = mailSmartMailboxUnreadRead("Today") {
            add("Today", v,
                "\(TOPBAR)/scripts/mail-select-mailbox.sh", ["Today"], symbol: "calendar")
        }
        if let v = mailSmartMailboxUnreadRead("Human Only") {
            add("Human Only", v,
                "\(TOPBAR)/scripts/mail-select-mailbox.sh", ["Human Only"], symbol: "person.fill")
        }
        if let v = mailSmartMailboxUnreadRead("Free Energy") {
            add("Free Energy", v,
                "\(TOPBAR)/scripts/mail-select-mailbox.sh", ["Free Energy"], symbol: "bolt.fill")
        }
        add("Music",   nowPlayingRead(),
            "/usr/bin/open", ["-a", "Music"], symbol: "music.note")
        add("Whisp",   whispQueueRead(),
            "/usr/bin/open", ["\(HOME)/work/comms/queue/whisp-results"], symbol: "mic.fill")
        if let v = vaultStatusRead() {
            add("Vault", v,
                "/usr/bin/open", ["\(HOME)/work/cc/vault/_index/transcripts-by-date.md"], symbol: "books.vertical.fill")
        }
        if let f = fileerataQueueRead() {
            add("Fileerata", f,
                "/usr/bin/open", ["\(HOME)/work/comms/queue/segment-outbox"], symbol: "scissors")
        }

        rowsStack.arrangedSubviews.forEach {
            rowsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        rowButtons.removeAll()
        rowKinds.removeAll()
        let titleW = rows.map { $0.title.count }.max() ?? 0
        for r in rows {
            let padded = r.title.padding(toLength: titleW + 2, withPad: " ", startingAt: 0) + r.body
            let btn = LiveRowButton(title: padded, target: self, action: #selector(rowClicked(_:)))
            btn.cmd = r.cmd
            btn.args = r.args
            btn.bezelStyle = .inline
            btn.isBordered = false
            btn.alignment = .left
            btn.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
            btn.contentTintColor = NSColor.labelColor
            btn.translatesAutoresizingMaskIntoConstraints = false
            // SF Symbol on the left, monospaced text on the right. All rows
            // get the same icon-column width via fixed-point symbol config,
            // so the text column stays aligned without the emoji prefix.
            if !r.symbol.isEmpty, #available(macOS 11.0, *),
               let img = NSImage(systemSymbolName: r.symbol, accessibilityDescription: r.title)?
                .withSymbolConfiguration(NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)) {
                btn.image = img
                btn.imagePosition = .imageLeft
                btn.imageHugsTitle = true
                (btn.cell as? NSButtonCell)?.imageScaling = .scaleNone
            } else {
                (btn.cell as? NSButtonCell)?.imagePosition = .noImage
            }

            if r.icons.isEmpty {
                rowsStack.addArrangedSubview(btn)
            } else {
                // Horizontal lane: text button on the left (flexible), icon
                // buttons hugging the right edge. NSWorkspace.icon(forFile:)
                // gives each app its real .icns so the row looks like the Dock.
                // Two stacked rows: text label on row 1, icon strip indented
                // on row 2. Data reading stays uncrowded, icons get room.
                let group = NSStackView()
                group.orientation = .vertical
                group.alignment = .leading
                group.spacing = 4
                group.translatesAutoresizingMaskIntoConstraints = false
                group.addArrangedSubview(btn)

                let lane = NSStackView()
                lane.orientation = .horizontal
                lane.alignment = .centerY
                lane.spacing = 6
                lane.translatesAutoresizingMaskIntoConstraints = false
                lane.edgeInsets = NSEdgeInsets(top: 0, left: 18, bottom: 0, right: 0)
                for (idx, l) in r.icons.enumerated() {
                    let isComposite = l.iconImage != nil
                    let btnW: CGFloat = isComposite ? 36 : 22
                    let iconBtn = LiveIconButton(frame: NSRect(x: 0, y: 0, width: btnW, height: 22))
                    let img: NSImage
                    if let override = l.iconImage {
                        img = override
                    } else if FileManager.default.fileExists(atPath: l.iconSource) {
                        img = NSWorkspace.shared.icon(forFile: l.iconSource)
                    } else {
                        img = NSImage(size: NSSize(width: 18, height: 18))
                    }
                    if !isComposite { img.size = NSSize(width: 18, height: 18) }
                    iconBtn.image = img
                    iconBtn.imagePosition = .imageOnly
                    iconBtn.bezelStyle = .regularSquare
                    iconBtn.isBordered = false
                    iconBtn.toolTip = l.tooltip
                    iconBtn.cmd = l.cmd
                    iconBtn.openArgs = l.openArgs
                    iconBtn.tag = idx
                    iconBtn.target = self
                    iconBtn.action = #selector(iconClicked(_:))
                    iconBtn.translatesAutoresizingMaskIntoConstraints = false
                    iconBtn.widthAnchor.constraint(equalToConstant: btnW).isActive = true
                    iconBtn.heightAnchor.constraint(equalToConstant: 22).isActive = true
                    iconBtn.setContentHuggingPriority(.required, for: .horizontal)
                    lane.addArrangedSubview(iconBtn)
                }
                group.addArrangedSubview(lane)
                rowsStack.addArrangedSubview(group)
            }
            rowButtons.append(btn)
            rowKinds.append(r.kind)
        }
        if rowButtons.isEmpty { selectedIndex = 0 }
        else { selectedIndex = min(selectedIndex, rowButtons.count - 1) }
        applyHighlight()

        let fmt = DateFormatter()
        fmt.dateFormat = "HH:mm:ss"
        headerLabel.stringValue = rows.isEmpty
            ? "🧰  ● live  ·  (no readers returned data)"
            : "🧰  ● live  ·  \(fmt.string(from: Date()))  ·  ↑↓ + ⏎ or click"
    }

    @objc func rowClicked(_ sender: LiveRowButton) {
        runDetached(sender.cmd, sender.args)
    }

    @objc func iconClicked(_ sender: LiveIconButton) {
        runDetached(sender.cmd, sender.openArgs)
    }

    /// Posted by the menu-bar process when the user picks "Show Live Panel".
    /// Brings the (possibly orderOut'd) panel back to front.
    @objc func showLivePanelRequested(_ note: Notification) {
        panel?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // ─── chat: state persistence ───────────────────────────────────────────

    func loadChatState() {
        sessionNames = [:]
        currentSessionId = nil
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: sessionStateFile)),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }
        if let sid = obj["current_session_id"] as? String, !sid.isEmpty {
            currentSessionId = sid
        }
        if let names = obj["names"] as? [String: String] {
            sessionNames = names
        }
    }

    func saveChatState() {
        let obj: [String: Any] = [
            "current_session_id": currentSessionId ?? "",
            "names": sessionNames,
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: obj, options: [.prettyPrinted]) else { return }
        let dir = (sessionStateFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        try? data.write(to: URL(fileURLWithPath: sessionStateFile))
    }

    // ─── composer draft + conversation log persistence ─────────────────────
    //
    // Every keystroke + every dictation partial pings scheduleDraftSave();
    // a 250 ms debounce coalesces a dictation burst into one disk write.
    // On launch the draft is loaded back into chatInput so unsent text
    // survives `--live` rebuilds and reboots. On sendChat the draft is
    // cleared and the message gets appended to the conversation log (the
    // "two-way communication saving" piece), where Claude's reply gets
    // appended as it streams.

    func loadComposerDraft() {
        guard chatInput != nil,
              let text = try? String(contentsOfFile: composerDraftFile, encoding: .utf8),
              !text.isEmpty else { return }
        smartDictation.suppressEditCallbacks = true
        chatInput.string = text
        chatInput.setSelectedRange(NSRange(location: (text as NSString).length, length: 0))
        smartDictation.suppressEditCallbacks = false
        chatInput.needsDisplay = true
    }

    func scheduleDraftSave() {
        draftSaveTimer?.invalidate()
        draftSaveTimer = Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) { [weak self] _ in
            self?.saveDraft()
        }
    }

    func saveDraft() {
        guard let chatInput = chatInput else { return }
        let dir = (composerDraftFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let text = chatInput.string
        if text.isEmpty {
            try? FileManager.default.removeItem(atPath: composerDraftFile)
        } else {
            try? text.write(toFile: composerDraftFile, atomically: true, encoding: .utf8)
        }
    }

    var conversationLogFile: String {
        let enc = chatCwd.replacingOccurrences(of: "/", with: "-")
        return "\(HOME)/.claude/projects/\(enc)/.appletoolbox-conversation.md"
    }

    func appendToConversationLog(_ entry: String) {
        let dir = (conversationLogFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        let data = entry.data(using: .utf8) ?? Data()
        if FileManager.default.fileExists(atPath: conversationLogFile) {
            if let handle = try? FileHandle(forWritingTo: URL(fileURLWithPath: conversationLogFile)) {
                handle.seekToEndOfFile()
                handle.write(data)
                try? handle.close()
            }
        } else {
            try? data.write(to: URL(fileURLWithPath: conversationLogFile))
        }
    }

    func updateChatHeader() {
        let label = sessionLabel(currentSessionId) ?? "new"
        let cwdAbbr = (chatCwd as NSString).abbreviatingWithTildeInPath
        let busyMark = chatBusy ? "  ·  ⏳ streaming" : ""
        let fileMark = anchoredFile.map { "  ·  📄 \(($0 as NSString).lastPathComponent)" } ?? ""
        chatHeaderLabel.stringValue = "💬 \(cwdAbbr)  ·  \(label)\(fileMark)\(busyMark)"
        chatInput?.placeholderString =
            "Talk to Claude in \((chatCwd as NSString).lastPathComponent)…  (Return to send)"
    }

    /// Human-friendly label for a session id: the user's name if set, otherwise
    /// the last 8 chars of the UUID.
    func sessionLabel(_ sid: String?) -> String? {
        guard let sid = sid, !sid.isEmpty else { return nil }
        if let name = sessionNames[sid], !name.isEmpty { return name }
        return "…\(String(sid.suffix(8)))"
    }

    // ─── chat: session picker + naming ─────────────────────────────────────

    struct SessionInfo {
        let uuid: String
        let snippet: String
        let mtime: Date
    }

    /// List sessions in the current project, newest first. Reads filenames in
    /// Mirror display names set via Claude Code's `/rename` (or `claude -n
    /// <name>` at launch) into our persistent state. Those names live in
    /// `~/.claude/sessions/<pid>.json` while the process is alive — once the
    /// CLI exits the file disappears, so we copy any names matching this
    /// project's cwd into our sessionNames map. Returns true if anything
    /// changed (so the caller can refresh the header).
    @discardableResult
    func refreshNamesFromClaudeSessions() -> Bool {
        let dir = "\(HOME)/.claude/sessions"
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return false }
        var changed = false
        for f in files where f.hasSuffix(".json") {
            let path = "\(dir)/\(f)"
            guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let cwd = obj["cwd"] as? String, cwd == chatCwd,
                  let sid = obj["sessionId"] as? String,
                  let name = obj["name"] as? String, !name.isEmpty else { continue }
            if sessionNames[sid] != name {
                sessionNames[sid] = name
                changed = true
            }
        }
        if changed { saveChatState() }
        return changed
    }

    /// `~/.claude/projects/<encoded-cwd>/*.jsonl` and pulls a snippet of the
    /// first user message from each.
    func listSessions(limit: Int = 30) -> [SessionInfo] {
        refreshNamesFromClaudeSessions()
        let dir = projectDir
        guard let files = try? FileManager.default.contentsOfDirectory(atPath: dir) else { return [] }
        let jsonl = files.filter { $0.hasSuffix(".jsonl") }
        let infos: [SessionInfo] = jsonl.compactMap { name in
            let path = "\(dir)/\(name)"
            let uuid = (name as NSString).deletingPathExtension
            guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
                  let mtime = attrs[.modificationDate] as? Date else { return nil }
            return SessionInfo(uuid: uuid, snippet: sessionSnippet(path: path), mtime: mtime)
        }
        return infos.sorted { $0.mtime > $1.mtime }.prefix(limit).map { $0 }
    }

    /// Extracts the first user message text from a session JSONL. Falls back
    /// to "(empty)" if none found in the first 50 lines (sessions usually have
    /// the first user message on line 1).
    func sessionSnippet(path: String) -> String {
        guard let fh = FileHandle(forReadingAtPath: path) else { return "(unreadable)" }
        defer { try? fh.close() }
        let data = fh.readData(ofLength: 16_384)  // first ~16K is plenty
        guard let s = String(data: data, encoding: .utf8) else { return "(binary?)" }
        for line in s.split(separator: "\n").prefix(50) {
            guard let lineData = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any],
                  obj["type"] as? String == "user" else { continue }
            if let msg = obj["message"] as? [String: Any] {
                if let c = msg["content"] as? String, !c.isEmpty {
                    return trimSnippet(c)
                }
                if let arr = msg["content"] as? [[String: Any]] {
                    for item in arr {
                        if let t = item["type"] as? String, t == "text",
                           let txt = item["text"] as? String, !txt.isEmpty {
                            return trimSnippet(txt)
                        }
                    }
                }
            }
        }
        return "(no user prompt)"
    }

    func trimSnippet(_ s: String) -> String {
        let oneline = s.replacingOccurrences(of: "\n", with: " ")
                       .trimmingCharacters(in: .whitespaces)
        return oneline.count > 60 ? String(oneline.prefix(60)) + "…" : oneline
    }

    @objc func showSessionsMenu(_ sender: Any?) {
        let menu = NSMenu()
        let sessions = listSessions()
        if sessions.isEmpty {
            let empty = NSMenuItem(title: "(no saved sessions in this folder)", action: nil, keyEquivalent: "")
            empty.isEnabled = false
            menu.addItem(empty)
        } else {
            let fmt = DateFormatter()
            fmt.dateFormat = "MM-dd HH:mm"
            for s in sessions {
                let nameOrSnippet = sessionNames[s.uuid] ?? s.snippet
                let title = "\(fmt.string(from: s.mtime))   \(nameOrSnippet)"
                let item = NSMenuItem(title: title, action: #selector(selectSession(_:)), keyEquivalent: "")
                item.target = self
                item.representedObject = s.uuid
                if s.uuid == currentSessionId { item.state = .on }
                menu.addItem(item)
            }
        }
        menu.addItem(.separator())

        let renameItem = NSMenuItem(title: "Rename current session…",
                                    action: #selector(renameCurrentSession(_:)), keyEquivalent: "")
        renameItem.target = self
        renameItem.isEnabled = currentSessionId != nil
        menu.addItem(renameItem)

        let revealItem = NSMenuItem(title: "Reveal project folder in Finder",
                                    action: #selector(revealProjectDir(_:)), keyEquivalent: "")
        revealItem.target = self
        menu.addItem(revealItem)

        menu.addItem(.separator())
        let grantItem = NSMenuItem(title: "🔐 Grant All Permissions…",
                                   action: #selector(grantAllPermissions(_:)), keyEquivalent: "")
        grantItem.target = self
        menu.addItem(grantItem)

        guard let button = sender as? NSView else { return }
        menu.popUp(positioning: nil,
                   at: NSPoint(x: 0, y: button.bounds.height + 4),
                   in: button)
    }

    @objc func selectSession(_ sender: NSMenuItem) {
        guard let uuid = sender.representedObject as? String else { return }
        resumeSession(uuid)
    }

    /// Switch the chat to the given session UUID. Used by both the Sessions ▾
    /// dropdown and the in-browser 💬 rows so behaviour stays unified.
    /// Replays the session's stored transcript into the chat pane so the user
    /// SEES the previous conversation, not just an empty pane labelled with a
    /// session ID. The next Send still spawns `claude --resume <sid>` and
    /// continues the real conversation.
    func resumeSession(_ uuid: String) {
        guard uuid != currentSessionId else { return }
        if let p = chatProcess, p.isRunning { p.terminate() }
        currentSessionId = uuid
        saveChatState()
        updateChatHeader()
        let label = sessionLabel(uuid) ?? uuid

        // Clear the pane and replay the stored transcript so the user lands
        // in the same conversation they remember, not just at its name.
        chatTranscript.textStorage?.setAttributedString(NSAttributedString(string: ""))
        appendTranscript("── resumed: \(label) ──\n",
                         color: NSColor(white: 0.7, alpha: 1.0))
        replaySessionTranscript(uuid: uuid)
    }

    /// Read `~/.claude/projects/<encoded-cwd>/<uuid>.jsonl` and render each
    /// user/assistant turn into the chat pane using the same `appendTranscript`
    /// styling Send uses, so resumed sessions look identical to live ones.
    func replaySessionTranscript(uuid: String) {
        let path = "\(projectDir)/\(uuid).jsonl"
        guard let data = try? String(contentsOfFile: path, encoding: .utf8) else {
            appendTranscript("(no stored transcript at \(path))\n",
                             color: NSColor(white: 0.6, alpha: 1.0))
            return
        }
        var turnCount = 0
        for line in data.split(separator: "\n") {
            guard let bytes = line.data(using: .utf8),
                  let obj = try? JSONSerialization.jsonObject(with: bytes) as? [String: Any]
            else { continue }
            // Claude Code stores events as either {type:"user", message:{...}}
            // or {type:"assistant", message:{...}}; message.content is either
            // a string or an array of content blocks ({type:"text", text:"..."}).
            guard let type = obj["type"] as? String,
                  let msg = obj["message"] as? [String: Any] else { continue }
            let text = extractMessageText(msg)
            guard !text.isEmpty else { continue }
            switch type {
            case "user":
                appendTranscript("\n▶ You\n", color: .systemOrange, bold: true)
                appendTranscript("\(text)\n", color: .white)
                turnCount += 1
            case "assistant":
                appendTranscript("\n● Claude\n", color: .systemTeal, bold: true)
                appendTranscript("\(text)\n", color: .white)
                turnCount += 1
            default:
                continue
            }
        }
        if turnCount == 0 {
            appendTranscript("(transcript empty)\n",
                             color: NSColor(white: 0.6, alpha: 1.0))
        } else {
            appendTranscript("\n── \(turnCount) turn\(turnCount == 1 ? "" : "s") replayed · type below to continue ──\n",
                             color: NSColor(white: 0.5, alpha: 1.0))
        }
    }

    /// Extract the human-readable text from a Claude Code message dict.
    /// content can be a plain string OR an array of content blocks.
    func extractMessageText(_ msg: [String: Any]) -> String {
        if let s = msg["content"] as? String { return s }
        guard let blocks = msg["content"] as? [[String: Any]] else { return "" }
        return blocks.compactMap { block -> String? in
            guard let t = block["type"] as? String else { return nil }
            switch t {
            case "text":
                return block["text"] as? String
            case "tool_use":
                let name = block["name"] as? String ?? "tool"
                return "⚙ \(name)"
            default:
                return nil
            }
        }.joined(separator: "\n")
    }

    @objc func renameCurrentSession(_ sender: Any?) {
        guard let sid = currentSessionId else { return }
        let alert = NSAlert()
        alert.messageText = "Name this session"
        alert.informativeText = "Give this conversation a human-readable label. Leave blank to remove the name."
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Cancel")
        let input = NSTextField(frame: NSRect(x: 0, y: 0, width: 320, height: 24))
        input.stringValue = sessionNames[sid] ?? ""
        alert.accessoryView = input
        NSApp.activate(ignoringOtherApps: true)
        DispatchQueue.main.async { alert.window.makeFirstResponder(input) }
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        let name = input.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            sessionNames.removeValue(forKey: sid)
        } else {
            sessionNames[sid] = name
        }
        saveChatState()
        updateChatHeader()
    }

    @objc func revealProjectDir(_ sender: Any?) {
        let dir = projectDir
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        runDetached("/usr/bin/open", [dir])
    }

    // ─── file browser ──────────────────────────────────────────────────────

    /// Reads chatCwd, builds the unfiltered item list (dirs first, alpha
    /// within group), then triggers renderBrowser() to apply the current
    /// filter and rebuild the visible rows.
    func loadBrowserItems() {
        let dir = chatCwd
        var items: [BrowserItem] = []
        if let names = try? FileManager.default.contentsOfDirectory(atPath: dir) {
            for name in names where !name.hasPrefix(".") {
                let path = "\(dir)/\(name)"
                var isDir: ObjCBool = false
                FileManager.default.fileExists(atPath: path, isDirectory: &isDir)
                // Only count sessions for dirs — checking every file would
                // be wasted I/O. The encoded-path lookup for files would
                // never match anything in ~/.claude/projects/ anyway.
                let sessions = isDir.boolValue ? sessionCountForFolder(path) : 0
                items.append(BrowserItem(
                    name: name, path: path, isDir: isDir.boolValue,
                    glyph: glyphForFile(name: name, isDir: isDir.boolValue),
                    sessionCount: sessions, sessionId: nil))
            }
        }
        items.sort { a, b in
            if a.isDir != b.isDir { return a.isDir }
            return a.name.localizedCaseInsensitiveCompare(b.name) == .orderedAscending
        }

        // Prepend Claude session rows for this folder so the actual
        // conversations are clickable from the browser, not just countable.
        // Ordered newest-first via listSessions(), and labelled with the
        // human name (set via /rename) when present, otherwise the first
        // user-message snippet.
        let fmt = DateFormatter()
        fmt.dateFormat = "MM-dd HH:mm"
        let sessionItems: [BrowserItem] = listSessions(limit: 50).map { s in
            let label = sessionNames[s.uuid] ?? s.snippet
            let display = "\(fmt.string(from: s.mtime))   \(label)"
            return BrowserItem(name: display, path: s.uuid, isDir: false,
                               glyph: "💬", sessionCount: 0, sessionId: s.uuid)
        }
        browserAllItems = sessionItems + items
        renderBrowser()

        // Restore the previously-selected child for this path (if any). Lets
        // the user step into a folder, come back, and find the same row still
        // highlighted — instead of having to re-scroll from the top.
        if let memoName = browserSelectionMemo[chatCwd],
           let idx = browserFilteredItems.firstIndex(where: { $0.name == memoName }) {
            browserSelectedIndex = idx
            applyBrowserHighlight()
        }
    }

    /// Apply the filter field's text and rebuild the row buttons. Called on
    /// every keystroke in the filter (via controlTextDidChange) and after
    /// loadBrowserItems().
    func renderBrowser() {
        // Re-entrancy guard: a single AppKit run loop pass that fires both
        // a controlTextDidChange (filter clear) and a click-driven rebuild can
        // otherwise interleave two renders, leaving the second one finishing
        // first on an empty intermediate state. One render at a time wins.
        if isRenderingBrowser { return }
        isRenderingBrowser = true
        defer { isRenderingBrowser = false }

        let raw = browserFilterField?.stringValue ?? ""
        let filter = raw.trimmingCharacters(in: .whitespaces)
        let filtered: [BrowserItem] = filter.isEmpty
            ? browserAllItems
            : browserAllItems.filter { fuzzyMatch(needle: filter, haystack: $0.name) }

        browserFilteredItems = filtered
        // Always re-arm to the top after a filter change so "type a few
        // letters → Return" feels like Spotlight: the visible top match
        // is the one Return opens.
        browserSelectedIndex = 0

        browserStack.arrangedSubviews.forEach {
            browserStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        for item in filtered {
            // Body text after the glyph. The glyph itself lives in its own
            // tab-stop column (see paragraph style below) so the body always
            // starts at the same X regardless of the emoji's rendered width.
            let body: String
            if item.sessionCount > 0 {
                let plural = item.sessionCount == 1 ? "session" : "sessions"
                body = "\(item.name)   ·  \(item.sessionCount) \(plural)"
            } else {
                body = item.name
            }
            // Color tiers: session rows = orange (the actionable artefacts —
            // click resumes the conversation). Folders with sessions = teal
            // (places to descend into where there's history). Everything
            // else = white.
            let tint: NSColor
            if item.sessionId != nil      { tint = NSColor.systemOrange }
            else if item.sessionCount > 0 { tint = NSColor.systemTeal }
            else                          { tint = NSColor.white }

            // Tab stop at 26pt fixes the wobble: emojis are variable-width
            // even inside a monospaced font, so `"💬  date snippet"` would
            // jitter. With `"💬\t…"` and a left tab at 26pt, every body
            // column starts at the same X regardless of glyph width.
            let paragraph = NSMutableParagraphStyle()
            paragraph.tabStops = [NSTextTab(textAlignment: .left, location: 26, options: [:])]
            paragraph.defaultTabInterval = 26
            paragraph.lineBreakMode = .byTruncatingTail
            let attrs: [NSAttributedString.Key: Any] = [
                .font: NSFont.monospacedSystemFont(ofSize: 12, weight: .regular),
                .foregroundColor: tint,
                .paragraphStyle: paragraph,
            ]
            let btn = BrowserItemButton(title: "",
                                         target: self, action: #selector(browserItemClicked(_:)))
            btn.item = item
            btn.bezelStyle = .inline
            btn.isBordered = false
            btn.alignment = .left
            btn.attributedTitle = NSAttributedString(
                string: "\(item.glyph)\t\(body)",
                attributes: attrs)
            btn.contentTintColor = tint
            btn.translatesAutoresizingMaskIntoConstraints = false
            (btn.cell as? NSButtonCell)?.imagePosition = .noImage
            browserStack.addArrangedSubview(btn)
            // Pin a minimum height so a stray autolayout pass can't collapse
            // the row to zero. Without this the stack occasionally finished a
            // rebuild with 0-pt rows — visually the list looked empty even
            // though the count in the header was correct.
            btn.heightAnchor.constraint(greaterThanOrEqualToConstant: 20).isActive = true
        }

        // Force the rebuild to settle before AppKit's next coalesced layout
        // tick. Pairing needsLayout + layoutSubtreeIfNeeded prevents a brief
        // empty frame between the removeArrangedSubview/add cycle and the
        // first natural layout pass.
        browserStack.needsLayout = true
        browserStack.layoutSubtreeIfNeeded()
        browserScroll?.documentView?.needsLayout = true
        browserScroll?.documentView?.layoutSubtreeIfNeeded()

        applyBrowserHighlight()

        let cwdAbbr = (chatCwd as NSString).abbreviatingWithTildeInPath
        let counts = filter.isEmpty
            ? "\(filtered.count) items"
            : "\(filtered.count)/\(browserAllItems.count)"
        browserPathLabel?.stringValue = "📂 \(cwdAbbr)   ·   \(counts)"
    }

    /// Paint the row at `browserSelectedIndex` with the standard selection
    /// accent so the user can see what Return will open.
    func applyBrowserHighlight() {
        guard let stack = browserStack else { return }
        let accent = NSColor.selectedContentBackgroundColor.withAlphaComponent(0.40).cgColor
        let clear = NSColor.clear.cgColor
        for (i, view) in stack.arrangedSubviews.enumerated() {
            guard let btn = view as? BrowserItemButton else { continue }
            btn.wantsLayer = true
            btn.layer?.cornerRadius = 4
            btn.layer?.backgroundColor = (i == browserSelectedIndex) ? accent : clear
        }
        // Scroll the highlighted row into the viewport — without this, ↓ past
        // the bottom (or ↑ past the top) leaves selection off-screen and the
        // browser appears to ignore the keys.
        if browserSelectedIndex >= 0,
           browserSelectedIndex < stack.arrangedSubviews.count {
            let row = stack.arrangedSubviews[browserSelectedIndex]
            row.scrollToVisible(row.bounds)
        }
    }

    /// Open a file via `/usr/bin/open`, then reclaim focus to AppleToolbox
    /// after the target app's launch settles (~700ms). The user keeps the
    /// keyboard inside the panel — typing into the filter or chat composer
    /// resumes without a click back. Sublime/Preview/etc. still get to come
    /// up; we just take the foreground back once they've settled.
    func openFileAndReclaimFocus(_ path: String) {
        runDetached("/usr/bin/open", [path])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            guard let self = self else { return }
            NSApp.activate(ignoringOtherApps: true)
            self.panel.makeKeyAndOrderFront(nil)
            self.panel.makeFirstResponder(self.browserFilterField)
        }
    }

    /// Open the currently highlighted browser item — directory → descend,
    /// file → `open`. Called from Return on the filter field.
    func openSelectedBrowserItem() {
        guard !browserFilteredItems.isEmpty,
              browserSelectedIndex < browserFilteredItems.count else { return }
        let item = browserFilteredItems[browserSelectedIndex]
        if let sid = item.sessionId {
            resumeSession(sid)
            panel.makeFirstResponder(chatInput)
            return
        }
        if item.isDir {
            switchChatCwd(to: item.path)
            browserFilterField?.stringValue = ""
            loadBrowserItems()
        } else {
            openFileAndReclaimFocus(item.path)
        }
    }

    @objc func browserItemClicked(_ sender: BrowserItemButton) {
        guard let item = sender.item else { return }
        if let sid = item.sessionId {
            // Session row → resume that conversation. Same plumbing as
            // Sessions ▾, but reached directly from the browser list.
            resumeSession(sid)
            panel.makeFirstResponder(chatInput)
            return
        }
        if item.isDir {
            // Clear filter BEFORE switching so the cwd-change-triggered reload
            // already paints the unfiltered list. Then `switchChatCwd` calls
            // `loadBrowserItems` exactly once — calling it again here would
            // cause a double render with the empty-filter notification racing
            // against the second rebuild, occasionally landing on an empty view.
            browserFilterField?.stringValue = ""
            switchChatCwd(to: item.path)
            // Restore focus to the filter field so ↑/↓/←/→ keep working
            // after a mouse click — otherwise AppKit puts focus on the
            // button and the doCommandBy handler never sees the keys.
            panel.makeFirstResponder(browserFilterField)
        } else {
            openFileAndReclaimFocus(item.path)
        }
    }

    @objc func browserGoUp(_ sender: Any?) {
        let parent = (chatCwd as NSString).deletingLastPathComponent
        guard !parent.isEmpty, parent != chatCwd else { return }
        switchChatCwd(to: parent)
        browserFilterField?.stringValue = ""
        loadBrowserItems()
    }

    @objc func browserGoHome(_ sender: Any?) {
        switchChatCwd(to: "\(HOME)/work")
        browserFilterField?.stringValue = ""
        loadBrowserItems()
    }

    /// Remember where the browser was before flipping into the vault so
    /// 🗄 vault toggles round-trip back with a second press.
    var browserPrevCwd: String?

    /// Toggle the browser between the user's working directory and the
    /// per-chat vault folder (where drafts, conversation log, and
    /// dictation audio land). Idempotent — pressing it on the vault
    /// folder returns you to the previous chatCwd, and pressing it
    /// elsewhere jumps to the vault. The vault folder is created on the
    /// fly if it doesn't exist yet so the click never lands on nothing.
    @objc func browserToggleVault(_ sender: Any?) {
        let vault = (sessionStateFile as NSString).deletingLastPathComponent
        // Pre-create the structure so the browser sees something useful
        // even before the first dictation / send.
        try? FileManager.default.createDirectory(atPath: vault,
                                                 withIntermediateDirectories: true)
        try? FileManager.default.createDirectory(atPath: "\(vault)/audio",
                                                 withIntermediateDirectories: true)

        if chatCwd == vault, let prev = browserPrevCwd {
            // Already in the vault → pop back to the previous folder.
            switchChatCwd(to: prev)
            browserPrevCwd = nil
        } else {
            // Otherwise → remember current, jump to vault.
            browserPrevCwd = chatCwd
            switchChatCwd(to: vault)
        }
        browserFilterField?.stringValue = ""
        loadBrowserItems()
    }

    /// True when the filter field has its caret at the end of its text (or
    /// is empty — empty fields have no field editor yet, so we can't ask).
    func browserFilterCaretAtEnd() -> Bool {
        let s = browserFilterField?.stringValue ?? ""
        if s.isEmpty { return true }
        guard let editor = browserFilterField?.currentEditor() else { return true }
        return editor.selectedRange.location == s.count
    }

    /// True when the filter field has its caret at the start (or is empty).
    func browserFilterCaretAtStart() -> Bool {
        let s = browserFilterField?.stringValue ?? ""
        if s.isEmpty { return true }
        guard let editor = browserFilterField?.currentEditor() else { return true }
        return editor.selectedRange.location == 0
    }

    /// NSControlTextEditingDelegate — keyboard navigation while focus is
    /// in the browser filter field. Spotlight-style: ↓ / ↑ walk the
    /// filtered rows, Return opens the highlighted one. Returning `true`
    /// swallows the command so the field doesn't beep or do its default.
    func control(_ control: NSControl, textView: NSTextView,
                 doCommandBy commandSelector: Selector) -> Bool {
        guard control === browserFilterField else { return false }
        switch commandSelector {
        case #selector(NSResponder.moveDown(_:)):
            if !browserFilteredItems.isEmpty {
                browserSelectedIndex = min(browserFilteredItems.count - 1,
                                           browserSelectedIndex + 1)
                applyBrowserHighlight()
            }
            return true
        case #selector(NSResponder.moveUp(_:)):
            if !browserFilteredItems.isEmpty {
                browserSelectedIndex = max(0, browserSelectedIndex - 1)
                applyBrowserHighlight()
            }
            return true
        case #selector(NSResponder.moveRight(_:)):
            // → matches Enter: session row → resume conversation; directory →
            // descend (Finder column-view grammar); file → open in default app.
            // Delegating to openSelectedBrowserItem keeps the branching identical
            // to Enter — one source of truth, no missed cases.
            //
            // Caret-at-end guard so mid-filter ← / → still move the caret. When
            // the field is empty, AppKit hasn't created a field editor yet
            // (currentEditor() returns nil), so treat empty stringValue as
            // "caret at end" by default. Without this, → on an empty filter
            // silently moved focus away via selectNextKeyView instead of
            // opening the highlighted row.
            if browserFilterCaretAtEnd(),
               !browserFilteredItems.isEmpty,
               browserSelectedIndex < browserFilteredItems.count {
                openSelectedBrowserItem()
                return true
            }
            return false
        case #selector(NSResponder.moveLeft(_:)):
            // ← pops to the parent of chatCwd. Mirror of the moveRight guard:
            // empty filter → caret-at-edge true; otherwise check the field
            // editor's caret position.
            if browserFilterCaretAtStart() {
                let parent = (chatCwd as NSString).deletingLastPathComponent
                if !parent.isEmpty && parent != chatCwd {
                    switchChatCwd(to: parent)
                }
                return true
            }
            return false
        case #selector(NSResponder.insertNewline(_:)):
            openSelectedBrowserItem()
            return true
        case #selector(NSResponder.moveRightAndModifySelection(_:)):
            // ⇧→ behaviour depends on the highlighted row:
            //   • 💬 session row    → hand off to iTerm with that UUID
            //   • regular file row  → copy file's text contents to clipboard
            //   • directory row     → fall through (default text-extend)
            // Gated on caret-at-end so it doesn't fight ordinary text editing.
            if browserFilterCaretAtEnd(),
               browserSelectedIndex >= 0,
               browserSelectedIndex < browserFilteredItems.count {
                let item = browserFilteredItems[browserSelectedIndex]
                if let sid = item.sessionId {
                    handoffSessionToTerminal(sessionId: sid)
                    return true
                }
                if !item.isDir {
                    copyFileContentsToClipboard(path: item.path)
                    return true
                }
            }
            return false
        case #selector(NSResponder.cancelOperation(_:)):
            // Esc clears the filter without leaving the field.
            browserFilterField?.stringValue = ""
            renderBrowser()
            return true
        default:
            return false
        }
    }

    // NSTextFieldDelegate — live filter as user types.
    func controlTextDidChange(_ obj: Notification) {
        guard let tf = obj.object as? NSTextField, tf === browserFilterField else { return }
        renderBrowser()
    }

    @objc func grantAllPermissions(_ sender: Any?) {
        let alert = NSAlert()
        alert.messageText = "Grant All Permissions"
        alert.informativeText =
            "AppleToolbox will fire every privacy-API request once so all the macOS prompts queue at the same time. Click through each dialog as it appears. Full Disk Access will open in System Settings — drag AppleToolbox.app into the list to enable Mail unread counts and friends."
        alert.addButton(withTitle: "Start")
        alert.addButton(withTitle: "Cancel")
        NSApp.activate(ignoringOtherApps: true)
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        requestAllPermissions()
    }

    // ─── chat: cwd + file pickers ──────────────────────────────────────────

    /// Reveal the per-project save folder in Finder. Everything
    /// AppleToolbox writes for this chat (drafts, conversation log,
    /// session state JSON, dictation audio) lives here. Creates the
    /// folder first if it doesn't exist yet so opening it never fails.
    @objc func openChatVault(_ sender: Any?) {
        let dir = (sessionStateFile as NSString).deletingLastPathComponent
        try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
        // Create the audio subfolder too so dictation files land in a
        // pre-existing location and the user sees the structure even
        // before they've dictated anything.
        try? FileManager.default.createDirectory(atPath: "\(dir)/audio",
                                                 withIntermediateDirectories: true)
        // Prefer revealing the conversation log file if it exists so the
        // user lands directly on the most relevant artifact, with the
        // folder open around it. Otherwise just open the folder.
        if FileManager.default.fileExists(atPath: conversationLogFile) {
            NSWorkspace.shared.activateFileViewerSelecting(
                [URL(fileURLWithPath: conversationLogFile)])
        } else {
            NSWorkspace.shared.open(URL(fileURLWithPath: dir))
        }
    }

    /// Hand the current chat off to an interactive terminal session. Builds a
    /// `cd <chatCwd> && claude [--resume <uuid>]` command line, then asks
    /// iTerm (or Terminal.app if iTerm isn't installed) to run it in a fresh
    /// window. The session UUID is the same one the panel was using, so the
    /// terminal picks up the conversation mid-thought — same JSONL, same
    /// memory, same /skill state.
    @objc func openInTerminal(_ sender: Any?) {
        handoffSessionToTerminal(sessionId: currentSessionId)
    }

    /// Open a new iTerm (or Terminal) window in `chatCwd` running
    /// `claude [--resume <uuid>]`. Used by both the ↗ Terminal header button
    /// (passes currentSessionId) and the Shift+→ shortcut on a 💬 browser
    /// row (passes that row's session id). Same command construction +
    /// AppleScript regardless of caller.
    /// ⇧→ on a regular file row copies its contents to the clipboard.
    /// Reads as UTF-8; falls back to lossy decoding so binary previews don't
    /// silently swallow the action. Posts a brief flash on the path label so
    /// the user sees something happened.
    /// Type-aware clipboard copy. UTType classification, no gibberish:
    ///   • image (png/jpg/gif/heic/tiff/webp/bmp/svg) → image data on the
    ///     pasteboard (NSImage). Paste into Preview/Mail/Notes/Keynote gets
    ///     the picture. File URL also written so Finder/Mail-as-attachment
    ///     recipients see it as a file too.
    ///   • text (md/txt/source code/json/xml/html/yaml/etc., anything UTI-
    ///     conformant to .text) → string on the pasteboard. Paste into any
    ///     text field gets the content.
    ///   • everything else (mp3/mp4/zip/dmg/pdf/etc.) → file URL on the
    ///     pasteboard. Paste into Finder copies the file, paste into Mail
    ///     attaches it. No bytes-to-string mangling.
    ///
    /// Failures beep + log instead of putting garbage on the clipboard.
    func copyFileContentsToClipboard(path: String) {
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        let pb = NSPasteboard.general

        // Resolve UTI via the file's resource values — same identification
        // mechanism Finder uses, so behavior matches user expectations.
        let type: UTType = (try? url.resourceValues(forKeys: [.contentTypeKey]).contentType) ?? .data
        let size = (try? FileManager.default.attributesOfItem(atPath: path)[.size] as? Int) ?? 0
        let bytesStr = ByteCountFormatter.string(fromByteCount: Int64(size), countStyle: .file)

        // ── Image branch ──
        if type.conforms(to: .image) {
            guard let img = NSImage(contentsOf: url) else {
                NSSound.beep()
                flashBrowserPath("✗ Couldn't decode \(name) as image")
                return
            }
            pb.clearContents()
            // writeObjects([img]) puts the image (as TIFF + other reps NSImage
            // exposes) on the pasteboard. Appending the file URL afterwards
            // ADDS it to the same paste record without clearing the image —
            // multi-format paste recipients pick whichever they prefer.
            pb.writeObjects([img])
            pb.writeObjects([url as NSURL])
            let w = Int(img.size.width), h = Int(img.size.height)
            flashBrowserPath("📋 Copied \(name) as image (\(w)×\(h), \(bytesStr))")
            return
        }

        // ── Text branch ──
        // UTType.text is the abstract base every text-bearing UTI conforms
        // to (md, source code, json, html, xml, yaml, log, csv, etc.).
        if type.conforms(to: .text) {
            guard let data = try? Data(contentsOf: url),
                  let text = String(data: data, encoding: .utf8) else {
                NSSound.beep()
                flashBrowserPath("✗ Couldn't decode \(name) as UTF-8")
                return
            }
            pb.clearContents()
            pb.setString(text, forType: .string)
            let lines = text.split(separator: "\n").count
            flashBrowserPath("📋 Copied \(name) (\(lines) lines, \(bytesStr))")
            return
        }

        // ── Default: file reference ──
        // mp3, mp4, zip, dmg, pdf, app, anything not text or image. ⌘V in
        // Finder copies the file; ⌘V in Mail attaches it.
        pb.clearContents()
        pb.writeObjects([url as NSURL])
        let kindHint = type.preferredFilenameExtension ?? type.identifier
        flashBrowserPath("📋 Copied \(name) as file (\(kindHint), \(bytesStr))")
    }

    /// Briefly overlay a status message on the browser's path label, then
    /// restore it. Used for one-shot acknowledgements (copy, etc.).
    func flashBrowserPath(_ message: String) {
        guard let label = browserPathLabel else { return }
        let prior = label.stringValue
        label.stringValue = message
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) { [weak self] in
            guard let self = self, self.browserPathLabel?.stringValue == message else { return }
            self.browserPathLabel?.stringValue = prior
        }
    }

    func handoffSessionToTerminal(sessionId: String?) {
        // Quote the cwd to survive paths with spaces.
        let cwd = chatCwd.replacingOccurrences(of: "\"", with: "\\\"")
        var cmd = "cd \"\(cwd)\" && \(claudeBin) \(Self.claudeCommonFlagsCmdline)"
        if let sid = sessionId, !sid.isEmpty {
            cmd += " --resume \(sid)"
        }
        // Detect iTerm.app; fall back to Terminal.app which is always present.
        let iTermInstalled = FileManager.default.fileExists(atPath: "/Applications/iTerm.app")
        let safe = cmd.replacingOccurrences(of: "\\", with: "\\\\")
                      .replacingOccurrences(of: "\"", with: "\\\"")
        let script: String
        if iTermInstalled {
            script = """
            tell application "iTerm"
                activate
                create window with default profile
                tell current session of current window to write text "\(safe)"
            end tell
            """
        } else {
            script = """
            tell application "Terminal"
                activate
                do script "\(safe)"
            end tell
            """
        }
        runDetached("/usr/bin/osascript", ["-e", script])
        if let sid = sessionId {
            appendTranscript("\n── handed off to \(iTermInstalled ? "iTerm" : "Terminal") · " +
                             "session …\(String(sid.suffix(8))) ──\n",
                             color: NSColor(white: 0.7, alpha: 1.0))
        } else {
            appendTranscript("\n── handed off to \(iTermInstalled ? "iTerm" : "Terminal") · " +
                             "new session in \((chatCwd as NSString).lastPathComponent) ──\n",
                             color: NSColor(white: 0.7, alpha: 1.0))
        }
    }

    /// Goldilocks picker: ~/work/ IS the world. The picker is a popup menu of
    /// the user's project subdirs, sorted by recency, so switching projects is
    /// one click — no modal NSOpenPanel, no navigating from / each time. The
    /// "Other folder…" fallback at the bottom covers anything outside ~/work.
    @objc func pickChatCwd(_ sender: Any?) {
        let menu = NSMenu()
        let workRoot = "\(HOME)/work"
        let fm = FileManager.default

        if let entries = try? fm.contentsOfDirectory(atPath: workRoot) {
            // Directories only, dotfiles excluded, sorted by mtime DESC so
            // the project the user last touched is the first thing they see.
            let dirs: [(name: String, path: String, mtime: Date)] = entries.compactMap { name in
                let full = "\(workRoot)/\(name)"
                var isDir: ObjCBool = false
                guard fm.fileExists(atPath: full, isDirectory: &isDir), isDir.boolValue,
                      !name.hasPrefix("."),
                      let attrs = try? fm.attributesOfItem(atPath: full),
                      let mtime = attrs[.modificationDate] as? Date else { return nil }
                return (name, full, mtime)
            }.sorted { $0.mtime > $1.mtime }

            for d in dirs {
                let item = NSMenuItem(title: "📁 \(d.name)",
                                      action: #selector(chatCwdMenuPicked(_:)),
                                      keyEquivalent: "")
                item.target = self
                item.representedObject = d.path
                if d.path == chatCwd { item.state = .on }  // checkmark current
                menu.addItem(item)
            }
        }

        menu.addItem(NSMenuItem.separator())
        let other = NSMenuItem(title: "Other folder…",
                               action: #selector(pickChatCwdOpenPanel(_:)),
                               keyEquivalent: "")
        other.target = self
        menu.addItem(other)

        if let btn = sender as? NSButton {
            menu.popUp(positioning: nil,
                       at: NSPoint(x: 0, y: btn.bounds.height + 2),
                       in: btn)
        } else {
            menu.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
        }
    }

    @objc func chatCwdMenuPicked(_ sender: NSMenuItem) {
        guard let path = sender.representedObject as? String else { return }
        switchChatCwd(to: path)
    }

    /// Fallback: full NSOpenPanel for the rare case the user wants a folder
    /// outside ~/work (system path, external volume, etc.).
    @objc func pickChatCwdOpenPanel(_ sender: Any?) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: "\(HOME)/work")
        panel.prompt = "Use Folder"
        panel.message = "Pick any folder for Claude's project memory + session list."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        switchChatCwd(to: url.path)
    }

    @objc func pickChatFile(_ sender: Any?) {
        if anchoredFile != nil {
            anchoredFile = nil
            updateChatHeader()
            appendTranscript("\n── file anchor cleared ──\n", color: NSColor(white: 0.7, alpha: 1.0))
            return
        }
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.directoryURL = URL(fileURLWithPath: chatCwd)
        panel.prompt = "Anchor"
        panel.message = "Anchor a file. The next prompt will reference it as @<path>."
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }
        anchoredFile = url.path
        updateChatHeader()
        appendTranscript("\n── anchored 📄 \(url.path) ──\n",
                         color: NSColor(white: 0.7, alpha: 1.0))
    }

    func switchChatCwd(to newCwd: String) {
        guard newCwd != chatCwd else { return }
        let old = chatCwd
        // Memoise the selection so re-arriving at a parent/child path restores
        // its highlight. Two cases:
        //   - Descending old → newCwd (newCwd is a child of old): remember the
        //     immediate child name under old so coming back highlights it.
        //   - Ascending old → newCwd (newCwd is an ancestor of old): remember
        //     the immediate child of newCwd on the path to old (same idea, the
        //     row the user just stepped out of).
        if newCwd.hasPrefix(old + "/") {
            let rel = String(newCwd.dropFirst(old.count + 1))
            let child = rel.split(separator: "/", maxSplits: 1).first.map(String.init) ?? rel
            if !child.isEmpty { browserSelectionMemo[old] = child }
        } else if old.hasPrefix(newCwd + "/") {
            let rel = String(old.dropFirst(newCwd.count + 1))
            let child = rel.split(separator: "/", maxSplits: 1).first.map(String.init) ?? rel
            if !child.isEmpty { browserSelectionMemo[newCwd] = child }
        }
        if let p = chatProcess, p.isRunning { p.terminate() }
        chatCwd = newCwd
        currentSessionId = nil
        loadChatState()
        anchoredFile = nil
        updateChatHeader()
        let cwdAbbr = (chatCwd as NSString).abbreviatingWithTildeInPath
        appendTranscript("\n── switched to \(cwdAbbr) ──\n",
                         color: NSColor(white: 0.7, alpha: 1.0))
        // Refresh the browser so its list reflects the new folder, even when
        // the cwd change came from the chat-header 📂 picker rather than an
        // in-browser click.
        if browserStack != nil { loadBrowserItems() }
    }

    // ─── chat: dictation ──────────────────────────────────────────────────

    /// Focuses the chat input, then dispatches the standard
    /// `startDictation:` responder action. AppKit walks the responder chain
    /// to the field editor (NSTextView) which owns the system dictation
    /// pipeline, so this brings up exactly the overlay you'd get from
    /// double-tapping Fn / using Edit ▸ Start Dictation in any other app.
    @objc func startDictationInChat(_ sender: Any?) {
        panel.makeFirstResponder(chatInput)
        NSApp.sendAction(Selector(("startDictation:")), to: nil, from: sender)
    }

    // ─── chat: smart dictation (SFSpeechRecognizer) ────────────────────────

    /// Toggle smart dictation on/off. Same entry point for the inline
    /// 〰 button, the in-panel ⌘D shortcut, and the global ⌃⌥⌘D hotkey.
    ///
    /// On start, sets a timestamped audio capture path so the raw mic
    /// stream gets saved alongside the transcript. On stop, captures the
    /// resulting file path into pendingAudioFiles so the next sendChat
    /// can reference it in the conversation log.
    /// Repaint the smart-dictation button across the three visual states
    /// of the controller: OFF, LIVE, and PAUSED-while-running. Called from
    /// both `onStateChange` and `onPauseChange`.
    func paintSmartDictateButton() {
        guard chatSmartDictateButton != nil else { return }
        if #available(macOS 11.0, *) {
            let name: String
            let tint: NSColor?
            if smartDictation.isRunning {
                if smartDictation.isPaused {
                    name = "waveform.circle"
                    tint = NSColor.systemOrange   // "I'm here, waiting"
                } else {
                    name = "waveform.circle.fill"
                    tint = NSColor.systemRed      // "listening"
                }
            } else {
                name = "waveform.circle"
                tint = nil                        // off
            }
            chatSmartDictateButton.image = NSImage(systemSymbolName: name,
                                                   accessibilityDescription: "Smart Dictation")
            chatSmartDictateButton.contentTintColor = tint
        }
    }

    @objc func toggleSmartDictation(_ sender: Any?) {
        panel.makeFirstResponder(chatInput)
        let wasRunning = smartDictation.isRunning
        if !wasRunning {
            let stamp = compactStamp()
            // Land the audio NEXT TO THE WORK — under <chatCwd>/dictation/.
            // Previously these went into ~/.claude/projects/<escaped>/audio/
            // which is hidden Claude metadata; the user couldn't find them.
            // Filename starts as just <stamp>.wav; after stop we rename to
            // <stamp>-<slug-of-what-was-said>.wav.
            let dir = "\(chatCwd)/dictation"
            smartDictation.nextAudioPath = "\(dir)/\(stamp).wav"
        }
        smartDictation.toggle(target: chatInput)
        if wasRunning {
            if let path = smartDictation.lastAudioPath {
                let finalPath = renameDictationFileWithTranscript(
                    path: path,
                    transcript: smartDictation.sessionTranscript)
                pendingAudioFiles.append(finalPath)
                // Log the FULL absolute path (clickable in many renderers) so
                // there's no guessing where the recording landed.
                appendToConversationLog("\n_(🎙 audio captured: [`\(finalPath)`](\(finalPath)))_\n")
                appendTranscriptPathLink(prefix: "\n🎙 audio: ", path: finalPath)
                // The dictation/ folder didn't exist before this session
                // first ran — refresh the file browser so the user can see
                // it appear without having to navigate away and back.
                if browserStack != nil { loadBrowserItems() }
            } else if let attempted = smartDictation.lastAttemptedAudioPath {
                // The capture file failed to open — surface where it tried so
                // the user isn't left wondering whether the audio is anywhere.
                appendToConversationLog("\n_(⚠ audio NOT saved — tried `\(attempted)`)_\n")
                appendTranscript("\n⚠ audio NOT saved — tried \(attempted)\n",
                                 color: .systemRed)
            }
        }
    }

    /// Audio files captured during composer cycle since the last send.
    /// Cleared each time sendChat runs.
    var pendingAudioFiles: [String] = []

    func isoStamp() -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f.string(from: Date())
    }

    /// Background maintenance — fired by `maintenanceTimer`. Hops off the
    /// main queue so the file walks + `vault.py backfill` never block UI.
    /// Both sub-tasks are safe to re-run (mirror skips files already at
    /// the destination with matching size; vault.py backfill is itself
    /// safe to re-run).
    func runMaintenance() {
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.mirrorDictationToVault()
            self?.runVaultBackfill()
        }
    }

    /// Walks `~/work/*/dictation/` (depth 5) and copies every `.wav` into
    /// `~/work/cc/vault/sources/dictation/<YYYY-MM-DD>/`. Copy (not move)
    /// — the source must stay next to the work it was captured against.
    /// Date subfolder is derived from the filename's leading `yyyymmdd`
    /// prefix written by `compactStamp()`.
    func mirrorDictationToVault() {
        let workRoot = "\(HOME)/work"
        let vaultDictation = "\(HOME)/work/cc/vault/sources/dictation"
        let task = Process()
        task.launchPath = "/usr/bin/find"
        task.arguments = [workRoot, "-maxdepth", "5", "-type", "d", "-name", "dictation"]
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        do { try task.run() } catch { return }
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let dirs = String(data: data, encoding: .utf8)?
            .split(separator: "\n").map(String.init) ?? []
        let fm = FileManager.default
        for dir in dirs {
            if dir.hasPrefix(vaultDictation) { continue }
            guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { continue }
            for name in entries where name.hasSuffix(".wav") {
                let src = "\(dir)/\(name)"
                let datePrefix: String
                if name.count >= 8,
                   let _ = Int(name.prefix(4)),
                   let _ = Int(name.dropFirst(4).prefix(2)),
                   let _ = Int(name.dropFirst(6).prefix(2)) {
                    let yyyy = String(name.prefix(4))
                    let mm = String(name.dropFirst(4).prefix(2))
                    let dd = String(name.dropFirst(6).prefix(2))
                    datePrefix = "\(yyyy)-\(mm)-\(dd)"
                } else {
                    datePrefix = "undated"
                }
                let destDir = "\(vaultDictation)/\(datePrefix)"
                let dest = "\(destDir)/\(name)"
                if fm.fileExists(atPath: dest),
                   let sAttr = try? fm.attributesOfItem(atPath: src),
                   let dAttr = try? fm.attributesOfItem(atPath: dest),
                   let sSize = sAttr[.size] as? NSNumber,
                   let dSize = dAttr[.size] as? NSNumber,
                   sSize == dSize {
                    continue
                }
                try? fm.createDirectory(atPath: destDir, withIntermediateDirectories: true)
                try? fm.removeItem(atPath: dest)
                try? fm.copyItem(atPath: src, toPath: dest)
            }
        }
    }

    /// Runs `python3 ~/.claude/skills/vault/vault.py backfill` so the
    /// cc/vault conversations folder picks up every Claude Code session
    /// that's been written since the last pass. Silent — if vault.py is
    /// missing or python3 isn't on PATH, this is a no-op.
    func runVaultBackfill() {
        let vaultPy = "\(HOME)/.claude/skills/vault/vault.py"
        guard FileManager.default.fileExists(atPath: vaultPy) else { return }
        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["python3", vaultPy, "backfill"]
        task.standardOutput = Pipe()
        task.standardError = Pipe()
        do { try task.run() } catch { return }
        task.waitUntilExit()
    }

    /// `yyyyMMdd-HHmmss` in local time — the filename prefix for dictation
    /// audio so files sort chronologically in Finder without colons or `T`.
    func compactStamp() -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f.string(from: Date())
    }

    /// Rename `<stamp>.wav` → `<stamp>-<slug>.wav` once the dictation
    /// session has produced its committed transcript. If the transcript is
    /// empty or the rename fails, return the original path so the log
    /// entry still points at a real file.
    func renameDictationFileWithTranscript(path: String, transcript: String) -> String {
        let slug = slugifyTranscript(transcript)
        guard !slug.isEmpty else { return path }
        let ns = path as NSString
        let dir = ns.deletingLastPathComponent
        let ext = ns.pathExtension                   // "wav"
        let stem = ns.lastPathComponent              // "20260521-143207.wav"
        let stampOnly = (stem as NSString).deletingPathExtension
        let newName = "\(stampOnly)-\(slug).\(ext)"
        let newPath = (dir as NSString).appendingPathComponent(newName)
        if newPath == path { return path }
        do {
            try FileManager.default.moveItem(atPath: path, toPath: newPath)
            return newPath
        } catch {
            fputs("[AppleToolbox] dictation rename failed: \(error)\n", stderr)
            return path
        }
    }

    /// Lower-case, kebab-case slug of the dictated text, capped at 60
    /// chars on a word boundary. Non-ASCII letters/digits collapse to `-`.
    /// Empty input → empty string (caller leaves the file un-renamed).
    func slugifyTranscript(_ text: String) -> String {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return "" }
        var out = ""
        var lastDash = true
        for scalar in trimmed.lowercased().unicodeScalars {
            let isAlnum = (scalar >= "a" && scalar <= "z") ||
                          (scalar >= "0" && scalar <= "9")
            if isAlnum {
                out.unicodeScalars.append(scalar)
                lastDash = false
            } else if !lastDash {
                out.append("-")
                lastDash = true
            }
        }
        while out.hasSuffix("-") { out.removeLast() }
        let cap = 60
        if out.count > cap {
            let cut = out.index(out.startIndex, offsetBy: cap)
            var truncated = String(out[..<cut])
            if let lastDash = truncated.lastIndex(of: "-"),
               truncated.distance(from: truncated.startIndex, to: lastDash) > cap / 2 {
                truncated = String(truncated[..<lastDash])
            }
            out = truncated
        }
        return out
    }

    /// NSTextViewDelegate hook: keep the smart-dictation anchor synced
    /// with the user's cursor. When the user clicks elsewhere or moves the
    /// caret with arrows, the next partial inserts at the new spot — the
    /// "edit / resume from cursor" loop the user wants.
    func textViewDidChangeSelection(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView, tv === chatInput else { return }
        smartDictation.userMovedCursor(to: tv.selectedRange().location)
    }

    /// NSTextDelegate hook — fires for every edit (typed, pasted, dictated,
    /// programmatic). This is the "on state sight, be saved" guarantee:
    /// any mutation of the composer buffer schedules a debounced disk save
    /// so a crash / quit / `--live` rebuild never loses in-progress text.
    func textDidChange(_ notification: Notification) {
        guard let tv = notification.object as? NSTextView, tv === chatInput else { return }
        scheduleDraftSave()
        // If the user is typing while smart dictation is on, pause the
        // recognizer and arm the auto-resume timer — the "brief nod"
        // pattern where the mic comes back on after they stop editing.
        smartDictation.userTyped()
    }

    // ─── chat: composer key handling ───────────────────────────────────────

    /// NSTextViewDelegate hook: Return = send, Shift+Return = newline,
    /// ⌘D = toggle smart dictation, ⌘. = brickwall current dictation
    /// segment. Any other command falls through to the standard
    /// `NSStandardKeyBindingResponding` machinery.
    func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        guard textView === chatInput else { return false }
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            let modifiers = NSApp.currentEvent?.modifierFlags ?? []
            if modifiers.contains(.shift) {
                textView.insertNewlineIgnoringFieldEditor(nil)
                return true
            }
            sendChat(textView)
            return true
        }
        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            // ⌘. → finalize the current tentative span and re-anchor at cursor.
            smartDictation.brickwall()
            return true
        }
        return false
    }

    // ─── chat: send / receive ──────────────────────────────────────────────

    /// Local router: "show <X>" → `bin/show <X>`. Speaks via Voicebox if
    /// up, opens a Smart Folder in Finder. Confirmation line lands in the
    /// chat log so the action is visible in the chronological record.
    func routeShow(_ concept: String) {
        let stamp = ISO8601DateFormatter().string(from: Date())
        let showBin = "\(APPLE_DIR)/bin/show"
        appendTranscript("\n▶ You\nshow \(concept)\n", color: .systemOrange, bold: true)
        appendToConversationLog("\n## ▶ You · \(stamp)\n\nshow \(concept)\n")
        guard FileManager.default.isExecutableFile(atPath: showBin) else {
            appendTranscript("✗ \(showBin) not executable\n", color: .systemRed)
            appendToConversationLog("\n_(✗ \(showBin) not executable)_\n")
            return
        }
        let p = Process()
        p.launchPath = showBin
        p.arguments = [concept]
        let out = Pipe(); p.standardOutput = out; p.standardError = out
        do { try p.run() } catch {
            appendTranscript("✗ show failed to launch: \(error)\n", color: .systemRed)
            return
        }
        // Don't block the UI — read the output asynchronously.
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            p.waitUntilExit()
            let data = out.fileHandleForReading.readDataToEndOfFile()
            let text = String(data: data, encoding: .utf8) ?? ""
            DispatchQueue.main.async {
                let ok = (p.terminationStatus == 0)
                let badge = ok ? "✓" : "✗"
                self?.appendTranscript("\(badge) show \(concept)\n\(text)",
                                       color: ok ? .systemGreen : .systemRed)
                self?.appendToConversationLog("\n_(\(badge) show \(concept))_\n")
            }
        }
    }

    @objc func sendChat(_ sender: Any?) {
        let text = chatInput.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !chatBusy else { return }

        // Local routers — caught BEFORE the Claude round-trip. Single-line
        // commands that map to a `bin/<verb>` script run locally; the chat
        // log gets a confirmation line so the action is visible in the
        // chronological record. Pattern: case-insensitive, full-line match.
        let lower = text.lowercased()
        if lower.hasPrefix("show ") && !text.contains("\n") {
            let arg = String(text.dropFirst(5)).trimmingCharacters(in: .whitespacesAndNewlines)
            if !arg.isEmpty {
                routeShow(arg)
                chatInput.string = ""
                chatInput.needsDisplay = true
                draftSaveTimer?.invalidate()
                saveDraft()
                return
            }
        }

        guard FileManager.default.isExecutableFile(atPath: claudeBin) else {
            appendTranscript("\n✗ claude binary not found at \(claudeBin)\n", color: .systemRed)
            return
        }

        chatBusy = true
        smartDictation.suppressEditCallbacks = true
        chatInput.string = ""
        smartDictation.suppressEditCallbacks = false
        chatInput.needsDisplay = true     // repaint placeholder
        chatInput.isEditable = false
        chatSendButton.isEnabled = false
        updateChatHeader()
        // Composer is now empty → flush the draft file (atomic delete).
        draftSaveTimer?.invalidate()
        saveDraft()

        // Two-way log: every user message gets appended with a timestamp
        // header so the file is a chronological record of the conversation.
        // If smart dictation produced audio files since the last send,
        // link them inside this entry so you can replay the audio of any
        // past message — the "voice + prompt combined" requirement.
        let stamp = ISO8601DateFormatter().string(from: Date())
        var audioLines = ""
        for path in pendingAudioFiles {
            audioLines += "🎙 audio: [`\((path as NSString).lastPathComponent)`](\(path))\n"
        }
        pendingAudioFiles.removeAll()
        appendToConversationLog("\n## ▶ You · \(stamp)\n\n\(audioLines)\(audioLines.isEmpty ? "" : "\n")\(text)\n")

        appendTranscript("\n▶ You\n", color: .systemOrange, bold: true)
        appendTranscript("\(text)\n", color: .white)
        appendTranscript("\n● Claude\n", color: .systemTeal, bold: true)
        appendToConversationLog("\n## ● Claude · \(stamp)\n\n")

        let p = Process()
        p.executableURL = URL(fileURLWithPath: claudeBin)
        var args: [String] = ["-p", "--verbose", "--output-format", "stream-json"]
                              + Self.claudeCommonFlags
        if let sid = currentSessionId, !sid.isEmpty {
            args += ["--resume", sid]
        }
        // If a file is anchored, prepend an @-reference so Claude reads it as
        // part of this turn. The anchor is one-shot — cleared after sending.
        let finalPrompt: String
        if let file = anchoredFile {
            finalPrompt = "@\(file)\n\n\(text)"
            anchoredFile = nil
        } else {
            finalPrompt = text
        }
        args.append(finalPrompt)
        p.arguments = args
        p.currentDirectoryURL = URL(fileURLWithPath: chatCwd)

        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()
        p.standardOutput = stdoutPipe
        p.standardError = stderrPipe
        chatBuffer = Data()

        stdoutPipe.fileHandleForReading.readabilityHandler = { [weak self] handle in
            let data = handle.availableData
            if data.isEmpty { return }
            DispatchQueue.main.async { self?.consumeChatBytes(data) }
        }
        stderrPipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            guard !data.isEmpty, let s = String(data: data, encoding: .utf8) else { return }
            fputs("[claude stderr] \(s)", stderr)
        }
        p.terminationHandler = { [weak self] proc in
            DispatchQueue.main.async {
                self?.finishChatResponse(exitCode: proc.terminationStatus)
            }
        }

        do {
            try p.run()
            chatProcess = p
        } catch {
            appendTranscript("\n✗ failed to launch claude: \(error)\n", color: .systemRed)
            finishChatResponse(exitCode: -1)
        }
    }

    func consumeChatBytes(_ data: Data) {
        chatBuffer.append(data)
        let newline: UInt8 = 0x0A
        while let nl = chatBuffer.firstIndex(of: newline) {
            let lineData = chatBuffer.subdata(in: chatBuffer.startIndex..<nl)
            chatBuffer.removeSubrange(chatBuffer.startIndex...nl)
            if lineData.isEmpty { continue }
            handleChatLine(lineData)
        }
    }

    func handleChatLine(_ data: Data) {
        guard let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = obj["type"] as? String else { return }
        switch type {
        case "system":
            if let sid = obj["session_id"] as? String, !sid.isEmpty, sid != currentSessionId {
                currentSessionId = sid
                saveChatState()
                updateChatHeader()
            }
        case "assistant":
            guard let msg = obj["message"] as? [String: Any],
                  let content = msg["content"] as? [[String: Any]] else { return }
            for c in content {
                let ctype = c["type"] as? String ?? ""
                if ctype == "text", let s = c["text"] as? String {
                    appendTranscript(s, color: .white)
                    appendToConversationLog(s)
                } else if ctype == "tool_use", let name = c["name"] as? String {
                    appendTranscript("\n⚙ \(name)", color: .systemPurple, bold: true)
                    if let input = c["input"] as? [String: Any],
                       let pretty = compactBriefDescription(input) {
                        appendTranscript("  \(pretty)", color: NSColor(white: 0.85, alpha: 1.0))
                    }
                    appendTranscript("\n", color: .white)
                } else if ctype == "thinking" {
                    appendTranscript("\n💭 (thinking)\n", color: .systemPurple)
                }
            }
        case "user":
            break
        case "result":
            let subtype = obj["subtype"] as? String ?? "done"
            let cost = (obj["total_cost_usd"] as? Double).map { String(format: "$%.4f", $0) } ?? "—"
            let durMs = (obj["duration_ms"] as? Int) ?? 0
            appendTranscript("\n— \(subtype) · \(durMs)ms · \(cost)\n",
                             color: NSColor(white: 0.7, alpha: 1.0))
        default:
            break
        }
    }

    func finishChatResponse(exitCode: Int32) {
        chatBusy = false
        chatProcess = nil
        chatInput.isEditable = true
        chatSendButton.isEnabled = true
        if exitCode != 0 && exitCode != -1 {
            appendTranscript("\n✗ claude exited with code \(exitCode)\n", color: .systemRed)
        }
        updateChatHeader()
        panel.makeFirstResponder(chatInput)
    }

    func appendTranscript(_ s: String, color: NSColor, bold: Bool = false) {
        let font: NSFont = bold
            ? NSFont.monospacedSystemFont(ofSize: 12, weight: .semibold)
            : NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let attrs: [NSAttributedString.Key: Any] = [.foregroundColor: color, .font: font]
        chatTranscript.textStorage?.append(NSAttributedString(string: s, attributes: attrs))
        chatTranscript.scrollToEndOfDocument(nil)
    }

    /// Append a line that contains a clickable file-path link. NSTextView
    /// handles the click via NSWorkspace.open — for a `.wav` that opens in
    /// QuickTime / Finder's audio handler. The visible glyphs are still the
    /// absolute path so you can copy-paste it too.
    func appendTranscriptPathLink(prefix: String, path: String,
                                  color: NSColor = NSColor(white: 0.7, alpha: 1.0)) {
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let storage = chatTranscript.textStorage
        if !prefix.isEmpty {
            storage?.append(NSAttributedString(string: prefix,
                                               attributes: [.foregroundColor: color, .font: font]))
        }
        let url = URL(fileURLWithPath: path)
        let linkAttrs: [NSAttributedString.Key: Any] = [
            .link: url,
            .font: font,
        ]
        storage?.append(NSAttributedString(string: path, attributes: linkAttrs))
        storage?.append(NSAttributedString(string: "\n",
                                            attributes: [.foregroundColor: color, .font: font]))
        chatTranscript.scrollToEndOfDocument(nil)
    }

    @objc func resetChat(_ sender: Any?) {
        if let p = chatProcess, p.isRunning {
            p.terminate()
        }
        currentSessionId = nil
        saveChatState()
        updateChatHeader()
        appendTranscript("\n── new session ──\n", color: NSColor(white: 0.7, alpha: 1.0))
    }

    /// One-line preview of a tool_use input dict — first 2 keys, values truncated.
    func compactBriefDescription(_ d: [String: Any]) -> String? {
        if d.isEmpty { return nil }
        let parts = d.prefix(2).map { (k, v) -> String in
            let s = String(describing: v).replacingOccurrences(of: "\n", with: " ")
            let trimmed = s.count > 60 ? String(s.prefix(60)) + "…" : s
            return "\(k)=\(trimmed)"
        }
        return parts.joined(separator: "  ")
    }
}

/// Flipped coordinate origin so NSStackView lays out top-down inside the
/// NSScrollView's documentView, not bottom-up.
class FlippedView: NSView {
    override var isFlipped: Bool { true }
}

/// Multi-line NSTextView for the chat composer. Adds a placeholder string
/// (NSTextView has none natively) and exposes `placeholderString` as a
/// settable property so the existing API in updateChatHeader keeps working.
/// Editing, selection, cursor movement, Opt/Cmd arrow word/line jumps,
/// find bar, spellcheck — all stock NSTextView, which means
/// `startDictation:` dispatched up the responder chain hits this view
/// directly (no field-editor indirection like NSTextField).
class ChatInputTextView: NSTextView {
    var placeholderString: String = "" {
        didSet { needsDisplay = true }
    }

    override func didChangeText() {
        super.didChangeText()
        needsDisplay = true
    }

    override func becomeFirstResponder() -> Bool {
        let r = super.becomeFirstResponder()
        needsDisplay = true
        return r
    }

    override func resignFirstResponder() -> Bool {
        let r = super.resignFirstResponder()
        needsDisplay = true
        return r
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard string.isEmpty, !placeholderString.isEmpty else { return }
        let attrs: [NSAttributedString.Key: Any] = [
            .font: font ?? NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.placeholderTextColor,
        ]
        let inset = textContainerInset
        let origin = NSPoint(x: inset.width + 5, y: inset.height)
        placeholderString.draw(at: origin, withAttributes: attrs)
    }
}

// ─── Smart dictation: SFSpeechRecognizer with cursor-aware partials ────────
//
// What `startDictation:` (the existing mic button) does: hands the field
// editor over to macOS, dictated text appears inline, you can edit during
// or after, but you don't see partial-vs-final state and there's no
// programmatic control.
//
// What this controller does: owns the audio pipeline (AVAudioEngine input
// tap → SFSpeechAudioBufferRecognitionRequest with on-device recognition),
// receives partial results every ~100 ms, paints the current partial in
// `secondaryLabelColor` as a "tentative range" inside ChatInputTextView,
// commits it to `labelColor` when isFinal arrives, then advances the
// anchor. If the user clicks somewhere else mid-stream, the next partial
// starts at the new cursor position — speak / edit / speak from cursor.
//
// The two flavors of toggle (⌘D inside the --live panel, ⌃⌥⌘D global)
// both end up calling `toggle(target:)` on a single instance owned by
// LiveViewportDelegate. Hotkey wiring lives in the delegate.
class SpeechDictationController: NSObject {
    private let audioEngine = AVAudioEngine()
    private let recognizer = SFSpeechRecognizer(locale: Locale.current)
        ?? SFSpeechRecognizer(locale: Locale(identifier: "en_US"))
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    private(set) var isRunning = false
    weak var target: ChatInputTextView?

    /// Audio capture alongside transcript. The same mic-tap buffers that
    /// feed SFSpeechRecognizer are also written to this AVAudioFile, so
    /// every dictation session leaves BOTH the text (in the composer +
    /// conversation log) AND the raw audio on disk. The delegate sets
    /// `nextAudioPath` before calling toggle/start; the controller writes
    /// the file and reports back through `lastAudioPath` after stop.
    ///
    /// TODO: voicebox integration — voicebox already does richer routing
    /// (cloud/local recognizer choice, multi-track, per-speaker tagging).
    /// Once its MCP server is reachable from AppleToolbox we can switch
    /// the heavy lifting over and keep this AVAudioFile path as the
    /// fallback. Tracking the stub here.
    var nextAudioPath: String?
    private(set) var lastAudioPath: String?
    /// Accumulates every committed (final) phrase during one start→stop
    /// session. Cleared on start. Read by the host after stop to slug the
    /// audio filename, so the .wav ends up named after what was said.
    private(set) var sessionTranscript: String = ""
    /// The path we tried to write even if AVAudioFile setup failed — used
    /// by the host so it can surface a "tried <path>, failed" message
    /// instead of silently dropping the recording.
    private(set) var lastAttemptedAudioPath: String?
    private var audioFile: AVAudioFile?

    /// Range of text currently rendered as "tentative" (light-grey,
    /// replaceable by the next partial result). `length == 0` means the
    /// next partial will be inserted at `location` without replacing
    /// anything — that's the state right after a final commit or right
    /// after the user repositioned the cursor.
    private var tentativeRange = NSRange(location: 0, length: 0)

    /// Set true while we are programmatically mutating the text storage,
    /// so the NSTextView delegate doesn't mistake our own writes for the
    /// user repositioning the cursor.
    var suppressEditCallbacks = false

    /// Notifies the delegate when start/stop happens — used to repaint the
    /// header label + button highlight.
    var onStateChange: ((Bool) -> Void)?

    /// Notifies the delegate when the recognizer suspends/resumes during a
    /// running session because the user grabbed the keyboard. Button can
    /// dim its mic icon while paused so it's obvious the mic isn't
    /// listening even though the session is technically still on.
    var onPauseChange: ((Bool) -> Void)?

    /// Auto-resume gap — the "brief nod" the user lets the keyboard rest
    /// before SFSpeechRecognizer turns back on. Every keystroke / cursor
    /// move resets this timer; when it finally fires without being
    /// re-pinged, recognition resumes from wherever the cursor is now.
    var autoResumeDelay: TimeInterval = 1.2
    private(set) var isPaused = false
    private var resumeTimer: Timer?

    /// Toggle entry point. Handles authorization (one-time prompts on
    /// first use), then start/stop. Called from the smart-dictate button,
    /// from ⌘D inside the panel, and from the global hotkey.
    func toggle(target: ChatInputTextView) {
        if isRunning { stop(); return }
        SFSpeechRecognizer.requestAuthorization { [weak self] authStatus in
            DispatchQueue.main.async {
                guard let self = self else { return }
                guard authStatus == .authorized else {
                    NSSound.beep()
                    fputs("[AppleToolbox] Speech recognition not authorized (\(authStatus.rawValue))\n", stderr)
                    return
                }
                self.start(target: target)
            }
        }
    }

    private func start(target: ChatInputTextView) {
        guard let recognizer = recognizer, recognizer.isAvailable else {
            NSSound.beep(); return
        }
        self.target = target
        tentativeRange = NSRange(location: target.selectedRange().location, length: 0)

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if #available(macOS 13.0, *), recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true
        }
        request = req

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)

        // Open the audio capture file if the delegate provided a path.
        // CAF (Core Audio Format) with the engine's native PCM format —
        // no transcoding, every tap buffer writes straight to disk.
        // Files are small (~1-2 MB per minute @ 16 kHz mono PCM) and
        // every Apple app can open them; transcoding to m4a if/when
        // the user wants smaller archive files is one `afconvert` away.
        audioFile = nil
        lastAudioPath = nil
        lastAttemptedAudioPath = nil
        sessionTranscript = ""
        if let path = nextAudioPath {
            lastAttemptedAudioPath = path
            let dir = (path as NSString).deletingLastPathComponent
            try? FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
            audioFile = try? AVAudioFile(forWriting: URL(fileURLWithPath: path),
                                         settings: format.settings,
                                         commonFormat: format.commonFormat,
                                         interleaved: format.isInterleaved)
            if audioFile != nil { lastAudioPath = path }
            nextAudioPath = nil
        }

        // Route through self.request (not the captured `req`) so we can
        // swap recognizers mid-stream without tearing down the audio engine.
        // Critical for cursor-move handling — see restartRecognitionTask().
        // ALSO write to self.audioFile so the raw audio of the dictation
        // session ends up on disk next to its transcript.
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buf, _ in
            // Drop buffers while paused — the user grabbed the keyboard,
            // we don't want their typing-while-thinking ending up in the
            // transcript OR in the audio file. Tap stays installed so we
            // can resume instantly without poking the audio engine again.
            guard let self = self, !self.isPaused else { return }
            self.request?.append(buf)
            try? self.audioFile?.write(from: buf)
        }
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            fputs("[AppleToolbox] audioEngine.start failed: \(error)\n", stderr)
            request = nil
            return
        }

        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                // Drop callbacks that arrive AFTER stop() flipped isRunning.
                // Without this guard, the recognizer's pending final-result
                // callback fires post-commit, applyPartial sees length==0,
                // and `replaceCharacters(in: (n, 0), with: text)` INSERTS
                // the whole phrase a second time at the cursor — the
                // "...great great" duplicate the user reported.
                guard self.isRunning else { return }
                if let result = result {
                    self.applyPartial(result.bestTranscription.formattedString,
                                       isFinal: result.isFinal)
                    if result.isFinal { self.commitFinal() }
                }
                if error != nil { self.stop() }
            }
        }

        isRunning = true
        onStateChange?(true)
    }

    func stop() {
        // CRITICAL ORDERING: flip isRunning OFF first. The recognition
        // task's main-queue callback checks `guard self.isRunning` and
        // drops any late-arriving final result, so we never apply the
        // same phrase twice. See the duplicate-text bug rationale at
        // the recognitionTask callback above.
        let wasRunning = isRunning
        let wasPaused = isPaused
        isRunning = false
        isPaused = false
        resumeTimer?.invalidate()
        resumeTimer = nil

        if audioEngine.isRunning { audioEngine.stop() }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        task?.finish()
        task = nil
        request = nil

        // Closing the audio file is automatic — AVAudioFile finalizes its
        // header on deinit. Dropping the reference flushes and closes.
        audioFile = nil

        // Commit any leftover tentative span as final so the user keeps
        // whatever was on screen at the moment they hit the toggle.
        // applyPartial won't fire again — isRunning is already false.
        commitFinal()

        if wasRunning {
            onStateChange?(false)
            if wasPaused { onPauseChange?(false) }
        }
    }

    /// Replace the tentative range in the text view with `text`. If
    /// `isFinal`, leaves it for commitFinal() to recolour.
    private func applyPartial(_ text: String, isFinal: Bool) {
        guard let tv = target, let ts = tv.textStorage else { return }
        suppressEditCallbacks = true
        defer { suppressEditCallbacks = false }

        // Guard against the underlying text being shorter than our cached
        // range (user could have deleted while we weren't watching).
        let storeLen = ts.length
        var range = tentativeRange
        if range.location > storeLen { range.location = storeLen }
        if range.location + range.length > storeLen {
            range.length = storeLen - range.location
        }

        let color: NSColor = isFinal ? .labelColor : .secondaryLabelColor
        let attrs: [NSAttributedString.Key: Any] = [
            .font: tv.font ?? NSFont.systemFont(ofSize: 12),
            .foregroundColor: color,
        ]
        ts.replaceCharacters(in: range, with: NSAttributedString(string: text, attributes: attrs))
        tentativeRange = NSRange(location: range.location, length: (text as NSString).length)
        tv.setSelectedRange(NSRange(location: tentativeRange.location + tentativeRange.length,
                                    length: 0))
        tv.needsDisplay = true
    }

    /// Recolour the tentative range to committed-text colour, advance the
    /// anchor, and clear the tentative length so the next phrase starts
    /// fresh at the cursor.
    private func commitFinal() {
        guard let tv = target, let ts = tv.textStorage,
              tentativeRange.length > 0 else { return }
        suppressEditCallbacks = true
        defer { suppressEditCallbacks = false }

        let storeLen = ts.length
        var range = tentativeRange
        if range.location + range.length > storeLen {
            range.length = max(0, storeLen - range.location)
        }
        ts.addAttribute(.foregroundColor, value: NSColor.labelColor, range: range)
        // Grab the committed substring so the host can slug it into the
        // audio filename after stop. NSString substring keeps UTF-16 math
        // aligned with the range we just used.
        if range.length > 0 {
            let committed = (ts.string as NSString).substring(with: range)
            if !committed.isEmpty {
                if !sessionTranscript.isEmpty { sessionTranscript += " " }
                sessionTranscript += committed
            }
        }
        tentativeRange = NSRange(location: range.location + range.length, length: 0)
    }

    /// Called by the NSTextView delegate when the user repositions the
    /// cursor or types. Commits the current tentative span IN PLACE,
    /// then PAUSES the recognizer and arms an auto-resume timer so the
    /// mic comes back on after `autoResumeDelay` seconds of keyboard
    /// quiet. Every subsequent keystroke / move re-pings the timer.
    ///
    /// Rationale for pause-then-resume instead of just restarting: while
    /// the user is editing with the keyboard, they don't want SpeechKit
    /// to be transcribing background noise / typing / their own muttering
    /// into the buffer. Pausing the mic until they signal "I'm done
    /// editing" (the brief nod = quiet keyboard) is the natural mode.
    func userMovedCursor(to location: Int) {
        guard isRunning, !suppressEditCallbacks else { return }
        if tentativeRange.length > 0 { commitFinal() }
        tentativeRange = NSRange(location: location, length: 0)
        pauseRecognition()
        scheduleResume()
    }

    /// Called every time the chat input's text changes (typed, pasted,
    /// dictation partial). Programmatic mutations from applyPartial guard
    /// themselves via `suppressEditCallbacks`. For genuine user typing we
    /// re-arm the resume timer so the mic stays paused until they stop.
    func userTyped() {
        guard isRunning, !suppressEditCallbacks else { return }
        if !isPaused { pauseRecognition() }
        scheduleResume()
    }

    /// Tear down the current SFSpeechRecognitionTask without ending the
    /// whole session. Audio engine + tap stay live (the tap will drop
    /// buffers thanks to the `isPaused` guard). Visual indicator dims.
    private func pauseRecognition() {
        guard isRunning, !isPaused else { return }
        request?.endAudio()
        task?.finish()
        task = nil
        request = nil
        isPaused = true
        onPauseChange?(true)
    }

    /// Cancel any pending resume and arm a new one. Called on every
    /// user-side edit so the timer always reflects "time since last
    /// keyboard activity".
    private func scheduleResume() {
        resumeTimer?.invalidate()
        resumeTimer = Timer.scheduledTimer(withTimeInterval: autoResumeDelay, repeats: false) { [weak self] _ in
            self?.resumeRecognition()
        }
    }

    /// Re-arm a fresh SFSpeechRecognitionTask anchored at the current
    /// cursor. Called by the resume timer when the user has been quiet
    /// for `autoResumeDelay` seconds.
    private func resumeRecognition() {
        guard isRunning, isPaused else { return }
        if let tv = target {
            tentativeRange = NSRange(location: tv.selectedRange().location, length: 0)
        }
        isPaused = false
        restartRecognitionTask()
        onPauseChange?(false)
    }

    /// Manual brickwall — finalize the current tentative span and start a
    /// fresh recognition segment. Same rationale as userMovedCursor: we
    /// must spin a fresh task or the next partial dumps the whole phrase.
    func brickwall() {
        guard isRunning else { return }
        commitFinal()
        if let tv = target {
            tentativeRange = NSRange(location: tv.selectedRange().location, length: 0)
        }
        restartRecognitionTask()
    }

    /// Tear down the current SFSpeechRecognitionTask and start a fresh
    /// one. The audio engine + tap stay running; only the request/task
    /// pair is swapped (the tap routes through self.request so new
    /// buffers flow into the new task automatically).
    private func restartRecognitionTask() {
        guard let recognizer = recognizer, recognizer.isAvailable else { return }

        request?.endAudio()
        task?.finish()
        task = nil
        request = nil

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if #available(macOS 13.0, *), recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true
        }
        request = req
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if let result = result {
                    self.applyPartial(result.bestTranscription.formattedString,
                                       isFinal: result.isFinal)
                    if result.isFinal { self.commitFinal() }
                }
                if error != nil { self.stop() }
            }
        }
    }
}

// ─── icon-strip menu row ───────────────────────────────────────────────────
//
// One NSMenuItem whose .view is a horizontal strip: status label on the left,
// row of small app-icon buttons on the right. Each button shows the real
// `.icns` resolved by NSWorkspace.icon(forFile:) — Apple's canonical icon
// system — so what you see in the menu matches the Dock and Finder.

struct IconStripLaunch {
    /// File whose icon is read. For apps, point at the .app bundle;
    /// NSWorkspace returns the bundle's CFBundleIconFile.
    let iconSource: String
    /// Optional NSImage that overrides iconSource — use this for SF Symbols,
    /// composites of multiple app icons, or any custom drawing.
    let iconImage: NSImage?
    /// Executable invoked on click. Defaults to /usr/bin/open. Override for
    /// UI-scripting helpers (osascript wrappers, bash scripts in topbar/scripts).
    let cmd: String
    /// Arguments passed to `cmd` when the icon is clicked.
    let openArgs: [String]
    /// Hover-tooltip text — disambiguate variants here (scan / vs scan ~).
    let tooltip: String

    init(iconSource: String, openArgs: [String], tooltip: String,
         cmd: String = "/usr/bin/open", iconImage: NSImage? = nil) {
        self.iconSource = iconSource
        self.iconImage = iconImage
        self.cmd = cmd
        self.openArgs = openArgs
        self.tooltip = tooltip
    }
}

/// Compose two app icons into a single side-by-side image — used for
/// "scan both, side-by-side" launchers so the button visually says
/// "two visualizers paired". Each icon takes half the width.
func compositeAppIcons(_ paths: [String], size: NSSize = NSSize(width: 36, height: 20)) -> NSImage {
    let composite = NSImage(size: size)
    composite.lockFocus()
    let slot = NSSize(width: size.width / CGFloat(paths.count), height: size.height)
    for (i, p) in paths.enumerated() {
        guard FileManager.default.fileExists(atPath: p) else { continue }
        let icon = NSWorkspace.shared.icon(forFile: p)
        let rect = NSRect(x: CGFloat(i) * slot.width, y: 0,
                          width: slot.width, height: slot.height)
        icon.draw(in: rect)
    }
    composite.unlockFocus()
    return composite
}

class IconStripView: NSView {
    let launches: [IconStripLaunch]

    init(label labelText: String, launches: [IconStripLaunch], width: CGFloat = 360) {
        self.launches = launches
        let iconBox: CGFloat = 26
        let iconImage: CGFloat = 20
        let height: CGFloat = 28
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: height))

        let stripW = CGFloat(launches.count) * iconBox + 6
        let labelW = max(60, width - stripW - 22)

        let label = NSTextField(labelWithString: labelText)
        label.frame = NSRect(x: 14, y: 6, width: labelW, height: 16)
        label.font = NSFont.menuFont(ofSize: 13)
        label.textColor = .labelColor
        label.lineBreakMode = .byTruncatingTail
        addSubview(label)

        var x = width - stripW
        for (idx, l) in launches.enumerated() {
            let btn = NSButton(frame: NSRect(x: x, y: (height - iconBox) / 2,
                                              width: iconBox - 2, height: iconBox - 2))
            let img: NSImage
            if let override = l.iconImage {
                img = override
            } else if FileManager.default.fileExists(atPath: l.iconSource) {
                img = NSWorkspace.shared.icon(forFile: l.iconSource)
            } else {
                img = NSImage(size: NSSize(width: iconImage, height: iconImage))
            }
            if l.iconImage == nil {
                img.size = NSSize(width: iconImage, height: iconImage)
            }
            btn.image = img
            btn.imagePosition = .imageOnly
            btn.bezelStyle = .regularSquare
            btn.isBordered = false
            btn.toolTip = l.tooltip
            btn.tag = idx
            btn.target = self
            btn.action = #selector(launchTapped(_:))
            addSubview(btn)
            x += iconBox
        }
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not used") }

    @objc func launchTapped(_ sender: NSButton) {
        let l = launches[sender.tag]
        runDetached(l.cmd, l.openArgs)
        enclosingMenuItem?.menu?.cancelTracking()
    }
}

/// Build an NSMenuItem whose view is an IconStripView. Use for status rows
/// where the body label and several launch targets should coexist on one line.
func iconStripRow(_ labelText: String, launches: [IconStripLaunch]) -> NSMenuItem {
    let item = NSMenuItem()
    item.view = IconStripView(label: labelText, launches: launches)
    return item
}

// ─── entry point ───────────────────────────────────────────────────────────

let argv = CommandLine.arguments
let liveMode = argv.contains("--live")
let grantMode = argv.contains("--grant-permissions")
let activateMode = argv.contains("--activate")

// `--activate`: one-shot wake. Bring an already-running --live panel front
// via Distributed Notification; if nothing is running, spawn `--live` and
// exit. Used by the "Hey Apple" Vocal Shortcut so the wake word doesn't
// have to know whether the live viewport is already up.
if activateMode {
    DistributedNotificationCenter.default().postNotificationName(
        NSNotification.Name("com.esaruoho.appletoolbox.ShowLivePanel"),
        object: nil,
        userInfo: nil,
        deliverImmediately: true)
    // Give the running process a moment to receive the notification.
    Thread.sleep(forTimeInterval: 0.2)
    // pgrep returns 0 if any AppleToolbox --live is alive. If so, we're done.
    let probe = Process()
    probe.launchPath = "/usr/bin/pgrep"
    probe.arguments = ["-f", "AppleToolbox.*--live"]
    let pipe = Pipe()
    probe.standardOutput = pipe
    do { try probe.run() } catch { exit(0) }
    probe.waitUntilExit()
    let alive = !pipe.fileHandleForReading.readDataToEndOfFile().isEmpty
    if !alive {
        let me = ProcessInfo.processInfo.arguments[0]
        let task = Process()
        task.launchPath = me
        task.arguments = ["--live"]
        try? task.run()
        // Don't waitUntilExit — let the new process keep running.
        Thread.sleep(forTimeInterval: 0.2)
    }
    exit(0)
}

let app = NSApplication.shared
if grantMode {
    // One-shot mode: fire the permission requests, then exit. Used by the
    // /grant-perms slash so it doesn't leave a stray menu-bar/Dock icon.
    app.setActivationPolicy(.accessory)
    app.activate(ignoringOtherApps: true)
    requestAllPermissions()
    // Give the async dialogs ~12 sec to finish queuing before we exit.
    let runUntil = Date().addingTimeInterval(12)
    while Date() < runUntil {
        RunLoop.current.run(mode: .default, before: Date().addingTimeInterval(0.5))
    }
} else if liveMode {
    let delegate = LiveViewportDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.regular)  // accessory mode hides panels on some macOS versions
    installLiveModeMainMenu()
    app.run()
} else {
    let delegate = AppDelegate()
    app.delegate = delegate
    app.setActivationPolicy(.accessory)  // no Dock icon — menu bar only
    app.run()
}

/// Install a minimal NSApp.mainMenu for the --live panel. Standard
/// text-editing key equivalents (Cmd+A / Cmd+C / Cmd+X / Cmd+V / Cmd+Z)
/// are dispatched by AppKit through main-menu items — without an Edit
/// menu present, the focused NSTextView never sees them. Each item has a
/// nil target so AppKit walks the responder chain and finds the
/// NSTextView (the chat composer or transcript) automatically.
func installLiveModeMainMenu() {
    let mainMenu = NSMenu()

    // App menu — required first slot; macOS shows the executable name
    // here. Contains Quit and a "Hide / Show" pair for completeness.
    let appItem = NSMenuItem()
    let appMenu = NSMenu()
    appMenu.addItem(NSMenuItem(title: "Hide AppleToolbox",
                               action: #selector(NSApplication.hide(_:)),
                               keyEquivalent: "h"))
    let hideOthers = NSMenuItem(title: "Hide Others",
                                action: #selector(NSApplication.hideOtherApplications(_:)),
                                keyEquivalent: "h")
    hideOthers.keyEquivalentModifierMask = [.command, .option]
    appMenu.addItem(hideOthers)
    appMenu.addItem(NSMenuItem(title: "Show All",
                               action: #selector(NSApplication.unhideAllApplications(_:)),
                               keyEquivalent: ""))
    appMenu.addItem(NSMenuItem.separator())
    appMenu.addItem(NSMenuItem(title: "Quit AppleToolbox",
                               action: #selector(NSApplication.terminate(_:)),
                               keyEquivalent: "q"))
    appItem.submenu = appMenu
    mainMenu.addItem(appItem)

    // Edit menu — the actual fix for Cmd+A/C/X/V/Z. Every action selector
    // is the standard NSText / NSResponder one; target stays nil so the
    // responder chain delivers them to the focused text view.
    let editItem = NSMenuItem()
    let editMenu = NSMenu(title: "Edit")
    editMenu.addItem(NSMenuItem(title: "Undo",
                                action: Selector(("undo:")), keyEquivalent: "z"))
    let redo = NSMenuItem(title: "Redo",
                          action: Selector(("redo:")), keyEquivalent: "Z")
    redo.keyEquivalentModifierMask = [.command, .shift]
    editMenu.addItem(redo)
    editMenu.addItem(NSMenuItem.separator())
    editMenu.addItem(NSMenuItem(title: "Cut",
                                action: #selector(NSText.cut(_:)), keyEquivalent: "x"))
    editMenu.addItem(NSMenuItem(title: "Copy",
                                action: #selector(NSText.copy(_:)), keyEquivalent: "c"))
    editMenu.addItem(NSMenuItem(title: "Paste",
                                action: #selector(NSText.paste(_:)), keyEquivalent: "v"))
    let pasteMatch = NSMenuItem(title: "Paste and Match Style",
                                action: Selector(("pasteAsPlainText:")),
                                keyEquivalent: "V")
    pasteMatch.keyEquivalentModifierMask = [.command, .shift, .option]
    editMenu.addItem(pasteMatch)
    editMenu.addItem(NSMenuItem(title: "Delete",
                                action: #selector(NSText.delete(_:)),
                                keyEquivalent: ""))
    editMenu.addItem(NSMenuItem(title: "Select All",
                                action: #selector(NSText.selectAll(_:)),
                                keyEquivalent: "a"))
    editMenu.addItem(NSMenuItem.separator())

    // Find submenu — wires Cmd+F to the find bar we already enabled on
    // ChatInputTextView via usesFindBar = true.
    let findItem = NSMenuItem(title: "Find", action: nil, keyEquivalent: "")
    let findMenu = NSMenu(title: "Find")
    findMenu.addItem(NSMenuItem(title: "Find…",
                                action: Selector(("performFindPanelAction:")),
                                keyEquivalent: "f"))
    findItem.submenu = findMenu
    editMenu.addItem(findItem)

    // Spelling submenu — Cmd+; flag spelling.
    let spellingItem = NSMenuItem(title: "Spelling and Grammar", action: nil, keyEquivalent: "")
    let spellingMenu = NSMenu(title: "Spelling and Grammar")
    spellingMenu.addItem(NSMenuItem(title: "Show Spelling and Grammar",
                                    action: Selector(("showGuessPanel:")),
                                    keyEquivalent: ":"))
    spellingMenu.addItem(NSMenuItem(title: "Check Document Now",
                                    action: Selector(("checkSpelling:")),
                                    keyEquivalent: ";"))
    spellingItem.submenu = spellingMenu
    editMenu.addItem(spellingItem)

    editItem.submenu = editMenu
    mainMenu.addItem(editItem)

    NSApp.mainMenu = mainMenu
}
