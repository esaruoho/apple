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
// semantic_search searches this folder (default: the apple wiki — always on the Mini).
let searchDir = popValue("--search-dir") ?? "\(NSHomeDirectory())/work/apple/wiki"
let binDir = ProcessInfo.processInfo.environment["FM_BIN_DIR"] ?? "\(NSHomeDirectory())/work/apple/bin"

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

// Fetch a web page and hand back its readable text. The model on its own can't
// reach the network; this tool gives it eyes on a single URL the user names.
// Foundation-only on purpose: NSAttributedString's HTML importer needs AppKit and
// a main thread, which is fragile in this headless CLI — so we strip markup with
// regex instead. Reads only; no JS, no following links, capped payload.
struct WebReaderTool: Tool {
    let name = "webReader"
    let description = "Fetch a web page by its URL and return its readable text (page title plus main body text). Call this whenever the user provides a URL or asks what a web page says."
    @Generable struct Arguments {
        @Guide(description: "The absolute URL to fetch, including the https:// scheme.")
        let url: String
    }
    func call(arguments: Arguments) async throws -> String {
        guard let url = URL(string: arguments.url),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return "Not a valid http(s) URL: \(arguments.url)"
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue("Mozilla/5.0 (Macintosh) fm", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            return "Could not fetch \(arguments.url) (HTTP \(status))."
        }
        guard let html = String(data: data, encoding: .utf8)
                ?? String(data: data, encoding: .isoLatin1) else {
            return "Could not decode the page at \(arguments.url)."
        }
        let title = WebText.title(html)
        let text = WebText.strip(html)
        let capped = String(text.prefix(6000))   // respect the small context window
        var out = title.isEmpty ? "" : "Title: \(title)\n\n"
        out += capped
        if text.count > capped.count { out += "\n\n[truncated]" }
        return out
    }
}

// Tiny Foundation-only HTML → text. Not a full parser; enough to read an article.
enum WebText {
    static func re(_ s: String, _ p: String, _ rep: String) -> String {
        s.replacingOccurrences(of: p, with: rep, options: [.regularExpression, .caseInsensitive])
    }
    static func title(_ html: String) -> String {
        guard let m = html.range(of: "<title[^>]*>(.*?)</title>",
                                 options: [.regularExpression, .caseInsensitive]) else { return "" }
        let inner = re(re(String(html[m]), "<title[^>]*>", ""), "</title>", "")
        return decode(inner).trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static func strip(_ html: String) -> String {
        var s = html
        s = re(s, "(?s)<script.*?</script>", " ")
        s = re(s, "(?s)<style.*?</style>", " ")
        s = re(s, "(?s)<!--.*?-->", " ")
        s = re(s, "(?s)<head.*?</head>", " ")
        s = re(s, "<(br|/p|/div|/h[1-6]|/li|/tr)[^>]*>", "\n")   // block ends → newline
        s = re(s, "<[^>]+>", " ")                                 // remaining tags → space
        s = decode(s)
        s = re(s, "[ \\t]+", " ")
        s = re(s, " *\\n *", "\n")
        s = re(s, "\\n{3,}", "\n\n")
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    static func decode(_ s: String) -> String {
        var t = s
        let ents = ["&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'",
                    "&apos;": "'", "&nbsp;": " ", "&mdash;": "—", "&ndash;": "–",
                    "&hellip;": "…", "&rsquo;": "'", "&lsquo;": "'", "&ldquo;": "\"", "&rdquo;": "\""]
        for (k, v) in ents { t = t.replacingOccurrences(of: k, with: v) }
        return re(t, "&#x?[0-9a-fA-F]+;", " ")   // drop any remaining numeric entities
    }
}

// semantic_search — on-device RAG. The model calls it to ground answers in the
// user's own notes; it shells to bin/vault-grep (NLEmbedding) and returns ranked
// snippets. Read-only, allowlisted — the model picks the query, never a command.
struct SemanticSearchTool: Tool {
    let name = "semantic_search"
    let description = "Search the user's own notes and documents for passages related in meaning to a query and return ranked snippets with their file locations. Call this whenever the user asks about their own notes, files, or projects rather than general knowledge, then ground the answer in what comes back."
    let searchDir: String
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "A short phrase or question describing what to look for.")
        let query: String
    }
    func call(arguments: Arguments) async throws -> String {
        // vault-rag ranks PARAGRAPH/section chunks (a heading + its body) via
        // NLEmbedding, so a hit is a whole quotable passage — not a stray line the
        // way line-level vault-grep returned. Its output is already readable blocks
        // ("[score] file" + the section text), so we hand it straight to the model.
        let out = runCLI(["\(binDir)/vault-rag", arguments.query,
                          "--root", searchDir, "--top", "4"], cap: 7000)
        return out == "(no output)" ? "No matching passages found in the user's notes." : out
    }
}

// ─────────────────────── tool plumbing (Priority-1 batch) ───────
// Most of the apple-* CLIs already do the real work on-device. These tools are
// thin, read-only Swift wrappers that shell to them and hand the text back to the
// model. One shared runner: optional stdin (fed on a background thread to avoid a
// pipe deadlock), drained stdout, capped so a big result can't blow the context.
func runCLI(_ argv: [String], stdin: String? = nil, cap: Int = 4000) -> String {
    let p = Process()
    p.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    p.arguments = argv
    let outPipe = Pipe()
    p.standardOutput = outPipe
    p.standardError = FileHandle.nullDevice
    var inPipe: Pipe?
    if stdin != nil { inPipe = Pipe(); p.standardInput = inPipe }
    do { try p.run() } catch { return "tool could not run: \(error)" }
    if let inPipe, let data = stdin?.data(using: .utf8) {
        DispatchQueue.global().async {
            inPipe.fileHandleForWriting.write(data)
            try? inPipe.fileHandleForWriting.close()
        }
    }
    let data = outPipe.fileHandleForReading.readDataToEndOfFile()
    p.waitUntilExit()
    let s = (String(data: data, encoding: .utf8) ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if s.isEmpty { return "(no output)" }
    return s.count > cap ? String(s.prefix(cap)) + "\n[truncated]" : s
}

struct ReadFileTool: Tool {
    let name = "readFile"
    let description = "Read a file from disk and return its text — works for text, PDF, RTF, and images (OCR). Use to read a path, often one returned by semantic_search, so you can quote the full passage."
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "Absolute path to the file to read.")
        let path: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["\(binDir)/file-to-text", arguments.path])
    }
}

struct OCRTool: Tool {
    let name = "ocr"
    let description = "Run on-device OCR (Apple Vision) on an image or scanned PDF and return the recognized text. Use when the user asks what a screenshot, photo, or scanned document says."
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "Absolute path to the image or PDF to OCR.")
        let path: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["\(binDir)/vision-ocr", arguments.path])
    }
}

struct EntitiesTool: Tool {
    let name = "entities"
    let description = "Extract named entities — people, places, organizations — from a piece of text. Pass the text to analyze."
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "The text to analyze for named entities.")
        let text: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["\(binDir)/apple-ner", "--table"], stdin: arguments.text)
    }
}

struct KeywordsTool: Tool {
    let name = "keywords"
    let description = "Return the most meaningful keywords/terms in a piece of text, ranked. Use to get the gist or topic of some text."
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "The text to extract keywords from.")
        let text: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["\(binDir)/apple-keywords"], stdin: arguments.text)
    }
}

struct TranslateTool: Tool {
    let name = "translate"
    let description = "Translate text into another language on-device (Apple Translation). Give the text and a target language code."
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "The text to translate.")
        let text: String
        @Guide(description: "Target language code, e.g. en, fi, sv, de, fr.")
        let to: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["\(binDir)/apple-translate", "--to", arguments.to, "--from", "auto"], stdin: arguments.text)
    }
}

struct SentimentTool: Tool {
    let name = "sentiment"
    let description = "Score the sentiment/tone of a piece of text (positive vs negative). Use for triage or to gauge how a message reads."
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "The text to score.")
        let text: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["\(binDir)/apple-sentiment", "--doc"], stdin: arguments.text)
    }
}

struct ImageSimilarTool: Tool {
    let name = "imageSimilar"
    let description = "Find images visually similar to a query image within a folder (Apple Vision feature-prints). Use for 'find the screenshot like this' or duplicate detection."
    let binDir: String
    @Generable struct Arguments {
        @Guide(description: "Absolute path to the query image.")
        let image: String
        @Guide(description: "Absolute path to the folder to search.")
        let folder: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["\(binDir)/apple-image-similar", "--query", arguments.image,
                "--dir", arguments.folder, "--top", "5"])
    }
}

struct SpotlightTool: Tool {
    let name = "spotlight"
    let description = "Find files on this Mac by name or content using Spotlight, returning matching paths. Use to locate a file the user describes."
    @Generable struct Arguments {
        @Guide(description: "The search query — a file name or content keywords.")
        let query: String
    }
    func call(arguments: Arguments) async throws -> String {
        runCLI(["mdfind", arguments.query], cap: 2000)
    }
}

struct FleetStatusTool: Tool {
    let name = "fleetStatus"
    let description = "Report which fleet workers (OCR, transcription, FoundationModels, mirror, pakettibot) are alive and what they're doing, from their heartbeat files. Call when asked if the Mini or a service is busy or OK."
    @Generable struct Arguments {}
    func call(arguments: Arguments) async throws -> String {
        let dir = URL(fileURLWithPath: "\(NSHomeDirectory())/work/comms/queue")
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil) else {
            return "No fleet queue directory found."
        }
        let beats = files.filter { $0.lastPathComponent.hasSuffix("-heartbeat.json") }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
        if beats.isEmpty { return "No heartbeats found." }
        let now = Date()
        let iso = ISO8601DateFormatter()
        var lines: [String] = []
        for f in beats {
            let name = f.lastPathComponent.replacingOccurrences(of: "-heartbeat.json", with: "")
            guard let data = try? Data(contentsOf: f),
                  let obj = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }
            var age = "?"
            if let ts = obj["ts"] as? Double { age = "\(Int(now.timeIntervalSince1970 - ts))s ago" }
            else if let s = obj["ts"] as? String, let d = iso.date(from: s) { age = "\(Int(now.timeIntervalSince(d)))s ago" }
            let status = (obj["status"] as? String).map { " [\($0)]" } ?? ""
            let job = (obj["current_job"] as? String).map { " job: \($0)" } ?? ""
            lines.append("\(name): \(age)\(status)\(job)")
        }
        return lines.isEmpty ? "No readable heartbeats." : lines.joined(separator: "\n")
    }
}

struct HomeClimateTool: Tool {
    let name = "homeClimate"
    let description = "Report the latest temperature and humidity at home from the HomePod sensor. Call when asked about the temperature or humidity at home."
    @Generable struct Arguments {}
    func call(arguments: Arguments) async throws -> String {
        let dir = URL(fileURLWithPath: "\(NSHomeDirectory())/work/comms/queue/homepod-climate")
        guard let files = try? FileManager.default.contentsOfDirectory(at: dir, includingPropertiesForKeys: nil),
              let latest = files.filter({ $0.pathExtension == "jsonl" })
                  .sorted(by: { $0.lastPathComponent < $1.lastPathComponent }).last,
              let content = try? String(contentsOf: latest, encoding: .utf8) else {
            return "No HomePod climate data found."
        }
        guard let last = content.split(separator: "\n").last(where: { !$0.isEmpty }),
              let data = last.data(using: .utf8),
              let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Could not read the latest climate reading."
        }
        let t = o["temperature_cal"] ?? o["temperature_c"] ?? "?"
        let h = o["humidity_cal"] ?? o["humidity_pct"] ?? "?"
        let ts = (o["timestamp"] as? String) ?? ""
        return "Home climate\(ts.isEmpty ? "" : " (as of \(ts))"): \(t)°C, \(h)% humidity."
    }
}

// ── generate (async bridged to the CLI via a semaphore) ──
let groundingTools: [any Tool] = [
    CurrentDateTimeTool(), CalculatorTool(), UnitConvertTool(), SystemStateTool(),
    WebReaderTool(), SemanticSearchTool(searchDir: searchDir, binDir: binDir),
    ReadFileTool(binDir: binDir), OCRTool(binDir: binDir),
    EntitiesTool(binDir: binDir), KeywordsTool(binDir: binDir),
    TranslateTool(binDir: binDir), SentimentTool(binDir: binDir),
    ImageSimilarTool(binDir: binDir), SpotlightTool(),
    FleetStatusTool(), HomeClimateTool(),
]
let toolHint = "\n\nYou can call tools: currentDateTime, calculator, unitConvert, systemState, "
    + "webReader, semantic_search, readFile, ocr, entities, keywords, translate, sentiment, "
    + "imageSimilar, spotlight, fleetStatus, homeClimate. Use them — for the date/time, arithmetic, "
    + "unit conversions, machine status, reading a web page, searching the user's own notes, reading a "
    + "file or OCRing an image, extracting entities/keywords, translating, scoring sentiment, finding "
    + "similar images, locating files with Spotlight, fleet worker status, and the home temperature — "
    + "rather than guessing."

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
