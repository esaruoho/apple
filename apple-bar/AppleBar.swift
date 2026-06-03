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
    var hotKeyRef: EventHotKeyRef?

    let panelWidth: CGFloat = 580
    let fieldRowHeight: CGFloat = 60

    func applicationDidFinishLaunching(_ note: Notification) {
        NSApp.setActivationPolicy(.accessory)   // menu-bar agent, no Dock icon

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "◧"
        statusItem.button?.toolTip = "AppleBar — ⌥Space"
        let menu = NSMenu()
        let openItem = NSMenuItem(title: "Open Command Bar  (⌥Space)", action: #selector(showPanel), keyEquivalent: "")
        openItem.target = self
        menu.addItem(openItem)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(title: "Quit AppleBar", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu

        buildPanel()
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

        field = NSTextField(frame: NSRect(x: 18, y: 12, width: panelWidth - 36, height: 36))
        field.font = NSFont.systemFont(ofSize: 22, weight: .regular)
        field.textColor = .white
        field.backgroundColor = .clear
        field.isBezeled = false
        field.focusRingType = .none
        field.placeholderString = "Ask the toolbox…   ↩ run · ⌘↩ rephrase"
        field.delegate = self
        field.target = self
        field.action = #selector(submit)
        root.addSubview(field)

        spinner = NSProgressIndicator(frame: NSRect(x: panelWidth - 44, y: 18, width: 22, height: 22))
        spinner.style = .spinning
        spinner.isDisplayedWhenStopped = false
        spinner.controlSize = .small
        root.addSubview(spinner)

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
            // move field + spinner to the new top
            field.frame = NSRect(x: 18, y: total - 48, width: panelWidth - 36, height: 36)
            spinner.frame = NSRect(x: panelWidth - 44, y: total - 42, width: 22, height: 22)
        }
    }

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

    // ── global hotkey: ⌥Space ──
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
            if hkID.id == 1 { DispatchQueue.main.async { me.togglePanel() } }
            return noErr
        }, 1, &eventType, selfPtr, nil)

        let mods = UInt32(optionKey)           // ⌥
        let id = EventHotKeyID(signature: OSType(0x4150424B), id: 1)   // 'APBK'
        let status = RegisterEventHotKey(UInt32(kVK_Space), mods, id,
                                         GetApplicationEventTarget(), 0, &hotKeyRef)
        if status != noErr { NSLog("AppleBar: ⌥Space registration failed, OSStatus \(status)") }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
