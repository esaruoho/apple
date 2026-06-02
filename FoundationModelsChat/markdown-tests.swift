// markdown-tests.swift — HEADLESS tests for the chat's Markdown→HTML renderer.
// Run:  ./test-markdown.sh   (compiles with Markdown.swift via swiftc)
// Pure Foundation — runs on any Mac, no GUI, no model. Add a case for every
// rendering bug. The whole point: catch render bugs here, not in a screenshot.
import Foundation

var failures = 0
func check(_ name: String, _ cond: Bool, _ got: String = "") {
    if cond { print("  ok  \(name)") }
    else { print("FAIL  \(name)\n      got: \(got)"); failures += 1 }
}
func count(_ s: String, _ sub: String) -> Int { s.components(separatedBy: sub).count - 1 }

@main
enum MarkdownTests {
    static func main() {
        // — ordered lists must COUNT UP: blank lines between items must NOT restart at 1.
        // (This is the 2026-06-02 bug: each "1." became its own <ol>.)
        let ol = renderMessageHTML("1. first\n\n2. second\n\n3. third")
        check("ordered list is ONE <ol>", count(ol, "<ol>") == 1, ol)
        check("ordered list has 3 <li>", count(ol, "<li>") == 3, ol)
        let olSame = renderMessageHTML("1. a\n\n1. b\n\n1. c")   // model often emits all "1."
        check("all-1 source still ONE <ol>", count(olSame, "<ol>") == 1 && count(olSame, "<li>") == 3, olSame)

        // — <math> the model emits must pass through verbatim, NOT be escaped/swallowed.
        let m = renderMessageHTML("here: <math><mi>x</mi></math> end")
        check("MathML passthrough", m.contains("<math><mi>x</mi></math>") && !m.contains("&lt;math"), m)

        // — fenced code block
        let code = renderMessageHTML("```swift\nlet x = 1\n```")
        check("code fence → pre/code", code.contains("<pre><code>") && code.contains("let x = 1"), code)

        // — inline formatting
        check("bold", renderMessageHTML("**hi**").contains("<strong>hi</strong>"), renderMessageHTML("**hi**"))
        check("italic", renderMessageHTML("*hi*").contains("<em>hi</em>"), renderMessageHTML("*hi*"))
        check("inline code", renderMessageHTML("`x`").contains("<code>x</code>"), renderMessageHTML("`x`"))
        check("link", renderMessageHTML("[a](http://x)").contains("<a href=\"http://x\">a</a>"), renderMessageHTML("[a](http://x)"))

        // — headings
        check("h2", renderMessageHTML("## Title").contains("<h2>Title</h2>"), renderMessageHTML("## Title"))

        // — unordered list
        let ul = renderMessageHTML("- a\n- b\n- c")
        check("ul is ONE <ul> with 3 <li>", count(ul, "<ul>") == 1 && count(ul, "<li>") == 3, ul)
        let ulLoose = renderMessageHTML("- a\n\n- b")   // blank line between bullets
        check("loose ul stays ONE <ul>", count(ulLoose, "<ul>") == 1 && count(ulLoose, "<li>") == 2, ulLoose)

        // — a list followed (after blank) by a paragraph must CLOSE the list
        let mix = renderMessageHTML("1. a\n2. b\n\nDone.")
        check("list closes before paragraph", count(mix, "<ol>") == 1 && mix.contains("<p>Done.</p>"), mix)

        // — plain text + HTML-escaping of stray angle brackets
        check("paragraph", renderMessageHTML("just text").contains("<p>just text</p>"), renderMessageHTML("just text"))
        check("escapes stray <", renderMessageHTML("a < b").contains("&lt;"), renderMessageHTML("a < b"))

        // — no raw sentinel leaks (the placeholders must all be restored)
        let combo = renderMessageHTML("# H\n\n1. `code`\n\n2. **bold**\n\ntext")
        check("no sentinel leak", !combo.contains("\u{e000}"), combo)

        if failures == 0 { print("\n✅ ALL MARKDOWN TESTS PASS") }
        else { print("\n❌ \(failures) MARKDOWN TEST FAILURE(S)"); exit(1) }
    }
}
