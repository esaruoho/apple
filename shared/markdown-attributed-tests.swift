// Headless tests for MarkdownAttributed — runs on the laptop, no GUI/FM/Mini.
// Compiled + run by shared/test-markdown-attributed.sh.
import Cocoa

var failed = false
func check(_ cond: Bool, _ msg: String) {
    print((cond ? "ok   - " : "FAIL - ") + msg); if !cond { failed = true }
}

@main
enum MarkdownTests {
    static func main() {
        let md = """
        # Whiteboard Knob
        **Goal:** browse `~/work/` boards
        ---
        - one
        - two
        """
        let a = MarkdownAttributed.render(md)
        let s = a.string

        check(s.contains("Whiteboard Knob"), "heading text kept")
        check(!s.contains("#"), "no leading # markers")
        check(!s.contains("**"), "no ** bold markers")
        check(!s.contains("`"), "no backtick markers")
        check(s.contains("•"), "bullets rendered")
        check(s.contains("\u{2500}"), "--- rendered as a rule")

        let g = (s as NSString).range(of: "Goal:")
        check(g.location != NSNotFound, "Goal present")
        if g.location != NSNotFound, let f = a.attributes(at: g.location, effectiveRange: nil)[.font] as? NSFont {
            check(f.fontDescriptor.symbolicTraits.contains(.bold), "Goal is bold")
        }
        let c = (s as NSString).range(of: "~/work/")
        check(c.location != NSNotFound, "code text present")
        if c.location != NSNotFound, let f = a.attributes(at: c.location, effectiveRange: nil)[.font] as? NSFont {
            check(f.fontDescriptor.symbolicTraits.contains(.monoSpace), "code span is monospaced")
        }

        print(failed ? "SOME TESTS FAILED" : "ALL PASS")
        exit(failed ? 1 : 0)
    }
}
