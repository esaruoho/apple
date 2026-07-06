// Guidance — a single-window Mac app that shows every AI agent (Claude / Codex /
// Copilot) running in your terminals: what each is DOING right now, which folder
// it's in (its "space"), and where two agents collide (same space, or same file).
//
// SAFETY (this tool wedged the machine on 2026-07-05 and was rebuilt):
//   • It NEVER sends AppleEvents / talks to iTerm2 or Terminal. Data comes only
//     from `bin/guidance`, which reads `ps` plus local Claude / Codex / Copilot
//     session data. It therefore cannot make a terminal unresponsive.
//   • There is NO timer and NO loop. It refreshes ONCE when opened, then only
//     when you click ⟳. `load()` is timeout-bounded and overlap-guarded as
//     belt-and-suspenders. Do not add a Timer.
//
// Apple-native: SwiftUI + AppKit, built with xcrun swiftc, no Xcode. Read-only.

import SwiftUI
import AppKit
import Foundation

// ───────────────────────────── Model ─────────────────────────────

struct Synopsis: Codable {
    var turns: Int
    var edited: [String]
    var wrote: [String]
    var read: [String]
    var commands: Int
    var commits: [String]
    var recap: [String]
}

struct Agent: Codable, Identifiable {
    var id: String { tty }
    var tty: String
    var pid: String
    var tool: String
    var cmd: String
    var session_id: String
    var cwd: String
    var space: String
    var name: String
    var mapped: String
    var last_ts: Int
    var focus: String
    var files: [String]
    var synopsis: Synopsis

    var isAgent: Bool { ["claude", "codex", "copilot"].contains(tool) }
}

struct Collision: Codable, Identifiable {
    var id: String { "\(kind):\(key)" }
    var kind: String            // "space" | "file"
    var key: String
    var ttys: [String]
    var count: Int
}

struct ScheduledPing: Codable, Identifiable {
    var id: String
    var tty: String
    var text: String
    var fire_epoch: Int
    var created_epoch: Int
    var tool: String
    var space: String
    var name: String
    var note: String
    var status: String          // pending | sent | failed | canceled
    var attempts: Int
    var result: String
    var fired_epoch: Int

    var isPending: Bool { status == "pending" }
    var fireDate: Date { Date(timeIntervalSince1970: TimeInterval(fire_epoch)) }
    var shortTTY: String { tty.replacingOccurrences(of: "/dev/", with: "") }
    var target: String {
        let s = space.isEmpty ? shortTTY : space
        return tool.isEmpty ? s : "\(tool) · \(s)"
    }
}

struct GuidanceData: Codable {
    var generated: Int
    var agents: [Agent]
    var collisions: [Collision]
    var schedule: [ScheduledPing]?
}

// ─────────────────────── Config (whitelabel) ───────────────────────

enum GuidanceConfig {
    static let bin: String = {
        if let v = ProcessInfo.processInfo.environment["GUIDANCE_BIN"], !v.isEmpty { return v }
        return "\(NSHomeDirectory())/work/apple/bin/guidance"
    }()
}

// ─────────────────────── Data source ───────────────────────

enum GuidanceSource {
    /// Run `guidance --json` and decode. Blocking — call off the main thread.
    static func load() -> GuidanceData? {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", GuidanceConfig.bin, "--json"]
        let outPipe = Pipe()
        let errPipe = Pipe()
        var output = Data()
        p.standardOutput = outPipe
        p.standardError = errPipe
        do {
            let done = DispatchSemaphore(value: 0)
            let lock = NSLock()
            outPipe.fileHandleForReading.readabilityHandler = { handle in
                let chunk = handle.availableData
                guard !chunk.isEmpty else { return }
                lock.lock()
                output.append(chunk)
                lock.unlock()
            }
            errPipe.fileHandleForReading.readabilityHandler = { _ in }
            p.terminationHandler = { _ in done.signal() }
            try p.run()
            if done.wait(timeout: .now() + 15) == .timedOut {
                p.terminate()
                outPipe.fileHandleForReading.readabilityHandler = nil
                errPipe.fileHandleForReading.readabilityHandler = nil
                return nil
            }
            outPipe.fileHandleForReading.readabilityHandler = nil
            errPipe.fileHandleForReading.readabilityHandler = nil
            let rest = outPipe.fileHandleForReading.readDataToEndOfFile()
            lock.lock()
            output.append(rest)
            let data = output
            lock.unlock()
            return try JSONDecoder().decode(GuidanceData.self, from: data)
        } catch { return nil }
    }
}

// ───────────────────────────── ViewModel ─────────────────────────────

final class GuidanceModel: ObservableObject {
    @Published var agents: [Agent] = []
    @Published var collisions: [Collision] = []
    @Published var schedule: [ScheduledPing] = []
    @Published var generated: Int = 0
    @Published var loading = false
    @Published var lastError: String?
    @Published var toast: String?
    @Published var auto = true
    @Published var expandedTTYs: Set<String> = []
    @Published var composingTTYs: Set<String> = []
    @Published var columns: Int = max(1, UserDefaults.standard.integer(forKey: "guidance.columns")) {
        didSet { UserDefaults.standard.set(columns, forKey: "guidance.columns") }
    }
    @Published var expandAll: Bool = UserDefaults.standard.bool(forKey: "guidance.expandAll") {
        didSet { UserDefaults.standard.set(expandAll, forKey: "guidance.expandAll") }
    }

    private var reloading = false
    private var timer: Timer?

    var agentCount: Int { agents.filter { $0.isAgent }.count }
    var spaceCollisions: [Collision] { collisions.filter { $0.kind == "space" } }
    var fileCollisions: [Collision] { collisions.filter { $0.kind == "file" } }

    /// Pending pings, soonest first — the "it WILL be re-pinged" list.
    var pendingPings: [ScheduledPing] {
        schedule.filter { $0.isPending }.sorted { $0.fire_epoch < $1.fire_epoch }
    }
    /// Recently resolved pings (sent/failed/canceled) newest first, for a short trail.
    var recentPings: [ScheduledPing] {
        schedule.filter { !$0.isPending }
            .sorted { max($0.fired_epoch, $0.created_epoch) > max($1.fired_epoch, $1.created_epoch) }
    }

    /// TTYs that are in a space-collision (for row highlighting).
    var collidingTTYs: Set<String> {
        Set(spaceCollisions.flatMap { $0.ttys })
    }

    /// Agents grouped by space, sorted, collisions first.
    /// Newest activity first (by transcript mtime), oldest last.
    var agentsSorted: [Agent] {
        agents.filter { $0.isAgent }.sorted { $0.last_ts > $1.last_ts }
    }

    func boot() {
        DispatchQueue.global(qos: .utility).async { Self.runDue() }
        reload(manual: true)
        setAuto(true)
    }

    /// SAFE auto-refresh: 15s interval, single-flight (the `reloading` guard in
    /// reload() drops overlapping ticks), each refresh timeout-bounded and cheap
    /// (ps + 64 KB transcript tails, ~0.3s). This is NOT the 2026-07-05 wedge
    /// pattern — that was a 4-SECOND timer firing un-timed-out full-buffer
    /// scrapes with no overlap guard. Toggle off with the pause button.
    func setAuto(_ on: Bool) {
        auto = on
        timer?.invalidate(); timer = nil
        guard on else { return }
        timer = Timer.scheduledTimer(withTimeInterval: 15, repeats: true) { [weak self] _ in
            // Fire due pings every tick regardless of whether the board reload is
            // skipped (it skips while a card is open). Firing must never wait on
            // the UI. The board reload then follows and picks up status changes.
            DispatchQueue.global(qos: .utility).async { Self.runDue() }
            self?.reload()
        }
    }

    func reload(manual: Bool = false) {
        guard !reloading else { return }
        // Don't reorder the list out from under you while a card is open (reading
        // or composing) — that's how a Send can land on the wrong session.
        // Manual ⌘R / ↻ always refreshes.
        if !manual && (!expandedTTYs.isEmpty || !composingTTYs.isEmpty) { return }
        reloading = true
        loading = true
        DispatchQueue.global(qos: .utility).async {
            let data = GuidanceSource.load()
            DispatchQueue.main.async {
                self.reloading = false
                self.loading = false
                guard let d = data else {
                    self.lastError = "Couldn’t read agents. Guidance reads `ps` plus local Claude / "
                        + "Codex / Copilot session data only — it never scrapes terminals. "
                        + "Check that ~/work/apple/bin/guidance is present, then click ⟳."
                    return
                }
                self.lastError = nil
                self.agents = d.agents
                self.collisions = d.collisions
                self.schedule = d.schedule ?? []
                self.generated = d.generated
            }
        }
    }

    /// Run every due scheduled ping. Lock-guarded and idempotent in the CLI.
    /// Called off the main thread on each refresh — this is the reliable firer
    /// (Guidance.app has the Automation grant that a launchd context lacks).
    static func runDue() {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
        p.arguments = ["python3", GuidanceConfig.bin, "schedule", "run-due"]
        p.standardOutput = Pipe(); p.standardError = Pipe()
        do {
            let done = DispatchSemaphore(value: 0)
            p.terminationHandler = { _ in done.signal() }
            try p.run()
            if done.wait(timeout: .now() + 50) == .timedOut { p.terminate() }
        } catch { }
    }

    /// Schedule a ping: `guidance schedule add …`. Refreshes on completion so the
    /// new pending ping shows in the banner immediately.
    func scheduleAdd(tty: String, tool: String, space: String, name: String,
                     atEpoch: Int, text: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            p.arguments = ["python3", GuidanceConfig.bin, "schedule", "add",
                           "--tty", tty, "--at", String(atEpoch), "--text", text,
                           "--tool", tool, "--space", space, "--name", name]
            let out = Pipe(); p.standardOutput = out; p.standardError = Pipe()
            var ok = false
            do {
                let done = DispatchSemaphore(value: 0)
                p.terminationHandler = { _ in done.signal() }
                try p.run()
                if done.wait(timeout: .now() + 10) == .timedOut { p.terminate() }
                else {
                    let s = String(data: out.fileHandleForReading.readDataToEndOfFile(),
                                   encoding: .utf8) ?? ""
                    ok = s.contains("\"status\": \"pending\"") || s.contains("\"status\":\"pending\"")
                }
            } catch { }
            DispatchQueue.main.async {
                let when = Date(timeIntervalSince1970: TimeInterval(atEpoch))
                let f = DateFormatter(); f.dateFormat = "HH:mm"
                if ok { self.flash("🕐 scheduled → \(space) at \(f.string(from: when))") }
                else { self.flash("⚠ couldn’t schedule ping") }
                self.reload(manual: true)
            }
        }
    }

    func scheduleCancel(_ id: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            p.arguments = ["python3", GuidanceConfig.bin, "schedule", "cancel", id]
            p.standardOutput = Pipe(); p.standardError = Pipe()
            do {
                let done = DispatchSemaphore(value: 0)
                p.terminationHandler = { _ in done.signal() }
                try p.run()
                if done.wait(timeout: .now() + 8) == .timedOut { p.terminate() }
            } catch { }
            DispatchQueue.main.async {
                self.flash("canceled ping")
                self.reload(manual: true)
            }
        }
    }

    /// Send ONE line to ONE session — shells `guidance write <tty> <text>`, which
    /// targets the matching iTerm session by tty. Called only from a button/Return in a card.
    /// Never on a timer, never batched. Fails loud (distinct toasts per outcome).
    func write(tty: String, text: String) {
        let short = tty.replacingOccurrences(of: "/dev/", with: "")
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            p.arguments = ["python3", GuidanceConfig.bin, "write", tty, text]
            let out = Pipe(); p.standardOutput = out; p.standardError = Pipe()
            var result = ""
            do {
                let done = DispatchSemaphore(value: 0)
                p.terminationHandler = { _ in done.signal() }
                try p.run()
                if done.wait(timeout: .now() + 12) == .timedOut {
                    p.terminate(); result = "error:timed out"
                } else {
                    result = String(data: out.fileHandleForReading.readDataToEndOfFile(),
                                    encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                }
            } catch { result = "error:\(error.localizedDescription)" }
            DispatchQueue.main.async {
                if result.hasPrefix("ok:") { self.flash("→ sent to \(short)") }
                else if result.hasPrefix("notfound") { self.flash("⚠ tty \(short) is gone — nothing sent") }
                else { self.flash("⚠ send to \(short) failed: \(result)") }
            }
        }
    }

    /// Bring one session's iTerm2 window to the front — one AppleEvent, on click.
    func front(tty: String) {
        DispatchQueue.global(qos: .userInitiated).async {
            let p = Process()
            p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            p.arguments = ["python3", GuidanceConfig.bin, "front", tty]
            p.standardOutput = Pipe(); p.standardError = Pipe()
            do {
                let done = DispatchSemaphore(value: 0)
                p.terminationHandler = { _ in done.signal() }
                try p.run()
                if done.wait(timeout: .now() + 10) == .timedOut { p.terminate() }
            } catch { }
        }
    }

    private func flash(_ msg: String) {
        toast = msg
        DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
            if self.toast == msg { self.toast = nil }
        }
    }

    func setComposing(tty: String, active: Bool) {
        if active { composingTTYs.insert(tty) }
        else { composingTTYs.remove(tty) }
    }
}

// ───────────────────────────── Views ─────────────────────────────

@main
struct GuidanceApp: App {
    @StateObject private var model = GuidanceModel()

    init() {
        // Kill window tabbing → removes View ▸ Show Tab Bar and Window ▸ Show
        // All Tabs. Guidance is a single window.
        NSWindow.allowsAutomaticWindowTabbing = false
    }

    var body: some Scene {
        // `Window` (not WindowGroup) = one window, no ⌘N "New Guidance Window".
        Window("Guidance", id: "guidance") {
            GuidanceView().environmentObject(model).onAppear { model.boot() }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 760, height: 640)
        .commands {
            AppHelpCommand(appName: "Guidance")   // shared Help + donate (see shared/SupportHelp.swift)
            CommandGroup(replacing: .newItem) { }  // no New-window command
        }
    }
}

func toolColor(_ tool: String) -> Color {
    switch tool {
    case "claude": return .orange
    case "codex": return .green
    case "copilot": return .blue
    default: return .gray
    }
}

/// Relative "Ns ago" from epoch seconds (0 = unknown → "").
func ago(_ ts: Int) -> String {
    guard ts > 0 else { return "" }
    let s = max(0, Int(Date().timeIntervalSince1970) - ts)
    if s < 60 { return "\(s)s ago" }
    if s < 3600 { return "\(s / 60)m ago" }
    if s < 86400 { return "\(s / 3600)h ago" }
    return "\(s / 86400)d ago"
}

/// Render inline markdown (**bold**, `code`, _italic_) so recap lines don't show
/// raw `**` markers. Falls back to plain text if it can't parse.
func mdText(_ s: String) -> Text {
    if let a = try? AttributedString(
        markdown: s,
        options: .init(interpretedSyntax: .inlineOnlyPreservingWhitespace)) {
        return Text(a)
    }
    return Text(s)
}

/// "26m 30s" / "0m 08s" / "now" from a seconds count.
func countdown(_ secs: Int) -> String {
    if secs <= 0 { return "now" }
    let h = secs / 3600, m = (secs % 3600) / 60, s = secs % 60
    if h > 0 { return "\(h)h \(m)m" }
    return "\(m)m \(String(format: "%02d", s))s"
}

func hhmmss(_ epoch: Int) -> String {
    let f = DateFormatter(); f.dateFormat = "HH:mm:ss"
    return f.string(from: Date(timeIntervalSince1970: TimeInterval(epoch)))
}

/// The always-visible proof: "these pings WILL be sent, at these times." Pending
/// pings show a live countdown; recently-resolved ones show a short outcome trail.
struct ScheduledPingsBar: View {
    @EnvironmentObject var model: GuidanceModel

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(model.pendingPings) { ping in pendingRow(ping) }
            ForEach(model.recentPings.prefix(3)) { ping in recentRow(ping) }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.accentColor.opacity(0.08))
    }

    private func pendingRow(_ ping: ScheduledPing) -> some View {
        // TimelineView redraws only this row every second — no model churn.
        TimelineView(.periodic(from: .now, by: 1)) { ctx in
            let remain = ping.fire_epoch - Int(ctx.date.timeIntervalSince1970)
            HStack(spacing: 8) {
                Image(systemName: "clock.badge.checkmark")
                    .foregroundColor(.accentColor)
                Text(hhmmss(ping.fire_epoch)).font(.system(size: 12, weight: .semibold, design: .monospaced))
                Text("in \(countdown(remain))")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(remain <= 60 ? .orange : .secondary)
                    .frame(width: 78, alignment: .leading)
                Circle().fill(toolColor(ping.tool)).frame(width: 7, height: 7)
                Text(ping.target).font(.system(size: 11)).foregroundColor(.secondary)
                    .lineLimit(1).truncationMode(.middle)
                Text("“\(ping.text)”").font(.system(size: 11)).italic()
                    .lineLimit(1).truncationMode(.tail)
                if ping.attempts > 0 {
                    Text("· sending… (try \(ping.attempts))").font(.system(size: 10)).foregroundColor(.orange)
                }
                Spacer(minLength: 4)
                Button {
                    model.scheduleCancel(ping.id)
                } label: {
                    Image(systemName: "xmark.circle.fill").foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Cancel this scheduled ping")
            }
        }
    }

    private func recentRow(_ ping: ScheduledPing) -> some View {
        let (icon, color): (String, Color) = {
            switch ping.status {
            case "sent": return ("checkmark.circle.fill", .green)
            case "failed": return ("exclamationmark.triangle.fill", .red)
            default: return ("minus.circle", .secondary)
            }
        }()
        return HStack(spacing: 8) {
            Image(systemName: icon).foregroundColor(color).font(.system(size: 11))
            Text(ping.status == "sent" ? hhmmss(ping.fired_epoch) : hhmmss(ping.fire_epoch))
                .font(.system(size: 11, design: .monospaced)).foregroundColor(.secondary)
            Text(ping.target).font(.system(size: 10)).foregroundColor(.secondary)
                .lineLimit(1).truncationMode(.middle)
            Text("“\(ping.text)”").font(.system(size: 10)).italic().foregroundColor(.secondary)
                .lineLimit(1).truncationMode(.tail)
            Spacer(minLength: 0)
            Text(ping.status).font(.system(size: 9)).foregroundColor(color)
        }
        .opacity(0.85)
    }
}

struct GuidanceView: View {
    @EnvironmentObject var model: GuidanceModel
    @State private var showHelp = false

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider()
            if !model.pendingPings.isEmpty || !model.recentPings.isEmpty {
                ScheduledPingsBar()
                Divider()
            }
            if let e = model.lastError {
                Text(e).font(.callout).foregroundColor(.secondary)
                    .padding().frame(maxWidth: .infinity, alignment: .leading)
            }
            ScrollView(.vertical, showsIndicators: true) {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 10, alignment: .top),
                                   count: max(1, model.columns)),
                    alignment: .leading, spacing: 10) {
                    ForEach(model.agentsSorted) { agent in
                        AgentRow(agent: agent)
                    }
                }
                .padding(16)
                if model.agentCount == 0 {
                    Text("No claude / codex / copilot session is running right now.\nStart one in a terminal, then it appears here.")
                        .foregroundColor(.secondary).padding()
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            if let toast = model.toast {
                Text(toast).font(.callout).padding(8)
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor.opacity(0.15))
            }
        }
        .frame(minWidth: 460, minHeight: 420)
        .onReceive(NotificationCenter.default.publisher(for: .showAppHelp)) { _ in
            showHelp = true
        }
    }

    private var header: some View {
        HStack(spacing: 10) {
            Image(systemName: "point.3.filled.connected.trianglepath.dotted")
                .foregroundColor(.accentColor)
            Text("Guidance").font(.headline)
            Picker("", selection: $model.columns) {
                ForEach(1...4, id: \.self) { Text("\($0)").tag($0) }
            }
            .pickerStyle(.segmented).labelsHidden().frame(width: 116)
            .help("Cards per row")
            Button { model.expandAll.toggle() } label: {
                Image(systemName: model.expandAll ? "rectangle.grid.1x2.fill" : "rectangle.grid.1x2")
            }
            .buttonStyle(.borderless)
            .help(model.expandAll ? "All cards open (post-it wall) — click to collapse" : "Open all cards (post-it wall)")
            Spacer()
            // Single merged label + a fixed-size spinner slot, so the header
            // never reflows/jumps when a refresh starts or finishes.
            Text("\(model.agentCount) agent\(model.agentCount == 1 ? "" : "s")\(model.generated > 0 ? " · \(ago(model.generated))" : "")")
                .font(.caption).foregroundColor(.secondary)
                .frame(minWidth: 120, alignment: .trailing)
            ProgressView().controlSize(.small)
                .frame(width: 16, height: 16)
                .opacity(model.loading ? 1 : 0)
            Button { model.setAuto(!model.auto) } label: {
                Image(systemName: model.auto ? "pause.circle" : "play.circle")
            }
            .buttonStyle(.borderless)
            .help(model.auto ? "Auto-refresh every 15s — click to pause" : "Auto-refresh paused — click to resume")
            Button { model.reload(manual: true) } label: { Image(systemName: "arrow.clockwise") }
                .buttonStyle(.borderless)
                .keyboardShortcut("r", modifiers: .command)
                .help("Refresh (⌘R)")
            Button { showHelp.toggle() } label: { Image(systemName: "questionmark.circle") }
                .buttonStyle(.borderless)
                .help("What is Guidance?")
                .popover(isPresented: $showHelp, arrowEdge: .bottom) {
                    AppHelpView(
                        appName: "Guidance",
                        tagline: "Every AI agent (Claude / Codex / Copilot) running in your terminals, newest activity first — and what each has been doing.",
                        usage: [
                            ("chevron.down", "Click a card anywhere to expand its “what was done” analysis."),
                            ("paperplane", "Type in a card, press Send — it confirms the target, then types one line into that session."),
                            ("arrow.clockwise", "⌘R or ↻ refreshes. ⏸ pauses auto-refresh; it also holds while a card is open."),
                            ("questionmark.circle", "≈ = analysis folder-matched, not exact-session."),
                        ],
                        note: "Read-only except Send. It reads `ps` plus local Claude / Codex / Copilot session data — it does not scrape your terminals.")
                }
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
    }
}

struct AgentRow: View {
    @EnvironmentObject var model: GuidanceModel
    let agent: Agent
    @State private var expanded = false
    @State private var draft = ""
    @State private var draftTTY = ""
    @State private var showSchedule = false
    @State private var pingText = ""
    @State private var pingDate = Date().addingTimeInterval(300)
    private let openCardHeight: CGFloat = 360

    /// Open if this card was tapped, or the whole board is in "open all" mode.
    private var isOpen: Bool { model.expandAll || expanded }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // The header toggles expand — big hotspot, focus text included.
            // (The tty is a separate button that brings the terminal to front.)
            headerRow
                .contentShape(Rectangle())
                .onTapGesture {
                    expanded.toggle()
                    if expanded { model.expandedTTYs.insert(agent.tty) }
                    else { model.expandedTTYs.remove(agent.tty) }
                }
            if isOpen { expandedBody }
        }
        .padding(12)
        .frame(maxWidth: .infinity,
               minHeight: isOpen ? openCardHeight : nil,
               maxHeight: isOpen ? openCardHeight : nil,
               alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(NSColor.controlBackgroundColor)))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.22), lineWidth: 1))
        .onDisappear {
            model.expandedTTYs.remove(agent.tty)
            model.setComposing(tty: agent.tty, active: false)
        }
    }

    private var headerRow: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle().fill(toolColor(agent.tool)).frame(width: 9, height: 9).padding(.top, 4)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(agent.tool).font(.caption).bold().foregroundColor(toolColor(agent.tool))
                    Button { model.front(tty: agent.tty) } label: {
                        Text(agent.tty.replacingOccurrences(of: "/dev/", with: ""))
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.accentColor)
                    }
                    .buttonStyle(.plain)
                    .help("Bring this session’s terminal window to the front")
                    Text(agent.space).font(.system(size: 10)).foregroundColor(.secondary)
                        .lineLimit(1).truncationMode(.middle)
                    if !agent.name.isEmpty {
                        Text("“\(agent.name)”").font(.system(size: 10)).italic().foregroundColor(.secondary)
                            .lineLimit(1).truncationMode(.middle)
                    }
                    if agent.mapped == "cwd" {
                        Text("≈").font(.system(size: 11)).foregroundColor(.orange)
                            .help("Synopsis matched by folder, not exact session — with several agents in one folder it may belong to a sibling. Send still targets this exact tty.")
                    }
                    Spacer(minLength: 0)
                    if !ago(agent.last_ts).isEmpty {
                        Text(ago(agent.last_ts)).font(.system(size: 10)).foregroundColor(.secondary)
                    }
                    // Prominent "schedule a timed ping to THIS session" button —
                    // one per card, on the right so it's always visible.
                    Button { showSchedule.toggle() } label: {
                        // `clock.badge.plus` is MISSING on some macOS builds and
                        // renders blank (a bare blue pill). Compose the same idea
                        // from symbols that always exist: a clock + a small plus,
                        // with a text "Ping" so it's unmistakable regardless.
                        HStack(spacing: 2) {
                            Image(systemName: "clock").font(.system(size: 11, weight: .semibold))
                            Image(systemName: "plus").font(.system(size: 8, weight: .bold))
                            Text("Ping").font(.system(size: 10, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 6).padding(.vertical, 3)
                        .background(RoundedRectangle(cornerRadius: 5).fill(Color.accentColor))
                    }
                    .buttonStyle(.plain)
                    .help("Schedule a timed message to this session")
                    .popover(isPresented: $showSchedule, arrowEdge: .bottom) { schedulePopover }
                    Image(systemName: isOpen ? "chevron.up" : "chevron.down")
                        .font(.system(size: 10)).foregroundColor(.secondary)
                }
                (agent.focus.isEmpty
                    ? Text("(running · no recent activity captured)").foregroundColor(.secondary)
                    : mdText(agent.focus).foregroundColor(.primary))
                    .font(.caption)
                    .lineLimit(5, reservesSpace: true)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder private var expandedBody: some View {
        let s = agent.synopsis
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.vertical, showsIndicators: true) {
                VStack(alignment: .leading, spacing: 6) {
                    if !agent.focus.isEmpty {
                        Text("LATEST")
                            .font(.system(size: 9)).bold().foregroundColor(.secondary).tracking(1)
                        mdText(agent.focus).font(.system(size: 11, weight: .semibold))
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if !s.recap.isEmpty {
                        Text("WHAT WAS DONE (agent's own words)")
                            .font(.system(size: 9)).bold().foregroundColor(.secondary).tracking(1)
                        ForEach(Array(s.recap.enumerated()), id: \.offset) { _, line in
                            (Text("• ") + mdText(line)).font(.system(size: 11))
                                .fixedSize(horizontal: false, vertical: true)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    if !s.commits.isEmpty {
                        ForEach(Array(s.commits.enumerated()), id: \.offset) { _, c in
                            Text(c).font(.system(size: 10, design: .monospaced)).foregroundColor(.secondary)
                                .lineLimit(1).truncationMode(.middle)
                        }
                    }
                    if !s.wrote.isEmpty { fileLine("Wrote", s.wrote) }
                    if !s.edited.isEmpty { fileLine("Edited", s.edited) }
                    if !s.read.isEmpty { fileLine("Read", Array(s.read.prefix(10))) }
                }
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            // Click-to-write: one line to THIS iTerm session, matched by tty.
            HStack(spacing: 6) {
                TextField("write a line to this session…", text: $draft)
                    .textFieldStyle(.roundedBorder).font(.caption)
                    .onSubmit(send)
                    .onChange(of: draft) { _, newValue in
                        if newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            if !draftTTY.isEmpty { model.setComposing(tty: draftTTY, active: false) }
                            draftTTY = ""
                        } else if draftTTY.isEmpty {
                            draftTTY = agent.tty
                            model.setComposing(tty: draftTTY, active: true)
                        }
                    }
                Button("Send", action: send)
                    .controlSize(.small)
                    .disabled(draft.trimmingCharacters(in: .whitespaces).isEmpty)
                    .help("Send this line to the session. ⇧-click to also bring its terminal to the front.")
            }
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(RoundedRectangle(cornerRadius: 6).fill(Color.black.opacity(0.06)))
        .textSelection(.enabled)
    }

    private func fileLine(_ label: String, _ paths: [String]) -> some View {
        let names = paths.map { ($0 as NSString).lastPathComponent }.joined(separator: ", ")
        return (Text(label + ": ").font(.system(size: 10)).bold().foregroundColor(.secondary)
                + Text(names).font(.system(size: 10)).foregroundColor(.secondary))
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var schedulePopover: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Schedule a ping")
                .font(.headline)
            HStack(spacing: 6) {
                Circle().fill(toolColor(agent.tool)).frame(width: 8, height: 8)
                Text("\(agent.tool) · \(agent.space) · \(agent.tty.replacingOccurrences(of: "/dev/", with: ""))")
                    .font(.caption).foregroundColor(.secondary).lineLimit(1).truncationMode(.middle)
            }
            TextField("message to send at that time…", text: $pingText)
                .textFieldStyle(.roundedBorder)
                .frame(width: 320)
            HStack {
                DatePicker("Send at", selection: $pingDate,
                           displayedComponents: [.hourAndMinute])
                    .datePickerStyle(.field).labelsHidden()
                Text("Send at").font(.caption).foregroundColor(.secondary)
                Spacer()
                ForEach([("+5m", 300), ("+15m", 900), ("+1h", 3600)], id: \.0) { label, secs in
                    Button(label) { pingDate = Date().addingTimeInterval(TimeInterval(secs)) }
                        .controlSize(.small).buttonStyle(.bordered)
                }
            }
            Text(scheduleSummary).font(.caption2).foregroundColor(.secondary)
            HStack {
                Spacer()
                Button("Cancel") { showSchedule = false }
                Button("Schedule") { doSchedule() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(pingText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(14)
        .frame(width: 360)
    }

    /// The resolved fire time (rolls to tomorrow if the chosen HH:mm already passed).
    private var resolvedEpoch: Int {
        var e = Int(pingDate.timeIntervalSince1970)
        if e <= Int(Date().timeIntervalSince1970) { e += 86400 }
        return e
    }

    private var scheduleSummary: String {
        let remain = resolvedEpoch - Int(Date().timeIntervalSince1970)
        return "Fires at \(hhmmss(resolvedEpoch)) — in \(countdown(remain))."
    }

    private func doSchedule() {
        let text = pingText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        model.scheduleAdd(tty: agent.tty, tool: agent.tool, space: agent.space,
                          name: agent.name, atEpoch: resolvedEpoch, text: text)
        showSchedule = false
        pingText = ""
    }

    private func send() {
        let line = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !line.isEmpty else { return }
        // ⇧-click Send (or ⇧-Return) = send AND bring that terminal to the front,
        // so you watch the line land. Capture the modifier at click time — by the
        // time the confirm sheet closes, shift is long released.
        let alsoFront = NSEvent.modifierFlags.contains(.shift)
        let targetTTY = draftTTY.isEmpty ? agent.tty : draftTTY
        let targetAgent = model.agents.first { $0.tty == targetTTY } ?? agent
        let short = targetTTY.replacingOccurrences(of: "/dev/", with: "")
        let alert = NSAlert()
        alert.messageText = "Send to \(targetAgent.tool) · \(short) · \(targetAgent.space)?"
        alert.informativeText = "“\(line)”\n\nThis writes the line into the iTerm session with THAT tty and submits it. Check it's the right one — this is how a message ends up in the wrong Claude."
            + (alsoFront ? "\n\n⇧ held → its terminal window will be brought to the front." : "")
        alert.addButton(withTitle: "Send")
        alert.addButton(withTitle: "Cancel")
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        if alsoFront { model.front(tty: targetTTY) }
        model.write(tty: targetTTY, text: line)
        model.setComposing(tty: targetTTY, active: false)
        draft = ""
        draftTTY = ""
    }
}
