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

// ─────────────────────────── helpers ───────────────────────────

func escapeHTML(_ s: String) -> String {
    var o = s
    o = o.replacingOccurrences(of: "&", with: "&amp;")
    o = o.replacingOccurrences(of: "<", with: "&lt;")
    o = o.replacingOccurrences(of: ">", with: "&gt;")
    return o
}

/// Regex find/replace with captured groups available to the transform.
func regexReplace(_ s: String, _ pattern: String,
                  _ opts: NSRegularExpression.Options = [],
                  _ transform: ([String]) -> String) -> String {
    guard let re = try? NSRegularExpression(pattern: pattern, options: opts) else { return s }
    let ns = s as NSString
    var result = ""
    var last = 0
    for m in re.matches(in: s, range: NSRange(location: 0, length: ns.length)) {
        result += ns.substring(with: NSRange(location: last, length: m.range.location - last))
        var groups: [String] = []
        for i in 0..<m.numberOfRanges {
            let r = m.range(at: i)
            groups.append(r.location == NSNotFound ? "" : ns.substring(with: r))
        }
        result += transform(groups)
        last = m.range.location + m.range.length
    }
    result += ns.substring(from: last)
    return result
}

// ─────────────────────── LaTeX → MathML (own code) ──────────────
// Bounded converter for when the model emits LaTeX instead of MathML.
// Primary math path is the model emitting <math> directly (passed through).

let GREEK: [String: String] = [
    "alpha":"α","beta":"β","gamma":"γ","delta":"δ","epsilon":"ε","zeta":"ζ",
    "eta":"η","theta":"θ","iota":"ι","kappa":"κ","lambda":"λ","mu":"μ","nu":"ν",
    "xi":"ξ","pi":"π","rho":"ρ","sigma":"σ","tau":"τ","phi":"φ","chi":"χ",
    "psi":"ψ","omega":"ω","Gamma":"Γ","Delta":"Δ","Theta":"Θ","Lambda":"Λ",
    "Pi":"Π","Sigma":"Σ","Phi":"Φ","Psi":"Ψ","Omega":"Ω","infty":"∞"]
let OPS: [String: String] = [
    "times":"×","cdot":"⋅","div":"÷","pm":"±","mp":"∓","leq":"≤","le":"≤",
    "geq":"≥","ge":"≥","neq":"≠","ne":"≠","approx":"≈","equiv":"≡","sim":"∼",
    "rightarrow":"→","to":"→","leftarrow":"←","Rightarrow":"⇒","partial":"∂",
    "nabla":"∇","int":"∫","sum":"∑","prod":"∏","forall":"∀","exists":"∃",
    "in":"∈","notin":"∉","subset":"⊂","cup":"∪","cap":"∩","cdots":"⋯"]

func latexToMathML(_ latex: String, display: Bool) -> String {
    let chars = Array(latex)
    var i = 0

    func wrap(_ s: String) -> String {
        // a single element doesn't need an <mrow>; multiple do
        return s.contains("</m") && (s.hasPrefix("<mrow") || countTopLevel(s) > 1) ? "<mrow>\(s)</mrow>" : (s.isEmpty ? "<mrow></mrow>" : s)
    }
    func countTopLevel(_ s: String) -> Int { 2 } // cheap: always wrap groups

    func parseBraced() -> String {
        if i < chars.count && chars[i] == "{" {
            i += 1
            let inner = parseSeq(stopAtBrace: true)
            if i < chars.count && chars[i] == "}" { i += 1 }
            return "<mrow>\(inner)</mrow>"
        }
        return parseAtom()
    }

    func parseCommand() -> String {
        i += 1 // skip backslash
        var name = ""
        while i < chars.count && chars[i].isLetter { name.append(chars[i]); i += 1 }
        if name == "frac" {
            let a = parseBraced(); let b = parseBraced()
            return "<mfrac>\(a)\(b)</mfrac>"
        }
        if name == "sqrt" {
            let a = parseBraced()
            return "<msqrt>\(a)</msqrt>"
        }
        if let g = GREEK[name] { return "<mi>\(g)</mi>" }
        if let op = OPS[name] { return "<mo>\(op)</mo>" }
        if name.isEmpty { i += 1; return "" } // stray backslash
        return "<mi>\(name)</mi>"
    }

    func parseAtom() -> String {
        guard i < chars.count else { return "" }
        let c = chars[i]
        if c == "\\" { return parseCommand() }
        if c == "{" { return parseBraced() }
        if c.isNumber {
            var num = ""
            while i < chars.count && (chars[i].isNumber || chars[i] == ".") { num.append(chars[i]); i += 1 }
            return "<mn>\(num)</mn>"
        }
        if c.isLetter {
            i += 1
            return "<mi>\(c)</mi>"
        }
        if "+-*/=<>(),.|".contains(c) {
            i += 1
            let sym = c == "*" ? "×" : String(c)
            if c == "(" || c == ")" || c == "|" { return "<mo stretchy=\"false\">\(escapeHTML(sym))</mo>" }
            return "<mo>\(escapeHTML(sym))</mo>"
        }
        if c == " " { i += 1; return "" }
        i += 1
        return "<mi>\(escapeHTML(String(c)))</mi>"
    }

    func parseSeq(stopAtBrace: Bool) -> String {
        var out = ""
        while i < chars.count {
            if stopAtBrace && chars[i] == "}" { break }
            var atom = parseAtom()
            while i < chars.count && (chars[i] == "^" || chars[i] == "_") {
                let sup = chars[i] == "^"; i += 1
                let arg = parseBraced()
                atom = sup ? "<msup>\(atom)\(arg)</msup>" : "<msub>\(atom)\(arg)</msub>"
            }
            out += atom
        }
        return out
    }

    let body = parseSeq(stopAtBrace: false)
    let dattr = display ? " display=\"block\"" : ""
    return "<math xmlns=\"http://www.w3.org/1998/Math/MathML\"\(dattr)><mrow>\(body)</mrow></math>"
}

// ─────────────────────── Markdown → HTML ────────────────────────

func renderMessageHTML(_ raw: String) -> String {
    var stash: [String: String] = [:]
    var n = 0
    func keep(_ html: String) -> String { let k = "\u{e000}\(n)\u{e000}"; n += 1; stash[k] = html; return k }

    var text = raw

    // 1) Protect raw MathML the model emits (Apple-native render path).
    text = regexReplace(text, "(?s)<math[\\s\\S]*?</math>") { g in keep(g[0]) }
    // 2) Protect fenced code blocks.
    text = regexReplace(text, "(?s)```[a-zA-Z0-9_+-]*\\n?(.*?)```") { g in
        keep("<pre><code>\(escapeHTML(g[1]))</code></pre>")
    }
    // 3) Display math $$...$$ and \[...\]
    text = regexReplace(text, "(?s)\\$\\$(.+?)\\$\\$") { g in keep(latexToMathML(g[1], display: true)) }
    text = regexReplace(text, "(?s)\\\\\\[(.+?)\\\\\\]") { g in keep(latexToMathML(g[1], display: true)) }
    // 4) Inline math $...$ (not $$) and \(...\)
    text = regexReplace(text, "\\$([^$\\n]+?)\\$") { g in keep(latexToMathML(g[1], display: false)) }
    text = regexReplace(text, "(?s)\\\\\\((.+?)\\\\\\)") { g in keep(latexToMathML(g[1], display: false)) }
    // 5) Inline code spans.
    text = regexReplace(text, "`([^`\\n]+?)`") { g in keep("<code>\(escapeHTML(g[1]))</code>") }

    // Escape everything that's left, then apply block + inline markdown.
    let lines = text.components(separatedBy: "\n")
    var html = ""
    var inList = false
    var inOL = false
    func closeLists() {
        if inList { html += "</ul>"; inList = false }
        if inOL { html += "</ol>"; inOL = false }
    }
    for rawLine in lines {
        let line = rawLine
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { closeLists(); continue }
        // headings
        if let m = trimmed.range(of: "^(#{1,4})\\s+", options: .regularExpression) {
            closeLists()
            let hashes = trimmed[m].trimmingCharacters(in: .whitespaces).count
            let content = String(trimmed[m.upperBound...])
            html += "<h\(hashes)>\(inlineMD(content, stash))</h\(hashes)>"
            continue
        }
        // unordered list
        if trimmed.range(of: "^[-*+]\\s+", options: .regularExpression) != nil {
            if !inList { closeLists(); html += "<ul>"; inList = true }
            let content = trimmed.replacingOccurrences(of: "^[-*+]\\s+", with: "", options: .regularExpression)
            html += "<li>\(inlineMD(content, stash))</li>"
            continue
        }
        // ordered list
        if trimmed.range(of: "^\\d+\\.\\s+", options: .regularExpression) != nil {
            if !inOL { closeLists(); html += "<ol>"; inOL = true }
            let content = trimmed.replacingOccurrences(of: "^\\d+\\.\\s+", with: "", options: .regularExpression)
            html += "<li>\(inlineMD(content, stash))</li>"
            continue
        }
        closeLists()
        html += "<p>\(inlineMD(trimmed, stash))</p>"
    }
    closeLists()

    // Restore protected blocks.
    for (k, v) in stash { html = html.replacingOccurrences(of: "<p>\(k)</p>", with: v) }
    for (k, v) in stash { html = html.replacingOccurrences(of: k, with: v) }
    return html
}

func inlineMD(_ s: String, _ stash: [String: String]) -> String {
    var t = escapeHTML(s)
    // restore placeholders BEFORE escaping would have mangled them — they were
    // kept raw, so just leave the sentinels and substitute after escape.
    t = regexReplace(t, "\\*\\*(.+?)\\*\\*") { g in "<strong>\(g[1])</strong>" }
    t = regexReplace(t, "(?<![\\*])\\*(?![\\*])(.+?)(?<![\\*])\\*(?![\\*])") { g in "<em>\(g[1])</em>" }
    t = regexReplace(t, "\\b_(.+?)_\\b") { g in "<em>\(g[1])</em>" }
    t = regexReplace(t, "\\[(.+?)\\]\\((.+?)\\)") { g in "<a href=\"\(g[2])\">\(g[1])</a>" }
    return t
}

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
    let description = "Fetch a web page by its URL and return its readable text (page title plus main body text). Call this whenever the user provides a URL or asks what a web page says."

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
            let session = LanguageModelSession(tools: fmTools(), instructions: FM.systemInstructions)
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
            let session = LanguageModelSession(tools: fmTools(), instructions: FM.systemInstructions)
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

    static let systemInstructions = """
    You are a helpful on-device assistant. Format replies in Markdown. \
    When you write mathematics, output Presentation MathML wrapped in <math> … </math> \
    tags (not LaTeX) so it renders natively. If the user gives a URL or asks what a \
    web page says, call the WebReader tool to fetch it and answer from the text it \
    returns. Be concise and clear.
    """

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
    func askStreaming(latest: String, history: [(role: String, text: String)],
                      onPartial: @escaping (String) -> Void,
                      completion: @escaping (Result<String, Error>) -> Void) {
        if case .local = backend, #available(macOS 26.0, *),
           let session = sessionBox as? LanguageModelSession {
            Task {
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
        for try await snapshot in session.streamResponse(to: prompt) {
            let cur = snapshot.content   // cumulative text so far
            last = cur
            await MainActor.run { onPartial(cur) }
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
        let summarizer = LanguageModelSession(instructions:
            "Summarize the conversation in 4-6 sentences, preserving names, facts, numbers, and the current task.")
        if let r = try? await summarizer.respond(to: "Conversation:\n\(transcript)") { summary = r.content }
        let instr = summary.isEmpty ? FM.systemInstructions
            : FM.systemInstructions + "\n\nEarlier context summary:\n" + summary
        let seeded = LanguageModelSession(tools: fmTools(), instructions: instr)
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

final class AppDelegate: NSObject, NSApplicationDelegate, NSTextViewDelegate, WKScriptMessageHandler {
    var window: NSWindow!
    var webView: WKWebView!
    var inputView: NSTextView!
    var sendButton: NSButton!
    let fm = FM()
    var store = SessionStore()
    var messages: [(role: String, text: String)] = []   // what's shown (display text)
    var convo: [(role: String, text: String)] = []       // what was actually sent (for remote replay)
    var busy = false

    // When a prompt overflows the context window we stash it here and attach a
    // "start a new chat with that prompt" button to the error bubble.
    var newChatPrompt: String?       // the userText to resend
    var newChatDisplay: String?      // its display label (for file-ingest prompts)
    var newChatMsgIndex: Int?        // which bubble carries the button

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

        // transcript
        let webConf = WKWebViewConfiguration()
        let ucc = WKUserContentController()
        ucc.add(self, name: "fmchat")   // HTML buttons post back here
        webConf.userContentController = ucc
        webView = WKWebView(frame: NSRect(x: 0, y: 110, width: 820, height: 610), configuration: webConf)
        webView.autoresizingMask = [.width, .height]
        webView.setValue(false, forKey: "drawsBackground")
        root.addSubview(webView)

        // input
        let inputScroll = NSScrollView(frame: NSRect(x: 12, y: 12, width: 690, height: 88))
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

        sendButton = NSButton(frame: NSRect(x: 712, y: 12, width: 96, height: 88))
        sendButton.autoresizingMask = [.minXMargin]
        sendButton.title = "Send"
        sendButton.bezelStyle = .rounded
        sendButton.keyEquivalent = "\r"
        sendButton.target = self
        sendButton.action = #selector(sendTapped)
        root.addSubview(sendButton)

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

    func buildMenu() {
        let mainMenu = NSMenu()

        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: "About FoundationModels Chat",
                                   action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: ""))
        appMenu.addItem(.separator())
        let nc = NSMenuItem(title: "New Chat", action: #selector(newChatMenu), keyEquivalent: "n")
        nc.target = self
        appMenu.addItem(nc)
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appItem.submenu = appMenu

        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "Edit")
        editMenu.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = editMenu

        let connItem = NSMenuItem()
        mainMenu.addItem(connItem)
        let connMenu = NSMenu(title: "Connect")
        let c = NSMenuItem(title: "Connect to a Mac…", action: #selector(connectToMac), keyEquivalent: "k")
        c.target = self
        connMenu.addItem(c)
        connItem.submenu = connMenu

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

    func send(userText: String, display: String? = nil) {
        guard fm.available else {
            appendAssistant("Model unavailable — can't send.")
            return
        }
        // Any previous overflow button is now stale.
        newChatPrompt = nil; newChatDisplay = nil; newChatMsgIndex = nil
        busy = true
        sendButton.isEnabled = false
        messages.append(("user", display ?? userText))
        convo.append(("user", userText))      // full sent text → remote replay
        store.log(role: "user", text: userText)
        messages.append(("assistant", "…"))   // live streaming target
        render()
        let idx = messages.count - 1
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
                case .success(let reply):
                    self.messages[idx] = ("assistant", reply)
                    self.convo.append(("assistant", reply))
                    self.store.log(role: "assistant", text: reply)
                case .failure(let err):
                    let msg = self.friendly(err)
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
        return "\(err)"
    }

    func appendAssistant(_ t: String) { messages.append(("assistant", t)); render() }

    func render() {
        var body = ""
        for (i, m) in messages.enumerated() {
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
