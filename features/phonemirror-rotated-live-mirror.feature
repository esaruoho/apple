# WHAT THIS CARD SPAWNS
#
# Codespace: phonemirror/PhoneMirror.swift · phonemirror/build.sh · bin/phonemirror (shim)
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
#   Files changed   : phonemirror/PhoneMirror.swift, phonemirror/build.sh, bin/phonemirror,
#                     features/phonemirror-rotated-live-mirror.feature (+ .session.md),
#                     wiki/concepts/iphone-usb-capture-probe.md

Feature: PhoneMirror — live, auto-oriented, auto-cropped mirror of a USB iPhone screen
  QuickTime Player can mirror a Lightning-connected iOS device, but its Edit ▸ Rotate Left /
  Rotate Right / Flip items are DISABLED during a live capture session, and its scripting
  dictionary has no rotate terminology at all. So a phone held in landscape whose iOS UI is
  locked to portrait cannot be un-rotated live — you can only record and then rotate the file.
  This app rotates the AVCaptureVideoPreviewLayer instead, so the window is already correct and a
  one-shot screen recording needs no post-edit.

  @built @hw-verified
  Scenario: A Lightning iPhone is found at all
    Given an iOS device connected over USB and trusted
    When PhoneMirror starts
    Then it sets kCMIOHardwarePropertyAllowScreenCaptureDevices on the CMIO system object
    And the device then appears in AVCaptureDevice enumeration
    # Without that property an iOS screen-capture DAL device is INVISIBLE to AVCaptureDevice.
    # QuickTime sets it; nothing else does by default. Verified: device "esaiPhoneX" opened.
    # → allowScreenCaptureDevices(), PhoneMirror.swift

  @built @hw-verified
  Scenario: The live feed is rotated, which QuickTime cannot do
    Given the phone's iOS UI is drawing portrait while the phone is held landscape
    When PhoneMirror displays it at 90°
    Then the scene is upright and landscape in the window with no recording step
    # Verified on screen: a CRT showing "E:\ITNU2026>_" legible and upright.
    # → PreviewView.layout(), CATransform3DMakeRotation

  @built @hw-verified
  Scenario: Orientation is chosen by reading the SCENE, not the chrome
    Given Vision OCR can read text at all four rotations
    When PhoneMirror scores each rotation
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

  @built @untested
  Scenario: Camera.app's ICON control row is also cropped out
    Given the opposite control band holds glyphs (flash, timer, Live Photo) and no words
    When the crop is computed from per-column MEDIAN luminance with an absolute threshold
    Then that band is removed too
    # Two measured dead ends first: MEAN luminance leaves the band in (white glyphs lift the
    # mean above any black threshold); a RELATIVE/max threshold cropped to a 0.156-wide sliver
    # because one overexposed window dominated max. Median + absolute threshold is immune to both.
    # NOT yet confirmed on screen with Camera.app in frame — the phone was on the home screen
    # when this landed. This grade stays @untested until a screenshot proves it.
    # → luminanceProfile() median, trimDark()

  @built @hw-verified
  Scenario: Bare invocation just works
    Given no command-line arguments
    When `phonemirror` runs
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
    When PhoneMirror cannot open the device
    Then the failure text says the device is SINGLE-CLIENT and names QuickTime
    # → failNoDevice(), AVCaptureDeviceInput failure branch

  @todo
  Scenario: recburn can bake the phone feed in directly
    Given recburn resolves --pip-camera through AVCaptureDevice
    When the name refers to a Lightning iPhone
    Then recburn must set kCMIOHardwarePropertyAllowScreenCaptureDevices first
    # Today --pip-camera silently falls back to the built-in camera for an iPhone.
    # Working Swift for the flag exists in PhoneMirror.swift; not yet ported to recburn.
