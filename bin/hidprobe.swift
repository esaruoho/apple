// hidprobe — Apple-native USB HID inspector (IOHIDManager, no Homebrew, no hidapi).
//
// Built to reverse-engineer devices that have no macOS driver — the first target
// being a Contour ShuttlePro v1 — but it is generic: any HID device can be
// enumerated, have its parsed report descriptor dumped, and have its live input
// reports watched byte-by-byte with a delta view.
//
// Subcommands:
//   list [--json]                 enumerate every HID device
//   elements <sel>                dump the parsed report-descriptor elements
//   descriptor <sel>              dump the raw report-descriptor bytes
//   watch <sel> [--seize] [--raw|--parsed|--both]
//                                 live input reports; changed bytes highlighted
//   access                        Input Monitoring (TCC) status; --request to prompt
//
// <sel> is any of:  --vid 0x0b33 --pid 0x0010  |  --name Shuttle  |  --index N
//
// See wiki/concepts/usb-hid-probing.md

import Foundation
import IOKit
import IOKit.hid

// ───────────────────────────── property helpers ─────────────────────────────

func intProp(_ d: IOHIDDevice, _ key: String) -> Int? {
    guard let v = IOHIDDeviceGetProperty(d, key as CFString) else { return nil }
    return (v as? NSNumber)?.intValue
}

func strProp(_ d: IOHIDDevice, _ key: String) -> String? {
    guard let v = IOHIDDeviceGetProperty(d, key as CFString) else { return nil }
    return v as? String
}

func dataProp(_ d: IOHIDDevice, _ key: String) -> Data? {
    guard let v = IOHIDDeviceGetProperty(d, key as CFString) else { return nil }
    return v as? Data
}

func hex4(_ n: Int?) -> String { n.map { String(format: "0x%04x", $0) } ?? "—" }

/// Left-pad to a column width. String(format:) with %s expects a C string, not
/// a Swift String — mixing the two silently prints garbage, so columns are
/// built here instead.
func pad(_ s: String, _ n: Int) -> String {
    s.count >= n ? s : s + String(repeating: " ", count: n - s.count)
}

struct DevInfo {
    let dev: IOHIDDevice
    let vid: Int?
    let pid: Int?
    let manufacturer: String
    let product: String
    let serial: String
    let usagePage: Int?
    let usage: Int?
    let transport: String
    let locationID: Int?
    let maxInput: Int?

    init(_ d: IOHIDDevice) {
        dev = d
        vid = intProp(d, kIOHIDVendorIDKey)
        pid = intProp(d, kIOHIDProductIDKey)
        manufacturer = strProp(d, kIOHIDManufacturerKey) ?? ""
        product = strProp(d, kIOHIDProductKey) ?? ""
        serial = strProp(d, kIOHIDSerialNumberKey) ?? ""
        usagePage = intProp(d, kIOHIDPrimaryUsagePageKey)
        usage = intProp(d, kIOHIDPrimaryUsageKey)
        transport = strProp(d, kIOHIDTransportKey) ?? ""
        locationID = intProp(d, kIOHIDLocationIDKey)
        maxInput = intProp(d, kIOHIDMaxInputReportSizeKey)
    }

    var label: String {
        let n = [manufacturer, product].filter { !$0.isEmpty }.joined(separator: " ")
        return n.isEmpty ? "(unnamed)" : n
    }
}

// Usage-page / usage names, enough to make a dump readable without a spec PDF.
func usagePageName(_ p: Int) -> String {
    switch p {
    case 0x01: return "GenericDesktop"
    case 0x02: return "Simulation"
    case 0x03: return "VR"
    case 0x04: return "Sport"
    case 0x05: return "Game"
    case 0x06: return "GenericDeviceControls"
    case 0x07: return "Keyboard/Keypad"
    case 0x08: return "LED"
    case 0x09: return "Button"
    case 0x0a: return "Ordinal"
    case 0x0b: return "Telephony"
    case 0x0c: return "Consumer"
    case 0x0d: return "Digitizer"
    case 0x0f: return "PID"
    case 0x14: return "AlphanumericDisplay"
    case 0x8c: return "BarCodeScanner"
    default:
        if p >= 0xff00 { return "Vendor(\(String(format: "0x%04x", p)))" }
        return String(format: "0x%04x", p)
    }
}

func genericDesktopUsageName(_ u: Int) -> String {
    switch u {
    case 0x01: return "Pointer"
    case 0x02: return "Mouse"
    case 0x04: return "Joystick"
    case 0x05: return "GamePad"
    case 0x06: return "Keyboard"
    case 0x07: return "Keypad"
    case 0x08: return "MultiAxisController"
    case 0x30: return "X"
    case 0x31: return "Y"
    case 0x32: return "Z"
    case 0x33: return "Rx"
    case 0x34: return "Ry"
    case 0x35: return "Rz"
    case 0x36: return "Slider"
    case 0x37: return "Dial"
    case 0x38: return "Wheel"
    case 0x39: return "HatSwitch"
    default: return String(format: "0x%02x", u)
    }
}

func usageName(page: Int, usage: Int) -> String {
    switch page {
    case 0x01: return genericDesktopUsageName(usage)
    case 0x09: return "Button\(usage)"
    default: return String(format: "0x%02x", usage)
    }
}

func elementTypeName(_ t: IOHIDElementType) -> String {
    switch t {
    case kIOHIDElementTypeInput_Misc: return "Input(Misc)"
    case kIOHIDElementTypeInput_Button: return "Input(Button)"
    case kIOHIDElementTypeInput_Axis: return "Input(Axis)"
    case kIOHIDElementTypeInput_ScanCodes: return "Input(ScanCodes)"
    case kIOHIDElementTypeOutput: return "Output"
    case kIOHIDElementTypeFeature: return "Feature"
    case kIOHIDElementTypeCollection: return "Collection"
    default: return "?"
    }
}

// ───────────────────────────── enumeration ─────────────────────────────

func allDevices() -> [DevInfo] {
    let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    IOHIDManagerSetDeviceMatching(mgr, nil)
    guard let set = IOHIDManagerCopyDevices(mgr) as? Set<IOHIDDevice> else { return [] }
    return set.map(DevInfo.init).sorted {
        ($0.vid ?? 0, $0.pid ?? 0, $0.locationID ?? 0) < ($1.vid ?? 0, $1.pid ?? 0, $1.locationID ?? 0)
    }
}

struct Selector {
    var vid: Int?
    var pid: Int?
    var name: String?
    var index: Int?

    var isEmpty: Bool { vid == nil && pid == nil && name == nil && index == nil }

    func describe() -> String {
        var parts: [String] = []
        if let v = vid { parts.append("vid=\(hex4(v))") }
        if let p = pid { parts.append("pid=\(hex4(p))") }
        if let n = name { parts.append("name~\"\(n)\"") }
        if let i = index { parts.append("index=\(i)") }
        return parts.isEmpty ? "(any)" : parts.joined(separator: " ")
    }

    func matches(_ d: DevInfo) -> Bool {
        if let v = vid, d.vid != v { return false }
        if let p = pid, d.pid != p { return false }
        if let n = name, !d.label.lowercased().contains(n.lowercased()) { return false }
        return true
    }
}

func select(_ sel: Selector) -> [DevInfo] {
    let all = allDevices()
    if let i = sel.index {
        guard i >= 0 && i < all.count else { return [] }
        return [all[i]]
    }
    if sel.isEmpty { return [] }
    return all.filter(sel.matches)
}

// ───────────────────────────── list ─────────────────────────────

func cmdList(json: Bool) {
    let devs = allDevices()
    if json {
        let arr: [[String: Any]] = devs.enumerated().map { (i, d) in
            var o: [String: Any] = [
                "index": i,
                "vendor_id": d.vid as Any,
                "product_id": d.pid as Any,
                "manufacturer": d.manufacturer,
                "product": d.product,
                "transport": d.transport,
            ]
            if !d.serial.isEmpty { o["serial"] = d.serial }
            if let up = d.usagePage { o["usage_page"] = up; o["usage_page_name"] = usagePageName(up) }
            if let u = d.usage, let up = d.usagePage { o["usage"] = u; o["usage_name"] = usageName(page: up, usage: u) }
            if let l = d.locationID { o["location_id"] = l }
            if let m = d.maxInput { o["max_input_report_size"] = m }
            return o
        }
        let data = try! JSONSerialization.data(withJSONObject: arr, options: [.prettyPrinted, .sortedKeys])
        print(String(data: data, encoding: .utf8)!)
        return
    }

    if devs.isEmpty { print("No HID devices found."); return }
    print(pad("#", 4) + pad("VID", 8) + pad("PID", 8) + pad("NAME", 36) + pad("USAGE", 28) + "IN")
    for (i, d) in devs.enumerated() {
        let usage: String
        if let up = d.usagePage, let u = d.usage {
            usage = "\(usagePageName(up))/\(usageName(page: up, usage: u))"
        } else { usage = "—" }
        let name = d.label.count > 34 ? String(d.label.prefix(31)) + "..." : d.label
        print(pad("\(i)", 4) + pad(hex4(d.vid), 8) + pad(hex4(d.pid), 8)
              + pad(name, 36) + pad(usage, 28) + (d.maxInput.map(String.init) ?? "—"))
    }
    print("\n\(devs.count) device(s). Watch one with:  hidprobe watch --vid <VID> --pid <PID>")
}

// ───────────────────────────── elements ─────────────────────────────

func cmdElements(_ sel: Selector) {
    let devs = select(sel)
    guard !devs.isEmpty else { fail("no device matched") }
    for d in devs {
        print("═══ \(d.label)  \(hex4(d.vid)):\(hex4(d.pid)) ═══")
        guard let els = IOHIDDeviceCopyMatchingElements(d.dev, nil, IOOptionBits(kIOHIDOptionsTypeNone)) as? [IOHIDElement] else {
            print("  (no elements)"); continue
        }
        print("  " + pad("TYPE", 17) + pad("RPTID", 7) + pad("BITS", 5) + pad("COUNT", 6)
              + pad("PAGE", 17) + pad("USAGE", 12) + pad("LOGICAL", 15) + "PHYSICAL")
        for e in els {
            let type = elementTypeName(IOHIDElementGetType(e))
            let page = Int(IOHIDElementGetUsagePage(e))
            let usage = Int(IOHIDElementGetUsage(e))
            let rid = IOHIDElementGetReportID(e)
            let size = IOHIDElementGetReportSize(e)
            let count = IOHIDElementGetReportCount(e)
            let lmin = IOHIDElementGetLogicalMin(e), lmax = IOHIDElementGetLogicalMax(e)
            let pmin = IOHIDElementGetPhysicalMin(e), pmax = IOHIDElementGetPhysicalMax(e)
            print("  " + pad(type, 17) + pad("\(rid)", 7) + pad("\(size)", 5) + pad("\(count)", 6)
                  + pad(usagePageName(page), 17) + pad(usageName(page: page, usage: usage), 12)
                  + pad("\(lmin)..\(lmax)", 15) + "\(pmin)..\(pmax)")
        }
        print("  \(els.count) element(s)")
    }
}

// ───────────────────────────── descriptor ─────────────────────────────

func cmdDescriptor(_ sel: Selector) {
    let devs = select(sel)
    guard !devs.isEmpty else { fail("no device matched") }
    for d in devs {
        print("═══ \(d.label)  \(hex4(d.vid)):\(hex4(d.pid)) ═══")
        guard let data = dataProp(d.dev, kIOHIDReportDescriptorKey), !data.isEmpty else {
            print("  (device exposes no raw report descriptor — use `hidprobe elements` instead)")
            continue
        }
        print("  \(data.count) bytes")
        let bytes = [UInt8](data)
        for row in stride(from: 0, to: bytes.count, by: 16) {
            let chunk = bytes[row..<min(row + 16, bytes.count)]
            let hex = chunk.map { String(format: "%02x", $0) }.joined(separator: " ")
            print(String(format: "  %04x  %@", row, hex as NSString))
        }
    }
}

// ───────────────────────────── watch ─────────────────────────────

let ANSI_RESET = "\u{1b}[0m"
let ANSI_HI = "\u{1b}[1;33m"   // changed byte
let ANSI_DIM = "\u{1b}[2m"

final class Watcher {
    let info: DevInfo
    let bufSize: Int
    let buf: UnsafeMutablePointer<UInt8>
    var previous: [UInt8]?
    var reportCount = 0
    let showRaw: Bool
    let showParsed: Bool
    let start = Date()

    init(_ info: DevInfo, showRaw: Bool, showParsed: Bool) {
        self.info = info
        // Some devices under-report max size; give ourselves headroom.
        self.bufSize = max(info.maxInput ?? 64, 64)
        self.buf = UnsafeMutablePointer<UInt8>.allocate(capacity: bufSize)
        self.buf.initialize(repeating: 0, count: bufSize)
        self.showRaw = showRaw
        self.showParsed = showParsed
    }

    func stamp() -> String {
        String(format: "%8.3f", Date().timeIntervalSince(start))
    }

    func onReport(length: Int, reportID: UInt32) {
        reportCount += 1
        guard showRaw else { return }
        let bytes = Array(UnsafeBufferPointer(start: buf, count: length))

        var cells: [String] = []
        for (i, b) in bytes.enumerated() {
            let changed = previous.map { i >= $0.count || $0[i] != b } ?? true
            let h = String(format: "%02x", b)
            cells.append(changed ? "\(ANSI_HI)\(h)\(ANSI_RESET)" : "\(ANSI_DIM)\(h)\(ANSI_RESET)")
        }

        // Decoded companions: unsigned, signed, and bit view of each byte.
        let dec = bytes.map { String(format: "%3d", $0) }.joined(separator: " ")
        let sgn = bytes.map { String(format: "%4d", Int8(bitPattern: $0)) }.joined(separator: " ")

        print("[\(stamp())] #\(reportCount) id=\(reportID) len=\(length)")
        print("   hex  \(cells.joined(separator: " "))")
        print("   u8   \(dec)")
        print("   i8   \(sgn)")

        // Bits of any byte that changed — the fastest way to find a button map.
        if let prev = previous {
            for (i, b) in bytes.enumerated() where i < prev.count && prev[i] != b {
                let bits = (0..<8).reversed().map { (b >> $0) & 1 == 1 ? "1" : "0" }.joined()
                let pbits = (0..<8).reversed().map { (prev[i] >> $0) & 1 == 1 ? "1" : "0" }.joined()
                print("   byte[\(i)] \(pbits) -> \(bits)   (\(prev[i]) -> \(b), delta \(Int(b) &- Int(prev[i])))")
            }
        }
        previous = bytes
    }

    func onValue(_ value: IOHIDValue) {
        guard showParsed else { return }
        let el = IOHIDValueGetElement(value)
        let page = Int(IOHIDElementGetUsagePage(el))
        let usage = Int(IOHIDElementGetUsage(el))
        let v = IOHIDValueGetIntegerValue(value)
        print("[\(stamp())] \(usagePageName(page))/\(usageName(page: page, usage: usage)) = \(v)")
    }

    deinit { buf.deallocate() }
}

/// Holds every attached Watcher for the life of the run loop, and remembers which
/// IOHIDDevices are already attached so a re-matching callback cannot double-open.
final class WatchSession {
    let sel: Selector
    let seize: Bool
    let showRaw: Bool
    let showParsed: Bool
    var watchers: [Watcher] = []
    var attached = Set<Int>()   // hashValue of the IOHIDDevice reference

    init(sel: Selector, seize: Bool, showRaw: Bool, showParsed: Bool) {
        self.sel = sel; self.seize = seize; self.showRaw = showRaw; self.showParsed = showParsed
    }

    func attach(_ device: IOHIDDevice) {
        let info = DevInfo(device)
        guard sel.matches(info) else { return }
        let key = ObjectIdentifier(device as AnyObject).hashValue
        guard !attached.contains(key) else { return }

        // A device whose buttons look like keys to macOS will otherwise type into
        // whatever is frontmost. Seizing takes it away from the system entirely.
        let opts = IOOptionBits(seize ? kIOHIDOptionsTypeSeizeDevice : kIOHIDOptionsTypeNone)
        let r = IOHIDDeviceOpen(device, opts)
        if r != kIOReturnSuccess {
            let msg = String(format: "  ! IOHIDDeviceOpen failed (0x%08x) for %@", r, info.label)
            print(msg)
            print("    0xe00002c1 = already claimed by another process (quit its vendor driver).")
            print("    an access error = grant Input Monitoring:  hidprobe access --request")
            return
        }
        attached.insert(key)

        let w = Watcher(info, showRaw: showRaw, showParsed: showParsed)
        watchers.append(w)
        let ctx = Unmanaged.passUnretained(w).toOpaque()

        IOHIDDeviceRegisterInputReportCallback(device, w.buf, w.bufSize, { ctx, result, _, _, reportID, _, length in
            guard result == kIOReturnSuccess, let ctx = ctx else { return }
            Unmanaged<Watcher>.fromOpaque(ctx).takeUnretainedValue()
                .onReport(length: Int(length), reportID: reportID)
        }, ctx)

        if showParsed {
            IOHIDDeviceRegisterInputValueCallback(device, { ctx, result, _, value in
                guard result == kIOReturnSuccess, let ctx = ctx else { return }
                Unmanaged<Watcher>.fromOpaque(ctx).takeUnretainedValue().onValue(value)
            }, ctx)
        }

        print("● attached: \(info.label)  \(hex4(info.vid)):\(hex4(info.pid))"
              + "  maxInputReport=\(info.maxInput.map(String.init) ?? "?")"
              + (seize ? "  [SEIZED]" : ""))
        print("  Now move ONE control at a time — ring, then jog, then each button in order.\n")
    }

    func detach(_ device: IOHIDDevice) {
        let key = ObjectIdentifier(device as AnyObject).hashValue
        guard attached.contains(key) else { return }
        attached.remove(key)
        print("○ detached: \(DevInfo(device).label)")
    }
}

func cmdWatch(_ sel: Selector, seize: Bool, showRaw: Bool, showParsed: Bool) {
    guard !sel.isEmpty else { fail("watch needs a selector — e.g. --name Shuttle, or --vid/--pid") }
    if sel.index != nil {
        fail("--index is a snapshot of the current list and cannot survive a replug; " +
             "use --vid/--pid or --name with watch")
    }

    let session = WatchSession(sel: sel, seize: seize, showRaw: showRaw, showParsed: showParsed)
    let ctx = Unmanaged.passRetained(session).toOpaque()

    let mgr = IOHIDManagerCreate(kCFAllocatorDefault, IOOptionBits(kIOHIDOptionsTypeNone))
    // Narrow in the kernel where we can; the name filter is applied in attach().
    var match: [String: Int] = [:]
    if let v = sel.vid { match[kIOHIDVendorIDKey] = v }
    if let p = sel.pid { match[kIOHIDProductIDKey] = p }
    IOHIDManagerSetDeviceMatching(mgr, match.isEmpty ? nil : (match as CFDictionary))

    // Fires once per already-present match, then again on every future hotplug —
    // so this command can be started BEFORE the device is plugged in.
    IOHIDManagerRegisterDeviceMatchingCallback(mgr, { ctx, _, _, device in
        guard let ctx = ctx else { return }
        Unmanaged<WatchSession>.fromOpaque(ctx).takeUnretainedValue().attach(device)
    }, ctx)
    IOHIDManagerRegisterDeviceRemovalCallback(mgr, { ctx, _, _, device in
        guard let ctx = ctx else { return }
        Unmanaged<WatchSession>.fromOpaque(ctx).takeUnretainedValue().detach(device)
    }, ctx)

    IOHIDManagerScheduleWithRunLoop(mgr, CFRunLoopGetCurrent(), CFRunLoopMode.defaultMode.rawValue)
    IOHIDManagerOpen(mgr, IOOptionBits(kIOHIDOptionsTypeNone))

    print("Waiting for a device matching \(sel.describe())… (plug it in now; Ctrl-C to stop)")
    CFRunLoopRun()
}

// ───────────────────────────── access (TCC) ─────────────────────────────

func cmdAccess(request: Bool) {
    let t = IOHIDCheckAccess(kIOHIDRequestTypeListenEvent)
    let name: String
    switch t {
    case kIOHIDAccessTypeGranted: name = "GRANTED"
    case kIOHIDAccessTypeDenied: name = "DENIED"
    case kIOHIDAccessTypeUnknown: name = "UNKNOWN (never asked)"
    default: name = "?(\(t.rawValue))"
    }
    print("Input Monitoring (kIOHIDRequestTypeListenEvent): \(name)")
    if request {
        let ok = IOHIDRequestAccess(kIOHIDRequestTypeListenEvent)
        print("IOHIDRequestAccess -> \(ok ? "granted" : "not granted")")
        if !ok {
            print("Grant it in System Settings ▸ Privacy & Security ▸ Input Monitoring,")
            print("for the app running this tool (Terminal/iTerm), then re-run.")
        }
    }
}

// ───────────────────────────── main ─────────────────────────────

func fail(_ msg: String) -> Never {
    FileHandle.standardError.write("hidprobe: \(msg)\n".data(using: .utf8)!)
    exit(1)
}

func parseNum(_ s: String) -> Int? {
    if s.hasPrefix("0x") || s.hasPrefix("0X") { return Int(s.dropFirst(2), radix: 16) }
    return Int(s)
}

let usageText = """
hidprobe — Apple-native USB HID inspector (IOHIDManager)

  hidprobe list [--json]
  hidprobe elements   <sel>
  hidprobe descriptor <sel>
  hidprobe watch      <sel> [--seize] [--raw|--parsed|--both]
  hidprobe access [--request]

<sel>: --vid 0x0b33 --pid 0x0010 | --name Shuttle | --index 4

  --seize   take the device away from macOS while watching, so its buttons do
            not type into the frontmost app
  --raw     hex/u8/i8/bit dump of each input report (default)
  --parsed  named usage/value events decoded via the report descriptor
  --both    both views
"""

// Line-buffer stdout: watch output is normally piped to `tee` for a capture log,
// and the default block buffering would hide every report until the buffer filled.
setvbuf(stdout, nil, _IOLBF, 0)

var args = Array(CommandLine.arguments.dropFirst())
guard let cmd = args.first else { print(usageText); exit(0) }
args.removeFirst()

var sel = Selector()
var json = false, seize = false, request = false
var wantRaw = false, wantParsed = false

func needStr(_ v: String?, _ what: String) -> String {
    guard let v = v else { fail("\(what) needs a value") }
    return v
}
func needNum(_ v: String?, _ what: String) -> Int {
    guard let n = parseNum(needStr(v, what)) else { fail("\(what) needs a number (decimal or 0x…)") }
    return n
}

var i = 0
while i < args.count {
    let a = args[i]
    switch a {
    case "--vid": i += 1; sel.vid = needNum(args[safe: i], "--vid")
    case "--pid": i += 1; sel.pid = needNum(args[safe: i], "--pid")
    case "--name": i += 1; sel.name = needStr(args[safe: i], "--name")
    case "--index": i += 1; sel.index = needNum(args[safe: i], "--index")
    case "--json": json = true
    case "--seize": seize = true
    case "--request": request = true
    case "--raw": wantRaw = true
    case "--parsed": wantParsed = true
    case "--both": wantRaw = true; wantParsed = true
    case "-h", "--help": print(usageText); exit(0)
    default: fail("unknown option \(a)")
    }
    i += 1
}
if !wantRaw && !wantParsed { wantRaw = true }

extension Array {
    subscript(safe i: Int) -> Element? { i >= 0 && i < count ? self[i] : nil }
}

switch cmd {
case "list": cmdList(json: json)
case "elements": cmdElements(sel)
case "descriptor": cmdDescriptor(sel)
case "watch": cmdWatch(sel, seize: seize, showRaw: wantRaw, showParsed: wantParsed)
case "access": cmdAccess(request: request)
case "-h", "--help", "help": print(usageText)
default: fail("unknown command \(cmd) — try `hidprobe --help`")
}
