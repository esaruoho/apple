// live-envelope — drive Ableton Live's Clip View Envelopes choosers.
//
//   live-envelope gain | transposition | "sample offset"   select that clip envelope
//   live-envelope smart                                    warp-mode aware: Sample Offset / Transposition
//   live-envelope next | prev                              cycle Gain <-> the warp-appropriate one
//   live-envelope link | unlink | toggle-link              Link/Unlink the envelope
//   live-envelope open                                     pop the chooser menu open
//   live-envelope open-at-mouse                            ... and move it under the pointer
//   live-envelope status                                   print the current state
//   live-envelope list                                     list every chooser entry
//
// Live publishes the Envelopes box through the accessibility API as two
// AXPopUpButtons ("Device Chooser", "Control Chooser") and an AXButton
// ("Link/Unlink Envelope"). This only changes what is *displayed*: no clip
// property is written, and Live does not need to be the frontmost application.
//
// Two quirks of Live's implementation drive the shape of this code:
//   - AXValue on the popups is read-only, so a selection has to go through the menu.
//   - Pressing a popup opens the menu as a separate top-level AXWindow (subrole
//     AXUnknown) rather than as a child of the popup, and the currently selected
//     item's title is prefixed with a check mark.
//
// The Sample/Envelopes tab itself is not exposed, so if the Envelopes box is
// hidden this first asks AbletonOSC to show it (one fire-and-forget UDP packet;
// harmless if AbletonOSC isn't running).
//
// build: swiftc -O -o live-envelope live-envelope.swift

import Cocoa
import ApplicationServices

let BUNDLE_ID = "com.ableton.live"

//--------------------------------------------------------------------------------
// Sample Offset only exists in Beats Warp Mode; in every other mode the equivalent
// pitch-shaping envelope is Transposition. So the second step of the cycle follows
// the clip's warp mode instead of being fixed, and "smart" selects it directly.
//--------------------------------------------------------------------------------
let BEATS_PARTNER = "Sample Offset"
let OTHER_PARTNER = "Transposition"
let CHECK_MARK = "\u{2714}"
let OSC_HOST = "127.0.0.1"
let OSC_PORT: UInt16 = 11000

func fail(_ message: String) -> Never {
    FileHandle.standardError.write("live-envelope: \(message)\n".data(using: .utf8)!)
    exit(1)
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

func role(_ element: AXUIElement) -> String {
    string(element, kAXRoleAttribute as String)
}

//--------------------------------------------------------------------------------
// The Envelopes box controls sit at depth 4 of the window. Everything expensive in
// Live's accessibility tree (warp markers, mixer strips, device chains) lives deeper
// or wider, and on a large Set a full walk takes minutes — so the search is bounded
// on both depth and node count. Without this, a Set with many tracks makes every
// invocation hang long enough to pile up if the trigger is pressed repeatedly.
//--------------------------------------------------------------------------------
let SEARCH_MAX_DEPTH = 6
let SEARCH_MAX_NODES = 4000

func findControl(in root: AXUIElement, role wanted: String, description: String) -> AXUIElement? {
    //--------------------------------------------------------------------------------
    // The Envelopes box always sits in a band just above the status bar. Skipping any
    // subtree that ends above that band discards the session grid and mixer wholesale,
    // which is what makes this fast on a Set with many tracks.
    //--------------------------------------------------------------------------------
    let band = frame(root).map { $0.maxY - 220 }

    var queue = [(element: root, depth: 0)]
    var visited = 0
    while !queue.isEmpty && visited < SEARCH_MAX_NODES {
        let (element, depth) = queue.removeFirst()
        visited += 1
        if role(element) == wanted && string(element, kAXDescriptionAttribute as String) == description {
            return element
        }
        guard depth < SEARCH_MAX_DEPTH else { continue }
        for child in children(element) {
            if let cutoff = band, depth >= 1, let box = frame(child), box.maxY < cutoff { continue }
            queue.append((element: child, depth: depth + 1))
        }
    }
    return nil
}

func collectMenuItems(_ element: AXUIElement, into found: inout [AXUIElement], depth: Int = 0) {
    if role(element) == "AXMenuItem" { found.append(element) }
    guard depth < 6 else { return }
    for child in children(element) { collectMenuItems(child, into: &found, depth: depth + 1) }
}

//--------------------------------------------------------------------------------
// Popup menus
//--------------------------------------------------------------------------------

struct MenuEntry {
    let title: String
    let checked: Bool
    let enabled: Bool
    let element: AXUIElement
}

func windows(of application: AXUIElement) -> [AXUIElement] {
    attribute(application, kAXWindowsAttribute as String) as? [AXUIElement] ?? []
}

/// A menu window is any top-level window that is not the standard document window.
func currentMenu(in application: AXUIElement) -> AXUIElement? {
    for window in windows(of: application) where string(window, kAXSubroleAttribute as String) != "AXStandardWindow" {
        var items: [AXUIElement] = []
        collectMenuItems(window, into: &items)
        if !items.isEmpty { return window }
    }
    return nil
}

func openMenu(_ popup: AXUIElement, in application: AXUIElement) -> AXUIElement? {
    //--------------------------------------------------------------------------------
    // Pressing the chooser toggles its menu, so a menu that is already on screen must
    // be reused rather than pressed again — pressing would close it.
    //--------------------------------------------------------------------------------
    if let alreadyOpen = currentMenu(in: application) { return alreadyOpen }

    for attempt in 0..<2 {
        guard AXUIElementPerformAction(popup, kAXPressAction as CFString) == .success else { return nil }
        //--------------------------------------------------------------------------------
        // Spin without sleeping at first. The menu can only be repositioned once it
        // exists, so every millisecond spent noticing it is a millisecond it is visible
        // at its original position before it jumps.
        //--------------------------------------------------------------------------------
        for poll in 0..<(attempt == 0 ? 60 : 100) {
            if let menu = currentMenu(in: application) { return menu }
            if poll > 20 { usleep(20_000) }
        }
    }
    return nil
}

func closeMenu(_ menu: AXUIElement) {
    AXUIElementPerformAction(menu, kAXCancelAction as CFString)
}

func entries(of menu: AXUIElement) -> [MenuEntry] {
    var items: [AXUIElement] = []
    collectMenuItems(menu, into: &items)
    return items.compactMap { item in
        var title = string(item, kAXTitleAttribute as String)
        guard !title.isEmpty else { return nil }
        let checked = title.hasPrefix(CHECK_MARK)
        if checked {
            title = String(title.dropFirst(CHECK_MARK.count)).trimmingCharacters(in: .whitespaces)
        }
        let enabled = (attribute(item, kAXEnabledAttribute as String) as? Bool) ?? true
        return MenuEntry(title: title, checked: checked, enabled: enabled, element: item)
    }
}

/// Selects `wanted` (case-insensitively) from a popup, returning the chosen title.
@discardableResult
func select(_ popup: AXUIElement, _ wanted: String, in application: AXUIElement, label: String) -> String {
    let current = string(popup, kAXValueAttribute as String)
    if current.lowercased() == wanted.lowercased() {
        return current
    }
    guard let menu = openMenu(popup, in: application) else { fail("could not open the \(label) menu") }
    let all = entries(of: menu)
    guard let match = all.first(where: { $0.title.lowercased() == wanted.lowercased() }) else {
        closeMenu(menu)
        fail("\(label) has no entry \"\(wanted)\". Available: "
             + all.map { $0.enabled ? $0.title : "\($0.title) (unavailable)" }.joined(separator: ", "))
    }
    guard match.enabled else {
        closeMenu(menu)
        fail("\"\(match.title)\" is greyed out for this clip"
             + (match.title == "Sample Offset" ? " — it requires Beats Warp Mode." : "."))
    }
    guard AXUIElementPerformAction(match.element, kAXPressAction as CFString) == .success else {
        closeMenu(menu)
        fail("could not select \"\(match.title)\"")
    }
    return match.title
}

//--------------------------------------------------------------------------------
// Ask AbletonOSC to reveal the Envelopes box; the choosers only exist once it is
// visible, and the Sample/Envelopes tab is not exposed to accessibility.
//--------------------------------------------------------------------------------

func oscPad(_ bytes: [UInt8]) -> [UInt8] {
    bytes + [UInt8](repeating: 0, count: (4 - bytes.count % 4) % 4)
}

func sendOSC(_ address: String, int32 value: Int32? = nil) {
    var packet = oscPad(Array(address.utf8) + [0])
    if let value = value {
        packet += oscPad(Array(",i".utf8) + [0])
        packet += withUnsafeBytes(of: value.bigEndian) { Array($0) }
    } else {
        packet += oscPad(Array(",".utf8) + [0])
    }

    let descriptor = socket(AF_INET, SOCK_DGRAM, 0)
    guard descriptor >= 0 else { return }
    defer { close(descriptor) }

    var target = sockaddr_in()
    target.sin_family = sa_family_t(AF_INET)
    target.sin_port = OSC_PORT.bigEndian
    target.sin_addr.s_addr = inet_addr(OSC_HOST)

    withUnsafePointer(to: &target) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            _ = sendto(descriptor, packet, packet.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
}

func showEnvelopeBox() {
    sendOSC("/live/view/show_clip_envelope")
}

func nudgeTransposition(by semitones: Int32) {
    sendOSC("/live/view/nudge_clip_transposition", int32: semitones)
}

//--------------------------------------------------------------------------------

let usage = """
usage: live-envelope <command>

  gain                                    toggle Gain <-> Transposition
  smart | sample offset | transposition   Beats: toggle the two; else Transposition
  transpose-up-12 | transpose-down-12      snap the clip's transposition by an octave
  exact <name>                            select <name> verbatim, no substitution
  next | prev                             cycle only what the warp mode offers
  link | unlink | toggle-link             Link/Unlink the displayed envelope
  open                                    pop the chooser menu open
  open-at-mouse                           ... and move it under the pointer
  status                                  print the current chooser state
  list                                    list every entry the chooser offers
"""

let command = CommandLine.arguments.dropFirst().joined(separator: " ").lowercased()
if command.isEmpty || command == "-h" || command == "--help" {
    print(usage)
    exit(command.isEmpty ? 2 : 0)
}

//--------------------------------------------------------------------------------
// Bound to a mouse button or MIDI pad this can be fired far faster than it can run,
// so only one instance is allowed at a time. Without this, a Set that makes lookups
// slow turns a burst of presses into a pile of stuck processes.
//--------------------------------------------------------------------------------
let lock = open("/tmp/live-envelope.lock", O_CREAT | O_RDWR, 0o644)
if lock < 0 || flock(lock, LOCK_EX | LOCK_NB) != 0 {
    exit(0)
}

guard AXIsProcessTrusted() else {
    fail("not trusted for Accessibility. Grant the app running this command access in "
         + "System Settings > Privacy & Security > Accessibility.")
}
guard let live = NSRunningApplication.runningApplications(withBundleIdentifier: BUNDLE_ID).first else {
    fail("Ableton Live is not running (no process with bundle id \(BUNDLE_ID)).")
}

let application = AXUIElementCreateApplication(live.processIdentifier)

//--------------------------------------------------------------------------------
// Never block indefinitely on a Live that is busy or mid-render.
//--------------------------------------------------------------------------------
AXUIElementSetMessagingTimeout(application, 2.0)

func frame(_ element: AXUIElement) -> CGRect? {
    guard let positionValue = attribute(element, kAXPositionAttribute as String),
          let sizeValue = attribute(element, kAXSizeAttribute as String),
          CFGetTypeID(positionValue as CFTypeRef) == AXValueGetTypeID(),
          CFGetTypeID(sizeValue as CFTypeRef) == AXValueGetTypeID() else { return nil }
    var origin = CGPoint.zero, size = CGSize.zero
    AXValueGetValue(positionValue as! AXValue, .cgPoint, &origin)
    AXValueGetValue(sizeValue as! AXValue, .cgSize, &size)
    return CGRect(origin: origin, size: size)
}

/// Searches every window, since a stray open menu or the Settings window can occupy
/// the first slot.
func locate(role wantedRole: String, description: String) -> AXUIElement? {
    for window in windows(of: application) {
        if let found = findControl(in: window, role: wantedRole, description: description) { return found }
    }
    return nil
}

//--------------------------------------------------------------------------------
// Whether the Envelopes box was on screen BEFORE this command touched anything.
// This has to be captured first: the chooser keeps its last value even while the
// Sample tab hides it, so forcing the tab open and then reading "is it already
// Gain?" would see stale leftover state and toggle away from an envelope the user
// was never actually looking at.
//--------------------------------------------------------------------------------
let wasAlreadyVisible = locate(role: "AXPopUpButton", description: "Control Chooser") != nil

//--------------------------------------------------------------------------------
// "status" and "list" are read-only and must not change what is on screen, so they
// report on whatever is already showing (or fail below) rather than revealing the
// box the way every selection command does.
//--------------------------------------------------------------------------------
let readOnly = command == "status" || command == "list"

var controlChooser = locate(role: "AXPopUpButton", description: "Control Chooser")
if controlChooser == nil && !readOnly {
    //--------------------------------------------------------------------------------
    // The Envelopes box is hidden, or Clip View is not showing at all. Ask AbletonOSC
    // to open it, then retry a bounded number of times — each retry is a fresh tree
    // search, so this deliberately stays small.
    //--------------------------------------------------------------------------------
    showEnvelopeBox()
    for _ in 0..<8 {
        usleep(60_000)
        controlChooser = locate(role: "AXPopUpButton", description: "Control Chooser")
        if controlChooser != nil { break }
    }
}
if controlChooser == nil && !readOnly, let filtered = locate(role: "AXPopUpButton", description: "Automated Control Chooser") {
    //--------------------------------------------------------------------------------
    // "Only show adjusted envelopes" is on, which replaces the Device + Control
    // chooser pair with a single filtered list of already-automated controls. The
    // clip's own envelopes are not reachable in that mode, so switch it back off.
    //--------------------------------------------------------------------------------
    if let menu = openMenu(filtered, in: application),
       let toggle = entries(of: menu).first(where: { $0.title.lowercased().contains("only show adjusted") }) {
        if AXUIElementPerformAction(toggle.element, kAXPressAction as CFString) != .success {
            closeMenu(menu)
        }
        for _ in 0..<10 {
            usleep(60_000)
            controlChooser = locate(role: "AXPopUpButton", description: "Control Chooser")
            if controlChooser != nil { break }
        }
    }
    if controlChooser == nil {
        fail("the Envelopes box is in \"Only show adjusted envelopes\" mode, which hides the "
             + "clip's own envelopes, and it could not be switched off automatically "
             + "(close Live's Settings window if it is open, then retry). "
             + "Otherwise untick it at the bottom of the envelope chooser menu.")
    }
}
guard let control = controlChooser else {
    fail("no Envelopes box. Select an audio clip and open Clip View — Live is currently "
         + "showing something else (Device View, or a MIDI clip).")
}

//--------------------------------------------------------------------------------
// The Warp Mode chooser stays visible in the clip properties panel while the
// Envelopes box is showing, so the mode can be read without touching Live's API.
// It is absent when the clip is unwarped, in which case Sample Offset is unavailable
// anyway and Transposition is the right partner.
//--------------------------------------------------------------------------------
func warpMode() -> String {
    //--------------------------------------------------------------------------------
    // Retry briefly: right after the Envelopes box is asked to show, or straight after
    // the displayed clip changes, the chooser can be momentarily unreadable. Treating
    // that blank as "not Beats" would silently pick the wrong envelope.
    //--------------------------------------------------------------------------------
    for attempt in 0..<4 {
        if let popup = locate(role: "AXPopUpButton", description: "Warp Mode") {
            let value = string(popup, kAXValueAttribute as String)
            if !value.isEmpty { return value }
        }
        if attempt < 3 { usleep(60_000) }
    }
    return ""
}

func isBeats() -> Bool {
    warpMode().caseInsensitiveCompare("Beats") == .orderedSame
}

func warpPartner() -> String {
    isBeats() ? BEATS_PARTNER : OTHER_PARTNER
}

switch command {
case "status":
    let device = locate(role: "AXPopUpButton", description: "Device Chooser")
    let link = locate(role: "AXButton", description: "Link/Unlink Envelope")
    print("device:   \(device.map { string($0, kAXValueAttribute as String) } ?? "?")")
    print("envelope: \(string(control, kAXValueAttribute as String))")
    print("link:     \(link.map { string($0, kAXValueAttribute as String) } ?? "?")")
    let warp = warpMode()
    print("warp:     \(warp.isEmpty ? "(unwarped)" : warp)")
    print("smart:    \(warpPartner())")

case "open", "menu", "open at mouse", "open-at-mouse":
    let atMouse = command.contains("mouse")
    //--------------------------------------------------------------------------------
    // Open the chooser and leave it open so it can be clicked by hand. Live closes
    // this menu again on its own after a few seconds, so it is a "pop it up and pick"
    // gesture, not a palette that can be parked.
    //
    // Re-triggering closes it again, so one button toggles the menu. A trigger that
    // repeats while held (a HID mouse button set to WhileDown, say) would otherwise
    // strobe it, so toggles closer together than the debounce are ignored.
    //--------------------------------------------------------------------------------
    let stamp = "/tmp/live-envelope.toggle"
    let debounce = 0.35
    let lastToggle = try? FileManager.default.attributesOfItem(atPath: stamp)[.modificationDate] as? Date
    if let last = lastToggle ?? nil, Date().timeIntervalSince(last) < debounce {
        exit(0)
    }
    FileManager.default.createFile(atPath: stamp, contents: nil)

    //--------------------------------------------------------------------------------
    // Pressing the chooser toggles its menu, so the same trigger both opens and
    // dismisses it. Live's own menu offers no cancel action, so this press is the only
    // way to close it without clicking elsewhere or synthesising a keystroke.
    //--------------------------------------------------------------------------------
    if currentMenu(in: application) != nil {
        AXUIElementPerformAction(control, kAXPressAction as CFString)
        print("closed")
        exit(0)
    }
    if let device = locate(role: "AXPopUpButton", description: "Device Chooser") {
        select(device, "Clip", in: application, label: "Device Chooser")
    }
    guard let menu = openMenu(control, in: application) else { fail("could not open the Control Chooser menu") }

    //--------------------------------------------------------------------------------
    // Move it under the pointer, only when asked. A menu can only be repositioned once
    // it already exists, so this always shows one frame at the chooser before jumping;
    // plain "open" leaves it where Live put it and so is visually clean.
    //
    // NSEvent reports a bottom-left origin, accessibility wants top-left, so the y
    // coordinate is flipped against the main screen.
    //--------------------------------------------------------------------------------
    if atMouse, let screen = NSScreen.screens.first {
        let mouse = NSEvent.mouseLocation
        var origin = CGPoint(x: mouse.x - 20, y: screen.frame.maxY - mouse.y - 10)
        if let size = attribute(menu, kAXSizeAttribute as String), CFGetTypeID(size as CFTypeRef) == AXValueGetTypeID() {
            var box = CGSize.zero
            AXValueGetValue(size as! AXValue, .cgSize, &box)
            origin.x = min(origin.x, screen.frame.maxX - box.width)
            origin.y = min(origin.y, screen.frame.maxY - box.height)
        }
        origin.x = max(origin.x, 0)
        origin.y = max(origin.y, 0)
        if let value = AXValueCreate(.cgPoint, &origin) {
            AXUIElementSetAttributeValue(menu, kAXPositionAttribute as CFString, value)
        }
    }
    print(string(control, kAXValueAttribute as String))

case "list":
    guard let menu = openMenu(control, in: application) else { fail("could not open the Control Chooser menu") }
    let all = entries(of: menu)
    closeMenu(menu)
    //--------------------------------------------------------------------------------
    // Live reports AXEnabled as true even for entries it greys out, so availability
    // cannot be shown here. Only the warp-dependent pair is known for certain.
    //--------------------------------------------------------------------------------
    let partner = warpPartner()
    for entry in all {
        let note = (entry.title == BEATS_PARTNER || entry.title == OTHER_PARTNER)
            ? (entry.title == partner ? "  <- available in this warp mode" : "  <- not in this warp mode")
            : ""
        print((entry.checked ? "* " : "  ") + entry.title + note)
    }

case "link", "unlink", "toggle-link":
    guard let button = locate(role: "AXButton", description: "Link/Unlink Envelope") else {
        fail("could not find the Link/Unlink button")
    }
    let current = string(button, kAXValueAttribute as String).lowercased()
    let wanted = command == "toggle-link" ? (current == "linked" ? "unlinked" : "linked") : command + "ed"
    if current != wanted {
        guard AXUIElementPerformAction(button, kAXPressAction as CFString) == .success else {
            fail("could not press the Link/Unlink button")
        }
    }
    print(string(button, kAXValueAttribute as String).lowercased())

default:
    //--------------------------------------------------------------------------------
    // The clip's own envelopes live under the "Clip" entry of the device chooser.
    //--------------------------------------------------------------------------------
    if let device = locate(role: "AXPopUpButton", description: "Device Chooser") {
        select(device, "Clip", in: application, label: "Device Chooser")
    }

    var wanted = command
    switch command {
    //--------------------------------------------------------------------------------
    // Snaps the clip's transposition by a full octave, via AbletonOSC — this writes
    // Live's actual pitch_coarse value, unlike every other command here, which only
    // changes which envelope is displayed. Transposition is then shown so the new
    // value is visible; it is never greyed out, so this needs no warp handling.
    //--------------------------------------------------------------------------------
    case "transpose-up-12", "transpose+12", "transpose-up":
        nudgeTransposition(by: 12)
        wanted = OTHER_PARTNER
    case "transpose-down-12", "transpose-12", "transpose-down":
        nudgeTransposition(by: -12)
        wanted = OTHER_PARTNER
    //--------------------------------------------------------------------------------
    // Gain is a toggle too: pressing it while Gain is already shown goes to
    // Transposition, and pressing again comes back. Transposition exists in every warp
    // mode, so this needs no warp handling.
    //--------------------------------------------------------------------------------
    case "gain", "volume":
        //--------------------------------------------------------------------------------
        // If the Envelopes box was not on screen, this press's job is to reveal it on
        // Gain, not to react to whatever it happened to be showing before it was hidden.
        //--------------------------------------------------------------------------------
        wanted = wasAlreadyVisible && string(control, kAXValueAttribute as String).caseInsensitiveCompare("Gain") == .orderedSame
            ? OTHER_PARTNER : "Gain"
    //--------------------------------------------------------------------------------
    // Sample Offset and Transposition are two names for the same dual-purpose slot:
    // whichever of them the clip's warp mode offers. Asking for either gets the one
    // that is actually usable, so a single trigger covers both. "exact <name>" bypasses
    // this and selects verbatim.
    //--------------------------------------------------------------------------------
    case "smart", "auto", "sample offset", "sample-offset", "sampleoffset",
         "transposition", "transpose", "pitch":
        //--------------------------------------------------------------------------------
        // In Beats both envelopes exist, so this one trigger toggles between them. In
        // every other warp mode Sample Offset is unavailable and Transposition is the
        // only meaningful destination.
        //--------------------------------------------------------------------------------
        // Same rule as gain: only react to the chooser's current value if it was
        // actually visible, otherwise this press's job is to reveal it.
        if isBeats() {
            wanted = wasAlreadyVisible && string(control, kAXValueAttribute as String).caseInsensitiveCompare(BEATS_PARTNER) == .orderedSame
                ? OTHER_PARTNER : BEATS_PARTNER
        } else {
            wanted = OTHER_PARTNER
        }
    case _ where command.hasPrefix("exact "):
        wanted = String(command.dropFirst("exact ".count))
    case "next", "prev":
        //--------------------------------------------------------------------------------
        // Only step through envelopes this warp mode actually offers. Beats has both
        // Sample Offset and Transposition; everything else has Transposition alone, and
        // landing on the entry Live greys out would make a press appear to do nothing.
        //--------------------------------------------------------------------------------
        let cycle = isBeats() ? ["Gain", BEATS_PARTNER, OTHER_PARTNER] : ["Gain", OTHER_PARTNER]
        //--------------------------------------------------------------------------------
        // Same rule as gain/smart: an invisible box's stale value is not a real position
        // in the cycle, so this press lands on the first step instead of stepping past it.
        //--------------------------------------------------------------------------------
        let current = string(control, kAXValueAttribute as String)
        let index = wasAlreadyVisible ? cycle.firstIndex { $0.lowercased() == current.lowercased() } : nil
        wanted = index.map { cycle[($0 + 1) % cycle.count] } ?? cycle[0]
    default:
        break
    }
    print(select(control, wanted, in: application, label: "Control Chooser"))
}
