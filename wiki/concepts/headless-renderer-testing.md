---
description: The FoundationModelsChat Markdown renderer is pure Foundation, extracted to Markdown.swift so it can be tested headlessly (no GUI/FM/Mini). Run test-markdown.sh before claiming any render fix works; build.sh gates on it.
---

# Headless renderer testing — catch render bugs in a test, not a screenshot

The chat app (`FoundationModelsChat`) renders the model's Markdown to HTML for a WKWebView.
That renderer is **pure logic** — `String` in, HTML `String` out, no AppKit, no WebKit, no
FoundationModels, no network. So it's the most testable thing in the app, and there is no
excuse for finding its bugs by eye. This page is the rule for doing it right.

## The mistake this fixes

Render bugs kept surfacing only when Esa screenshotted them: `<math>` blocks getting
swallowed/escaped, ordered lists showing `1. 1. 1.` instead of counting up (blank lines
between items were closing the `<ol>`). Leaning on the user's eyeballs as the test suite is
backwards — and it burned his patience. A renderer gets an assertion test, full stop.

## The shape

| File | Role |
|---|---|
| `FoundationModelsChat/Markdown.swift` | The renderer + helpers (`escapeHTML`, `regexReplace`, `latexToMathML`, `renderMessageHTML`, `inlineMD`), extracted out of `main.swift`. **Pure Foundation — no AppKit.** Compiled into the app *and* into the test. Single source of truth, no divergence. |
| `FoundationModelsChat/markdown-tests.swift` | `@main` test runner: feeds known-tricky Markdown to `renderMessageHTML` and asserts the HTML. Prints `ok`/`FAIL` per case, exits nonzero on any failure. |
| `FoundationModelsChat/test-markdown.sh` | `swiftc Markdown.swift markdown-tests.swift -o … && run`. Runs on **any** Mac — no macOS 26, no FM, no Mini, no GUI. |
| `FoundationModelsChat/build.sh` | Runs `test-markdown.sh` **before** compiling the app. A render regression blocks the build loudly. |

Why extraction matters: `renderMessageHTML` used to live inside `main.swift`, which
`import`s AppKit/WebKit/FoundationModels — so it could only compile on the Mini (macOS 26).
Pulling the pure-Foundation renderer into its own file means the laptop can compile and test
it in ~1 s. `main.swift` and the test both compile `Markdown.swift`, so there's one renderer,
never a drifting copy.

## The rule

1. **Before claiming a render fix works — and before/after changing rendering at all — run
   `./FoundationModelsChat/test-markdown.sh`.** Green or it's not done.
2. **Every render bug gets a test case** that asserts the exact failure, added in the same
   change that fixes it. Ordered list → exactly one `<ol>` with N `<li>`; `<math>` present and
   NOT `&lt;math`; no leftover `\u{e000}` sentinels; etc.
3. **Never rely on Esa screenshotting a rendering bug.** The screenshot is the symptom; the
   test is where it should have died.
4. `build.sh` enforces 1–2 automatically (the gate), so a regression can't reach the Mini.

## It has teeth (verified)

Reintroducing the ordered-list bug (blank line always closes the list) makes the suite report
3 FAILs and exit 1. A passing run that can't fail is theatre; this one fails when it should.

## Generalize it

Any pure-logic unit — parser, formatter, router, the `@Generable` extractors, the
`apple-do` dispatcher's arg parsing — gets the same treatment: if it's `data → data` with no
side effects, extract it from the UI/IO layer (if buried) and put assertions on the tricky
inputs. Logic you can test headlessly, you test headlessly.

## See also
- `FoundationModelsChat/` — the chat app (renderer, tests, build gate)
- [on-device-ml.md](on-device-ml.md) — the FoundationModels stack the app runs on (Mini only)
- memory `feedback-test-renderers-headlessly` — the cross-session version of this rule
