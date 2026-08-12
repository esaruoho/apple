# FEATURE CARD — Overlay P0: a click-through spatial canvas over the desktop
#
# WHAT THIS CARD SPAWNS
#   Codespace   overlay/OverlayCore.swift      platform-neutral core (no AppKit)
#               overlay/Overlay.swift          AppKit adapter: panel, ink view, hotkey, menu bar
#               overlay/OverlaySelfTest.swift  AppKit assertions against a live window server
#               overlay/overlay-tests.swift    pure-core assertions, headless
#               overlay/build.sh               test-gated build → Overlay.app
#               bin/overlay                    python3-stdlib CLI (open/quit/status/dump/reveal)
#   Thinkspace  overlay/overlay.session.md — the conversation that produced this
#               wiki/operations/spatial-overlay-plan.md — the five-phase plan
#   Areaspace   OWNS:  the transparent canvas layer, its object store, its input mode
#               TOUCHES NOT: other apps' windows (P2), the pointer of any other app,
#               any private CGS/SkyLight Space API, any synthesized keystroke
#
# RESULT
#   Feature commits:  (see git log for overlay/ — P0 landed 2026-08-12)
#   PR:               direct-push, no PR
#   Card commits:     same commit as the code (born together)
#   Files changed:    overlay/{OverlayCore,Overlay,OverlaySelfTest,overlay-tests}.swift,
#                     overlay/build.sh, bin/overlay, wiki/operations/spatial-overlay-plan.md
#
# GRADES
#   @verified      asserted by overlay-tests.swift or OverlaySelfTest and passing
#   @measured      measured on this Mac, number recorded
#   @needs-human   correct by construction + API contract, but needs a real keypress/click
#   @todo          named, not built — belongs to a later phase

Feature: A spatial canvas that floats over everything and is invisible until asked for

  Background:
    Given Overlay.app is running as an .accessory app (menu-bar only)
    And no Accessibility, Screen Recording or any other TCC grant has been requested

  # ─────────────────────────── the core ───────────────────────────

  @verified
  Scenario: A stroke's bounding box is the crop rect a model will be shown
    Given a square drawn from (300,300) spanning 200x200
    When its cropRect is taken with 24pt of padding
    Then the rect is 248 wide and stays inside the screen
    # OverlayCore.swift Geometry.padded / OverlayObject.cropRect
    # This is the seam P3 hands to FoundationModels — draw a square, get that region.

  @verified
  Scenario: Ink survives a window moving, resizing and changing resolution
    Given a point normalized against a 400x800 parent at (100,200)
    When the same normalized point is re-projected into a 200x400 parent at (900,0)
    Then it lands proportionally in the same place
    # Geometry.normalize/denormalize. Nothing is stored in desktop pixels.

  @verified
  Scenario: A degenerate parent cannot poison the store
    Given a parent rect of zero width and height
    When a point is normalized against it
    Then the result is 0, not NaN

  @verified
  Scenario: Trackpad oversampling is discarded but the endpoint is kept
    Given 100 samples one pixel apart and a 5pt decimation threshold
    Then roughly every 5th sample survives, including the first and the last
    And a 2-point flick shorter than the threshold still keeps both points
    # Regression: the first implementation collapsed short flicks to a single
    # point, which renders as nothing. Caught by overlay-tests before any UI existed.

  @verified
  Scenario: Malformed agent JSON throws instead of taking the app down
    Given a body of "{ not json"
    When the store decodes it
    Then it throws

  @verified
  Scenario: Agent TTLs are collected, human ink never is
    Given a stale ephemeral mark, a fresh ephemeral mark and a persistent one
    When expire() runs
    Then only the stale ephemeral mark is removed

  @verified
  Scenario: Undo, redo and the redo-branch invariant
    Given three strokes, one undone
    When a new stroke is drawn
    Then redo is no longer possible
    And clear() is itself undoable one stroke at a time

  # ─────────────────────────── the overlay ───────────────────────────

  @verified
  Scenario: The panel is a genuine overlay
    When draw mode is entered for the first time
    Then a canvas exists for every display
    And its panel is borderless, non-activating, shadowless and fully transparent
    And it sits at NSWindow.Level.floating
    And its frame exactly equals its screen's frame
    # OverlaySelfTest, run against a live window server: 1512x982 matched.

  @verified
  Scenario: Screen-anchored ink belongs to the Space it was drawn in
    When a canvas is created
    Then its collectionBehavior does NOT contain .canJoinAllSpaces
    And it does contain .fullScreenAuxiliary
    And isOnActiveSpace reports true
    # The whole Spaces story with zero private API: it is an ordinary managed
    # window, so macOS slides it away with its Space for free.

  @verified
  Scenario: The Mac stays usable with the overlay up
    When the mode is passthrough
    Then the panel ignoresMouseEvents
    And the panel is still visible — only input changes, never the ink

  @verified
  Scenario: A drag becomes one provenance-stamped object
    When a square is dragged on the canvas
    Then exactly one object is stored
    And it records actor "human:esa", lifetime persistent, and an anchor naming the display
    And its bounding box matches where it was drawn to within 2pt

  @verified
  Scenario: Keyboard control inside draw mode
    When "2" is pressed          Then the second palette colour is selected
    When "]" then "[" is pressed Then the stroke widens and narrows back
    When Cmd-Z is pressed        Then the last mark is undone
    When Shift-Cmd-Z is pressed  Then it comes back
    When Esc is pressed          Then draw mode ends and the panel goes click-through

  @verified
  Scenario: Marks are mirrored to disk
    When persist() runs
    Then ~/.overlay/store/session.json holds every mark across every canvas
    And each one parses back byte-identical

  @measured
  Scenario: The overlay costs nothing to leave running
    Given the app has been up for a minute with no interaction
    Then CPU is 0.0% and RSS is 12 MB
    # Nothing polls in P0 — no timer, no run loop work, no window scanning.

  @needs-human
  Scenario: The global hotkey actually fires
    When Ctrl-Opt-Cmd-D is pressed anywhere
    Then draw mode toggles
    # RegisterEventHotKey returned status 0 and "Overlay: ready" is in the log, but
    # per feedback_carbon_hotkey_gotchas #2 a clean registration does NOT prove the
    # keystroke arrives — an upstream interceptor can still swallow it. Chose the
    # Ctrl-Opt-Cmd family for exactly this reason. Needs one real keypress to grade.

  @needs-human
  Scenario: Clicks really do pass through to Safari underneath
    Given the overlay is up in passthrough with ink on it
    When Safari is clicked where the ink is
    Then Safari receives the click
    # ignoresMouseEvents is asserted true by the self-test; end-to-end delivery is a
    # window-server behaviour that only a real click can demonstrate. Deliberately
    # NOT tested by synthesizing a click — that would hijack the frontmost app
    # (feedback_never_ui_hijack_active_session).

  @needs-human
  Scenario: Esc hands focus back to the app you came from
    When draw mode ends
    Then the application that was frontmost before it began is reactivated
    # NSWorkspace frontmostApplication is captured on entry and .activate()d on exit.
    # The self-test runs with activatesOnDraw = false so it cannot steal Esa's focus,
    # which means this specific path is unexercised by it.

  # ─────────────────────────── known limits ───────────────────────────

  @todo
  Scenario: Marks are restored after a relaunch
    # Deliberately NOT done. macOS exposes no durable Space identity through public
    # API, so restoring would drop yesterday's ink onto whichever desktop happens to
    # be frontmost. session.json is written for inspection and for P1's agent side.
    # Persistence across restarts needs a window or display anchor — that is P2.

  @todo
  Scenario: Ink attaches to another app's window and follows it
    # P2: CGWindowList fingerprint first (no permission), then AXObserver.

  @todo
  Scenario: An agent posts an object without a compile step
    # P1: ~/.overlay/inbox/*.json + `overlay post` + semantic object kinds.

  @todo
  Scenario: A drawn square becomes a question with a picture attached
    # P3: ScreenCaptureKit crop of cropRect + vision-ocr + anchored chat bubble,
    # answered by bin/fm on-device. This is the destination; P0 built the geometry
    # and provenance it needs.
