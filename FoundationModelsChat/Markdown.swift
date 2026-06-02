// Markdown.swift — the chat's Markdown→HTML renderer + helpers, extracted from
// main.swift so it can be unit-tested HEADLESSLY (pure Foundation, no AppKit).
// RULE: before changing rendering, run ./FoundationModelsChat/test-markdown.sh — it
// must pass; add a case for any rendering bug you fix. See markdown-tests.swift.
import Foundation

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
    var pendingBlank = false
    for rawLine in lines {
        let trimmed = rawLine.trimmingCharacters(in: .whitespaces)
        if trimmed.isEmpty { pendingBlank = true; continue }
        let isUL = trimmed.range(of: "^[-*+]\\s+", options: .regularExpression) != nil
        let isOL = trimmed.range(of: "^\\d+\\.\\s+", options: .regularExpression) != nil
        // A blank line BETWEEN items of the same list is a "loose list" — keep the list
        // open, otherwise an ordered list restarts at 1 on every item (the bug). Only a
        // blank line followed by a NON-list line actually ends the list.
        if pendingBlank {
            if !((inOL && isOL) || (inList && isUL)) { closeLists() }
            pendingBlank = false
        }
        // headings
        if let m = trimmed.range(of: "^(#{1,4})\\s+", options: .regularExpression) {
            closeLists()
            let hashes = trimmed[m].trimmingCharacters(in: .whitespaces).count
            let content = String(trimmed[m.upperBound...])
            html += "<h\(hashes)>\(inlineMD(content, stash))</h\(hashes)>"
            continue
        }
        if isUL {
            if !inList { closeLists(); html += "<ul>"; inList = true }
            let content = trimmed.replacingOccurrences(of: "^[-*+]\\s+", with: "", options: .regularExpression)
            html += "<li>\(inlineMD(content, stash))</li>"
            continue
        }
        if isOL {
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
