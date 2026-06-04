// AppleBar — a Spotlight-style command bar for the Apple toolbox.
//
// Press the global hotkey (⌥Space) anywhere → a floating text field drops in →
// type a plain-language request ("how warm is it at home") → it runs `apple-intent`
// (on-device NLEmbedding routing → an apple-do action) and shows the result inline.
//
// Runs on ANY Mac — NLEmbedding is macOS 10.15+, so this is the NON-TAHOE front
// door to the toolbox: no FoundationModels, no LLM in the loop. Apple-native:
// Cocoa + Carbon (RegisterEventHotKey, no accessibility permission needed).
//
// Build: ./apple-bar/build.sh   (LSUIElement menu-bar agent, no Dock icon)
import Cocoa
import Carbon.HIToolbox
import Speech
import AVFoundation
import NaturalLanguage

// Path to the engine. Override with APPLE_INTENT if the repo lives elsewhere.
let INTENT_BIN = ProcessInfo.processInfo.environment["APPLE_INTENT"]
    ?? "/Users/esaruoho/work/apple/bin/apple-intent"
// The shared capability catalog (same file apple-intent routes over).
let INTENTS_JSON = (INTENT_BIN as NSString).deletingLastPathComponent
    .replacingOccurrences(of: "/bin", with: "/shared") + "/intents.json"

/// A borderless panel that will accept key focus so the text field is typable.
final class CommandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}

/// NSTextField draws a single line of text toward the TOP of its cell, which with a
/// 22pt font in a tall field reads as "slightly upper". Centre it by computing the line
/// height from the FONT (not cellSize, which returns ~the full bounds for a scrollable
/// single-line cell — why the drawingRect-only attempt did nothing) and overriding every
/// rect the cell uses: the title (placeholder/value) AND the field editor (typing).
final class VCenteredCell: NSTextFieldCell {
    private func centered(_ rect: NSRect) -> NSRect {
        let f = font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)
        let lineH = ceil(f.ascender - f.descender + f.leading)
        let dy = rect.height - lineH
        guard dy > 0 else { return rect }
        return NSRect(x: rect.origin.x, y: rect.origin.y + dy / 2, width: rect.width, height: lineH)
    }
    override func titleRect(forBounds rect: NSRect) -> NSRect { centered(super.titleRect(forBounds: rect)) }
    override func drawInterior(withFrame cellFrame: NSRect, in controlView: NSView) {
        super.drawInterior(withFrame: centered(cellFrame), in: controlView)
    }
    override func edit(withFrame rect: NSRect, in controlView: NSView, editor: NSText, delegate: Any?, event: NSEvent?) {
        super.edit(withFrame: centered(rect), in: controlView, editor: editor, delegate: delegate, event: event)
    }
    override func select(withFrame rect: NSRect, in controlView: NSView, editor: NSText, delegate: Any?, start selStart: Int, length selLength: Int) {
        super.select(withFrame: centered(rect), in: controlView, editor: editor, delegate: delegate, start: selStart, length: selLength)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextFieldDelegate {
    var statusItem: NSStatusItem!
    var panel: CommandPanel!
    var field: NSTextField!
    var resultView: NSTextView!
    var resultScroll: NSScrollView!
    var spinner: NSProgressIndicator!
    var micButton: NSButton!
    var hotKeyRef: EventHotKeyRef?       // ⌥Space
    var hotKeyRefCtrl: EventHotKeyRef?   // ⌃Space

    // Dictation: the shared on-device engine (shared/Dictation.swift), not a
    // re-roll. AppleBar just wires its callbacks to the text field + mic button.
    let dictation = OnDeviceDictation()

    // "Hey Sal" fold: hands-free voice. listenMode is set when AppleBar is woken by
    // applebar://listen (the Vocal Shortcut). In that mode the silence timer auto-runs
    // the heard phrase once you stop speaking — so voice routes through the SAME
    // apple-intent → apple-do pipeline as typing, no separate sal-siri-match path.
    // FEATURE-CARD >> features/hey-sal-fold.feature
    var listenMode = false
    var silenceTimer: Timer?
    var listenGiveUpTimer: Timer?
    let silenceSeconds: TimeInterval = 1.6     // quiet gap AFTER speech = "I'm done talking"
    let listenGiveUpSeconds: TimeInterval = 9  // no speech at all by now → stop the mic (energy)

    // Spotlight-style live suggestions, ranked in-process by NLEmbedding over the
    // shared catalog (shared/intents.json). No subprocess per keystroke.
    struct CatItem { let action: String; let desc: String; let needsArg: Bool; let examples: [String]; let vecs: [[Double]] }
    struct Sugg { let action: String; let desc: String; let needsArg: Bool; let score: Double }
    let sEmb = NLEmbedding.sentenceEmbedding(for: .english)
    var catalog: [CatItem] = []
    var suggestions: [Sugg] = []
    var selected = 0
    var suggesting = false   // true while showing the suggestion list (vs a result)

    let panelWidth: CGFloat = 580
    let fieldRowHeight: CGFloat = 60

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu-bar agent, no Dock icon

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◧"
        statusItem.button?.toolTip = "AppleBar — ⌥Space"
        let menu = NSMenu()
        let openItem = NSMenuItem(title: "Open Command Bar  (⌥Space / ⌃Space)", action: #selector(showPanel), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit AppleBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        buildPanel()
        wireDictation()
        loadCatalog()
        registerHotKey()
        registerURLScheme()   // applebar://listen — the "Hey Sal" voice wake

        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self = self, self.panel.isVisible else { return e }
            // ⌘↩ → rephrase the result via the LLM (FM on the Mini)
            if e.keyCode == 36, e.modifierFlags.contains(.command) { self.runQuery(speak: true); return nil }
            // ↑/↓ → move through the live suggestions (Spotlight-style)
            if self.suggesting, !self.suggestions.isEmpty {
                if e.keyCode == 125 { self.selected = min(self.selected + 1, self.suggestions.count - 1); self.renderSuggestions(); return nil } // ↓
                if e.keyCode == 126 { self.selected = max(self.selected - 1, 0); self.renderSuggestions(); return nil }                          // ↑
            }
            return e
        }
    }

    // ── catalog: load shared/intents.json + embed every example once ──
    func loadCatalog() {
        guard let emb = sEmb,
              let data = FileManager.default.contents(atPath: INTENTS_JSON),
              let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let arr = obj["intents"] as? [[String: Any]] else { return }
        catalog = arr.compactMap { d in
            guard let a = d["action"] as? String, let ex = d["examples"] as? [String] else { return nil }
            let vecs = ex.compactMap { emb.vector(for: $0.lowercased()) }
            return CatItem(action: a, desc: (d["desc"] as? String) ?? a,
                           needsArg: (d["needsArg"] as? Bool) ?? false, examples: ex, vecs: vecs)
        }
    }

    func cosine(_ a: [Double], _ b: [Double]) -> Double {
        var d = 0.0, na = 0.0, nb = 0.0
        for i in 0..<min(a.count, b.count) { d += a[i]*b[i]; na += a[i]*a[i]; nb += b[i]*b[i] }
        return (na == 0 || nb == 0) ? 0 : d/(sqrt(na)*sqrt(nb))
    }

    // Hybrid score: a literal prefix/substring match (Spotlight-style, so typing the
    // start of a capability like "di" surfaces "directions"/"disk") blended with the
    // semantic embedding (so "how warm is it" → home even with no shared word). The
    // literal term dominates when present; embedding ranks the rest and breaks ties.
    func rank(_ text: String) {
        let t = text.lowercased()
        guard !t.isEmpty else { suggestions = []; return }
        let qv = sEmb?.vector(for: t)
        suggestions = catalog.map { item -> Sugg in
            let a = item.action.lowercased()
            var lit = 0.0
            if a == t { lit = 1.2 }
            else if a.hasPrefix(t) { lit = 1.0 }
            else if a.contains(t) { lit = 0.7 }
            else {
                for e in item.examples {
                    let el = e.lowercased()
                    if el.hasPrefix(t) { lit = max(lit, 0.6) }
                    else if el.contains(t) { lit = max(lit, 0.35) }
                }
            }
            let emb = (qv != nil) ? (item.vecs.map { cosine(qv!, $0) }.max() ?? 0) : 0
            return Sugg(action: item.action, desc: item.desc, needsArg: item.needsArg, score: emb + 2.0 * lit)
        }.sorted { $0.score > $1.score }
        if suggestions.count > 6 { suggestions = Array(suggestions.prefix(6)) }
        selected = 0
    }

    // ── the panel ──
    func buildPanel() {
        panel = CommandPanel(contentRect: NSRect(x: 0, y: 0, width: panelWidth, height: fieldRowHeight),
                             styleMask: [.borderless, .nonactivatingPanel],
                             backing: .buffered, defer: false)
        panel.level = .floating
        panel.isFloatingPanel = true
        panel.hidesOnDeactivate = true
        panel.isMovableByWindowBackground = true
        panel.backgroundColor = .clear
        panel.hasShadow = true

        let root = NSView(frame: NSRect(x: 0, y: 0, width: panelWidth, height: fieldRowHeight))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor(calibratedWhite: 0.13, alpha: 0.98).cgColor
        root.layer?.cornerRadius = 14
        panel.contentView = root

        field = NSTextField(frame: NSRect(x: 18, y: 12, width: panelWidth - 36 - 84, height: 36))
        let vcell = VCenteredCell(textCell: "")   // centre the text vertically (no more "slightly upper")
        vcell.isEditable = true; vcell.isSelectable = true; vcell.isScrollable = true
        vcell.wraps = false; vcell.usesSingleLineMode = true
        field.cell = vcell
        field.font = NSFont.systemFont(ofSize: 22, weight: .regular)
        field.textColor = .white
        field.backgroundColor = .clear
        field.isBezeled = false
        field.focusRingType = .none
        field.placeholderString = "Ask…   ↩ run · ? ask · ⌘↩ rephrase · dictate"
        field.delegate = self
        field.target = self
        field.action = #selector(submit)
        root.addSubview(field)

        spinner = NSProgressIndicator(frame: NSRect(x: panelWidth - 80, y: 18, width: 22, height: 22))
        spinner.style = .spinning
        spinner.isDisplayedWhenStopped = false
        spinner.controlSize = .small
        root.addSubview(spinner)

        // The legit macOS dictation glyph (SF Symbol mic), not a cartoon emoji.
        micButton = NSButton(frame: NSRect(x: panelWidth - 50, y: 13, width: 36, height: 34))
        micButton.image = micIcon(active: false)
        micButton.imagePosition = .imageOnly
        micButton.bezelStyle = .rounded
        micButton.isBordered = false
        micButton.toolTip = "Dictate (on-device speech recognition)"
        micButton.target = self
        micButton.action = #selector(toggleDictation)
        root.addSubview(micButton)

        // result area (hidden until there's a result)
        resultScroll = NSScrollView(frame: NSRect(x: 12, y: 10, width: panelWidth - 24, height: 0))
        resultScroll.hasVerticalScroller = true
        resultScroll.drawsBackground = false
        resultScroll.borderType = .noBorder
        resultView = NSTextView(frame: resultScroll.bounds)
        resultView.isEditable = false
        resultView.drawsBackground = false
        resultView.textColor = NSColor(calibratedWhite: 0.92, alpha: 1)
        resultView.font = NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        resultView.textContainerInset = NSSize(width: 6, height: 6)
        resultScroll.documentView = resultView
        resultScroll.isHidden = true
        root.addSubview(resultScroll)
    }

    @objc func showPanel() {
        collapseBody()              // open clean: just the field, no stale result/suggestions
        field.stringValue = ""
        let screen = NSScreen.main ?? NSScreen.screens.first
        if let vf = screen?.visibleFrame {
            let x = vf.midX - panel.frame.width / 2
            let y = vf.midY + vf.height * 0.18   // sit a little above center, Spotlight-style
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(field)
    }

    // Shrink to just the field row (hide the body), without moving the top edge.
    func collapseBody() {
        suggesting = false
        resultScroll.isHidden = true
        let topY = panel.frame.origin.y + panel.frame.height
        var f = panel.frame
        f.size.height = fieldRowHeight
        f.origin.y = topY - fieldRowHeight
        panel.setFrame(f, display: true, animate: false)
        field.frame = NSRect(x: 18, y: 12, width: panelWidth - 36 - 84, height: 36)
        spinner.frame = NSRect(x: panelWidth - 80, y: 18, width: 22, height: 22)
        micButton.frame = NSRect(x: panelWidth - 50, y: 13, width: 36, height: 34)
    }

    func togglePanel() {
        if panel.isVisible { panel.orderOut(nil) } else { showPanel() }
    }

    // ── run the engine ──
    //  ↩  → whitelabel template (instant)   ⌘↩ → LLM rephrase via FM on the Mini
    @objc func submit() { runQuery(speak: false) }

    func runQuery(speak: Bool) {
        if dictation.isRunning { dictation.stop() }   // ↩/⌘↩ stops the mic, then runs what was heard
        let q = field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !q.isEmpty else { return }
        // Run the HIGHLIGHTED suggestion (Spotlight-style). For "?" converse or when
        // there are no suggestions, pass nil → apple-intent routes/answers itself.
        let action: String? = (suggesting && !isConverse(q) && selected < suggestions.count)
            ? suggestions[selected].action : nil
        spinner.startAnimation(nil)
        showResult(speak ? "… (asking the model on the Mini)" : "…")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let output = self.runIntent(q, speak: speak, action: action)
            DispatchQueue.main.async {
                self.spinner.stopAnimation(nil)
                self.showResult(output.isEmpty ? "(no output)" : output)
            }
        }
    }

    func runIntent(_ q: String, speak: Bool, action: String? = nil) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: INTENT_BIN)
        var a = [q]
        if let action = action { a += ["--action", action] }
        if speak { a += ["--speak"] }
        p.arguments = a
        // Process() inherits a minimal PATH — apple-do shells out to date/ssh/mdfind
        // and the apple-* tools, so give it a real one.
        var env = ProcessInfo.processInfo.environment
        let extra = "/usr/bin:/bin:/usr/sbin:/sbin:/opt/homebrew/bin:/usr/local/bin"
        env["PATH"] = extra + ":" + (env["PATH"] ?? "")
        p.environment = env
        let pipe = Pipe()
        p.standardOutput = pipe
        p.standardError = pipe
        do { try p.run() } catch { return "couldn't run apple-intent:\n\(error.localizedDescription)" }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        p.waitUntilExit()
        return String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    // One body area shows EITHER the live suggestion list (while typing) or the
    // result (after running). setBody sizes the panel to the content and keeps the
    // field row pinned at the top.
    func setBody(_ attr: NSAttributedString, maxH: CGFloat = 340) {
        resultView.textStorage?.setAttributedString(attr)
        let w = panelWidth - 24 - 12
        let bound = attr.boundingRect(with: NSSize(width: w, height: .greatestFiniteMagnitude),
                                      options: [.usesLineFragmentOrigin, .usesFontLeading])
        let bodyH = max(28, min(maxH, ceil(bound.height) + 18))
        resultScroll.isHidden = false
        resultScroll.frame = NSRect(x: 12, y: 10, width: panelWidth - 24, height: bodyH)
        resultView.frame = NSRect(x: 0, y: 0, width: panelWidth - 24, height: bodyH)

        let total = fieldRowHeight + bodyH + 8
        let topY = panel.frame.origin.y + panel.frame.height
        var f = panel.frame
        f.size.height = total
        f.origin.y = topY - total
        panel.setFrame(f, display: true, animate: false)
        field.frame = NSRect(x: 18, y: total - 48, width: panelWidth - 36 - 84, height: 36)
        spinner.frame = NSRect(x: panelWidth - 80, y: total - 42, width: 22, height: 22)
        micButton.frame = NSRect(x: panelWidth - 50, y: total - 47, width: 36, height: 34)
    }

    func showResult(_ text: String) {
        suggesting = false
        setBody(NSAttributedString(string: text, attributes: [
            .font: NSFont.monospacedSystemFont(ofSize: 13, weight: .regular),
            .foregroundColor: NSColor(calibratedWhite: 0.92, alpha: 1)]))
    }

    // Spotlight-style ranked list; the selected row is highlighted. ↑/↓ move it.
    func renderSuggestions() {
        suggesting = true
        let out = NSMutableAttributedString()
        let nameFont = NSFont.monospacedSystemFont(ofSize: 13, weight: .semibold)
        let descFont = NSFont.systemFont(ofSize: 12)
        for (i, s) in suggestions.enumerated() {
            let sel = (i == selected)
            let row = NSMutableAttributedString(string: "\(sel ? "▸ " : "  ")\(s.action)", attributes: [
                .font: nameFont, .foregroundColor: sel ? NSColor.white : NSColor(calibratedWhite: 0.85, alpha: 1)])
            row.append(NSAttributedString(string: "   \(s.desc)\n", attributes: [
                .font: descFont, .foregroundColor: NSColor(calibratedWhite: 0.6, alpha: 1)]))
            if sel {
                row.addAttribute(.backgroundColor,
                                 value: NSColor(calibratedRed: 0.04, green: 0.30, blue: 0.55, alpha: 1),
                                 range: NSRange(location: 0, length: row.length))
            }
            out.append(row)
        }
        if suggestions.isEmpty {
            out.append(NSAttributedString(string: "no matching capability", attributes: [
                .font: descFont, .foregroundColor: NSColor.systemGray]))
        }
        setBody(out)
    }

    // A query that goes to the LLM rather than an action: "?" / "chat …" / "converse …"
    func isConverse(_ q: String) -> Bool {
        let l = q.lowercased()
        return q.hasPrefix("?") || l == "chat" || l == "converse"
            || l.hasPrefix("chat ") || l.hasPrefix("converse ")
    }

    // Live suggestions as you type. Converse queries get no suggestions.
    func controlTextDidChange(_ obj: Notification) {
        if dictation.isRunning { return }
        let q = field.stringValue.trimmingCharacters(in: .whitespaces)
        if q.isEmpty || isConverse(q) { resultScroll.isHidden = true; suggesting = false; return }
        rank(q)
        renderSuggestions()
    }

    // ── dictation: wire the shared OnDeviceDictation engine to the UI ──
    // The engine (shared/Dictation.swift) owns the mic + recognizer; AppleBar only
    // decides what its three callbacks do. No SFSpeechRecognizer code lives here.
    // FEATURE-CARD >> features/dictation-button.feature
    func wireDictation() {
        dictation.onText = { [weak self] text, _ in
            guard let self = self else { return }
            self.field.stringValue = text
            if self.listenMode { self.bumpSilenceTimer() }   // each word resets the "done?" clock
        }
        dictation.onStateChange = { [weak self] running in
            guard let self = self else { return }
            self.micButton.image = self.micIcon(active: running)
            self.micButton.contentTintColor = running ? .systemRed : nil
            if running {
                self.field.stringValue = ""
                if !self.listenMode { self.field.placeholderString = "Listening…  (tap mic or ↩ to stop)" }
            } else {
                self.clearSilenceTimer()
                self.listenMode = false   // a stop (manual or auto) leaves hands-free mode
                self.field.placeholderString = "Ask…   ↩ run · ? ask · ⌘↩ rephrase · dictate"
                self.panel.makeFirstResponder(self.field)
            }
        }
        dictation.onError = { [weak self] msg in self?.showResult(msg) }
    }

    @objc func toggleDictation() { dictation.toggle() }

    // The real macOS dictation glyph (SF Symbol mic.fill), template-tinted so it goes
    // red while listening — the same affordance as the system dictation button.
    func micIcon(active: Bool) -> NSImage? {
        let cfg = NSImage.SymbolConfiguration(pointSize: 17, weight: .regular)
        let img = NSImage(systemSymbolName: "mic.fill", accessibilityDescription: "Dictate")?
            .withSymbolConfiguration(cfg)
        img?.isTemplate = true
        return img
    }

    // ── the "Hey Sal" fold: applebar://listen wakes the bar in hands-free voice mode ──
    // The Vocal Shortcut fires `open applebar://listen`; this handler brings the panel
    // up and starts dictation. Speaking fills the field; silenceTimer auto-runs it.
    // applebar://open just shows the bar (keyboard mode), for symmetry.
    func registerURLScheme() {
        NSAppleEventManager.shared().setEventHandler(
            self, andSelector: #selector(handleGetURL(_:withReply:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL))
    }

    @objc func handleGetURL(_ event: NSAppleEventDescriptor, withReply reply: NSAppleEventDescriptor) {
        let s = event.paramDescriptor(forKeyword: AEKeyword(keyDirectObject))?.stringValue ?? ""
        let host = URL(string: s)?.host ?? ""
        NSLog("AppleBar: handleGetURL '\(s)' host='\(host)'")
        if host == "listen" { showPanelAndListen() } else { showPanel() }
    }

    func showPanelAndListen() {
        showPanel()
        listenMode = true
        field.placeholderString = "Listening (Hey Sal)…  speak, then pause — or ↩"
        dictation.authorizeThenStart()   // shared engine; same one the 🎙 button uses
        // Safety: if no speech arrives at all, don't leave the mic open forever.
        listenGiveUpTimer?.invalidate()
        listenGiveUpTimer = Timer.scheduledTimer(withTimeInterval: listenGiveUpSeconds, repeats: false) { [weak self] _ in
            guard let self = self, self.listenMode, self.dictation.isRunning,
                  self.field.stringValue.trimmingCharacters(in: .whitespaces).isEmpty else { return }
            self.dictation.stop()   // heard nothing → release the mic
        }
    }

    // Reset on every partial result; fire after a quiet gap = "you stopped talking".
    func bumpSilenceTimer() {
        silenceTimer?.invalidate()
        silenceTimer = Timer.scheduledTimer(withTimeInterval: silenceSeconds, repeats: false) { [weak self] _ in
            guard let self = self, self.listenMode, self.dictation.isRunning else { return }
            let heard = self.field.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !heard.isEmpty else { return }   // never auto-run on silence-only
            self.runQuery(speak: false)            // routes via apple-intent → apple-do
        }
    }

    func clearSilenceTimer() {
        silenceTimer?.invalidate(); silenceTimer = nil
        listenGiveUpTimer?.invalidate(); listenGiveUpTimer = nil
    }

    // ESC closes; Enter submits (handled by field.action).
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.cancelOperation(_:)) {
            if dictation.isRunning { dictation.stop() }   // abort a hands-free listen too
            panel.orderOut(nil)
            return true
        }
        return false
    }

    // ── global hotkeys: ⌥Space AND ⌃Space (either opens the bar) ──
    // Two bindings because ⌥Space is often taken by another launcher; if one fails
    // to register the other still works (plus the menu-bar item is always a fallback).
    func registerHotKey() {
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard),
                                      eventKind: UInt32(kEventHotKeyPressed))
        let selfPtr = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(GetApplicationEventTarget(), { _, eventRef, userData -> OSStatus in
            guard let userData = userData, let eventRef = eventRef else { return noErr }
            var hkID = EventHotKeyID()
            GetEventParameter(eventRef, EventParamName(kEventParamDirectObject),
                              EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &hkID)
            let me = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            if hkID.id == 1 || hkID.id == 2 { DispatchQueue.main.async { me.togglePanel() } }
            return noErr
        }, 1, &eventType, selfPtr, nil)

        let target = GetApplicationEventTarget()
        // id 1 — ⌥Space
        let optStatus = RegisterEventHotKey(UInt32(kVK_Space), UInt32(optionKey),
                                            EventHotKeyID(signature: OSType(0x4150424B), id: 1),
                                            target, 0, &hotKeyRef)
        if optStatus != noErr { NSLog("AppleBar: ⌥Space registration failed, OSStatus \(optStatus)") }
        // id 2 — ⌃Space  (note: macOS may bind ⌃Space to input-source switching;
        // disable that in System Settings ▸ Keyboard ▸ Shortcuts if it doesn't fire)
        let ctlStatus = RegisterEventHotKey(UInt32(kVK_Space), UInt32(controlKey),
                                            EventHotKeyID(signature: OSType(0x4150424B), id: 2),
                                            target, 0, &hotKeyRefCtrl)
        if ctlStatus != noErr { NSLog("AppleBar: ⌃Space registration failed, OSStatus \(ctlStatus)") }
    }
}

// @main entry point — required now that AppleBar.swift compiles alongside
// shared/Dictation.swift (top-level statements aren't allowed across multiple files).
@main
enum AppleBarMain {
    static let delegate = AppDelegate()   // strong-held so NSApplication's weak ref survives
    static func main() {
        let app = NSApplication.shared
        app.delegate = delegate
        app.run()
    }
}
