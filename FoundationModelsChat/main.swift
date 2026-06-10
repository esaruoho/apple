// FoundationModelsChat — a whitelabeled, on-device chat app for Apple's
// FoundationModels LLM. Runs the model IN-PROCESS on the user's own Apple
// Silicon Mac (macOS 26 + Apple Intelligence). No network, no accounts, no
// per-token cost. Every prompt and reply is autosaved. Drag in a PDF or text
// file and it's read and sent. Math renders as MathML via WebKit (Apple-native).
//
// Apple-native pedigree: AppKit, WebKit, FoundationModels, PDFKit, Vision,
// ImageIO — system frameworks only. No third-party code, no bundled JS.

import AppKit
import WebKit
import FoundationModels
import PDFKit
import Vision
import ImageIO
import UniformTypeIdentifiers
import NaturalLanguage
#if canImport(ImagePlayground)
import ImagePlayground   // on-device Image Playground (macOS 15.4+) — the prose's
                         // visual twin: prose from FoundationModels, picture here.
#endif

// Markdown renderer (escapeHTML/regexReplace/latexToMathML/renderMessageHTML/inlineMD)
// lives in Markdown.swift — compiled together; testable headlessly via markdown-tests.swift.

// ─────────────────────── file → text extraction ────────────────

func ocrCGImage(_ cg: CGImage) -> String {
    let req = VNRecognizeTextRequest()
    req.recognitionLevel = .accurate
    req.usesLanguageCorrection = true
    let handler = VNImageRequestHandler(cgImage: cg, options: [:])
    try? handler.perform([req])
    let obs = req.results ?? []
    return obs.compactMap { $0.topCandidates(1).first?.string }.joined(separator: "\n")
}

func cgImage(from url: URL) -> CGImage? {
    guard let src = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    return CGImageSourceCreateImageAtIndex(src, 0, nil)
}

func ocrPDF(_ doc: PDFDocument, maxPages: Int = 25) -> String {
    var out = ""
    for idx in 0..<min(doc.pageCount, maxPages) {
        guard let page = doc.page(at: idx) else { continue }
        let rect = page.bounds(for: .mediaBox)
        let scale: CGFloat = 2.0
        let w = Int(rect.width * scale), h = Int(rect.height * scale)
        guard w > 0, h > 0,
              let ctx = CGContext(data: nil, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
        else { continue }
        ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
        ctx.fill(CGRect(x: 0, y: 0, width: w, height: h))
        ctx.scaleBy(x: scale, y: scale)
        page.draw(with: .mediaBox, to: ctx)
        if let cg = ctx.makeImage() { out += ocrCGImage(cg) + "\n" }
    }
    return out
}

/// (extractedText, filename) or nil.
func extractText(from url: URL) -> (String, String)? {
    let ext = url.pathExtension.lowercased()
    let name = url.lastPathComponent
    let textExt: Set<String> = ["txt","text","md","markdown","mdown","csv","tsv","json","jsonl",
                                 "log","conf","cfg","ini","yaml","yml","xml","srt","vtt","tex",
                                 "rst","org","swift","py","js","ts","c","h","cpp","rb","go","rs","sh","lua"]
    if textExt.contains(ext), let s = try? String(contentsOf: url, encoding: .utf8) { return (s, name) }

    let richExt: Set<String> = ["rtf","rtfd","doc","docx","odt","html","htm","webarchive"]
    if richExt.contains(ext),
       let a = try? NSAttributedString(url: url, options: [:], documentAttributes: nil) {
        return (a.string, name)
    }
    if ext == "pdf", let doc = PDFDocument(url: url) {
        let s = doc.string ?? ""
        if s.trimmingCharacters(in: .whitespacesAndNewlines).count > 20 { return (s, name) }
        let ocr = ocrPDF(doc)
        if !ocr.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return (ocr, name) }
    }
    let imgExt: Set<String> = ["png","jpg","jpeg","tiff","tif","heic","heif","gif","bmp","webp"]
    if imgExt.contains(ext), let cg = cgImage(from: url) { return (ocrCGImage(cg), name) }

    if let s = try? String(contentsOf: url, encoding: .utf8) { return (s, name) }
    return nil
}

// ─────────────────────── autosave ──────────────────────────────

final class SessionStore {
    let dir: URL
    let mdURL: URL
    let jsonlURL: URL
    let stamp: String

    init() {
        let fmt = DateFormatter()
        fmt.dateFormat = "yyyy-MM-dd-HHmmss"
        stamp = fmt.string(from: Date())
        let base = (FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
                    ?? URL(fileURLWithPath: NSHomeDirectory()))
            .appendingPathComponent("FoundationModelsChat")
        dir = base.appendingPathComponent(stamp)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        mdURL = dir.appendingPathComponent("chat-\(stamp).md")
        jsonlURL = dir.appendingPathComponent("events.jsonl")
        appendString("# FoundationModels Chat — \(stamp)\n\n", to: mdURL)
    }

    private func appendString(_ s: String, to url: URL) {
        guard let data = s.data(using: .utf8) else { return }
        if let h = try? FileHandle(forWritingTo: url) {
            h.seekToEndOfFile(); h.write(data); try? h.close()
        } else {
            try? data.write(to: url)
        }
    }

    /// Continuous save: append to the human-readable .md AND the event log.
    func log(role: String, text: String) {
        let who = role == "user" ? "You" : "FoundationModels"
        appendString("**\(who):**\n\n\(text)\n\n", to: mdURL)
        let iso = ISO8601DateFormatter().string(from: Date())
        let obj: [String: Any] = ["t": iso, "role": role, "text": text]
        if let d = try? JSONSerialization.data(withJSONObject: obj),
           let line = String(data: d, encoding: .utf8) {
            appendString(line + "\n", to: jsonlURL)
        }
    }
}

// ─────────────────────── tools (borrowed pattern) ──────────────
// FoundationModels can call into our own code mid-reply. WebReaderTool lets the
// model fetch a web page the user names and read its text. Dimillian's reference
// app does this with SwiftSoup (third-party); we stay Apple-native: URLSession to
// fetch, NSAttributedString's HTML importer to turn markup into readable text.


// ───────── ported from bin/fm.swift for CLI⇄GUI parity (15 tools) ─────────
// ── ToolEnv: where the ported tools find the apple bin/ + the RAG corpus.
// Whitelabel-safe: NSHomeDirectory() (no hardcoded username), env-overridable.
enum ToolEnv {
    static let binDir = ProcessInfo.processInfo.environment["FM_BIN_DIR"]
        ?? "\(NSHomeDirectory())/work/apple/bin"
    static let searchDir = ProcessInfo.processInfo.environment["FM_SEARCH_DIR"]
        ?? "\(NSHomeDirectory())/work/apple/wiki"
}

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
struct SemanticSearchTool: Tool {
    let name = "semantic_search"
    let description = "Search the user's own notes and documents for passages related in meaning to a query and return ranked snippets with their file locations. Call this whenever the user asks about their own notes, files, or projects rather than general knowledge. Each result is a SHORT snippet plus a file path — when you need to quote or summarize a result in any depth, call the readFile tool on that path to read the full passage before answering. Always ground the answer in what comes back, and cite the file."
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

/// Append a timestamped line to ~/Documents/FoundationModelsChat/debug.log so the
/// whole pipeline (input, detected language, model input, RAW reply, translation,
/// errors) can be inspected after the fact — snoop it with `tail -f` or over ssh.
func dlog(_ s: String) {
    let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        .appendingPathComponent("FoundationModelsChat", isDirectory: true)
    try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    let url = dir.appendingPathComponent("debug.log")
    let line = "[\(ISO8601DateFormatter().string(from: Date()))] \(s)\n"
    if let h = try? FileHandle(forWritingTo: url) {
        defer { try? h.close() }
        h.seekToEndOfFile(); h.write(Data(line.utf8))
    } else {
        try? line.write(to: url, atomically: true, encoding: .utf8)
    }
}

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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
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

@available(macOS 26.0, *)
func fmTools() -> [any Tool] {
    [
        WebReaderTool(),
        CurrentDateTimeTool(), CalculatorTool(), UnitConvertTool(), SystemStateTool(),
        SemanticSearchTool(searchDir: ToolEnv.searchDir, binDir: ToolEnv.binDir),
        ReadFileTool(binDir: ToolEnv.binDir), OCRTool(binDir: ToolEnv.binDir),
        EntitiesTool(binDir: ToolEnv.binDir), KeywordsTool(binDir: ToolEnv.binDir),
        TranslateTool(binDir: ToolEnv.binDir), SentimentTool(binDir: ToolEnv.binDir),
        ImageSimilarTool(binDir: ToolEnv.binDir), SpotlightTool(),
        FleetStatusTool(), HomeClimateTool(),
    ]
}
// ───────── end ported tools ─────────

@available(macOS 26.0, *)
struct WebReaderTool: Tool {
    let name = "WebReader"
    let description = "Fetch ONE web page's readable text. Call this ONLY when the user's message contains an explicit http:// or https:// URL to fetch. Never call it to find sources, verify claims, or look something up when there is no literal URL in the message."

    @Generable
    struct Arguments {
        @Guide(description: "The absolute URL to fetch, including the https:// scheme")
        let url: String
    }

    // String conforms to PromptRepresentable, so it's a valid Tool.Output — no
    // need for the ToolOutput wrapper shown in older docs.
    func call(arguments: Arguments) async throws -> String {
        guard let url = URL(string: arguments.url),
              let scheme = url.scheme?.lowercased(), scheme == "http" || scheme == "https" else {
            return "Not a valid http(s) URL: \(arguments.url)"
        }
        var req = URLRequest(url: url)
        req.timeoutInterval = 20
        req.setValue("Mozilla/5.0 (Macintosh) FoundationModelsChat", forHTTPHeaderField: "User-Agent")
        let (data, resp) = try await URLSession.shared.data(for: req)
        let status = (resp as? HTTPURLResponse)?.statusCode ?? 0
        guard (200..<300).contains(status) else {
            return "Could not fetch \(arguments.url) (HTTP \(status))."
        }
        let title = Self.extractTitle(data)
        // NSAttributedString's HTML importer must run on the main thread.
        let body = await MainActor.run { () -> String in
            let opts: [NSAttributedString.DocumentReadingOptionKey: Any] = [
                .documentType: NSAttributedString.DocumentType.html,
                .characterEncoding: String.Encoding.utf8.rawValue]
            if let a = try? NSAttributedString(data: data, options: opts, documentAttributes: nil) {
                return a.string
            }
            return String(data: data, encoding: .utf8) ?? ""
        }
        let cleaned = body.replacingOccurrences(of: "\n{3,}", with: "\n\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        // Respect the on-device model's small context window — cap the payload.
        let capped = String(cleaned.prefix(6000))
        var out = title.isEmpty ? "" : "Title: \(title)\n\n"
        out += capped
        if cleaned.count > capped.count { out += "\n\n[truncated]" }
        return out
    }

    private static func extractTitle(_ data: Data) -> String {
        guard let html = String(data: data, encoding: .utf8),
              let m = html.range(of: "<title[^>]*>(.*?)</title>",
                                 options: [.regularExpression, .caseInsensitive]) else { return "" }
        return String(html[m])
            .replacingOccurrences(of: "<title[^>]*>", with: "", options: [.regularExpression, .caseInsensitive])
            .replacingOccurrences(of: "</title>", with: "", options: [.regularExpression, .caseInsensitive])
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

// ─────────────────────── FoundationModels ──────────────────────

final class FM {
    enum Backend { case local, remote(URL), none }

    // sessionBox holds a LanguageModelSession on macOS 26+ (set in #available).
    private var sessionBox: Any?
    private(set) var backend: Backend = .none
    private(set) var reason = ""
    var available: Bool { if case .none = backend { return false }; return true }

    init() {
        if #available(macOS 26.0, *), case .available = SystemLanguageModel.default.availability {
            let session = LanguageModelSession(model: FM.permissiveModel, instructions:FM.fullInstructions)
            session.prewarm()   // warm the model so the first reply isn't slow
            sessionBox = session
            backend = .local
            return
        }
        // No local model → the loophole: a remote FoundationModels machine
        // reachable through a file-drop bridge (e.g. Syncthing to a Mac Mini on
        // macOS 26). Opt-in via config/env so the app stays whitelabeled.
        if let dir = FM.bridgeDir(),
           FileManager.default.fileExists(atPath: dir.appendingPathComponent("fm-inbox").path) {
            backend = .remote(dir)
            return
        }
        if #available(macOS 26.0, *) {
            if case .unavailable(let r) = SystemLanguageModel.default.availability { reason = "\(r)" }
        } else {
            reason = "This Mac is on an older macOS (FoundationModels needs macOS 26), and no FM bridge is configured."
        }
    }

    /// Throw away the current on-device session and start a brand-new one with
    /// no history — a true "new chat". The remote bridge is stateless (each call
    /// replays the whole convo), so clearing the caller's `convo` is enough;
    /// no-model has nothing to reset.
    func startFreshSession() {
        if #available(macOS 26.0, *), case .local = backend {
            let session = LanguageModelSession(model: FM.permissiveModel, instructions:FM.fullInstructions)
            session.prewarm()
            sessionBox = session
        }
    }

    var backendDescription: String {
        switch backend {
        case .local: return "on-device model"
        case .remote(let d): return "remote model via bridge (\(d.lastPathComponent))"
        case .none: return "unavailable"
        }
    }

    static let defaultInstructions = """
    You are a knowledgeable conversational assistant running fully on-device. You have \
    broad built-in knowledge of science, engineering, history, and general topics — \
    ANSWER FROM IT. You do NOT have, and do NOT need, the internet. NEVER reply that you \
    "can't access external resources", "can't search the web", or "can't verify" — just \
    discuss the topic directly with what you know, noting uncertainty in a normal way \
    ("I'm not certain, but…") when relevant. You ALSO help, warmly and practically, with \
    everyday emotional, well-being, motivation, relationship, and self-care questions. You \
    are not a doctor or therapist and must not diagnose or handle emergencies — but for \
    ordinary questions like "how do I love and accept myself" you MUST give kind, useful, \
    general suggestions. NEVER refuse such a question with "I can't assist with that", "I'm \
    not qualified", or "that's too sensitive" — just help. When the user pastes text and asks you to \
    discuss, critique, fact-check, or continue it, engage with that text directly in \
    your OWN words — do NOT repeat it back. Write in plain Markdown only — do NOT output \
    HTML or <math> tags; put any math in plain notation (e.g. "ΔG = +237 kJ/mol", "1.23 V"). \
    Answer only the user's most recent message, concisely, and do not fold in earlier turns unless asked.
    """

    /// The system prompt lives in a real, maintainable FILE — not opaque UserDefaults:
    ///   ~/Documents/FoundationModelsChat/system-prompt.md
    /// Human-readable, editable in-app (⇧⌘P) or in any editor, persistent, backable-up.
    static let promptFileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("FoundationModelsChat", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("system-prompt.md")
    }()

    /// The LIVE system prompt that colors every reply. Read from the file; seeded with
    /// defaultInstructions (and the file written) on first use. Saving writes the file.
    static var systemInstructions: String {
        get {
            if let s = try? String(contentsOf: promptFileURL, encoding: .utf8),
               !s.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return s
            }
            try? defaultInstructions.write(to: promptFileURL, atomically: true, encoding: .utf8)
            return defaultInstructions
        }
        set {
            let v = newValue.trimmingCharacters(in: .whitespacesAndNewlines)
            try? (v.isEmpty ? defaultInstructions : v)
                .write(to: promptFileURL, atomically: true, encoding: .utf8)
        }
    }

    /// Long-term MEMORY — a real file the chat affects and the model reads:
    ///   ~/Documents/FoundationModelsChat/memory.md
    /// Injected into the prompt every session so the model "remembers" across chats.
    /// Affect it in chat with "remember: …" / "forget: …", or the ⇧⌘M editor.
    static let memoryFileURL: URL =
        promptFileURL.deletingLastPathComponent().appendingPathComponent("memory.md")
    static var memory: String {
        get { (try? String(contentsOf: memoryFileURL, encoding: .utf8)) ?? "" }
        set { try? newValue.write(to: memoryFileURL, atomically: true, encoding: .utf8) }
    }

    /// What actually seeds each session: the system prompt + the long-term memory. Memory
    /// is capped so it can't blow the small (~4k-token) window — keep memory short.
    static var fullInstructions: String {
        let mem = memory.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !mem.isEmpty else { return systemInstructions }
        let capped = mem.count > 1500 ? "…\n" + String(mem.suffix(1500)) : mem
        return systemInstructions
            + "\n\nLong-term memory — established facts about the user from past chats. "
            + "Use them naturally; don't recite them back:\n" + capped
    }

    /// A model with RELAXED guardrails. Apple's DEFAULT guardrail blocks benign prompts
    /// like "how to love myself" / "how do I accept myself" as "unsafe" (caught in the
    /// debug log 2026-06-02 — it even fired mid-stream and ate the reply).
    /// permissiveContentTransformations is the SDK's sanctioned relaxation.
    @available(macOS 26.0, *)
    static var permissiveModel: SystemLanguageModel {
        SystemLanguageModel(guardrails: .permissiveContentTransformations)
    }

    /// Recreate the local session so an edited system prompt takes effect immediately.
    func resetSession() {
        if #available(macOS 26.0, *), case .local = backend {
            let s = LanguageModelSession(model: FM.permissiveModel, instructions: FM.fullInstructions)
            s.prewarm()
            sessionBox = s
        }
    }

    /// Configured bridge queue dir (holds fm-inbox/ + fm-outbox/). Whitelabel
    /// default is none; set ~/Library/Application Support/FoundationModelsChat/
    /// config.json {"bridgeQueueDir": "..."} or env FMCHAT_BRIDGE_DIR.
    static func bridgeDir() -> URL? {
        if let cfg = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("FoundationModelsChat/config.json"),
           let data = try? Data(contentsOf: cfg),
           let o = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let p = o["bridgeQueueDir"] as? String, !p.isEmpty {
            return URL(fileURLWithPath: (p as NSString).expandingTildeInPath)
        }
        if let env = ProcessInfo.processInfo.environment["FMCHAT_BRIDGE_DIR"], !env.isEmpty {
            return URL(fileURLWithPath: (env as NSString).expandingTildeInPath)
        }
        return nil
    }

    /// Persist (or clear, if empty) the bridge queue dir to the config file.
    static func saveBridgeDir(_ path: String) {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appendingPathComponent("FoundationModelsChat") else { return }
        try? FileManager.default.createDirectory(at: base, withIntermediateDirectories: true)
        let cfg = base.appendingPathComponent("config.json")
        let obj: [String: Any] = ["bridgeQueueDir": path]
        if let d = try? JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted) {
            try? d.write(to: cfg)
        }
    }

    /// Ask the model. `latest` is the new prompt (used by the stateful local
    /// session); `history` is the full dialogue (replayed for the stateless
    /// remote worker so it remembers too).
    func ask(history: [(role: String, text: String)], latest: String,
             completion: @escaping (Result<String, Error>) -> Void) {
        func fail(_ msg: String) {
            completion(.failure(NSError(domain: "FM", code: 1,
                userInfo: [NSLocalizedDescriptionKey: msg])))
        }
        switch backend {
        case .local:
            if #available(macOS 26.0, *), let session = sessionBox as? LanguageModelSession {
                Task {
                    do {
                        let content = try await session.respond(to: latest).content
                        await MainActor.run { completion(.success(content)) }
                    } catch { await MainActor.run { completion(.failure(error)) } }
                }
            } else { fail("model unavailable") }
        case .remote(let dir):
            remoteAsk(dir, replay: FM.renderReplay(history), completion: completion)
        case .none:
            fail(reason.isEmpty ? "model unavailable" : reason)
        }
    }

    /// Stream a reply from the LOCAL session: `onPartial` fires with the growing
    /// text as it's generated, `completion` fires once with the final text (or an
    /// error). The remote bridge is request/response (file-drop), so for it — and
    /// when there's no model — we fall back to the one-shot `ask`.
    /// The in-flight local streaming task, so ESC can abort a generation.
    var streamTask: Task<Void, Never>?
    func cancelStreaming() { streamTask?.cancel() }

    func askStreaming(latest: String, history: [(role: String, text: String)],
                      onPartial: @escaping (String) -> Void,
                      completion: @escaping (Result<String, Error>) -> Void) {
        if case .local = backend, #available(macOS 26.0, *),
           let session = sessionBox as? LanguageModelSession {
            streamTask = Task {
                do {
                    let out = try await FM.runStream(session, prompt: latest, onPartial: onPartial)
                    await MainActor.run { completion(.success(out)) }
                } catch LanguageModelSession.GenerationError.exceededContextWindowSize {
                    // The 4096-token window filled. Summarize what came before,
                    // rebuild a fresh tool-enabled session seeded with that summary,
                    // and retry the prompt once.
                    await MainActor.run { onPartial("…context was full — condensing and retrying…") }
                    do {
                        let fresh = await self.rebuildLocalSession(history: history)
                        let out = try await FM.runStream(fresh, prompt: latest, onPartial: onPartial)
                        await MainActor.run { completion(.success(out)) }
                    } catch {
                        await MainActor.run { completion(.failure(error)) }
                    }
                } catch {
                    await MainActor.run { completion(.failure(error)) }
                }
            }
        } else {
            ask(history: history, latest: latest, completion: completion)
        }
    }

    /// Drive one streaming response, forwarding each cumulative snapshot to the UI.
    @available(macOS 26.0, *)
    private static func runStream(_ session: LanguageModelSession, prompt: String,
                                  onPartial: @escaping (String) -> Void) async throws -> String {
        var last = ""
        do {
            for try await snapshot in session.streamResponse(to: prompt) {
                if Task.isCancelled { break }   // ESC aborted — keep what streamed so far
                let cur = snapshot.content   // cumulative text so far
                last = cur
                await MainActor.run { onPartial(cur) }
            }
        } catch is CancellationError {
            // user pressed ESC: stop streaming, return the partial text
        }
        return last
    }

    /// Build a new local session seeded with a short summary of the prior turns,
    /// so context survives once the on-device window overflows. Best-effort: if the
    /// summary call fails we still return a fresh session, which unblocks the user.
    @available(macOS 26.0, *)
    private func rebuildLocalSession(history: [(role: String, text: String)]) async -> LanguageModelSession {
        let transcript = history
            .filter { $0.role == "user" || $0.role == "assistant" }
            .map { "\($0.role == "user" ? "User" : "Assistant"): \($0.text)" }
            .joined(separator: "\n")
        var summary = ""
        let summarizer = LanguageModelSession(model: FM.permissiveModel, instructions:
            "Summarize the conversation in 4-6 sentences, preserving names, facts, numbers, and the current task.")
        if let r = try? await summarizer.respond(to: "Conversation:\n\(transcript)") { summary = r.content }
        let instr = summary.isEmpty ? FM.fullInstructions
            : FM.fullInstructions + "\n\nEarlier context summary:\n" + summary
        let seeded = LanguageModelSession(model: FM.permissiveModel, instructions:instr)
        seeded.prewarm()
        sessionBox = seeded
        return seeded
    }

    /// "User: …\nAssistant: …\nUser: <new>\nAssistant:" — gives the stateless
    /// remote worker the whole conversation so it remembers.
    static func renderReplay(_ history: [(role: String, text: String)]) -> String {
        var lines: [String] = []
        for (role, text) in history where role == "user" || role == "assistant" {
            lines.append("\(role == "user" ? "User" : "Assistant"): \(text)")
        }
        lines.append("Assistant:")
        return lines.joined(separator: "\n")
    }

    private func remoteAsk(_ dir: URL, replay: String,
                           completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let inbox = dir.appendingPathComponent("fm-inbox")
            let outbox = dir.appendingPathComponent("fm-outbox")
            try? FileManager.default.createDirectory(at: inbox, withIntermediateDirectories: true)
            let id = "fmchat-\(Int(Date().timeIntervalSince1970))-\(UUID().uuidString.prefix(6))"
            let spec: [String: Any] = ["id": id, "prompt": replay,
                                       "system": FM.systemInstructions,
                                       "submitter_host": Host.current().localizedName ?? "FMChat"]
            let tmp = inbox.appendingPathComponent(".\(id).tmp")
            let final = inbox.appendingPathComponent("\(id).json")
            guard let data = try? JSONSerialization.data(withJSONObject: spec) else {
                DispatchQueue.main.async { completion(.failure(NSError(domain: "FM", code: 3))) }; return
            }
            do { try data.write(to: tmp); try FileManager.default.moveItem(at: tmp, to: final) }
            catch { DispatchQueue.main.async { completion(.failure(error)) }; return }

            let result = outbox.appendingPathComponent("\(id).json")
            let deadline = Date().addingTimeInterval(150)
            while Date() < deadline {
                if let d = try? Data(contentsOf: result),
                   let obj = try? JSONSerialization.jsonObject(with: d) as? [String: Any] {
                    try? FileManager.default.removeItem(at: result)
                    if (obj["ok"] as? Bool) == true {
                        var out = (obj["out"] as? String ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
                        if out.lowercased().hasPrefix("assistant:") {
                            out = String(out.dropFirst("assistant:".count)).trimmingCharacters(in: .whitespacesAndNewlines)
                        }
                        DispatchQueue.main.async { completion(.success(out)) }
                    } else {
                        let e = (obj["err"] as? String ?? "remote error")
                        DispatchQueue.main.async {
                            completion(.failure(NSError(domain: "FM", code: 4,
                                userInfo: [NSLocalizedDescriptionKey: e])))
                        }
                    }
                    return
                }
                Thread.sleep(forTimeInterval: 1.0)
            }
            DispatchQueue.main.async {
                completion(.failure(NSError(domain: "FM", code: 5, userInfo: [NSLocalizedDescriptionKey:
                    "timed out waiting on the bridge (\(dir.path)). Is fm-worker running on the remote Mac?"])))
            }
        }
    }
}

// ─────────────────────── drag-drop view ────────────────────────

final class DropView: NSView {
    var onDrop: (([URL]) -> Void)?
    override func draggingEntered(_ s: NSDraggingInfo) -> NSDragOperation {
        s.draggingPasteboard.canReadObject(forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]) ? .copy : []
    }
    override func performDragOperation(_ s: NSDraggingInfo) -> Bool {
        guard let urls = s.draggingPasteboard.readObjects(forClasses: [NSURL.self],
            options: [.urlReadingFileURLsOnly: true]) as? [URL], !urls.isEmpty else { return false }
        onDrop?(urls)
        return true
    }
}

// ─────────────────────── app ───────────────────────────────────

/// Calls `done(webView)` once a WKWebView finishes loading, after a short tick so
/// layout settles — used by the PDF export to print only after content is ready.
final class LoadDoneDelegate: NSObject, WKNavigationDelegate {
    let done: (WKWebView) -> Void
    init(_ done: @escaping (WKWebView) -> Void) { self.done = done }
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak webView] in
            guard let webView = webView else { return }
            self.done(webView)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!
    var inputView: NSTextView!
    var sendButton: NSButton!
    var mdButton: NSButton!
    var pdfButton: NSButton!
    var pdfExportWeb: WKWebView?         // offscreen webview kept alive during PDF render
    var pdfExportDelegate: AnyObject?    // its nav delegate, kept alive too
    var pdfExportWindow: NSWindow?       // offscreen host window — print needs one
    let fm = FM()
    var store = SessionStore()
    var messages: [(role: String, text: String)] = []   // what's shown (display text)
    var convo: [(role: String, text: String)] = []       // what was actually sent (for remote replay)
    var busy = false
    var escMonitor: Any?

    // When a prompt overflows the context window we stash it here and attach a
    // "start a new chat with that prompt" button to the error bubble.
    var newChatPrompt: String?       // the userText to resend
    var newChatDisplay: String?      // its display label (for file-ingest prompts)
    var newChatMsgIndex: Int?        // which bubble carries the button

    // ── Image Playground (Illustrate) ──
    // When on, every model reply is paired with an on-device Image Playground
    // picture drawn from the same prompt — so "what does a tiger look like?" gives
    // you the prose AND the tiger. The picture renders right here in this app
    // (a foreground window); ImageCreator refuses to run in a background process.
    var illustrate = false           // toggle (⌘I / Image menu)
    var illustrateStyle = "illustration"   // animation | illustration | sketch
    var illustrateItem: NSMenuItem?  // menu item whose checkmark mirrors `illustrate`
    var illustratorBox: AnyObject?   // cached ImageCreator (typed via #available)

    func applicationDidFinishLaunching(_ note: Notification) {
        let frame = NSRect(x: 0, y: 0, width: 820, height: 720)
        window = NSWindow(contentRect: frame,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered, defer: false)
        window.title = "FoundationModels Chat"
        window.center()
        window.setFrameAutosaveName("FMChatWindow")

        let root = DropView(frame: frame)
        root.autoresizingMask = [.width, .height]
        root.registerForDraggedTypes([.fileURL])
        root.onDrop = { [weak self] urls in self?.ingest(urls) }
        window.contentView = root
        // The WebView is transparent (drawsBackground=false), so paint a dark backdrop
        // behind it — otherwise the desktop shows through wherever the chat HTML doesn't reach.
        let bg = NSColor(calibratedRed: 0.055, green: 0.055, blue: 0.07, alpha: 1)
        window.backgroundColor = bg
        root.wantsLayer = true
        root.layer?.backgroundColor = bg.cgColor

        // transcript
        let webConf = WKWebViewConfiguration()
        let ucc = WKUserContentController()
        ucc.add(self, name: "fmchat")   // HTML buttons post back here
        webConf.userContentController = ucc
        webView = WKWebView(frame: NSRect(x: 0, y: 110, width: root.bounds.width, height: max(root.bounds.height - 110, 100)), configuration: webConf)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        root.addSubview(webView)

        // input
        let inputScroll = NSScrollView(frame: NSRect(x: 12, y: 12, width: max(root.bounds.width - 130, 100), height: 88))
        inputScroll.autoresizingMask = [.width]
        inputScroll.hasVerticalScroller = true
        inputScroll.borderType = .lineBorder
        inputView = NSTextView(frame: inputScroll.bounds)
        inputView.autoresizingMask = [.width]
        inputView.font = NSFont.systemFont(ofSize: 14)
        inputView.isRichText = false
        inputView.delegate = self
        inputView.textContainerInset = NSSize(width: 6, height: 6)
        inputScroll.documentView = inputView
        root.addSubview(inputScroll)

        sendButton = NSButton(frame: NSRect(x: root.bounds.width - 108, y: 42, width: 96, height: 58))
        sendButton.autoresizingMask = [.minXMargin]
        sendButton.title = "Send"
        sendButton.bezelStyle = .rounded
        sendButton.keyEquivalent = "\r"
        sendButton.target = self
        sendButton.action = #selector(sendTapped)
        root.addSubview(sendButton)

        // Export this conversation, verbatim. .md = the labelled transcript; .pdf =
        // the same content rendered (lists/code/headings/math preserved). Both also
        // available from the File menu (⌘E / ⇧⌘E).
        mdButton = NSButton(frame: NSRect(x: root.bounds.width - 108, y: 12, width: 46, height: 24))
        mdButton.autoresizingMask = [.minXMargin]
        mdButton.title = ".md"
        mdButton.bezelStyle = .rounded
        mdButton.font = NSFont.systemFont(ofSize: 11)
        mdButton.toolTip = "Export conversation as Markdown (⌘E)"
        mdButton.target = self
        mdButton.action = #selector(exportMarkdown)
        root.addSubview(mdButton)

        pdfButton = NSButton(frame: NSRect(x: root.bounds.width - 58, y: 12, width: 46, height: 24))
        pdfButton.autoresizingMask = [.minXMargin]
        pdfButton.title = ".pdf"
        pdfButton.bezelStyle = .rounded
        pdfButton.font = NSFont.systemFont(ofSize: 11)
        pdfButton.toolTip = "Export conversation as PDF (⇧⌘E)"
        pdfButton.target = self
        pdfButton.action = #selector(exportPDF)
        root.addSubview(pdfButton)

        // ESC aborts an in-flight answer and re-enables Send so you can start over.
        escMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return event }
            if event.keyCode == 53, self.busy {   // 53 = Escape
                self.fm.cancelStreaming()
                self.busy = false
                self.sendButton.isEnabled = true
                return nil   // consume ESC
            }
            return event
        }

        buildMenu()
        render()
        window.makeKeyAndOrderFront(nil)
        window.makeFirstResponder(inputView)
        NSApp.activate(ignoringOtherApps: true)

        switch fm.backend {
        case .local:
            appendAssistant("On-device model ready. Type below, or drag in a **PDF / text file** and press Send. Everything is saved to `~/Documents/FoundationModelsChat/`.")
        case .remote(let d):
            appendAssistant("This Mac has no local model — connected to **FoundationModels on a remote Mac** via the bridge at `\(d.path)`. Replies come back over that channel. Type below or drag a file in.")
        case .none:
            appendAssistant("⚠️ No FoundationModels here.\n\n\(fm.reason)\n\n**Two ways to fix it:**\n1. Run this app on an **Apple Silicon Mac on macOS 26** with **Apple Intelligence** enabled, or\n2. **Connect to a Mac that has it** — menu **Connect ▸ Connect to a Mac…**, and point it at a folder shared with that Mac (e.g. a Syncthing queue dir). That Mac runs the worker; this app sends prompts there and shows the replies.")
        }

        if ProcessInfo.processInfo.environment["FMCHAT_SIMULATE_OVERFLOW"] != nil {
            simulateOverflow()
        }
    }

    @objc func connectToMac() {
        let alert = NSAlert()
        alert.messageText = "Connect to a Mac with FoundationModels"
        alert.informativeText = "Enter the path to a folder this Mac SHARES with the Mac that has the model (e.g. a Syncthing-synced queue dir). That Mac must run the fm-worker. This app drops prompts in <folder>/fm-inbox and reads replies from <folder>/fm-outbox.\n\nLeave blank and OK to clear (use local only)."
        alert.addButton(withTitle: "Save & Reconnect")
        alert.addButton(withTitle: "Cancel")
        let field = NSTextField(frame: NSRect(x: 0, y: 0, width: 460, height: 24))
        field.placeholderString = "/Users/you/path/to/shared/queue"
        field.stringValue = FM.bridgeDir()?.path ?? ""
        alert.accessoryView = field
        alert.window.initialFirstResponder = field
        guard alert.runModal() == .alertFirstButtonReturn else { return }
        FM.saveBridgeDir(field.stringValue.trimmingCharacters(in: .whitespaces))
        // Re-evaluate the backend with the new setting.
        let restart = NSAlert()
        restart.messageText = "Saved."
        restart.informativeText = "Quit and reopen FoundationModelsChat to connect with the new setting."
        restart.runModal()
    }

    // HTML → Swift bridge. The overflow bubble's button posts "newchat".
    func userContentController(_ ucc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard message.name == "fmchat", (message.body as? String) == "newchat" else { return }
        startNewChatFromOverflow()
    }

    /// Tear down the current chat and start a clean one: fresh on-device session,
    /// empty history, and a NEW timestamped transcript on disk (the previous one
    /// stays saved). Returns the previous transcript dir so callers can show it.
    @discardableResult
    func beginNewChat() -> String {
        let prevDir = store.dir.path
        newChatPrompt = nil; newChatDisplay = nil; newChatMsgIndex = nil
        fm.startFreshSession()
        store = SessionStore()          // fresh transcript on disk; old one preserved
        messages.removeAll()
        convo.removeAll()
        return prevDir
    }

    /// ⌘N — start a new conversation. The previous one is already fully saved.
    @objc func newChatMenu() {
        guard !busy else { return }
        let prev = beginNewChat()
        render()
        appendAssistant("🆕 New chat. The previous conversation is saved to `\(prev)`.")
    }

    /// ⇧⌘P — view/edit the system prompt that colors every reply. Save applies it to a
    /// fresh chat so you can watch how the prompt changes the model's behavior.
    /// ⇧⌘M — view/edit the long-term memory the model is given every session.
    @objc func editMemory() {
        let alert = NSAlert()
        alert.messageText = "Long-Term Memory"
        alert.informativeText = "Facts the model is given every session (stored at ~/Documents/FoundationModelsChat/memory.md; you can also add them in chat with \"remember: …\"). Edit + Save; takes effect on the next message. Keep it short — it counts against the context window."
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 540, height: 260))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let tv = NSTextView(frame: NSRect(x: 0, y: 0, width: 540, height: 260))
        tv.isEditable = true
        tv.isRichText = false
        tv.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.string = FM.memory
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.autoresizingMask = [.width, .height]
        scroll.documentView = tv
        alert.accessoryView = scroll
        alert.addButton(withTitle: "Save")
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        let r = alert.runModal()
        if r == .alertFirstButtonReturn {
            FM.memory = tv.string; fm.resetSession()
            appendAssistant("🧠 Memory updated — it'll color replies from now on.")
        } else if r == .alertSecondButtonReturn {
            FM.memory = ""; fm.resetSession()
            appendAssistant("🧠 Memory cleared.")
        }
    }

    @objc func editSystemPrompt() {
        let alert = NSAlert()
        alert.messageText = "System Prompt"
        alert.informativeText = "Stored at ~/Documents/FoundationModelsChat/system-prompt.md (edit here or in any editor). Sent to the model ahead of every message — it colors all replies. Save applies it and starts a fresh chat."
        let scroll = NSScrollView(frame: NSRect(x: 0, y: 0, width: 540, height: 260))
        scroll.hasVerticalScroller = true
        scroll.borderType = .bezelBorder
        let tv = NSTextView(frame: NSRect(x: 0, y: 0, width: 540, height: 260))
        tv.isEditable = true
        tv.isRichText = false
        tv.font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        tv.string = FM.systemInstructions
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.autoresizingMask = [.width, .height]
        scroll.documentView = tv
        alert.accessoryView = scroll
        alert.addButton(withTitle: "Save")             // .alertFirstButtonReturn
        alert.addButton(withTitle: "Reset to Default")  // .alertSecondButtonReturn
        alert.addButton(withTitle: "Cancel")            // .alertThirdButtonReturn
        let r = alert.runModal()
        if r == .alertFirstButtonReturn {
            FM.systemInstructions = tv.string
            fm.resetSession()
            _ = beginNewChat(); render()
            appendAssistant("✏️ System prompt updated — fresh chat started. Replies are now colored by your new prompt.")
        } else if r == .alertSecondButtonReturn {
            FM.systemInstructions = ""   // clearing the key falls back to defaultInstructions
            fm.resetSession()
            _ = beginNewChat(); render()
            appendAssistant("↩︎ System prompt reset to default — fresh chat started.")
        }
    }

    /// Start a genuinely fresh chat and re-send the exact prompt that overflowed
    /// the previous window — fired by the button on the overflow bubble.
    func startNewChatFromOverflow() {
        guard !busy, let prompt = newChatPrompt else { return }
        let display = newChatDisplay
        beginNewChat()                  // clears newChatPrompt — captured above first
        appendAssistant("🆕 New chat — re-sending the prompt that filled the previous one.")
        send(userText: prompt, display: display)
    }

    /// Debug only (env FMCHAT_SIMULATE_OVERFLOW): render the context-window
    /// dead-end + recovery button on a Mac with no on-device model (macOS <26),
    /// through the exact same friendly()/render() path the real error hits.
    func simulateOverflow() {
        // MathML render proof: LaTeX the on-device model actually emits.
        messages.append(("assistant", "Reactance: \\(X = 2 \\pi f L\\)\n\nReactive power: \\(Q = V^2 / X\\)"))
        let prompt = "show me the variable reactance, lenz law and reactive power equations."
        messages.append(("user", "…(earlier long conversation that filled the 4096-token window)…"))
        messages.append(("user", prompt))
        let err = NSError(domain: "FM", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "exceededContextWindowSize"])
        messages.append(("assistant", "⚠️ " + friendly(err)))
        newChatPrompt = prompt
        newChatDisplay = nil
        newChatMsgIndex = messages.count - 1
        render()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ s: NSApplication) -> Bool { true }

    // ─────────────────────── Image Playground (Illustrate) ──────────────────
    // The visual twin of the prose path. FoundationModels (possibly on the Mini)
    // answers in words; Image Playground (always local — it needs THIS foreground
    // window) draws the same subject. They run concurrently.
    // FEATURE-CARD >> features/image-playground.feature

    @objc func toggleIllustrate() {
        illustrate.toggle()
        illustrateItem?.state = illustrate ? .on : .off
        appendAssistant(illustrate
            ? "🖼 **Illustrate is ON** — each reply now comes with an Image Playground picture drawn from your prompt. (Style: \(illustrateStyle). Keep this window in front while it draws.)"
            : "🖼 Illustrate is OFF.")
    }

    @objc func setIllustrateStyle(_ sender: NSMenuItem) {
        illustrateStyle = sender.title.lowercased()
        if let menu = sender.menu {
            for it in menu.items where it.action == #selector(setIllustrateStyle(_:)) {
                it.state = (it === sender) ? .on : .off
            }
        }
    }

    /// Encode a CGImage as a self-contained PNG data: URI so it renders in the
    /// WebView without file-system read access (the transcript loads with baseURL nil).
    func pngDataURI(_ cg: CGImage) -> String? {
        let data = NSMutableData()
        guard let dest = CGImageDestinationCreateWithData(
            data as CFMutableData, UTType.png.identifier as CFString, 1, nil) else { return nil }
        CGImageDestinationAddImage(dest, cg, nil)
        guard CGImageDestinationFinalize(dest) else { return nil }
        return "data:image/png;base64," + (data as Data).base64EncodedString()
    }

    func illustrateFriendly(_ error: Error) -> String {
        let s = "\(error)".lowercased()
        if s.contains("background") || s.contains("hidden") {
            return "Bring this window to the front — Image Playground won't draw while the app is in the background."
        }
        if s.contains("notsupported") || s.contains("unavailable") || s.contains("not available") {
            return "Image Playground isn't available here — enable Apple Intelligence and download its model (Settings ▸ Apple Intelligence & Siri)."
        }
        // Apple returns a vague "The image creation failed." for content-policy
        // blocks — it won't admit it's filtering. Treat the generic failure as a
        // likely blocked word (e.g. "pussycat" trips on the substring) and say so.
        if s.contains("guardrail") || s.contains("unsafe") || s.contains("sensitive")
            || s.contains("creation failed") {
            return "Image Playground declined that prompt — Apple's on-device content filter is aggressive and can trip on an innocent word or substring (e.g. \"pussycat\"). Try rephrasing."
        }
        return "Couldn't draw that — \((error as NSError).localizedDescription)"
    }

    /// Replace the placeholder image bubble at `imageIdx` with a rendered picture
    /// (or a reason it couldn't). Runs concurrently with the prose stream.
    func startIllustration(prompt: String, into imageIdx: Int) {
        #if canImport(ImagePlayground)
        guard #available(macOS 15.4, *) else {
            setImageBubble(imageIdx, html: "🖼 Image Playground needs macOS 15.4+.")
            return
        }
        Task {
            var html = "🖼 No image was produced."
            do {
                if let cg = try await self.makeIllustration(prompt: prompt, style: self.illustrateStyle),
                   let uri = self.pngDataURI(cg) {
                    html = "<img src=\"\(uri)\" alt=\"Image Playground illustration\" "
                         + "style=\"max-width:100%;border-radius:10px;display:block;\">"
                }
            } catch {
                html = "🖼 " + self.illustrateFriendly(error)
            }
            await MainActor.run { self.setImageBubble(imageIdx, html: html) }
        }
        #else
        setImageBubble(imageIdx, html: "🖼 This build lacks the ImagePlayground framework.")
        #endif
    }

    func setImageBubble(_ idx: Int, html: String) {
        guard idx >= 0, idx < messages.count else { return }
        messages[idx] = ("image", html)
        render()
    }

    #if canImport(ImagePlayground)
    @available(macOS 15.4, *)
    func makeIllustration(prompt: String, style: String) async throws -> CGImage? {
        let creator: ImageCreator
        if let c = illustratorBox as? ImageCreator { creator = c }
        else { creator = try await ImageCreator(); illustratorBox = creator }
        let styles = creator.availableStyles
        let chosen = styles.first { "\($0.id)".lowercased().contains(style.lowercased()) }
            ?? styles.first ?? .animation
        // The generator intermittently throws a vague "The image creation failed."
        // for the same prompt — it's transient, so retry several times before giving up.
        let retries = 8
        var lastError: Error?
        for attempt in 1...retries {
            do {
                for try await img in creator.images(for: [.text(prompt)], style: chosen, limit: 1) {
                    return img.cgImage
                }
                return nil
            } catch {
                let s = "\(error) \(error.localizedDescription)".lowercased()
                if s.contains("background") || s.contains("hidden") { throw error }  // won't self-heal
                lastError = error
                if attempt < retries {
                    try? await Task.sleep(nanoseconds: UInt64(attempt) * 600_000_000)
                }
            }
        }
        if let lastError { throw lastError }
        return nil
    }
    #endif

    /// "/image …", "draw: …", "draw me …", "picture of …" → the subject to draw
    /// (a one-off picture, no model call). Returns nil for ordinary messages.
    func imageCommand(_ text: String) -> String? {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lower = t.lowercased()
        for p in ["/image ", "/draw ", "draw: ", "draw me ", "picture of "] {
            if lower.hasPrefix(p) { return String(t.dropFirst(p.count)).trimmingCharacters(in: .whitespaces) }
        }
        return nil
    }

    func buildMenu() {
        let mainMenu = NSMenu()

        // ── App menu ──
        let appItem = NSMenuItem(); mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About FoundationModels Chat",
                                   action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Hide FoundationModels Chat",
                                   action: #selector(NSApplication.hide(_:)), keyEquivalent: "h"))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit FoundationModels Chat",
                                   action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu

        // ── File menu — New Chat (⌘N) lives here; Close (⌘W) now works ──
        let fileItem = NSMenuItem(); mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "File")
        let nc = NSMenuItem(title: "New Chat", action: #selector(newChatMenu), keyEquivalent: "n")
        nc.target = self
        fileMenu.addItem(nc)
        fileMenu.addItem(.separator())
        let exMD = NSMenuItem(title: "Export as Markdown…", action: #selector(exportMarkdown), keyEquivalent: "e")
        exMD.target = self
        fileMenu.addItem(exMD)
        let exPDF = NSMenuItem(title: "Export as PDF…", action: #selector(exportPDF), keyEquivalent: "E")
        exPDF.keyEquivalentModifierMask = [.command, .shift]
        exPDF.target = self
        fileMenu.addItem(exPDF)
        fileMenu.addItem(.separator())
        // performClose: routes up the responder chain to the key window.
        fileMenu.addItem(NSMenuItem(title: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w"))
        fileItem.submenu = fileMenu

        // ── Edit menu — so ⌘Z/⌘C/⌘V/⌘A work in the input field ──
        let editItem = NSMenuItem(); mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = NSMenuItem(title: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(redo)
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        // ── Connect menu (kept) ──
        let connItem = NSMenuItem(); mainMenu.addItem(connItem)
        let connMenu = NSMenu(title: "Connect")
        let c = NSMenuItem(title: "Connect to a Mac…", action: #selector(connectToMac), keyEquivalent: "k")
        c.target = self
        connMenu.addItem(c)
        connItem.submenu = connMenu

        // ── Prompt menu — view/edit the system prompt that colors replies ──
        let promptItem = NSMenuItem(); mainMenu.addItem(promptItem)
        let promptMenu = NSMenu(title: "Prompt")
        let ep = NSMenuItem(title: "Edit System Prompt…", action: #selector(editSystemPrompt), keyEquivalent: "p")
        ep.keyEquivalentModifierMask = [.command, .shift]   // ⇧⌘P (avoid ⌘P = print)
        ep.target = self
        promptMenu.addItem(ep)
        let em = NSMenuItem(title: "Edit Memory…", action: #selector(editMemory), keyEquivalent: "m")
        em.keyEquivalentModifierMask = [.command, .shift]   // ⇧⌘M (⌘M = minimize)
        em.target = self
        promptMenu.addItem(em)
        promptItem.submenu = promptMenu

        // ── Image menu — pair each reply with an on-device Image Playground picture ──
        let imgItem = NSMenuItem(); mainMenu.addItem(imgItem)
        let imgMenu = NSMenu(title: "Image")
        let ill = NSMenuItem(title: "Illustrate Replies", action: #selector(toggleIllustrate), keyEquivalent: "i")
        ill.target = self
        ill.state = illustrate ? .on : .off
        ill.toolTip = "Draw a picture (Apple Image Playground) alongside each model reply"
        imgMenu.addItem(ill)
        illustrateItem = ill
        imgMenu.addItem(.separator())
        let styleHeader = NSMenuItem(title: "Style", action: nil, keyEquivalent: "")
        styleHeader.isEnabled = false
        imgMenu.addItem(styleHeader)
        for name in ["Animation", "Illustration", "Sketch"] {
            let it = NSMenuItem(title: name, action: #selector(setIllustrateStyle(_:)), keyEquivalent: "")
            it.target = self
            it.state = (name.lowercased() == illustrateStyle) ? .on : .off
            imgMenu.addItem(it)
        }
        imgItem.submenu = imgMenu

        // ── Window menu — Minimize (⌘M), Zoom, standard window list ──
        let winItem = NSMenuItem(); mainMenu.addItem(winItem)
        let winMenu = NSMenu(title: "Window")
        winMenu.addItem(withTitle: "Minimize", action: #selector(NSWindow.performMiniaturize(_:)), keyEquivalent: "m")
        winMenu.addItem(withTitle: "Zoom", action: #selector(NSWindow.performZoom(_:)), keyEquivalent: "")
        winItem.submenu = winMenu
        NSApp.windowsMenu = winMenu

        NSApp.mainMenu = mainMenu
    }

    // Enter sends; Shift-Enter inserts a newline.
    func textView(_ tv: NSTextView, doCommandBy sel: Selector) -> Bool {
        if sel == #selector(NSResponder.insertNewline(_:)) {
            let shift = NSApp.currentEvent?.modifierFlags.contains(.shift) ?? false
            if !shift { sendTapped(); return true }
        }
        return false
    }

    @objc func sendTapped() {
        let text = inputView.string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !busy else { return }
        inputView.string = ""
        send(userText: text)
    }

    func ingest(_ urls: [URL]) {
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            var blocks: [String] = []
            var labels: [String] = []
            for url in urls {
                if let (txt, name) = extractText(from: url) {
                    blocks.append("Here is the contents of \(name):\n\n\(txt)")
                    labels.append(name)
                }
            }
            guard !blocks.isEmpty else { return }
            let joined = blocks.joined(separator: "\n\n---\n\n")
            DispatchQueue.main.async {
                let typed = self?.inputView.string.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                self?.inputView.string = ""
                let lead = typed.isEmpty ? "" : typed + "\n\n"
                self?.send(userText: lead + joined,
                           display: "📎 " + labels.joined(separator: ", ")
                                    + (typed.isEmpty ? "" : "\n\n" + typed))
            }
        }
    }

    /// Pre-LLM fast path: obvious intents run a script directly (via apple-do) and
    /// return the answer — no model to reason, decide, stream, or hang. A 3B model is
    /// slow and unreliable at *deciding* to call a tool (it'll refuse "homepod sensors"
    /// outright), so for known intents we skip it. Returns the answer, or nil to fall
    /// through to the model. Works even when FoundationModels is unavailable.
    func directAnswer(_ text: String) -> String? {
        let q = text.lowercased()
        func has(_ ws: [String]) -> Bool { ws.contains { q.contains($0) } }
        let ad = "\(ToolEnv.binDir)/apple-do"
        if has(["temperature", "humidity", "homepod", "climate", "how warm", "how hot", "how cold"])
            && !has(["weather", "outside", "outdoor"]) {
            return runCLI([ad, "home"])
        }
        if has(["fleet", "workers"]) || (q.contains("mini") && has(["busy", "status", "running", "hot", "alive"])) {
            return runCLI([ad, "fleet"])
        }
        if has(["what day", "what time", "what's the date", "what is the date", "today's date",
                "todays date", "current time", "current date", "time is it", "day is it"]) {
            return runCLI([ad, "now"])
        }
        return nil
    }

    /// Pull a fact out of a "remember …" message, else nil.
    func memoryFact(from text: String) -> String? {
        let t = text.trimmingCharacters(in: .whitespaces)
        for p in ["remember that ", "remember: ", "remember ", "note that ", "keep in mind that "] {
            if t.lowercased().hasPrefix(p) {
                let fact = String(t.dropFirst(p.count)).trimmingCharacters(in: .whitespaces)
                return fact.isEmpty ? nil : fact
            }
        }
        return nil
    }

    func send(userText: String, display: String? = nil) {
        // Memory commands — affect/inspect the long-term memory the model reads, no model call.
        let memQ = userText.trimmingCharacters(in: .whitespaces).lowercased()
        if ["what do you remember", "what do you remember about me", "show memory", "show my memory",
            "show me my memory", "memory", "what's in your memory", "whats in your memory",
            "list memory", "what have you remembered"].contains(memQ) {
            let mem = FM.memory.trimmingCharacters(in: .whitespacesAndNewlines)
            messages.append(("user", display ?? userText)); store.log(role: "user", text: userText)
            appendAssistant(mem.isEmpty
                ? "🧠 Nothing yet. Add facts with \"remember: …\" (or ⇧⌘M)."
                : "🧠 Here's what I remember:\n\n\(mem)")
            return
        }
        if let fact = memoryFact(from: userText) {
            FM.memory = (FM.memory.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "" : FM.memory + "\n") + "- " + fact
            fm.resetSession()   // re-seed the session so the new memory takes effect now
            messages.append(("user", display ?? userText))
            store.log(role: "user", text: userText)
            appendAssistant("🧠 Added to memory: \(fact)")
            store.log(role: "assistant", text: "[memory+] \(fact)")
            return
        }
        if ["forget everything", "clear memory", "clear my memory"].contains(userText.trimmingCharacters(in: .whitespaces).lowercased()) {
            FM.memory = ""; fm.resetSession()
            messages.append(("user", display ?? userText)); store.log(role: "user", text: userText)
            appendAssistant("🧠 Memory cleared.")
            return
        }
        // "/image tiger" / "draw: tiger" — a one-off picture, no model call.
        if let subject = imageCommand(userText) {
            messages.append(("user", display ?? userText))
            store.log(role: "user", text: userText)
            let imageIdx = messages.count
            messages.append(("image", "🖼 drawing…"))
            render()
            startIllustration(prompt: subject, into: imageIdx)
            return
        }
        // Pre-LLM fast path: known intents run a script, no model — instant, can't hang.
        if let direct = directAnswer(userText) {
            messages.append(("user", display ?? userText))
            convo.append(("user", userText))
            store.log(role: "user", text: userText)
            messages.append(("assistant", direct))
            convo.append(("assistant", direct))
            store.log(role: "assistant", text: direct)
            render()
            return
        }
        guard fm.available else {
            appendAssistant("Model unavailable — can't send.")
            return
        }
        // Plain English chat — no translation harness. You type, it goes straight to
        // the model (which speaks English). Nothing runs on the main thread before send.
        // Any previous overflow button is now stale.
        newChatPrompt = nil; newChatDisplay = nil; newChatMsgIndex = nil
        busy = true
        sendButton.isEnabled = false
        messages.append(("user", display ?? userText))
        convo.append(("user", userText))
        store.log(role: "user", text: userText)
        // When Illustrate is on, insert the picture bubble BEFORE the assistant
        // bubble so the assistant stays the LAST bubble — updateLastBubble (which
        // targets the last bubble during streaming) must not hit the image.
        var imageIdx = -1
        if illustrate {
            messages.append(("image", "🖼 drawing…"))
            imageIdx = messages.count - 1
        }
        messages.append(("assistant", "…"))   // live streaming target (stays last)
        render()
        let idx = messages.count - 1
        if illustrate { startIllustration(prompt: userText, into: imageIdx) }
        dlog("SEND userText=\(userText.replacingOccurrences(of: "\n", with: "⏎").prefix(200))")
        fm.askStreaming(latest: userText, history: convo,
            onPartial: { [weak self] partial in
                // Update only the last bubble in place — no full reload, so the
                // view doesn't flicker or lose scroll while tokens arrive.
                guard let self = self, idx < self.messages.count else { return }
                let text = partial.isEmpty ? "…" : partial
                self.messages[idx] = ("assistant", text)
                self.updateLastBubble(text)
            },
            completion: { [weak self] result in
                guard let self = self, idx < self.messages.count else { return }
                switch result {
                case .success(let raw):
                    dlog("RAW-REPLY (\(raw.count) chars): \(raw.replacingOccurrences(of: "\n", with: "⏎").prefix(600))")
                    // Never surface a raw empty / "null" generation — map it to a real message.
                    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
                    let reply = (trimmed.isEmpty || trimmed.lowercased() == "null" || trimmed.lowercased() == "nil")
                        ? "⚠️ The model returned an empty reply (it ran out of room or stalled). Press ⌘N for a fresh chat, or rephrase / shorten the message."
                        : trimmed
                    self.messages[idx] = ("assistant", reply)
                    self.convo.append(("assistant", reply))
                    self.store.log(role: "assistant", text: reply)
                case .failure(let err):
                    dlog("ERROR raw: \(err)")
                    let msg = self.friendly(err)
                    dlog("ERROR friendly: \(msg)")
                    self.messages[idx] = ("assistant", "⚠️ " + msg)
                    self.store.log(role: "assistant", text: "[error] " + msg)
                    if self.errorIsContextWindow(err) {
                        // Same predicate friendly() uses → button can't diverge
                        // from the "start a new chat" message.
                        self.newChatPrompt = userText
                        self.newChatDisplay = display
                        self.newChatMsgIndex = idx
                    }
                }
                self.busy = false
                self.sendButton.isEnabled = true
                self.render()   // one clean full render at the end
            })
    }

    /// Replace the innermost (last) chat bubble's HTML without reloading the page.
    func updateLastBubble(_ text: String) {
        let html = renderMessageHTML(text)
        guard let data = try? JSONSerialization.data(withJSONObject: [html]),
              let lit = String(data: data, encoding: .utf8) else { return }
        // `lit` is a JSON array literal like ["…html…"]; index [0] in JS yields the
        // properly-escaped string. Avoids hand-rolling JS string escaping.
        let js = "(function(){var b=document.querySelectorAll('.bubble');"
               + "if(b.length){b[b.length-1].innerHTML=(\(lit))[0];"
               + "window.scrollTo(0,document.body.scrollHeight);}})();"
        webView.evaluateJavaScript(js, completionHandler: nil)
    }

    /// True when an error is the context-window-full case — from the typed
    /// on-device GenerationError or, for the remote bridge, the error string.
    /// friendly() and the recovery-button logic both call this, so the button
    /// always appears exactly when the "start a new chat" message does.
    func errorIsContextWindow(_ err: Error) -> Bool {
        if #available(macOS 26.0, *) {
            if case LanguageModelSession.GenerationError.exceededContextWindowSize = err { return true }
        }
        let s = "\(err)".lowercased()
        return (s.contains("context") && s.contains("window")) || s.contains("exceededcontext")
            || s.contains("context length") || s.contains("contextlength")
    }

    func friendly(_ err: Error) -> String {
        let s = "\(err)".lowercased()
        if s.contains("guardrail") || s.contains("unsafe") {
            return "Apple's on-device safety guardrail blocked that one (it's aggressive). Rephrase and try again."
        }
        if errorIsContextWindow(err) {
            return "The conversation filled the on-device model's context window and couldn't be condensed. Use the button below — or press ⌘N — to start a fresh chat with your last prompt."
        }
        if s.contains("unsupportedlanguage") || s.contains("unsupported language") || s.contains("languageorlocale") {
            return "This on-device model doesn't support that language. It works in English (and a few others) — Finnish isn't supported, so ask in English. (I can add automatic Finnish⇄English translation if you want to keep writing in Finnish.)"
        }
        if s.contains("ratelimit") || s.contains("rate limit") {
            return "The model is rate-limited right now — wait a moment and try again."
        }
        // Unknown error: a clean sentence — NEVER a raw Swift/JSON-looking dump.
        // 1) a real message we attached to a bridge NSError, 2) the model's own
        // debugDescription, else 3) a plain generic sentence.
        let ld = (err as NSError).localizedDescription
        if !ld.isEmpty, !ld.lowercased().hasPrefix("the operation couldn") {
            return ld
        }
        let raw = "\(err)"
        if let lo = raw.range(of: "debugDescription: \""),
           let hi = raw.range(of: "\"", range: lo.upperBound..<raw.endIndex) {
            return "The model couldn't complete that: \(raw[lo.upperBound..<hi.lowerBound]) — try rephrasing, or ⌘N for a fresh chat."
        }
        return "The model couldn't complete that. Try rephrasing, or ⌘N for a fresh chat."
    }

    func appendAssistant(_ t: String) { messages.append(("assistant", t)); render() }

    /// Best-guess dominant language code ("fi", "en", …) of a message, for the
    /// translation harness. Returns nil/"und" when it can't tell (short text).
    func dominantLanguage(_ text: String) -> String? {
        guard text.count >= 8 else { return "en" }   // too short to judge → assume English
        let r = NLLanguageRecognizer()
        r.processString(text)
        return r.dominantLanguage?.rawValue
    }

    // ─────────────────────── export (Markdown / PDF) ────────────────
    // Verbatim from `messages` — the same text shown on screen and saved to the
    // continuous transcript. .md is the labelled source; .pdf renders it.

    /// The conversation as Markdown — identical shape to the auto-saved transcript.
    func conversationMarkdown() -> String {
        var out = "# FoundationModels Chat — \(store.stamp)\n\n"
        for m in messages {
            if m.role == "image" {
                out += "**Image Playground:**\n\n*(generated illustration)*\n\n"
                continue
            }
            let who = m.role == "user" ? "You" : "FoundationModels"
            out += "**\(who):**\n\n\(m.text)\n\n"
        }
        return out
    }

    /// A print-friendly (light) HTML document of the whole conversation, with each
    /// turn's Markdown rendered. Used as the source for the PDF.
    func conversationExportHTML() -> String {
        var body = ""
        for m in messages {
            if m.role == "image" {
                body += "<div class=\"msg bot\"><div class=\"who\">Image Playground</div>"
                      + "<div class=\"bubble\">\(m.text)</div></div>"
                continue
            }
            let who = m.role == "user" ? "You" : "FoundationModels"
            body += "<div class=\"msg \(m.role)\"><div class=\"who\">\(who)</div>"
                  + "<div class=\"bubble\">\(renderMessageHTML(m.text))</div></div>"
        }
        return """
        <!DOCTYPE html><html><head><meta charset="utf-8"><style>
          body { font: 12pt -apple-system, system-ui; color: #111; background: #fff;
                 margin: 0; -webkit-print-color-adjust: exact; }
          h1.title { font-size: 16pt; margin: 0 0 14pt; }
          .msg { margin: 0 0 12pt; page-break-inside: avoid; }
          .who { font-size: 8pt; text-transform: uppercase; letter-spacing: .06em;
                 color: #666; margin-bottom: 3pt; }
          .bubble { border: 1px solid #ddd; border-radius: 8px; padding: 6pt 9pt; background: #fafafa; }
          .user .bubble { background: #eef4fb; border-color: #cfe0f3; }
          p { margin: 4pt 0; } h1,h2,h3,h4 { margin: 8pt 0 4pt; }
          code { background: #f0f0f0; border-radius: 3px; padding: 1px 4px; font: 10pt ui-monospace, Menlo; }
          pre { background: #f4f4f4; border-radius: 6px; padding: 8pt; white-space: pre-wrap; word-wrap: break-word; }
          pre code { background: none; padding: 0; }
          a { color: #0a4d8c; }
          math { font-family: "STIX Two Math", "Latin Modern Math", serif; }
          math[display="block"] { display: block; margin: 6pt 0; }
        </style></head><body><h1 class="title">FoundationModels Chat — \(store.stamp)</h1>\(body)</body></html>
        """
    }

    @objc func exportMarkdown() {
        guard !messages.isEmpty else { NSSound.beep(); return }
        // Save into the session's own folder — right beside the conversation —
        // then highlight it in Finder. No Save dialog, no opening it.
        let url = store.dir.appendingPathComponent("chat-\(store.stamp).md")
        do {
            try conversationMarkdown().data(using: .utf8)?.write(to: url)
            NSWorkspace.shared.activateFileViewerSelecting([url])   // highlight in Finder
        } catch { exportAlert("Couldn't save the Markdown file: \(error.localizedDescription)") }
    }

    @objc func exportPDF() {
        guard !messages.isEmpty else { NSSound.beep(); return }
        // Save into the session's own folder, beside the .md, then open in Preview.
        let url = store.dir.appendingPathComponent("chat-\(store.stamp).pdf")

        // Render the export HTML in a webview hosted in an OFFSCREEN WINDOW, then
        // print it to PDF (paginated, US Letter). The window is essential: a
        // print operation on a windowless WKWebView hangs the main thread (the
        // earlier freeze). With a window, run() paginates and returns cleanly,
        // honouring the stylesheet's page-break-inside:avoid so bubbles don't split.
        let pageW: CGFloat = 612, pageH: CGFloat = 792   // US Letter @72dpi
        let web = WKWebView(frame: NSRect(x: 0, y: 0, width: pageW, height: pageH))
        let win = NSWindow(contentRect: NSRect(x: 0, y: 0, width: pageW, height: pageH),
                           styleMask: [.borderless], backing: .buffered, defer: false)
        win.isReleasedWhenClosed = false
        win.contentView = web
        win.setFrameOrigin(NSPoint(x: -20000, y: -20000))   // park it off every screen
        win.orderBack(nil)

        let delegate = LoadDoneDelegate { [weak self] w in
            guard let self = self else { return }
            let info = NSPrintInfo(dictionary: [
                .jobDisposition: NSPrintInfo.JobDisposition.save,
                .jobSavingURL: url
            ])
            info.paperSize = NSSize(width: pageW, height: pageH)
            info.leftMargin = 36; info.rightMargin = 36
            info.topMargin = 36; info.bottomMargin = 36
            info.horizontalPagination = .fit
            info.verticalPagination = .automatic
            info.isHorizontallyCentered = false
            info.isVerticallyCentered = false
            let op = w.printOperation(with: info)
            op.showsPrintPanel = false
            op.showsProgressPanel = false
            op.run()
            self.openInPreview(url)
            self.pdfExportWindow?.orderOut(nil)
            self.pdfExportWeb = nil
            self.pdfExportDelegate = nil
            self.pdfExportWindow = nil
        }
        pdfExportWeb = web
        pdfExportDelegate = delegate
        pdfExportWindow = win
        web.navigationDelegate = delegate
        web.loadHTMLString(conversationExportHTML(), baseURL: nil)
    }

    /// Open a file specifically in Preview.app (falls back to the default app).
    private func openInPreview(_ url: URL) {
        let preview = URL(fileURLWithPath: "/System/Applications/Preview.app")
        if FileManager.default.fileExists(atPath: preview.path) {
            NSWorkspace.shared.open([url], withApplicationAt: preview,
                                    configuration: NSWorkspace.OpenConfiguration(),
                                    completionHandler: nil)
        } else {
            NSWorkspace.shared.open(url)
        }
    }

    private func exportAlert(_ msg: String) {
        let a = NSAlert(); a.messageText = "Export failed"; a.informativeText = msg
        a.alertStyle = .warning; a.runModal()
    }

    func render() {
        var body = ""
        for (i, m) in messages.enumerated() {
            // Image bubbles carry ready-made HTML (an <img> data URI or a status
            // line) — inject it raw, never through the Markdown escaper.
            if m.role == "image" {
                body += "<div class=\"msg bot\"><div class=\"who\">Image Playground</div>"
                      + "<div class=\"bubble\">\(m.text)</div></div>"
                continue
            }
            let cls = m.role == "user" ? "user" : "bot"
            let who = m.role == "user" ? "You" : "FoundationModels"
            var inner = "<div class=\"who\">\(who)</div><div class=\"bubble\">\(renderMessageHTML(m.text))</div>"
            if i == newChatMsgIndex, newChatPrompt != nil {
                inner += "<div><button class=\"newchat\" "
                       + "onclick=\"window.webkit.messageHandlers.fmchat.postMessage('newchat')\">"
                       + "↻ Start a new chat with that prompt</button></div>"
            }
            body += "<div class=\"msg \(cls)\">\(inner)</div>"
        }
        let html = """
        <!DOCTYPE html><html><head><meta charset="utf-8">
        <style>
          :root { color-scheme: dark; }
          body { font: 15px -apple-system, system-ui; margin: 0; padding: 18px;
                 background: #1c1c1e; color: #e8e8ea; }
          .msg { margin: 0 0 18px; }
          .who { font-size: 11px; text-transform: uppercase; letter-spacing: .06em;
                 color: #8e8e93; margin-bottom: 4px; }
          .bubble { background: #2c2c2e; border-radius: 12px; padding: 10px 14px;
                    max-width: 80%; display: inline-block; }
          .user .bubble { background: #0a4d8c; }
          .user { text-align: right; } .user .bubble { text-align: left; }
          p { margin: 6px 0; } h1,h2,h3,h4 { margin: 10px 0 6px; }
          code { background: #000; border-radius: 4px; padding: 1px 5px;
                 font: 13px ui-monospace, Menlo; }
          pre { background: #000; border-radius: 8px; padding: 10px 12px; overflow-x: auto; }
          pre code { background: none; padding: 0; }
          a { color: #4aa3ff; }
          .newchat { margin-top: 10px; background: #0a4d8c; color: #fff; border: none;
                     border-radius: 8px; padding: 8px 14px; cursor: pointer;
                     font: 13px -apple-system, system-ui; }
          .newchat:hover { background: #0b5aa6; }
          math { font-family: "STIX Two Math", "Latin Modern Math", serif; font-size: 1.05em; }
          math[display="block"] { display: block; margin: 8px 0; }
        </style></head><body>\(body)
        <script>window.scrollTo(0, document.body.scrollHeight);</script>
        </body></html>
        """
        webView.loadHTMLString(html, baseURL: nil)
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
