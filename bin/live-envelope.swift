// live-envelope — drive Ableton Live's Clip View Envelopes choosers.
//
//   live-envelope gain | transposition | "sample offset"   select that clip envelope
//   live-envelope next | prev                              cycle through the three
//   live-envelope link | unlink | toggle-link              Link/Unlink the envelope
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
let CYCLE = ["Gain", "Transposition", "Sample Offset"]
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

/// Breadth-first, so the shallow Envelopes box controls are found without
/// descending into the sample editor's thousands of warp markers.
func findControl(in root: AXUIElement, role wanted: String, description: String) -> AXUIElement? {
    var queue = [root]
    var visited = 0
    while !queue.isEmpty && visited < 60000 {
        let element = queue.removeFirst()
        visited += 1
        if role(element) == wanted && string(element, kAXDescriptionAttribute as String) == description {
            return element
        }
        queue.append(contentsOf: children(element))
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
    // A menu left over from a previous command swallows the next press, so dismiss
    // anything still on screen and wait for it to actually go away first.
    //--------------------------------------------------------------------------------
    if let stale = currentMenu(in: application) {
        closeMenu(stale)
        for _ in 0..<25 where currentMenu(in: application) != nil { usleep(20_000) }
    }

    for attempt in 0..<2 {
        guard AXUIElementPerformAction(popup, kAXPressAction as CFString) == .success else { return nil }
        for _ in 0..<(attempt == 0 ? 25 : 60) {
            if let menu = currentMenu(in: application) { return menu }
            usleep(20_000)
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

func showEnvelopeBox() {
    func pad(_ bytes: [UInt8]) -> [UInt8] {
        bytes + [UInt8](repeating: 0, count: (4 - bytes.count % 4) % 4)
    }
    let packet = pad(Array("/live/view/show_clip_envelope".utf8) + [0]) + pad(Array(",".utf8) + [0])

    let descriptor = socket(AF_INET, SOCK_DGRAM, 0)
    guard descriptor >= 0 else { return }
    defer { close(descriptor) }

    var address = sockaddr_in()
    address.sin_family = sa_family_t(AF_INET)
    address.sin_port = OSC_PORT.bigEndian
    address.sin_addr.s_addr = inet_addr(OSC_HOST)

    withUnsafePointer(to: &address) { pointer in
        pointer.withMemoryRebound(to: sockaddr.self, capacity: 1) {
            _ = sendto(descriptor, packet, packet.count, 0, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
        }
    }
}

//--------------------------------------------------------------------------------

let usage = """
usage: live-envelope <command>

  gain | transposition | sample offset    select that clip envelope
  next | prev                             cycle through the three
  link | unlink | toggle-link             Link/Unlink the displayed envelope
  status                                  print the current chooser state
  list                                    list every entry the chooser offers
"""

let command = CommandLine.arguments.dropFirst().joined(separator: " ").lowercased()
if command.isEmpty || command == "-h" || command == "--help" {
    print(usage)
    exit(command.isEmpty ? 2 : 0)
}

guard AXIsProcessTrusted() else {
    fail("not trusted for Accessibility. Grant the app running this command access in "
         + "System Settings > Privacy & Security > Accessibility.")
}
guard let live = NSRunningApplication.runningApplications(withBundleIdentifier: BUNDLE_ID).first else {
    fail("Ableton Live is not running (no process with bundle id \(BUNDLE_ID)).")
}

let application = AXUIElementCreateApplication(live.processIdentifier)

/// Searches every window, since a stray open menu can occupy the first slot.
func locate(role: String, description: String) -> AXUIElement? {
    for window in windows(of: application) {
        if let found = findControl(in: window, role: role, description: description) { return found }
    }
    return nil
}

var controlChooser = locate(role: "AXPopUpButton", description: "Control Chooser")
if controlChooser == nil {
    showEnvelopeBox()
    for _ in 0..<50 {
        usleep(20_000)
        controlChooser = locate(role: "AXPopUpButton", description: "Control Chooser")
        if controlChooser != nil { break }
    }
}
guard let control = controlChooser else {
    fail("could not find the Envelopes box. Select an audio clip and show Clip View "
         + "(AbletonOSC must be enabled for it to be opened automatically).")
}

switch command {
case "status":
    let device = locate(role: "AXPopUpButton", description: "Device Chooser")
    let link = locate(role: "AXButton", description: "Link/Unlink Envelope")
    print("device:   \(device.map { string($0, kAXValueAttribute as String) } ?? "?")")
    print("envelope: \(string(control, kAXValueAttribute as String))")
    print("link:     \(link.map { string($0, kAXValueAttribute as String) } ?? "?")")

case "list":
    guard let menu = openMenu(control, in: application) else { fail("could not open the Control Chooser menu") }
    let all = entries(of: menu)
    closeMenu(menu)
    for entry in all {
        print((entry.checked ? "* " : "  ") + entry.title + (entry.enabled ? "" : "  (unavailable)"))
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
    if command == "next" || command == "prev" {
        let current = string(control, kAXValueAttribute as String)
        let index = CYCLE.firstIndex { $0.lowercased() == current.lowercased() } ?? 0
        wanted = CYCLE[(index + (command == "next" ? 1 : CYCLE.count - 1)) % CYCLE.count]
    }
    print(select(control, wanted, in: application, label: "Control Chooser"))
}
