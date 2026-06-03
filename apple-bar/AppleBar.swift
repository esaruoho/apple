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

// Path to the engine. Override with APPLE_INTENT if the repo lives elsewhere.
let INTENT_BIN = ProcessInfo.processInfo.environment["APPLE_INTENT"]
    ?? "/Users/esaruoho/work/apple/bin/apple-intent"

/// A borderless panel that will accept key focus so the text field is typable.
final class CommandPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
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
        registerHotKey()

        // ⌘↩ while the bar is open → rephrase the result via the LLM (FM on the Mini).
        // Plain ↩ stays the instant template path (field.action → submit).
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] e in
            guard let self = self, self.panel.isVisible else { return e }
            if e.keyCode == 36, e.modifierFlags.contains(.command) {   // 36 = Return
                self.runQuery(speak: true); return nil
            }
            return e
        }
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
        field.font = NSFont.systemFont(ofSize: 22, weight: .regular)
        field.textColor = .white
        field.backgroundColor = .clear
        field.isBezeled = false
        field.focusRingType = .none
        field.placeholderString = "Ask…   ↩ run · ? ask · ⌘↩ rephrase · 🎙 dictate"
        field.delegate = self
        field.target = self
        field.action = #selector(submit)
        root.addSubview(field)

        spinner = NSProgressIndicator(frame: NSRect(x: panelWidth - 80, y: 18, width: 22, height: 22))
        spinner.style = .spinning
        spinner.isDisplayedWhenStopped = false
        spinner.controlSize = .small
        root.addSubview(spinner)

        micButton = NSButton(frame: NSRect(x: panelWidth - 50, y: 13, width: 36, height: 34))
        micButton.title = "🎙"
        micButton.bezelStyle = .rounded
        micButton.isBordered = false
        micButton.font = NSFont.systemFont(ofSize: 18)
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
        // center on the screen with the mouse / key window
        let screen = NSScreen.main ?? NSScreen.screens.first
        if let vf = screen?.visibleFrame {
            let x = vf.midX - panel.frame.width / 2
            let y = vf.midY + vf.height * 0.18   // sit a little above center, Spotlight-style
            panel.setFrameOrigin(NSPoint(x: x, y: y))
        }
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
        panel.makeFirstResponder(field)
        field.currentEditor()?.selectAll(nil)
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
        spinner.startAnimation(nil)
        showResult(speak ? "… (asking the model on the Mini)" : "…")
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let output = self.runIntent(q, speak: speak)
            DispatchQueue.main.async {
                self.spinner.stopAnimation(nil)
                self.showResult(output.isEmpty ? "(no output)" : output)
            }
        }
    }

    func runIntent(_ q: String, speak: Bool) -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: INTENT_BIN)
        p.arguments = speak ? [q, "--speak"] : [q]
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

    func showResult(_ text: String) {
        resultView.string = text
        // size the result area to the content (capped), then grow the panel + recenter.
        let maxResultH: CGFloat = 320
        let textH = max(28, min(maxResultH, ceil(idealHeight(of: text)) + 18))
        resultScroll.isHidden = false
        resultScroll.frame = NSRect(x: 12, y: 10, width: panelWidth - 24, height: textH)
        resultView.frame = NSRect(x: 0, y: 0, width: panelWidth - 24, height: textH)

        let total = fieldRowHeight + textH + 8
        if let origin = panel.frame.origin as NSPoint? {
            // keep the field row pinned at the top by lowering origin.y as it grows
            let topY = origin.y + panel.frame.height
            var f = panel.frame
            f.size.height = total
            f.origin.y = topY - total
            panel.setFrame(f, display: true, animate: false)
            // move field + spinner + mic to the new top
            field.frame = NSRect(x: 18, y: total - 48, width: panelWidth - 36 - 84, height: 36)
            spinner.frame = NSRect(x: panelWidth - 80, y: total - 42, width: 22, height: 22)
            micButton.frame = NSRect(x: panelWidth - 50, y: total - 47, width: 36, height: 34)
        }
    }

    // ── dictation: wire the shared OnDeviceDictation engine to the UI ──
    // The engine (shared/Dictation.swift) owns the mic + recognizer; AppleBar only
    // decides what its three callbacks do. No SFSpeechRecognizer code lives here.
    // FEATURE-CARD >> features/dictation-button.feature
    func wireDictation() {
        dictation.onText = { [weak self] text, _ in self?.field.stringValue = text }
        dictation.onStateChange = { [weak self] running in
            guard let self = self else { return }
            self.micButton.title = running ? "⏹" : "🎙"
            self.micButton.contentTintColor = running ? .systemRed : nil
            if running {
                self.field.stringValue = ""
                self.field.placeholderString = "Listening…  (🎙/⏹ or ↩ to stop)"
            } else {
                self.field.placeholderString = "Ask…   ↩ run · ? ask · ⌘↩ rephrase · 🎙 dictate"
                self.panel.makeFirstResponder(self.field)
            }
        }
        dictation.onError = { [weak self] msg in self?.showResult(msg) }
    }

    @objc func toggleDictation() { dictation.toggle() }

    func idealHeight(of text: String) -> CGFloat {
        let font = resultView.font ?? NSFont.monospacedSystemFont(ofSize: 13, weight: .regular)
        let width = panelWidth - 24 - 12
        let attr = NSAttributedString(string: text, attributes: [.font: font])
        let r = attr.boundingRect(with: NSSize(width: width, height: .greatestFiniteMagnitude),
                                  options: [.usesLineFragmentOrigin, .usesFontLeading])
        return r.height
    }

    // ESC closes; Enter submits (handled by field.action).
    func control(_ control: NSControl, textView: NSTextView, doCommandBy selector: Selector) -> Bool {
        if selector == #selector(NSResponder.cancelOperation(_:)) {
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
