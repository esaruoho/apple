// MarkdownAttributed.swift — render Markdown to an NSAttributedString for AppKit text
// views (AppleBar's result pane, and anything else that shows model/markdown output).
// The repo already has FoundationModelsChat/Markdown.swift, but that renders to HTML for
// a WebView; an NSTextView needs attributed strings, so this is the attributed sibling.
//
// Handles the constructs that actually show up in tool output: # / ## / ### headings,
// **bold**, *italic* / _italic_, `inline code`, ``` fenced code ```, --- rules,
// - / * bullets, and common inline/display LaTeX math. Plain lines pass through. Pure logic → headless-testable
// (shared/test-markdown-attributed.sh) per the "test renderers headlessly" rule.
//
// FEATURE-CARD >> features/markdown-attributed.feature
import Cocoa

enum MarkdownAttributed {
    static func render(_ md: String,
                       bodySize: CGFloat = 13,
                       bodyColor: NSColor = NSColor(calibratedWhite: 0.92, alpha: 1)) -> NSAttributedString {
        let body  = NSFont.systemFont(ofSize: bodySize)
        let codeC = NSColor(calibratedWhite: 0.97, alpha: 1)
        let codeBG = NSColor(calibratedWhite: 1, alpha: 0.10)
        let dim   = NSColor(calibratedWhite: 0.5, alpha: 1)
        let head  = NSColor.white

        let out = NSMutableAttributedString()
        var inFence = false
        var inDisplayMath = false
        var displayMath = ""
        for raw in md.components(separatedBy: "\n") {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)

            if !inFence, trimmed == "$$" || trimmed == "\\[" {
                if inDisplayMath {
                    out.append(math(displayMath, font: body, color: bodyColor, display: true))
                    out.append(NSAttributedString(string: "\n"))
                    displayMath = ""
                    inDisplayMath = false
                } else {
                    inDisplayMath = true
                    displayMath = ""
                }
                continue
            }
            if !inFence, inDisplayMath {
                if trimmed == "\\]" {
                    out.append(math(displayMath, font: body, color: bodyColor, display: true))
                    out.append(NSAttributedString(string: "\n"))
                    displayMath = ""
                    inDisplayMath = false
                } else {
                    displayMath += (displayMath.isEmpty ? "" : " ") + raw
                }
                continue
            }
            if trimmed.hasPrefix("```") { inFence.toggle(); continue }   // fence marker, not shown
            if inFence {
                out.append(NSAttributedString(string: raw + "\n", attributes: [
                    .font: NSFont.monospacedSystemFont(ofSize: bodySize - 1, weight: .regular),
                    .foregroundColor: codeC, .backgroundColor: codeBG]))
                continue
            }
            if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                out.append(NSAttributedString(string: String(repeating: "\u{2500}", count: 24) + "\n",
                                              attributes: [.font: body, .foregroundColor: dim]))
                continue
            }
            if let (level, text) = heading(trimmed) {
                let size = bodySize + (level == 1 ? 6 : level == 2 ? 3 : 1)
                out.append(inline(text, font: NSFont.boldSystemFont(ofSize: size),
                                  color: head, codeC: codeC, codeBG: codeBG))
                out.append(NSAttributedString(string: "\n"))
                continue
            }
            if let item = bullet(trimmed) {
                out.append(NSAttributedString(string: "  •  ", attributes: [.font: body, .foregroundColor: bodyColor]))
                out.append(inline(item, font: body, color: bodyColor, codeC: codeC, codeBG: codeBG))
                out.append(NSAttributedString(string: "\n"))
                continue
            }
            out.append(inline(raw, font: body, color: bodyColor, codeC: codeC, codeBG: codeBG))
            out.append(NSAttributedString(string: "\n"))
        }
        if inDisplayMath {
            out.append(math(displayMath, font: body, color: bodyColor, display: true))
        }
        if out.string.hasSuffix("\n") { out.deleteCharacters(in: NSRange(location: out.length - 1, length: 1)) }
        return out
    }

    private static func heading(_ line: String) -> (Int, String)? {
        var level = 0, idx = line.startIndex
        while idx < line.endIndex, line[idx] == "#", level < 6 { level += 1; idx = line.index(after: idx) }
        guard level > 0, idx < line.endIndex, line[idx] == " " else { return nil }
        return (level, String(line[line.index(after: idx)...]))
    }

    private static func bullet(_ line: String) -> String? {
        if line.hasPrefix("- ") { return String(line.dropFirst(2)) }
        if line.hasPrefix("* ") { return String(line.dropFirst(2)) }
        return nil
    }

    // Inline spans: `code`, **bold**, *italic* / _italic_, and $LaTeX$ math.
    // Linear scan with a style flush.
    static func inline(_ s: String, font: NSFont, color: NSColor,
                       codeC: NSColor, codeBG: NSColor) -> NSAttributedString {
        let out = NSMutableAttributedString()
        let a = Array(s); let n = a.count
        var i = 0, buf = "", bold = false, italic = false
        func flush() {
            guard !buf.isEmpty else { return }
            var traits: NSFontTraitMask = []
            if bold { traits.insert(.boldFontMask) }
            if italic { traits.insert(.italicFontMask) }
            let f = traits.isEmpty ? font : NSFontManager.shared.convert(font, toHaveTrait: traits)
            out.append(NSAttributedString(string: buf, attributes: [.font: f, .foregroundColor: color]))
            buf = ""
        }
        while i < n {
            let c = a[i]
            if c == "`" {
                flush()
                var j = i + 1, code = ""
                while j < n, a[j] != "`" { code.append(a[j]); j += 1 }
                if j < n {
                    out.append(NSAttributedString(string: code, attributes: [
                        .font: NSFont.monospacedSystemFont(ofSize: font.pointSize - 0.5, weight: .regular),
                        .foregroundColor: codeC, .backgroundColor: codeBG]))
                    i = j + 1; continue
                }
            }
            if c == "$" {
                flush()
                let display = i + 1 < n && a[i + 1] == "$"
                var j = i + (display ? 2 : 1)
                var latex = ""
                while j < n {
                    if display, j + 1 < n, a[j] == "$", a[j + 1] == "$" { break }
                    if !display, a[j] == "$" { break }
                    latex.append(a[j]); j += 1
                }
                if (display && j + 1 < n) || (!display && j < n) {
                    out.append(math(latex, font: font, color: color, display: display))
                    i = j + (display ? 2 : 1); continue
                }
            }
            if c == "\\", i + 1 < n, (a[i + 1] == "(" || a[i + 1] == "[") {
                flush()
                let display = a[i + 1] == "["
                let close = display ? "]" : ")"
                var j = i + 2
                var latex = ""
                while j + 1 < n {
                    if a[j] == "\\", String(a[j + 1]) == close { break }
                    latex.append(a[j]); j += 1
                }
                if j + 1 < n {
                    out.append(math(latex, font: font, color: color, display: display))
                    i = j + 2; continue
                }
            }
            if c == "*", i + 1 < n, a[i + 1] == "*" { flush(); bold.toggle(); i += 2; continue }
            if c == "*" || c == "_" { flush(); italic.toggle(); i += 1; continue }
            buf.append(c); i += 1
        }
        flush()
        return out
    }

    private static let greek: [String: String] = [
        "alpha":"α","beta":"β","gamma":"γ","delta":"δ","epsilon":"ε","zeta":"ζ",
        "eta":"η","theta":"θ","iota":"ι","kappa":"κ","lambda":"λ","mu":"μ","nu":"ν",
        "xi":"ξ","pi":"π","rho":"ρ","sigma":"σ","tau":"τ","phi":"φ","chi":"χ",
        "psi":"ψ","omega":"ω","Gamma":"Γ","Delta":"Δ","Theta":"Θ","Lambda":"Λ",
        "Pi":"Π","Sigma":"Σ","Phi":"Φ","Psi":"Ψ","Omega":"Ω","infty":"∞"
    ]
    private static let ops: [String: String] = [
        "times":"×","cdot":"⋅","div":"÷","pm":"±","mp":"∓","leq":"≤","le":"≤",
        "geq":"≥","ge":"≥","neq":"≠","ne":"≠","approx":"≈","equiv":"≡","sim":"∼",
        "rightarrow":"→","to":"→","leftarrow":"←","Rightarrow":"⇒","partial":"∂",
        "nabla":"∇","int":"∫","sum":"∑","prod":"∏","forall":"∀","exists":"∃"
    ]

    private static func math(_ latex: String, font: NSFont, color: NSColor, display: Bool) -> NSAttributedString {
        let rendered = renderLatexText(latex)
        let size = display ? font.pointSize + 1 : font.pointSize
        let mathFont = NSFont(name: "STIX Two Math", size: size)
            ?? NSFont(name: "Times New Roman", size: size)
            ?? NSFont.systemFont(ofSize: size)
        let s = display ? "\n\(rendered)\n" : rendered
        return NSAttributedString(string: s, attributes: [
            .font: mathFont,
            .foregroundColor: color,
            .baselineOffset: display ? 0 : 1
        ])
    }

    private static func renderLatexText(_ latex: String) -> String {
        var s = latex.trimmingCharacters(in: .whitespacesAndNewlines)
        s = replaceFractions(in: s)
        s = replaceCommands(in: s)
        s = s.replacingOccurrences(of: #"\\left|\\right"#, with: "", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\\,"#, with: " ", options: .regularExpression)
        s = s.replacingOccurrences(of: #"\s+"#, with: " ", options: .regularExpression)
        return s.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func replaceCommands(in input: String) -> String {
        var out = ""
        let a = Array(input)
        var i = 0
        while i < a.count {
            if a[i] == "\\", i + 1 < a.count {
                var j = i + 1
                var name = ""
                while j < a.count, a[j].isLetter { name.append(a[j]); j += 1 }
                if name == "mathcal", j < a.count, a[j] == "{" {
                    let (body, end) = braced(Array(a[j...]))
                    out += mathcal(body)
                    i = j + end
                    continue
                }
                if let g = greek[name] ?? ops[name] {
                    out += g
                    i = j
                    continue
                }
                if !name.isEmpty {
                    out += name
                    i = j
                    continue
                }
            }
            out.append(a[i]); i += 1
        }
        return out
    }

    private static func replaceFractions(in input: String) -> String {
        var out = ""
        let a = Array(input)
        var i = 0
        while i < a.count {
            if i + 5 < a.count, String(a[i...min(i + 4, a.count - 1)]) == "\\frac" {
                var j = i + 5
                while j < a.count, a[j].isWhitespace { j += 1 }
                guard j < a.count, a[j] == "{" else { out.append(a[i]); i += 1; continue }
                let (num, nEnd) = braced(Array(a[j...]))
                j += nEnd
                while j < a.count, a[j].isWhitespace { j += 1 }
                guard j < a.count, a[j] == "{" else { out.append(a[i]); i += 1; continue }
                let (den, dEnd) = braced(Array(a[j...]))
                out += "\(renderLatexText(num))/\(renderLatexText(den))"
                i = j + dEnd
                continue
            }
            out.append(a[i]); i += 1
        }
        return out
    }

    private static func braced(_ a: [Character]) -> (String, Int) {
        guard a.first == "{" else { return ("", 0) }
        var depth = 0
        var body = ""
        for i in 0..<a.count {
            let c = a[i]
            if c == "{" {
                depth += 1
                if depth > 1 { body.append(c) }
            } else if c == "}" {
                depth -= 1
                if depth == 0 { return (body, i + 1) }
                body.append(c)
            } else {
                body.append(c)
            }
        }
        return (body, a.count)
    }

    private static func mathcal(_ s: String) -> String {
        let map: [Character: Character] = ["A":"𝒜","B":"ℬ","C":"𝒞","D":"𝒟","E":"ℰ",
                                           "F":"ℱ","G":"𝒢","H":"ℋ","I":"ℐ","J":"𝒥",
                                           "K":"𝒦","L":"ℒ","M":"ℳ","N":"𝒩","O":"𝒪",
                                           "P":"𝒫","Q":"𝒬","R":"ℛ","S":"𝒮","T":"𝒯",
                                           "U":"𝒰","V":"𝒱","W":"𝒲","X":"𝒳","Y":"𝒴","Z":"𝒵"]
        return String(s.map { map[$0] ?? $0 })
    }
}
