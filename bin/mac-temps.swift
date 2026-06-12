// mac-temps.swift — read this Mac's temperature sensors in °C, WITHOUT sudo.
//
// Apple Silicon exposes thermal sensors through the IOHIDEventSystemClient
// (HID page kHIDPage_AppleVendor 0xff00, usage TemperatureSensor 0x0005).
// Those symbols live in IOKit.framework but aren't in the public SDK headers,
// so we resolve them with dlsym. No Homebrew, no third-party tools — just an
// Apple framework reached from compiled Swift (the tier the skill reserves for
// exactly this: a domain no AppleScript/ASObjC/Python stdlib can touch).
//
// Usage:  mac-temps           human-readable
//         mac-temps --json    {"ok":true,"avg":..,"max":..,"cpu":..,"gpu":..,"sensors":[...]}

import Foundation

let handle = dlopen("/System/Library/Frameworks/IOKit.framework/IOKit", RTLD_NOW)

func sym<T>(_ name: String, _ type: T.Type) -> T? {
    guard let h = handle, let p = dlsym(h, name) else { return nil }
    return unsafeBitCast(p, to: T.self)
}

typealias CreateT      = @convention(c) (CFAllocator?) -> Unmanaged<AnyObject>?
typealias SetMatchingT = @convention(c) (AnyObject, CFDictionary) -> Void
typealias CopyServicesT = @convention(c) (AnyObject) -> Unmanaged<CFArray>?
typealias CopyEventT   = @convention(c) (AnyObject, Int32, Int32, Int64) -> Unmanaged<AnyObject>?
typealias CopyPropT    = @convention(c) (AnyObject, CFString) -> Unmanaged<AnyObject>?
typealias GetFloatT    = @convention(c) (AnyObject, Int32) -> Double

guard
    let create   = sym("IOHIDEventSystemClientCreate", CreateT.self),
    let setMatch = sym("IOHIDEventSystemClientSetMatching", SetMatchingT.self),
    let copySvcs = sym("IOHIDEventSystemClientCopyServices", CopyServicesT.self),
    let copyEvt  = sym("IOHIDServiceClientCopyEvent", CopyEventT.self),
    let copyProp = sym("IOHIDServiceClientCopyProperty", CopyPropT.self),
    let getFloat = sym("IOHIDEventGetFloatValue", GetFloatT.self),
    let client   = create(kCFAllocatorDefault)?.takeRetainedValue()
else {
    print("{\"ok\":false,\"error\":\"could not open IOHIDEventSystemClient\"}")
    exit(1)
}

// match temperature sensors
let match: [String: Int] = ["PrimaryUsagePage": 0xff00, "PrimaryUsage": 0x0005]
setMatch(client, match as CFDictionary)

let kTemperature: Int32 = 15
let field = Int32(kTemperature << 16)   // IOHIDEventFieldBase(kIOHIDEventTypeTemperature)

var sensors: [(name: String, c: Double)] = []
if let arr = copySvcs(client)?.takeRetainedValue() as? [AnyObject] {
    for svc in arr {
        guard let name = copyProp(svc, "Product" as CFString)?.takeRetainedValue() as? String
        else { continue }
        guard let ev = copyEvt(svc, kTemperature, 0, 0)?.takeRetainedValue() else { continue }
        let t = getFloat(ev, field)
        if t > 0, t < 130 { sensors.append((name, t)) }
    }
}

if sensors.isEmpty {
    print("{\"ok\":false,\"error\":\"no temperature sensors returned\"}")
    exit(1)
}

// On Apple Silicon the SoC die sensors are named "... tdie ..."; CPU "Tp..", GPU "Tg..".
func avg(_ xs: [Double]) -> Double { xs.isEmpty ? 0 : xs.reduce(0, +) / Double(xs.count) }
let die = sensors.filter { $0.name.lowercased().contains("tdie") }.map { $0.c }
let cpu = sensors.filter { $0.name.hasPrefix("Tp") || $0.name.lowercased().contains("cpu") }.map { $0.c }
let gpu = sensors.filter { $0.name.hasPrefix("Tg") || $0.name.lowercased().contains("gpu") }.map { $0.c }
let all = sensors.map { $0.c }
// headline temp: hottest die sensor if present, else hottest overall
let dieMax = die.max() ?? 0, dieAvg = avg(die)
let cpuT = cpu.isEmpty ? dieAvg : avg(cpu)
let gpuT = avg(gpu), avgT = avg(all), maxT = all.max() ?? 0
let headline = dieMax > 0 ? dieMax : maxT

// Thermal pressure — the OS's own coarse verdict (the "Thermal Pressure:
// Nominal" line Hot.app shows). ProcessInfo gives this for free, no sudo,
// and it's the same value the kernel uses to decide whether to throttle.
func thermalPressure() -> String {
    switch ProcessInfo.processInfo.thermalState {
    case .nominal:    return "nominal"
    case .fair:       return "fair"
    case .serious:    return "serious"
    case .critical:   return "critical"
    @unknown default: return "unknown"
    }
}
let pressure = thermalPressure()

let json = ProcessInfo.processInfo.arguments.contains("--json")
if json {
    let items = sensors.sorted { $0.c > $1.c }.prefix(20).map {
        "{\"name\":\"\($0.name)\",\"c\":\(String(format: "%.1f", $0.c))}"
    }.joined(separator: ",")
    print("{\"ok\":true,\"headline\":\(String(format: "%.1f", headline)),"
        + "\"avg\":\(String(format: "%.1f", avgT)),"
        + "\"max\":\(String(format: "%.1f", maxT)),"
        + "\"die_avg\":\(String(format: "%.1f", dieAvg)),"
        + "\"cpu\":\(String(format: "%.1f", cpuT)),"
        + "\"gpu\":\(String(format: "%.1f", gpuT)),"
        + "\"pressure\":\"\(pressure)\","
        + "\"count\":\(sensors.count),\"sensors\":[\(items)]}")
} else {
    print(String(format: "\n  🌡  %d sensors · avg %.1f°C · max %.1f°C · pressure %@",
                 sensors.count, avgT, maxT, pressure as NSString))
    if cpuT > 0 { print(String(format: "      CPU ~%.1f°C", cpuT)) }
    if gpuT > 0 { print(String(format: "      GPU ~%.1f°C", gpuT)) }
    print()
    for s in sensors.sorted(by: { $0.c > $1.c }).prefix(12) {
        print(String(format: "      %-22@ %.1f°C", s.name as NSString, s.c))
    }
    print()
}
