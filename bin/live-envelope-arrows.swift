// live-envelope-arrows — hover-gated arrow keys for Ableton Live's Clip Envelopes box.
//
//   Hover the Envelopes chooser (or the Link button), then:
//     <-  ->    cycle the clip envelope (warp-aware: what the mode actually offers)
//     ^   v     walk the transposition ladder: -48 -36 -24 -12 0 +12 +24 +36 +48
//
// Anywhere else, arrow keys are returned to the system untouched — Live's normal
// arrow behaviour is bit-for-bit unaffected. This is the whole point of using a
// CGEventTap rather than a hotkey manager: pass-through is native, so there is no
// swallow-and-retype trick and no risk of a synthetic keystroke re-triggering us.
//
// build:  swiftc -O -o live-envelope-arrows live-envelope-arrows.swift
// run:    ./live-envelope-arrows            (foreground; Ctrl-C to stop)
//         ./live-envelope-arrows --verbose  (log every decision)
//
// Requires Accessibility trust (System Settings > Privacy & Security > Accessibility)
// for BOTH the event tap and the AX reads. When run from a terminal the terminal's
// grant is what counts; as a LaunchAgent the binary needs its own grant.
//
// Division of labour, deliberately: this process decides WHEN to act (hover gate)
// and computes the transposition ladder, but every actual change is delegated to
// `live-envelope`, which owns the fiddly warp-mode/menu logic. One source of truth.

import Cocoa
import ApplicationServices

let BUNDLE_ID = "com.ableton.live"
let SIBLING = "/Users/esaruoho/work/apple/bin/live-envelope"

//--------------------------------------------------------------------------------
// Hovering any of these hands the arrow keys to us. Everything else in Live keeps
// its normal arrow behaviour, so this stays a deliberate, local gesture.
//--------------------------------------------------------------------------------
let HOVER_TARGETS: Set<String> = [
    "Control Chooser",
    "Device Chooser",
    "Automated Control Chooser",
    "Link/Unlink Envelope",
    "Transposition/Semitones",
]

/// The stops the up/down keys walk between. Clamped at both ends, no wrap-around.
let LADDER: [Int] = [-48, -36, -24, -12, 0, 12, 24, 36, 48]

let KEY_LEFT: Int64 = 123, KEY_RIGHT: Int64 = 124, KEY_DOWN: Int64 = 125, KEY_UP: Int64 = 126

//--------------------------------------------------------------------------------
// Holding an arrow down autorepeats far faster than a round trip to Live, and each
// ladder step has to read the value the previous step wrote. Throttling keeps the
// read from racing the write, and keeps a held key from flooding `live-envelope`
// (whose own flock would silently drop the excess anyway).
//--------------------------------------------------------------------------------
let THROTTLE: TimeInterval = 0.2
var lastAction: TimeInterval = 0

let verbose = CommandLine.arguments.contains("--verbose")

func log(_ message: String) {
    guard verbose else { return }
    FileHandle.standardError.write("live-envelope-arrows: \(message)\n".data(using: .utf8)!)
}

//--------------------------------------------------------------------------------
// Accessibility helpers
//--------------------------------------------------------------------------------

func attribute(_ element: AXUIElement, _ name: String) -> Any? {
    var value: AnyObject?
    guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
    return value
}

func string(_ element: AXUIElement, _ name: String) -> String {
    attribute(element, name) as? String ?? ""
}

func children(_ element: AXUIElement) -> [AXUIElement] {
    attribute(element, kAXChildrenAttribute as String) as? [AXUIElement] ?? []
}

func frame(_ element: AXUIElement) -> CGRect? {
    guard let position = attribute(element, kAXPositionAttribute as String),
          let size = attribute(element, kAXSizeAttribute as String),
          CFGetTypeID(position as CFTypeRef) == AXValueGetTypeID(),
          CFGetTypeID(size as CFTypeRef) == AXValueGetTypeID() else { return nil }
    var origin = CGPoint.zero, extent = CGSize.zero
    AXValueGetValue(position as! AXValue, .cgPoint, &origin)
    AXValueGetValue(size as! AXValue, .cgSize, &extent)
    return CGRect(origin: origin, size: extent)
}

/// The AX application element for Live, rebuilt whenever Live restarts.
var liveApplication: (pid: pid_t, element: AXUIElement)?

//--------------------------------------------------------------------------------
// Live 11 and Live 12 share the bundle id "com.ableton.live", so on a machine with
// both installed `runningApplications(withBundleIdentifier:).first` picks an arbitrary
// instance — and would happily drive the one you are not looking at. Since we only
// ever act while Live is frontmost, the frontmost process IS the unambiguous answer:
// the caller passes its pid in.
//--------------------------------------------------------------------------------
func liveElement(pid: pid_t) -> AXUIElement? {
    if let cached = liveApplication, cached.pid == pid {
        return cached.element
    }
    let element = AXUIElementCreateApplication(pid)
    //--------------------------------------------------------------------------------
    // Never let a busy or mid-render Live stall the event tap: macOS disables a tap
    // whose callback takes too long, which would silently kill every arrow key.
    //--------------------------------------------------------------------------------
    AXUIElementSetMessagingTimeout(element, 0.5)
    liveApplication = (pid: pid, element: element)
    log("attached to Live pid \(pid)")
    return element
}

//--------------------------------------------------------------------------------
// The hover gate. A single AXUIElementCopyElementAtPosition hit-test — no tree walk,
// so this is cheap enough to run inside the event tap on every arrow press.
//
// NSEvent reports a bottom-left origin; accessibility wants top-left, so y is
// flipped against the main screen.
//--------------------------------------------------------------------------------
func hoveredTarget(in application: AXUIElement) -> String? {
    guard let screen = NSScreen.screens.first else { return nil }
    let mouse = NSEvent.mouseLocation
    let point = CGPoint(x: mouse.x, y: screen.frame.maxY - mouse.y)

    var hit: AXUIElement?
    guard AXUIElementCopyElementAtPosition(application, Float(point.x), Float(point.y), &hit) == .success,
          let element = hit else { return nil }

    let description = string(element, kAXDescriptionAttribute as String)
    if HOVER_TARGETS.contains(description) { return description }

    //--------------------------------------------------------------------------------
    // Live nests the chooser's label and arrow glyph inside the popup, so a hit can
    // land on an unnamed child. Walk up a couple of levels before giving up.
    //--------------------------------------------------------------------------------
    var current = element
    for _ in 0..<3 {
        guard let parent = attribute(current, kAXParentAttribute as String) else { break }
        let parentElement = parent as! AXUIElement
        let parentDescription = string(parentElement, kAXDescriptionAttribute as String)
        if HOVER_TARGETS.contains(parentDescription) { return parentDescription }
        current = parentElement
    }
    return nil
}

//--------------------------------------------------------------------------------
// Reading the clip's transposition. AXValue on this slider is a number in
// semitones with min -48 / max 48 — but it is NOT writable, so the ladder reads
// here and writes through `live-envelope transpose-set-<n>` (which goes via
// AbletonOSC's set_clip_transposition).
//--------------------------------------------------------------------------------
let SEARCH_MAX_DEPTH = 7
let SEARCH_MAX_NODES = 4000

func locate(role wantedRole: String, description wanted: String, in application: AXUIElement) -> AXUIElement? {
    let windows = attribute(application, kAXWindowsAttribute as String) as? [AXUIElement] ?? []
    for window in windows {
        //--------------------------------------------------------------------------------
        // Same pruning trick `live-envelope` uses: the clip panel sits in a band above
        // the status bar, so any subtree ending above it (session grid, mixer, browser)
        // is skipped wholesale. Without this a large Set takes minutes.
        //--------------------------------------------------------------------------------
        let band = frame(window).map { $0.maxY - 220 }
        var queue = [(element: window, depth: 0)]
        var visited = 0
        while !queue.isEmpty && visited < SEARCH_MAX_NODES {
            let (element, depth) = queue.removeFirst()
            visited += 1
            if string(element, kAXRoleAttribute as String) == wantedRole
                && string(element, kAXDescriptionAttribute as String) == wanted {
                return element
            }
            guard depth < SEARCH_MAX_DEPTH else { continue }
            for child in children(element) {
                if let cutoff = band, depth >= 1, let box = frame(child), box.maxY < cutoff { continue }
                queue.append((element: child, depth: depth + 1))
            }
        }
    }
    return nil
}

func currentTransposition(in application: AXUIElement) -> Int? {
    guard let slider = locate(role: "AXSlider", description: "Transposition/Semitones", in: application) else {
        return nil
    }
    if let number = attribute(slider, kAXValueAttribute as String) as? NSNumber {
        return Int(number.doubleValue.rounded())
    }
    //--------------------------------------------------------------------------------
    // Fall back to the display string, which reads e.g. "0" or "-12".
    //--------------------------------------------------------------------------------
    return Int(string(slider, "AXValueDescription").trimmingCharacters(in: .whitespaces))
}

/// The next ladder stop strictly above (or below) `value`, clamped at the ends.
func ladderStep(from value: Int, up: Bool) -> Int? {
    if up {
        guard let next = LADDER.first(where: { $0 > value }) else { return nil }
        return next
    }
    guard let previous = LADDER.last(where: { $0 < value }) else { return nil }
    return previous
}

//--------------------------------------------------------------------------------
// Every change is delegated to `live-envelope`, spawned detached: the event tap must
// return promptly, and that binary's own flock serialises overlapping invocations.
//--------------------------------------------------------------------------------
func run(_ argument: String) {
    let process = Process()
    process.executableURL = URL(fileURLWithPath: SIBLING)
    process.arguments = [argument]
    process.standardOutput = FileHandle.nullDevice
    process.standardError = FileHandle.nullDevice
    do { try process.run() } catch { log("could not run \(SIBLING): \(error)") }
}

func handleArrow(keyCode: Int64, application: AXUIElement) {
    switch keyCode {
    case KEY_LEFT:
        log("prev")
        run("prev")
    case KEY_RIGHT:
        log("next")
        run("next")
    case KEY_UP, KEY_DOWN:
        let up = keyCode == KEY_UP
        guard let current = currentTransposition(in: application) else {
            log("could not read Transposition/Semitones — is an audio clip in Clip View?")
            return
        }
        guard let target = ladderStep(from: current, up: up) else {
            log("already at the \(up ? "top" : "bottom") of the ladder (\(current))")
            return
        }
        //--------------------------------------------------------------------------------
        // `live-envelope` lowercases and joins its arguments, and a literal "-" cannot
        // sit inside a single unquoted command word, so negatives use its "neg" spelling.
        //--------------------------------------------------------------------------------
        let suffix = target < 0 ? "neg\(-target)" : "\(target)"
        log("transposition \(current) -> \(target)")
        run("transpose-set-\(suffix)")
    default:
        break
    }
}

//--------------------------------------------------------------------------------
// The event tap
//--------------------------------------------------------------------------------

let callback: CGEventTapCallBack = { _, type, event, _ in
    //--------------------------------------------------------------------------------
    // macOS disables a tap that is too slow or that errors; re-arm instead of dying,
    // otherwise every arrow key in the system would keep being routed to a dead tap.
    //--------------------------------------------------------------------------------
    if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
        log("tap disabled by system — re-enabling")
        if let tap = eventTap { CGEvent.tapEnable(tap: tap, enable: true) }
        return Unmanaged.passUnretained(event)
    }
    guard type == .keyDown else { return Unmanaged.passUnretained(event) }

    let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
    guard [KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN].contains(keyCode) else {
        return Unmanaged.passUnretained(event)
    }

    //--------------------------------------------------------------------------------
    // Bare arrows only. Any modifier is left alone so existing shortcuts still work —
    // notably the Keyboard Maestro macros on Opt-Cmd-Up / Opt-Cmd-Down.
    //--------------------------------------------------------------------------------
    let modifiers: CGEventFlags = [.maskCommand, .maskAlternate, .maskControl, .maskShift]
    if !event.flags.intersection(modifiers).isEmpty {
        return Unmanaged.passUnretained(event)
    }

    //--------------------------------------------------------------------------------
    // Only ever consider intercepting while Live is the frontmost app, so no other
    // application's arrow keys are even hit-tested.
    //--------------------------------------------------------------------------------
    guard let front = NSWorkspace.shared.frontmostApplication,
          front.bundleIdentifier == BUNDLE_ID,
          let application = liveElement(pid: front.processIdentifier) else {
        return Unmanaged.passUnretained(event)
    }

    guard let target = hoveredTarget(in: application) else {
        return Unmanaged.passUnretained(event)   // not hovering: Live gets its arrow
    }

    let now = Date().timeIntervalSince1970
    if now - lastAction < THROTTLE {
        //--------------------------------------------------------------------------------
        // Still swallow the key while throttled: passing it through mid-gesture would
        // move Live's selection under the pointer, which is never what was meant.
        //--------------------------------------------------------------------------------
        return nil
    }
    lastAction = now

    log("hovering \"\(target)\" — taking keyCode \(keyCode)")
    handleArrow(keyCode: keyCode, application: application)
    return nil                                   // swallowed
}

var eventTap: CFMachPort?

guard AXIsProcessTrusted() else {
    FileHandle.standardError.write("""
        live-envelope-arrows: not trusted for Accessibility.
        Grant the app running this command access in
        System Settings > Privacy & Security > Accessibility, then run it again.\n
        """.data(using: .utf8)!)
    exit(1)
}

let mask = (1 << CGEventType.keyDown.rawValue)
guard let tap = CGEvent.tapCreate(tap: .cgSessionEventTap,
                                 place: .headInsertEventTap,
                                 options: .defaultTap,
                                 eventsOfInterest: CGEventMask(mask),
                                 callback: callback,
                                 userInfo: nil) else {
    FileHandle.standardError.write("""
        live-envelope-arrows: could not create the event tap.
        This needs Accessibility (and on some systems Input Monitoring) permission
        for whichever app is running it.\n
        """.data(using: .utf8)!)
    exit(1)
}
eventTap = tap

let source = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, tap, 0)
CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .commonModes)
CGEvent.tapEnable(tap: tap, enable: true)

FileHandle.standardError.write("""
    live-envelope-arrows: watching bare arrow keys while Ableton Live is frontmost.
      hover the envelope chooser, then <- -> to cycle, ^ v for the transposition ladder
      everything else passes straight through. Ctrl-C to stop.\n
    """.data(using: .utf8)!)

CFRunLoopRun()
