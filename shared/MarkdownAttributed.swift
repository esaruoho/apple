// MarkdownAttributed.swift — render Markdown to an NSAttributedString for AppKit text
// views (AppleBar's result pane, and anything else that shows model/markdown output).
// The repo already has FoundationModelsChat/Markdown.swift, but that renders to HTML for
// a WebView; an NSTextView needs attributed strings, so this is the attributed sibling.
//
// Handles the constructs that actually show up in tool output: # / ## / ### headings,
// **bold**, *italic* / _italic_, `inline code`, ``` fenced code ```, --- rules, and
// - / * bullets. Plain lines pass through. Pure logic → headless-testable
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
        for raw in md.components(separatedBy: "\n") {
            let trimmed = raw.trimmingCharacters(in: .whitespaces)

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

    // Inline spans: `code`, **bold**, *italic* / _italic_. Linear scan with a style flush.
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
            if c == "*", i + 1 < n, a[i + 1] == "*" { flush(); bold.toggle(); i += 2; continue }
            if c == "*" || c == "_" { flush(); italic.toggle(); i += 1; continue }
            buf.append(c); i += 1
        }
        flush()
        return out
    }
}
