# overlay.session — the conversation that spawned Overlay P0

Companion to `overlay/overlay.feature`. Faithful, not flattering: this is the grade's
audit trail, so the wrong turns are in here too.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/3e92c228-3254-4396-9b54-d9ee14b5fc28.jsonl`
- Session ID: `3e92c228-3254-4396-9b54-d9ee14b5fc28`
- Resume: `claude --resume 3e92c228-3254-4396-9b54-d9ee14b5fc28`
- Date: 2026-08-11 (planning) → 2026-08-12 (P0 built), Apple skill session in `~/work/apple`

## The requests, in order

1. **"boot up apple skills"** — Sal archive refresh + TODO action queue.

2. **"here is a bunch of chat. i want the spatial overlay with chat, annotation and
   responses. r u able to plan how to do that using apple native skills."**
   Source: `~/work/convey-packs/chatgpt/6a785108-e47c-83ed-a844-e5bfaca19635/conversation.md`
   — a 2026-08-08 gpt-5-6-thinking thread that reasoned its way to the right abstraction
   ("a shared spatial blackboard between humans and machine agents") and then concluded
   **"prototype it in Electron."**

3. **"build p0, then test it hard, then start scaffolding and building p1. fullscreen
   games/DRM dont freaking matter."** Plus the destination, stated explicitly:

   > *"i want to combine apple foundational models in such a way that if i draw a square,
   > or a cube, that it can be turned into an image generation, or a comment. do you see?
   > so that i can show a part of an image (in this case, whiteboard image) and have the
   > models see only that and respond to that."*

   That sentence is why `OverlayObject.cropRect(in:pad:)` exists in P0 rather than P3.
   The whole point of the geometry layer is: **a drawn square is a crop rect**.

## Decisions and why

**Rejected the source thread's conclusion.** Electron would have meant a second
rendering engine, a second update path and a Homebrew dependency to reach where
`xcrun swiftc` reaches in an afternoon. Every primitive the thread wanted was verified
PUBLIC before a line was written.

**Probed before naming, per the skill's hard rule.** `bin/cocoa-class-probe` on NSPanel,
NSVisualEffectView, NSBezierPath, NSTrackingArea, CAShapeLayer, SCShareableContent,
NLEmbedding, NSTextView, PKCanvasView — all PUBLIC. `AXObserver` came back **ABSENT**,
which is correct and not a blocker: it is a CoreFoundation type, and `AXObserverCreate` +
`kAXWindowMovedNotification` were then verified directly in the SDK headers.

**Rejected PencilKit even though PKCanvasView is PUBLIC on macOS.** It would have given
the ink engine for free, but `PKDrawing` has nowhere to put actor, lifetime, anchor or
object identity, and the plan's core rule is that the data model must not be dictated by
the rendering backend. Hand-rolled NSBezierPath instead. This is a real trade — P0 has no
pressure or tilt support as a result.

**⌥⌘D became ⌃⌥⌘D.** Project memory `feedback_carbon_hotkey_gotchas` #2: a clean
`RegisterEventHotKey` does not mean the keystroke arrives, and the ⌃⌥⌘‹letter› family is
the one that survives iTerm2 / Karabiner / other menu-bar apps. Changed before building,
not after debugging.

**Renamed `Anchor` → `OverlayAnchor` mid-build.** SwiftUI ships its own `Anchor` type and
the module imports SwiftUI for the shared Help panel. Same-module types win, so it
compiled — but it was a trap sitting there for P1. Renamed while it was cheap.

**Refused to test the hotkey by synthesizing keystrokes.** `feedback_never_ui_hijack_active_session`:
System Events keys land in whatever is frontmost, which is Esa's terminal. Built
`--selftest` instead — it constructs `NSEvent`s and hands them **directly to the view**,
touching the real window server without posting anything to the event system. Three
scenarios are therefore graded `@needs-human` rather than claimed as passing.

## Corrections made during the build

- **Bug caught by the tests before any UI existed.** `Geometry.decimate` guarded the
  tail-keep on the *output* count (`out.count > 1`), so a two-point flick shorter than
  the threshold collapsed to a single point — which draws nothing at all. The guard
  belongs on the *input* count. The failing assertion existed before the bug was found.
- **`-parse-as-library` needs `@main`.** First build failed with "expressions are not
  allowed at the top level". Also required owning the AppDelegate in a static, since
  `NSApplication.delegate` is weak and a local `let` would be released before
  `applicationDidFinishLaunching` ever ran.
- **`activatesOnDraw`** was added purely so the self-test cannot yank focus away from
  whatever Esa is doing. The cost is honest: the focus-restore path is consequently
  ungraded.

## What was NOT done, and said so

- No restore-on-launch. There is no durable Space identity in public API; restoring would
  splatter old ink onto the wrong desktop. `session.json` is written, never read back.
- No window attachment, no agent inbox, no chat, no model. P2 / P1 / P3 respectively.
- Fullscreen games and DRM video were explicitly dropped from scope by Esa.

## Verification at the point of hand-off

- `overlay-tests.swift` — 61 assertions, 0 failures (pure core, headless)
- `OverlaySelfTest` — 49 assertions, 0 failures (live window server)
- Idle cost — 0.0% CPU, 12 MB RSS after a minute up
- `RegisterEventHotKey` status 0, `Overlay: ready` in the unified log
