// fm — talk to Apple's on-device LLM via the FoundationModels framework.
//
// The same model behind Apple Intelligence, running locally on the Neural
// Engine — Apple-native, no Ollama, no pip, no network. macOS 26 (Tahoe) only,
// and only when Apple Intelligence is enabled + the model is downloaded.
//
// Usage:
//   fm "your prompt"            generate a reply (prompt from args)
//   echo "text" | fm            prompt from stdin (e.g. summarize piped text)
//   fm --check                  report model availability, then exit
//   fm --system "..." "prompt"  set system instructions

import Foundation
import FoundationModels

var args = Array(CommandLine.arguments.dropFirst())
func popValue(_ flag: String) -> String? {
    guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
    let v = args[i + 1]; args.removeSubrange(i...(i + 1)); return v
}
let checkOnly = args.contains("--check"); args.removeAll { $0 == "--check" }
let system = popValue("--system")

// ── availability ──
let model = SystemLanguageModel.default
switch model.availability {
case .available:
    if checkOnly { print("available"); exit(0) }
case .unavailable(let reason):
    FileHandle.standardError.write(Data("FoundationModels unavailable: \(reason)\n".utf8))
    exit(3)
@unknown default:
    FileHandle.standardError.write(Data("FoundationModels unavailable (unknown state)\n".utf8))
    exit(3)
}

// ── prompt (args, else stdin) ──
var prompt = args.filter { !$0.hasPrefix("--") }.joined(separator: " ")
if prompt.isEmpty {
    let data = FileHandle.standardInput.readDataToEndOfFile()
    prompt = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
}
guard !prompt.isEmpty else {
    FileHandle.standardError.write(Data("usage: fm \"prompt\"   (or pipe text on stdin)   ·   fm --check\n".utf8))
    exit(2)
}

// ─────────────────────── grounding tools ───────────────────────
// A small on-device model has no idea what "now" is and fumbles arithmetic.
// These read-only, Foundation-only tools ground it in reality. No network.

struct CurrentDateTimeTool: Tool {
    let name = "currentDateTime"
    let description = "Returns the current date, time, weekday and timezone. Call whenever the user asks about today, now, the current date/time, or the day of the week."
    @Generable struct Arguments {}
    func call(arguments: Arguments) async throws -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "EEEE, d MMMM yyyy, HH:mm:ss zzz"
        return "Current date and time: \(f.string(from: Date()))"
    }
}

// Safe recursive-descent arithmetic — no NSExpression, no eval, can't crash.
enum Calc {
    static func eval(_ s: String) -> Double? {
        let chars = Array(s); var i = 0
        func skip() { while i < chars.count && chars[i] == " " { i += 1 } }
        func number() -> Double? {
            skip(); var str = ""
            while i < chars.count && (chars[i].isNumber || chars[i] == ".") { str.append(chars[i]); i += 1 }
            return str.isEmpty ? nil : Double(str)
        }
        func factor() -> Double? {
            skip()
            if i < chars.count && chars[i] == "-" { i += 1; return factor().map { -$0 } }
            if i < chars.count && chars[i] == "+" { i += 1; return factor() }
            if i < chars.count && chars[i] == "(" {
                i += 1; let v = expr(); skip()
                if i < chars.count && chars[i] == ")" { i += 1 }
                return v
            }
            return number()
        }
        func term() -> Double? {
            guard var v = factor() else { return nil }
            while true {
                skip()
                guard i < chars.count, chars[i] == "*" || chars[i] == "/" else { break }
                let op = chars[i]; i += 1
                guard let r = factor() else { return nil }
                v = op == "*" ? v * r : (r == 0 ? .nan : v / r)
            }
            return v
        }
        func expr() -> Double? {
            guard var v = term() else { return nil }
            while true {
                skip()
                guard i < chars.count, chars[i] == "+" || chars[i] == "-" else { break }
                let op = chars[i]; i += 1
                guard let r = term() else { return nil }
                v = op == "+" ? v + r : v - r
            }
            return v
        }
        let v = expr(); skip()
        return i == chars.count ? v : nil
    }
}

struct CalculatorTool: Tool {
    let name = "calculator"
    let description = "Evaluate an arithmetic expression with + - * / and parentheses, e.g. (12.5 * 8) + 3/2. Always use this for arithmetic instead of computing it yourself."
    @Generable struct Arguments {
        @Guide(description: "Arithmetic using only digits, + - * / ( ) and decimal points.")
        let expression: String
    }
    func call(arguments: Arguments) async throws -> String {
        guard let v = Calc.eval(arguments.expression), v.isFinite else {
            return "Could not evaluate '\(arguments.expression)'. Use only digits and + - * / ( )."
        }
        let pretty = (v == v.rounded() && abs(v) < 1e15) ? String(Int(v)) : String(v)
        return "\(arguments.expression) = \(pretty)"
    }
}

enum Units {
    static func unit(_ s: String) -> Dimension? {
        switch s.lowercased().trimmingCharacters(in: .whitespaces) {
        case "m","meter","meters","metre","metres": return UnitLength.meters
        case "km","kilometer","kilometers": return UnitLength.kilometers
        case "cm","centimeter","centimeters": return UnitLength.centimeters
        case "mm","millimeter","millimeters": return UnitLength.millimeters
        case "mi","mile","miles": return UnitLength.miles
        case "ft","foot","feet": return UnitLength.feet
        case "in","inch","inches": return UnitLength.inches
        case "yd","yard","yards": return UnitLength.yards
        case "kg","kilogram","kilograms": return UnitMass.kilograms
        case "g","gram","grams": return UnitMass.grams
        case "mg","milligram","milligrams": return UnitMass.milligrams
        case "lb","lbs","pound","pounds": return UnitMass.pounds
        case "oz","ounce","ounces": return UnitMass.ounces
        case "c","celsius","centigrade","°c": return UnitTemperature.celsius
        case "f","fahrenheit","°f": return UnitTemperature.fahrenheit
        case "k","kelvin": return UnitTemperature.kelvin
        case "l","liter","liters","litre","litres": return UnitVolume.liters
        case "ml","milliliter","milliliters": return UnitVolume.milliliters
        case "gal","gallon","gallons": return UnitVolume.gallons
        case "s","sec","secs","second","seconds": return UnitDuration.seconds
        case "min","mins","minute","minutes": return UnitDuration.minutes
        case "h","hr","hrs","hour","hours": return UnitDuration.hours
        default: return nil
        }
    }
    static func convert(_ v: Double, _ from: String, _ to: String) -> Double? {
        guard let fu = unit(from), let tu = unit(to), type(of: fu) == type(of: tu) else { return nil }
        return Measurement(value: v, unit: fu).converted(to: tu).value
    }
}

struct UnitConvertTool: Tool {
    let name = "unitConvert"
    let description = "Convert a value between units of length, mass, temperature, volume, or duration (e.g. 10 km to miles, 72 F to C, 2 kg to lb). Use for any unit conversion."
    @Generable struct Arguments {
        @Guide(description: "The numeric value to convert.") let value: Double
        @Guide(description: "Unit to convert FROM, e.g. km, mi, kg, lb, C, F, L, gal, min, hr.") let from: String
        @Guide(description: "Unit to convert TO.") let to: String
    }
    func call(arguments: Arguments) async throws -> String {
        guard let r = Units.convert(arguments.value, arguments.from, arguments.to) else {
            return "Can't convert \(arguments.from) → \(arguments.to) (unknown or incompatible units)."
        }
        let pretty = (r == r.rounded()) ? String(Int(r)) : String(format: "%.4g", r)
        return "\(arguments.value) \(arguments.from) = \(pretty) \(arguments.to)"
    }
}

struct SystemStateTool: Tool {
    let name = "systemState"
    let description = "Reports this machine's status: hostname, uptime, free disk space, total memory, and thermal state. Call when asked how the computer/Mac/Mini is doing."
    @Generable struct Arguments {}
    func call(arguments: Arguments) async throws -> String {
        let pi = ProcessInfo.processInfo
        let up = Int(pi.systemUptime)
        let mem = Double(pi.physicalMemory) / 1_073_741_824.0
        let thermal: String
        switch pi.thermalState {
        case .nominal: thermal = "nominal"
        case .fair: thermal = "fair"
        case .serious: thermal = "serious"
        case .critical: thermal = "critical"
        @unknown default: thermal = "unknown"
        }
        var disk = "unknown"
        if let a = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let free = a[.systemFreeSize] as? NSNumber {
            disk = String(format: "%.1f GB free", free.doubleValue / 1_073_741_824.0)
        }
        return "Host: \(pi.hostName); uptime: \(up/3600)h \((up%3600)/60)m; "
            + "memory: \(String(format: "%.0f", mem)) GB; disk: \(disk); thermal: \(thermal)."
    }
}

// ── generate (async bridged to the CLI via a semaphore) ──
let groundingTools: [any Tool] = [
    CurrentDateTimeTool(), CalculatorTool(), UnitConvertTool(), SystemStateTool(),
]
let toolHint = "\n\nYou can call tools: currentDateTime, calculator, unitConvert, systemState. "
    + "Use them for the current date/time, arithmetic, unit conversions, and machine status rather than guessing."

let sema = DispatchSemaphore(value: 0)
var output = ""
var failure: String?
Task {
    do {
        let instructions = (system ?? "You are a helpful, concise assistant.") + toolHint
        let session = LanguageModelSession(tools: groundingTools, instructions: instructions)
        let result = try await session.respond(to: prompt)
        output = result.content
    } catch {
        failure = "\(error)"
    }
    sema.signal()
}
sema.wait()

if let f = failure {
    FileHandle.standardError.write(Data("fm error: \(f)\n".utf8))
    exit(1)
}
print(output)
