# WHAT THIS CARD SPAWNS
#
# Codespace: iphonemirror/iiPhoneMirror.swift · iphonemirror/build.sh · bin/iphonemirror (shim)
#            wiki/concepts/iphone-usb-capture-probe.md (the diagnosis knowledge)
# Thinkspace: features/phonemirror-rotated-live-mirror.session.md
# Areaspace: OWNS the live display of a USB iOS device screen on this Mac — orientation, crop,
#            and CoreMediaIO device discovery for iOS screen-capture DAL devices.
#            Does NOT own: recording (that is recburn), pairing/Trust (that is iOS + usbmuxd),
#            the phone's own UI orientation (that is Rotation Lock on the device).
#
# RESULT
#   Feature commits : see RESULT-LOG below (stamped by hooks/pre-commit)
#   PR              : direct-push, no PR
#   Files changed   : phonemirror/iPhoneMirror.swift, phonemirror/build.sh, bin/phonemirror,
#                     features/phonemirror-rotated-live-mirror.feature (+ .session.md),
#                     wiki/concepts/iphone-usb-capture-probe.md

Feature: iPhoneMirror — live, auto-oriented, auto-cropped mirror of a USB iPhone screen
  QuickTime Player can mirror a Lightning-connected iOS device, but its Edit ▸ Rotate Left /
  Rotate Right / Flip items are DISABLED during a live capture session, and its scripting
  dictionary has no rotate terminology at all. So a phone held in landscape whose iOS UI is
  locked to portrait cannot be un-rotated live — you can only record and then rotate the file.
  This app rotates the AVCaptureVideoPreviewLayer instead, so the window is already correct and a
  one-shot screen recording needs no post-edit.

  @built @hw-verified
  Scenario: A Lightning iPhone is found at all
    Given an iOS device connected over USB and trusted
    When iPhoneMirror starts
    Then it sets kCMIOHardwarePropertyAllowScreenCaptureDevices on the CMIO system object
    And the device then appears in AVCaptureDevice enumeration
    # Without that property an iOS screen-capture DAL device is INVISIBLE to AVCaptureDevice.
    # QuickTime sets it; nothing else does by default. Verified: device "esaiPhoneX" opened.
    # → allowScreenCaptureDevices(), iPhoneMirror.swift

  @built @hw-verified
  Scenario: The live feed is rotated, which QuickTime cannot do
    Given the phone's iOS UI is drawing portrait while the phone is held landscape
    When iPhoneMirror displays it at 90°
    Then the scene is upright and landscape in the window with no recording step
    # Verified on screen: a CRT showing "E:\ITNU2026>_" legible and upright.
    # → PreviewView.layout(), CATransform3DMakeRotation

  @built @hw-verified
  Scenario: Orientation is chosen by reading the SCENE, not the chrome
    Given Vision OCR can read text at all four rotations
    When iPhoneMirror scores each rotation
    Then it prefers the rotation where text INSIDE the viewfinder reads upright
    And it falls back to (chrome-upright + 90°) when the scene has no readable text
    # Upright chrome indicates the iOS UI orientation, which is the WRONG target: with Rotation
    # Lock on, iOS draws UI upright and turns the scene 90°. Measured failure before this fix:
    # chose 0° because SLO-MO/VIDEO/PHOTO/PORTRAIT/SQUARE read upright.
    # → detectOrientation()

  @built @hw-verified
  Scenario: OCR garbage from upside-down chrome is rejected
    Given the chrome band read at 180° yields invented words
    When scene scoring runs
    Then only text whose box falls INSIDE the detected viewfinder counts
    # Measured failure before this fix: SQUARE→"IYVNUS", PHOTO→"OIOHD", VIDEO→"OAAIA",
    # PORTRAIT→"IIVIIITIOD", SLO-MO→"OW-OIS" scored as scene text and forced 180°.
    # → sceneWords() closure in detectOrientation(), confidence >= 0.4

  @built @hw-verified
  Scenario: Camera.app's mode wheel is cropped out by default
    Given the mode-wheel labels are located by name in source coordinates
    When the crop is computed
    Then the band they occupy is removed, and the window opens at the cropped aspect
    # Verified on screen: mode wheel and shutter absent from the window.
    # → detectCrop(), mapRect() for source↔display coordinate mapping

  @built @hw-verified
  Scenario: Camera.app's ICON control row is also cropped out
    Given the opposite control band holds glyphs (flash, timer, Live Photo) and no words
    When the crop is computed from the viewfinder's known GEOMETRY, not from luminance
    Then that band is removed too
    # FOUR measured dead ends before this worked, all recorded so they are not re-walked:
    #   1. MEAN luminance — white glyphs lift a black band's mean above any threshold; band stayed
    #   2. RELATIVE/max threshold — one overexposed window dominated max; cropped to a 0.156 sliver
    #   3. MEDIAN luminance — the SUBJECT is a black DOS CRT, so no brightness test can separate
    #      "black control band" from "black subject". It ate the middle of the feed (w=0.523).
    #   4. Sliding a 4:3 window to maximise contained image — picked the chrome band, whose big
    #      white shutter circle and colour thumbnail outweighed a dark subject.
    # What works: pure GEOMETRY. The viewfinder spans the full short edge and PHOTO mode is 4:3,
    # so the band is anchored to the OCR-located mode wheel with one measured gap constant.
    # → detectCrop(), gapToPreview

  @built @hw-verified
  Scenario: Bare invocation just works
    Given no command-line arguments
    When `iphonemirror` runs
    Then rotation and crop are both auto-detected
    And a non-Camera screen (home screen) yields 0° and no crop
    # Verified: home screen read as PHONE/MESSAGES/MAIL/SETTINGS/FIND MY → 0°, crop 1.0×1.0,
    # portrait 423×944 window. Adapting to what it sees, not assuming Camera.app.

  @built @untested
  Scenario: Detection does not deadlock the main thread
    Given the CoreMediaIO plugin needs a live run loop to deliver frames
    When the first frame drives the Vision pass
    Then the window opens immediately with a safe default and snaps to the detected values
    # Measured failure before this fix: blocking on a semaphore in applicationDidFinishLaunching
    # starved the plugin — 0 frames in 5s, "could not read a frame".
    # → FirstFrameWatcher, inspect() dispatching to a background queue

  @built @untested
  Scenario: The device is single-client, and that is explained not swallowed
    Given QuickTime holds a Movie Recording window on the same phone
    When iPhoneMirror cannot open the device
    Then the failure text says the device is SINGLE-CLIENT and names QuickTime
    # → failNoDevice(), AVCaptureDeviceInput failure branch

  @built @hw-verified
  Scenario: The crop constant is calibrated, and nudgeable when it is not right
    Given the gap between the mode-wheel text and the 4:3 preview edge is a fixed iOS layout
    When the band is anchored with gapToPreview = 0.040
    Then the viewfinder fills the window with uniform edges
    And ⌘[ / ⌘] slide the crop live, preserving its size
    # Measured extremes that bracket it: 0.012 left a black bar on the far side only; 0.062 pulled
    # the icon strip in on the near side. Esa's read at 0.062: "almost.. just a little bit to the
    # right". → gapToPreview, slideCrop()

  @built @hw-verified
  Scenario: Space hides every other app
    Given the mirror should be the only thing on screen for a recording
    When Space is pressed with no modifier
    Then every other app hides, and Space again restores them
    # Uses NSApplication.hideOtherApplications / unhideAllApplications — the ⌘⌥H path. Per-app
    # NSRunningApplication.hide() returned false for every app (measured: "hid 0 app(s)").
    # A plain-Space menu keyEquivalent would render as ⌘Space (Spotlight), so it is a local
    # key monitor. NOT synthesised keystrokes — those land on whatever is frontmost.
    # → toggleSolo(), addLocalMonitorForEvents

  @built @hw-verified
  Scenario: It ships the SHARED Help and donate panel, like every app here
    Given the project ground rule is one Help component for all Apple-native apps
    When Help ▸ PhoneMirror Help (⌘?) or the About item is chosen
    Then the shared AppHelpView from shared/SupportHelp.swift opens
    And the donation links come from SupportLinks, not a per-app list
    # This app is AppKit, so the shared SwiftUI view is hosted via NSHostingController. Compiling
    # two files means top-level code is illegal → @main + -parse-as-library.
    # I shipped the first version WITHOUT this and Esa had to ask. It is a ground rule; bake it in
    # from the start. → showHelp(), build.sh compiling ../shared/SupportHelp.swift

  @built @hw-verified
  Scenario: It has a real app icon, on the macOS icon grid
    Given a generic placeholder icon reads as unfinished
    And a full-bleed icon reads as OVERSIZED next to every other Dock icon
    When build.sh runs
    Then AppIcon.icns is generated on Apple's grid and referenced by CFBundleIconFile
    # The grid is now DOCUMENTED: wiki/concepts/macos-app-icon-sizing.md. guidance/ and topbar/
    # already used 0.098 / 0.2237 — the convention existed, undocumented, and I ignored it.
    # Drawn programmatically (AppKit NSBezierPath) at all 10 iconutil sizes — a landscape phone
    # with a rotation arc, which is literally what the app does. No third-party asset pipeline.
    # Apple's macOS template is an 824x824 shape on a 1024x1024 canvas: ~9.77% transparent margin
    # per side, corner radius 22.48% of the shape, plus a soft contact shadow. v1 filled the whole
    # canvas and looked too big. ALL interior geometry is relative to the inset art square (A),
    # never the canvas (S) — otherwise contents overflow the shape. → make-icon.swift
    # v1 also hid the arc behind the phone body and drew a notch that read as a defect.

  @built @hw-verified
  Scenario: There is exactly ONE copy of the app, in /Applications
    Given running the bundle from the build directory makes every rebuild a different app to macOS
    When build.sh finishes
    Then it dittos the bundle to /Applications/PhoneMirror.app and lsregisters both
    And bin/phonemirror execs the INSTALLED binary, falling back to the build copy
    # Why it matters: separate bundle paths mean separate TCC identities (so the Camera grant is
    # re-prompted), stale Launch Services entries, and two icons in the Dock. ditto rather than cp
    # because it copies bundles faithfully and preserves the signature — and cp is aliased to -iv
    # on this machine, which would prompt and silently leave the destination stale.
    # NOT visually confirmed in the Dock: the Dock is auto-hidden here, so the icon's rendered
    # appearance at Dock size is unverified. The bundle contents and lsregister run are verified.

  @built @hw-verified
  Scenario: Several phones at once, ticked on and off from a menu
    Given two or three iOS devices are plugged in
    When iPhoneMirror starts
    Then nothing opens by itself; the Devices menu lists every device
    And clicking a device ticks it ON and opens its own window
    And clicking it again unticks it and closes that window
    And each window has its OWN session, orientation, crop and resize
    # Verified with esaiPhoneX (Lightning) + esaiPhone16Pro (USB-C) open simultaneously, each
    # detected independently. Menu shows "Showing <name>" ticked vs "Show <name>".
    # Menu-driven rather than auto-opening: Esa wants to choose which phones are on screen.
    # → Mirror (one per device), AppDelegate.toggleDeviceFromMenu, rebuildDevicesMenu

  @built @hw-verified
  Scenario: Unticking a device does not crash the app
    Given a Mirror owns its window and is owned by the app's mirrors array
    When its window closes
    Then the window is NOT released by AppKit, and the Mirror outlives its own callback
    # MEASURED CRASH: EXC_BAD_ACCESS / SIGSEGV in objc_release during objc_autoreleasePoolPop,
    # immediately on unticking a device. TWO distinct lifetime bugs:
    #   1. A programmatically-created NSWindow defaults to isReleasedWhenClosed = true, so AppKit
    #      released it AND ARC released our strong property → double release.
    #   2. mirrors.removeAll() ran inside the Mirror's own windowWillClose, deallocating it
    #      mid-callback. Removal is now deferred to the next run-loop turn.
    # Stress-verified: 4 untick/retick cycles, no new crash report.
    # → buildWindow (isReleasedWhenClosed = false), windowWillClose, mirrorClosed

  @built @hw-verified
  Scenario: Each device remembers its own calibration
    Given rotation and crop are dialled in for one phone
    When it is reopened, or the app restarts
    Then that device's own settings come back, keyed by its uniqueID
    # Verified from the log: "esaiPhoneX: restored saved calibration rot=0 crop=0,0,1,1" and
    # "esaiPhone16Pro: restored saved calibration rot=0 crop=0,0.275,1,0.613".
    # A restored calibration disables auto-detect for that device — ⌘D re-detects, and
    # View ▸ Forget Saved Calibration clears it. → Mirror.saveCalibration / loadCalibration

  @built @hw-verified
  Scenario: Continuity Cameras are offered but never auto-opened
    Given an A12-or-later device publishes BOTH a screen mirror and a Continuity Camera
    When the Devices menu is built
    Then they are listed in separate sections and only screen mirrors are the default
    # An iPhone 16 Pro publishes "esaiPhone16Pro" (screen) and "esaiPhone16Pro Camera"
    # (Continuity). Auto-opening both would give one phone two windows. The Continuity feed is a
    # CLEAN camera with no chrome and no rotation problem — strictly better than mirroring
    # Camera.app when the hardware supports it. → isContinuityCamera(), rebuildDevicesMenu()

  @built @hw-verified
  Scenario: Detection is CONTINUOUS, not one-shot
    Given a phone's screen changes while its window is open
    When the picture changes materially
    Then Vision re-runs and the rotation/crop follow it
    # THE REGRESSION Esa hit: "the cropping has stopped working. it used to be automatic." A
    # one-shot first-frame pass detected "home screen → no chrome → no crop", and opening Camera
    # afterwards changed nothing, forever. Gated three ways so continuous ≠ expensive:
    #   • manualOverride — a hand rotate/nudge/uncrop wins until ⌘D resumes automatic tracking
    #   • 16x16 grayscale signature — skip frames that look like the last analysed one
    #   • busy flag + 1.2s throttle — never overlap two Vision passes (4 OCR passes each)
    # Verified: both phones came up 90° landscape and cropped (w=0.616 and w=0.613) without any
    # manual step. → FrameWatcher, frameSignature(), signatureDelta(), Mirror.inspect()

  @built @hw-verified
  Scenario: Menu rows never swap slots
    Given AVCaptureDevice enumeration order is not stable
    When the Devices menu is rebuilt after ticking a device
    Then rows stay in the same order, sorted by name
    # Esa: "its not okay that when you show something, it moves from 2nd slot to 1st slot". For a
    # menu, stable order is correctness — you click by position and hit the wrong phone otherwise.
    # Verified: 16Pro then X, identical before and after ticking. → localizedStandardCompare sort

  @built @hw-verified
  Scenario: A device row never vanishes while you reach for it
    Given a Continuity Camera comes and goes with proximity, wake and other apps' use
    When it stops enumerating
    Then its row REMAINS, greyed, labelled "(not connected)"
    # Esa: "the continuity camera keeps vanishing as an option". A menu built only from what
    # enumerates right now loses the row mid-click. A persisted roster (uniqueID → name, kind)
    # keeps every device ever seen; Devices ▸ Forget Disconnected Devices clears it.
    # Verified: "Show esaiPhone16Pro Camera  (not connected)" still listed while absent.
    # → roster, loadRoster/saveRoster, rosterItem()

  @built @hw-verified
  Scenario: A saved calibration seeds, it does not lock
    Given a device has a remembered rotation and crop
    When its window opens
    Then those values seed the window AND Vision still re-checks them
    # Suppressing detection when a calibration existed was the other half of the "not landscape"
    # bug: a value saved while the phone showed the home screen came back portrait and STAYED
    # portrait with Camera.app open. → Mirror.init

  @built @untested
  Scenario: A yanked cable closes its window instead of freezing a frame
    Given a device disappears from enumeration
    When the 3s rescan runs
    Then its window closes and the menu updates
    # Polling, not AVCaptureDevice connect/disconnect notifications: DAL screen-capture devices
    # come from an out-of-process assistant and do not reliably post those. NOT yet tested by
    # actually pulling a cable mid-session. → rescanDevices()

  @built @hw-verified
  Scenario: The screen-capture assistant is kept alive
    Given iOSScreenCaptureAssistant exits whenever no screen mirror is in use
    When a Continuity Camera is the only thing open
    Then re-asserting the CMIO property on each rescan brings the mirrors back
    # MEASURED: with the 16 Pro's Continuity Camera showing, BOTH phones vanished from
    # enumeration — 22 IOUSBHostDevice nodes present the whole time, pgrep of the assistant empty.
    # Enumeration alone does not respawn it; setting the property does. Esa: "i am not able to
    # connect the iPhoneX while continuity camera is on". → rescanDevices()

  @built @hw-verified
  Scenario: Continuity Cameras get no Vision pass at all
    Given a Continuity feed is already upright, landscape and chrome-free
    When such a device is opened
    Then it is pinned at 0°, uncropped, and never analysed
    # Esa: "the re-detect (vision) on iphone16pro goes from landscape to portrait, does a shoddy
    # detect". Of course it did — it was OCR-ing whatever the lens saw. → Mirror.init

  @built @hw-verified
  Scenario: Layout is one keypress before a take
    Given two or three mirrors are open with DIFFERENT aspect ratios
    When ⌘1 / ⌘2 / ⌘3 is pressed
    Then windows tile into equal cells, letterboxed inside them, never stretched
    And ⌘3 cycles which phone is full screen, wrapping forever
    # Aspect ratios genuinely differ (a cropped 4:3 viewfinder beside a 16:9 Continuity feed), so
    # cells are divided evenly and each window is FITTED, not stretched. Two details that make it
    # land on the pixels: NSScreen.visibleFrame (excludes menu bar + Dock) and subtracting the
    # title-bar height before fitting the aspect.
    # ⌘3 WRAPS rather than exiting — Esa: "if im looking at one, pressing cmd-3 will always show
    # the other". ⌘1/⌘2 is the way out. One phone open → fill/restore toggle instead of a no-op.
    # Verified: five ⌘3 presses alternate 16Pro→X→16Pro→X→16Pro.
    # → tile(), fit(), fillScreen(), fillOrder()

  @built @hw-verified
  Scenario: ⌘0 rescues minimised windows
    Given a mirror has been minimised, and the title bar may be off
    When ⌘0 is pressed
    Then every mirror window is un-minimised, un-hidden and raised
    And other apps stay hidden if you are in solo mode
    # Minimising is easy by accident and awkward to undo once ⌘B has removed the title bar.
    # v1 also dropped solo mode, which un-hid every other app — Esa: "the cmd-0 now acts as if
    # 'unhide all other windows' is what i want. thats not what i want." Correct: ⌘0 touches ONLY
    # this app's windows; Space owns the solo toggle and nothing else may reach into it.
    And each window gets EXACTLY ONE ordering call, so there is no flicker
    # Verified in solo mode: mirrors AXMinimized true → false while iTerm2 AXHidden stayed true.
    # v2 flicker Esa saw — "they appear quickly, and then vanish and animate back as if they come
    # from the dock" — was deminiaturize() plus orderFront/orderFrontRegardless/makeKeyAndOrderFront
    # on the SAME window: the window snapped on screen, then the un-minimise animation replayed it
    # out of the Dock. deminiaturize() already raises; never mix it with another ordering call, and
    # do not force key on a window with an animation in flight.
    # → bringAllBack()
    # NOTE this moved "no crop" off ⌘0 onto ⌘U.

  @built @untested
  Scenario: Front-window commands hit the window you clicked
    Given a borderless window cannot become key by default
    When you click a phone and press ⌘B or ⌘3
    Then the command applies to THAT window
    # Esa: "im stuck with iPhoneX getting the cmd-b commands". Two causes: NSWindow.canBecomeKey
    # is FALSE for .borderless (fixed with a subclass), and `front` was a guess (now: keyWindow →
    # last windowDidBecomeKey → most recent). PreviewView.mouseDown focuses its window, since the
    # image is the only hit target with no title bar.
    # @untested because I drove it through System Events, not a real mouse click — the mechanism is
    # right but the click path is unverified by hand. → MirrorWindow, front, PreviewView.mouseDown

  @built @hw-verified
  Scenario: The picture does not flip on its own
    Given continuous detection re-reads the feed every ~1.2s
    When one analysis disagrees with the current orientation
    Then it is IGNORED until several consecutive analyses agree
    And a 180° flip must clear a higher bar than a 90° turn
    # Esa, mid-demo: "it keeps rotating the video even though there should be no reason […] i have
    # enabled portrait lock on the iPhone, yet something in the iPhoneMirror actually does it".
    # He was right and Rotation Lock could not have helped — the flip was happening on the MAC.
    # Cause: continuous detection applied EVERY reading immediately. One frame where the lens
    # caught text at an angle turned the whole feed over. A single OCR pass is not evidence.
    # Now: a change needs 3 consecutive agreeing analyses (~4s), a 180° change needs 5 (~6s, because
    # upside-down misreads are the classic OCR failure and the most jarring on camera), and weak
    # evidence (score < 2) cannot even start a streak. Crop needs a >0.02 delta so it cannot jitter.
    # Verified: 80s of continuous watching with both feeds live — ZERO orientation changes, where
    # before it flipped unprompted. → pendingRot / pendingRotCount in Mirror.inspect()

  @built @untested
  Scenario: Orientation can be hard-locked for a demo
    Given hysteresis makes a spurious flip unlikely but not impossible
    When ⌘K is pressed on a window
    Then no automatic orientation or crop change is applied to it at all
    And the lock persists for that device, and ⌘D clears it
    # Belt and braces: hysteresis is a probability argument, and a demo wants a guarantee.
    # @untested — the toggle and its persistence compile and are wired, but I have not exercised it.
    # → orientationLocked, toggleOrientationLock(), Calibration.locked

  @built @hw-verified
  Scenario: A Continuity Camera that flaps does not flap its window
    Given a Continuity Camera drops out of enumeration intermittently while still streaming fine
    When a device scan does not see it
    Then its window stays open unless it is absent for 3 consecutive scans AND not streaming
    # Esa's log: "window open / disconnected — closing its window / window closed / window open /
    # disconnected …" — closing on a SINGLE missed scan turned unreliable enumeration into a visible
    # flap. Three misses (~9s) plus a stopped session means genuinely gone; less means enumeration
    # is being unreliable, which is its normal state for these devices.
    # Verified: 60s with both feeds live, ZERO close events. → Mirror.missedScans, rescanDevices()

  @built @hw-verified
  Scenario: Device enumeration must be LIVE, not a per-process snapshot
    Given AVCaptureDevice.devices(for:) returns a stale snapshot for the life of a process
    When a device disappears and comes back
    Then a long-lived AVCaptureDevice.DiscoverySession still sees it
    # Esa: "i briefly turned on the iPhone16Pro non-continuity method and then turned it off and
    # tried to get to continuity one and it didnt work." Proof it was OUR staleness and not the
    # system: a FRESH `--list` process saw all three devices while the running app still said
    # "(not connected)". Hence his workaround — "i had to disconnect the cable and reconnect" — a
    # replug forced an event the old snapshot could not miss. No longer needed.
    # The compiler had been warning about devices(for:) being deprecated all along; this is exactly
    # why. DiscoverySession must be created ONCE and re-read, never rebuilt per call. Legacy lists
    # are still merged in as a safety net for the unusual DAL devices.
    # Also added NSCameraUseContinuityCameraDeviceType to Info.plist, which the runtime warning had
    # been asking for. → deviceDiscovery, captureDevices()

  @todo
  Scenario: recburn can bake the phone feed in directly
    Given recburn resolves --pip-camera through AVCaptureDevice
    When the name refers to a Lightning iPhone
    Then recburn must set kCMIOHardwarePropertyAllowScreenCaptureDevices first
    # Today --pip-camera silently falls back to the built-in camera for an iPhone.
    # Working Swift for the flag exists in iPhoneMirror.swift; not yet ported to recburn.
