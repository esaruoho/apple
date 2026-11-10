@apple @iphone @menubar
Feature: iPhoneLatest.app — take a photo with the iPhone, drag it into any chat
  One click on the 📱 menu-bar icon opens the iPhone camera (Continuity Camera);
  the shot comes back as a draggable thumbnail. Apple-native, no third-party deps.

  Implementation: iphone-latest/main.swift · iphone-latest/build.sh · iphone-latest/make-icon.swift
  Standalone (canonical): github.com/esaruoho/apple-continuity-camera-photographer
  Docs: iphone-latest/README.md · iphone-latest/FINDINGS.md (why not USB)
  Session: features/iphone-latest.session.md (claude --resume 80e0eb8a-1733-48c4-8ec5-10bc261249c6)

  # ---- The app (v1.0) ----

  @built @hw-verified
  Scenario: Click 📱 → iPhone camera → thumbnail
    Given iPhoneLatest is running and the iPhone shares the Apple ID (Wi-Fi + Bluetooth)
    When I click 📱 with the thumbnail closed
    Then App.takePhoto fires AppKit's "Take Photo" (NSMenuItem.importFromDeviceIdentifier) directly
    And the shot returns through NSServicesMenuRequestor.readSelection → savePhoto
    And it is saved as ~/Pictures/iPhone-Latest/Continuity-<yyyyMMdd-HHmmss>.jpg and shown as the thumbnail
    # hw log 2026-11-10 10:48: 1440x1920 shots returned ~5 s after "firing Take Photo"

  @built @hw-verified
  Scenario: The Continuity item must live in the MAIN menu
    Given a probe app (scratchpad probe.swift) with a key window and a requestor first responder
    Then the importFromDevice item in a pop-up menu stays disabled with no submenu
    And the same item in NSApp.mainMenu is enabled ("<<Import From Device>>")
    So App.importMenu is installed as the main menu's File menu

  @built @untested
  Scenario: First click after launch primes the menu
    Given AppKit fills the device submenu only after the menu has been opened
    When "Take Photo" is not yet present
    Then takePhoto pops importMenu, cancels it after 0.4 s (RunLoop .common timer), and fires Take Photo

  @built @untested
  Scenario: Icon click while the thumbnail is open only dismisses
    Given the transient popover closes itself on the same click before click(_:) runs
    When click(_:) sees pop.isShown or a close < 0.5 s ago (closedAt)
    Then it closes and does NOT open the camera

  @built @untested
  Scenario: One capture at a time
    Given a Take Photo is pending (capturing = true)
    Then further takePhoto calls are ignored until the photo arrives or the popover closes

  @built @untested
  Scenario: Thumbnail is drag-only
    Then DragView starts a drag only after the mouse moves > 4 pt (no square/offset flash on click)
    And no click or double-click on the thumbnail triggers any action

  @built @untested
  Scenario: Folder row
    When I click "📂 Open iPhone-Latest folder"
    Then the popover closes and ~/Pictures/iPhone-Latest opens in Finder (photos are never overwritten)

  @built @hw-verified
  Scenario: Open at Login
    Given first launch (UserDefaults loginItemInitialized unset)
    Then SMAppService.mainApp.register() runs (log: "open at login: true")
    And right-click 📱 ▸ Open at Login toggles it

  @built
  Scenario: Installs as /Applications/iPhoneLatest.app
    When I run iphone-latest/build.sh
    Then it compiles with shared/SupportHelp.swift (shared Help + donate panel), signs with the stable
      Apple Development identity, installs /Applications/iPhoneLatest.app, removes the old
      /Applications/AppleToolbox copy, lsregisters and relaunches

  # ---- Retired: the USB cable path (kept as CLI, not in the app) ----

  @built @hw-verified
  Scenario: CLI bin/iphone-latest — newest USB photo → JPEG → clipboard
    When I run bin/iphone-latest on a cabled, unlocked iPhone
    Then the newest photo per ImageCaptureCore is converted via sips and put on the clipboard

  @hw-verified
  Scenario: Why the app dropped USB (see FINDINGS.md)
    Then iOS publishes new photos to ImageCaptureCore one at a time, 15–60 s after the shot
    And same-process session reopens return a stale catalog; locked-phone sessions open restricted/empty

  # ---- Claude can ask for a photo ----

  @built @hw-verified
  Scenario: A — bin/iphone-snap (URL scheme + wait)
    When a Claude session runs bin/iphone-snap
    Then it opens iphonelatest://take (App.application(_:open:)) → the iPhone camera opens
    And it waits for the next Continuity-*.jpg and prints its path for the Read tool
    # hw 2026-11-10 13:05: Continuity-20261110-130519.jpg (Arduino Uno clone) seen by Claude in-session

  @built @untested
  Scenario: B — MCP server take_iphone_photo
    Given bin/iphone-snap-mcp is registered: claude mcp add iphone -s user -- …/bin/iphone-snap-mcp
    When any Claude Code session (any repo) calls take_iphone_photo
    Then it runs bin/iphone-snap and returns the photo as an MCP image (long edge 1600) + the saved path
    # handshake + tools/list verified; health check "✔ Connected"; a full tools/call needs a new session
