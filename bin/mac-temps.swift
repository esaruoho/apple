// mac-temps.swift — read this Mac's temperature sensors in °C, WITHOUT sudo.
//
// Reads the AppleSMC IOService directly (the same source Hot.app, iStat Menus
// and TG Pro use), NOT the IOHIDEventSystemClient "PMU tdie" page. That matters:
// the HID `tdie` sensors are PACKAGE-distributed and read ~30 °C COOLER than the
// per-core junction sensors. Under load this Mac's `tdie` reads 65 °C while the
// CPU performance cores (`Tp**` SMC keys) read 97 °C — and 97 is what Hot shows
// and what actually throttles. Matching Hot means reading the SMC core temps.
//
// SMC reads go through a user IOConnect — no sudo, no Homebrew, no third-party
// tool. Apple Silicon temperature keys are 4-char `T***` keys of type "flt "
// (4-byte LE float); Intel Macs use "sp78" (2-byte signed fixed point /256).
//
// Headline = hottest CPU core sensor (Tp*/Te*/TC* — what Hot reports). GPU =
// hottest Tg*. The JSON contract (ok/headline/avg/max/die_avg/cpu/gpu/pressure/
// count/sensors) is unchanged, so machine-card / Fleet / AppleToolbox need no
// edits — only the underlying number got correct.
//
// Usage:  mac-temps           human-readable
//         mac-temps --json    {"ok":true,"headline":..,"cpu":..,"gpu":..,"sensors":[...]}

import Foundation
import IOKit

// ───────────────────────── SMC plumbing ─────────────────────────

typealias SMCBytes = (UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,
                      UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8,UInt8)

struct SMCVers   { var major:UInt8=0; var minor:UInt8=0; var build:UInt8=0; var reserved:UInt8=0; var release:UInt16=0 }
struct SMCLimit  { var version:UInt16=0; var length:UInt16=0; var cpuPLimit:UInt32=0; var gpuPLimit:UInt32=0; var memPLimit:UInt32=0 }
struct SMCKeyInfo { var dataSize:UInt32=0; var dataType:UInt32=0; var dataAttributes:UInt8=0 }

// Field order + the UInt16 padding before `result` mirror the C SMCKeyData_t
// ABI exactly; get this wrong and IOConnectCallStructMethod returns garbage
// (the #KEY count comes back 0). MemoryLayout<SMCParam>.stride must be 80.
struct SMCParam {
    var key:UInt32=0
    var vers=SMCVers()
    var pLimit=SMCLimit()
    var keyInfo=SMCKeyInfo()
    var padding:UInt16=0
    var result:UInt8=0
    var status:UInt8=0
    var data8:UInt8=0
    var data32:UInt32=0
    var bytes:SMCBytes=(0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

func fourCC(_ s:String)->UInt32 { var r:UInt32=0; for c in s.utf8 { r=(r<<8)|UInt32(c) }; return r }
func keyToStr(_ k:UInt32)->String {
    String(bytes:[UInt8((k>>24)&0xff),UInt8((k>>16)&0xff),UInt8((k>>8)&0xff),UInt8(k&0xff)], encoding:.ascii) ?? "?"
}

var conn:io_connect_t = 0
let smcService = IOServiceGetMatchingService(kIOMainPortDefault, IOServiceMatching("AppleSMC"))
guard smcService != 0, IOServiceOpen(smcService, mach_task_self_, 0, &conn) == KERN_SUCCESS else {
    print("{\"ok\":false,\"error\":\"could not open AppleSMC\"}")
    exit(1)
}

func smcCall(_ inp: inout SMCParam, _ out: inout SMCParam) -> Bool {
    let isz = MemoryLayout<SMCParam>.stride
    var osz = MemoryLayout<SMCParam>.stride
    return IOConnectCallStructMethod(conn, 2, &inp, isz, &out, &osz) == KERN_SUCCESS
}
func smcKeyInfo(_ key:UInt32) -> SMCKeyInfo? {
    var i = SMCParam(); i.key = key; i.data8 = 9   // kSMCGetKeyInfo
    var o = SMCParam()
    return (smcCall(&i,&o) && o.result == 0) ? o.keyInfo : nil
}
func tupleBytes(_ t:SMCBytes) -> [UInt8] { Mirror(reflecting:t).children.map { $0.value as! UInt8 } }
func smcReadBytes(_ key:UInt32,_ ki:SMCKeyInfo) -> [UInt8]? {
    var i = SMCParam(); i.key = key; i.keyInfo = ki; i.data8 = 5   // kSMCReadKey
    var o = SMCParam()
    guard smcCall(&i,&o), o.result == 0 else { return nil }
    return Array(tupleBytes(o.bytes).prefix(Int(ki.dataSize)))
}
func smcKeyCount() -> Int {
    guard let ki = smcKeyInfo(fourCC("#KEY")), let b = smcReadBytes(fourCC("#KEY"), ki), b.count >= 4
    else { return 0 }
    return Int(b[0])<<24 | Int(b[1])<<16 | Int(b[2])<<8 | Int(b[3])
}
func smcKeyAt(_ idx:Int) -> UInt32? {
    var i = SMCParam(); i.data8 = 8; i.data32 = UInt32(idx)   // kSMCGetKeyFromIndex
    var o = SMCParam()
    return (smcCall(&i,&o) && o.result == 0) ? o.key : nil
}
/// Decode a temperature key to °C — "flt " (Apple Silicon) or "sp78" (Intel).
func smcReadTemp(_ key:UInt32) -> Double? {
    guard let ki = smcKeyInfo(key) else { return nil }
    let t = keyToStr(ki.dataType)
    guard let b = smcReadBytes(key, ki) else { return nil }
    if t == "flt " && b.count == 4 {
        return Double(Float(bitPattern: UInt32(b[0]) | UInt32(b[1])<<8 | UInt32(b[2])<<16 | UInt32(b[3])<<24))
    }
    if t == "sp78" && b.count == 2 {
        return Double(Int16(bitPattern: UInt16(b[0])<<8 | UInt16(b[1]))) / 256.0
    }
    return nil
}

// ───────────────────────── enumerate temperature sensors ─────────────────────────

// A friendly label for the common Apple Silicon temperature-key families, so
// the per-sensor list reads like Hot's instead of bare 4-char codes.
func friendly(_ k:String) -> String {
    if k.hasPrefix("Tp") { return "CPU P-core (\(k))" }
    if k.hasPrefix("Te") { return "CPU E-core (\(k))" }
    if k.hasPrefix("TC") { return "CPU cluster (\(k))" }
    if k.hasPrefix("Tg") { return "GPU (\(k))" }
    if k.hasPrefix("Tm") { return "Memory (\(k))" }
    if k.hasPrefix("Ts") { return "Skin/enclosure (\(k))" }
    if k.hasPrefix("TB") { return "Battery (\(k))" }
    return k
}

let count = smcKeyCount()
var sensors: [(name:String, key:String, c:Double)] = []
if count > 0 {
    for idx in 0..<count {
        guard let k = smcKeyAt(idx) else { continue }
        let ks = keyToStr(k)
        guard ks.first == "T" else { continue }          // temperature keys
        guard let v = smcReadTemp(k), v > 0, v < 125 else { continue }  // sane band
        sensors.append((friendly(ks), ks, v))
    }
}

if sensors.isEmpty {
    print("{\"ok\":false,\"error\":\"no SMC temperature sensors returned\"}")
    exit(1)
}

// CPU cores = Tp* (performance) + Te* (efficiency) + TC* (cluster). Hot's
// headline is the hottest of these — the junction temp that actually throttles.
func avg(_ xs:[Double]) -> Double { xs.isEmpty ? 0 : xs.reduce(0,+) / Double(xs.count) }
let cpuTemps = sensors.filter { $0.key.hasPrefix("Tp") || $0.key.hasPrefix("Te") || $0.key.hasPrefix("TC") }.map { $0.c }
let gpuTemps = sensors.filter { $0.key.hasPrefix("Tg") }.map { $0.c }
let allTemps = sensors.map { $0.c }

let cpuMax  = cpuTemps.max() ?? (allTemps.max() ?? 0)
let cpuAvg  = avg(cpuTemps)
let gpuMax  = gpuTemps.max() ?? 0
let avgT    = avg(allTemps)
let maxT    = allTemps.max() ?? 0
let headline = cpuMax            // ← what Hot shows

// Thermal pressure — the OS's own coarse verdict (the "Thermal Pressure:
// Nominal" line Hot shows), free from ProcessInfo, same value the kernel
// uses to decide whether to throttle.
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

IOServiceClose(conn)

let json = ProcessInfo.processInfo.arguments.contains("--json")
if json {
    let items = sensors.sorted { $0.c > $1.c }.prefix(24).map {
        "{\"name\":\"\($0.name)\",\"key\":\"\($0.key)\",\"c\":\(String(format: "%.1f", $0.c))}"
    }.joined(separator: ",")
    print("{\"ok\":true,\"headline\":\(String(format: "%.1f", headline)),"
        + "\"avg\":\(String(format: "%.1f", avgT)),"
        + "\"max\":\(String(format: "%.1f", maxT)),"
        + "\"die_avg\":\(String(format: "%.1f", cpuAvg)),"
        + "\"cpu\":\(String(format: "%.1f", cpuMax)),"
        + "\"gpu\":\(String(format: "%.1f", gpuMax)),"
        + "\"pressure\":\"\(pressure)\","
        + "\"count\":\(sensors.count),\"sensors\":[\(items)]}")
} else {
    print(String(format: "\n  🔥  CPU %.1f°C · GPU %.1f°C · %d sensors · pressure %@",
                 cpuMax, gpuMax, sensors.count, pressure as NSString))
    print(String(format: "      max %.1f°C · avg %.1f°C", maxT, avgT))
    print()
    for s in sensors.sorted(by: { $0.c > $1.c }).prefix(14) {
        print(String(format: "      %-22@ %.1f°C", s.name as NSString, s.c))
    }
    print()
}
