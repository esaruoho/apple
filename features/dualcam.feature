# ============================================================================
# REPORT CARD — DualCam: both iPhone cameras at once, for USB screen capture
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : dualcam/DualCam/DualCam.swift, dualcam/DualCam.xcodeproj, dualcam/build.sh,
#               dualcam/README.md.
#   Thinkspace: this card.
#   Areaspace : OWNS = compositing the iPhone's front and rear cameras onto its own screen.
#               MUST NOT TOUCH = anything on the Mac side; the Mac's job is to capture the
#               resulting screen via iPhoneMirror.
#
# WHY THIS CARD EXISTS
#   macOS cannot receive an iPhone's front camera at all: Continuity Camera exposes the phone
#   as ONE AVCaptureDevice wired to the rear system, reporting position=unspecified. And a
#   phone serves one role at a time — taking its screen freezes its cameras — so nothing is
#   lost by doing the capture on the phone and shipping one screen.
#
# REPORT-CARD LEGEND
#   @hw-verified  compiled AND run on hardware.
#   @built        compiles and is signed; NOT run on a device (and why).
#   @note         a documented boundary.
#
# RESULT
#   Direct-push to main, no PR.
# ============================================================================

Feature: Front and rear iPhone cameras in one picture

  @built
  Scenario: both sensors run simultaneously
    Given AVCaptureMultiCamSession (A12 / iPhone XS or later)
    When the app starts
    Then the rear and front cameras are added with NO automatic connections and wired by
      hand — port to preview layer — because addInput/addOutput form connections that assume
      exclusive use of a device, which is exactly what multi-cam is not
    And a device that cannot do multi-cam is told so in words rather than shown a black screen
    # innards: dualcam/DualCam/DualCam.swift `configure()` + `add(position:to:)`
    # NOT VERIFIED ON HARDWARE: see the blocked scenario below.

  @built
  Scenario: five layouts, cycled by tapping
    Then side-by-side → rear+front PiP → front+rear PiP → rear only → front only
    And portrait stacks the two while landscape splits them left/right
    # innards: `Layout`, `cycleLayout()`, `viewDidLayoutSubviews()`

  @built
  Scenario: it is built to be FILMED, not used
    Then no chrome, no status bar, black background, no implicit CALayer animations
    And UIApplication.isIdleTimerDisabled — a rig that sleeps after 30s is not a rig
    # innards: `viewDidLoad()`, `prefersStatusBarHidden`

  @hw-verified
  Scenario: it compiles and signs  (2026-08-17)
    Given Xcode 26.3, iOS SDK 26.2, free Personal Team 4V23QQYP9T
    Then BUILD SUCCEEDED, and an embedded profile is produced
    # innards: dualcam/build.sh

  @hw-verified
  Scenario: the build discovers the team instead of hardcoding it  (2026-08-17)
    Given a hardcoded DEVELOPMENT_TEAM produced "No Account for Team XXXX", which reads as
      "you are not signed in" when the real cause is a stale id in the project
    When build.sh runs
    Then it reads the team from com.apple.dt.Xcode.plist and passes it on the command line
    # innards: dualcam/build.sh
    # NOTE: a keychain identity is NOT proof of a usable team — the stale id came from an
    #       Apple Development certificate for a former employer's team.

  @built
  Scenario: INSTALL IS BLOCKED — the free team is full
    Given a free Personal Team allows 3 iPhone devices and they cannot be removed
    When the device is registered by building with -destination "id=<UDID>"
    Then Apple refuses: "Your development team has reached the maximum number of registered
      iPhone devices", and the install fails ApplicationVerificationFailed / 0xe8008012
    And the one device that IS provisioned is a 40-hex UDID — an iPhone X or older, i.e. A11,
      which cannot run multi-cam anyway, so that slot is useless for this app
    # THEREFORE: this app is unverified on hardware, and the blocker is a device slot rather
    #   than anything in the code. A paid Apple Developer Program membership (100 devices)
    #   is what a permanent multi-phone rig needs regardless.
    # See wiki/concepts/ios-free-provisioning-limits.md

  @note
  Boundary: building with -destination 'generic/platform=iOS' never registers the device
    Xcode has no idea which phone is meant, so the profile is built without it and the
    install fails with a signature error that looks like a signing problem rather than a
    device-registration one.

  @note
  Boundary: this app exists because of the role exclusivity, not despite it
    Since taking a phone's screen freezes its cameras anyway, putting both cameras INTO the
    screen costs nothing that was otherwise available.
    See wiki/concepts/iphone-capture-over-usb.md
