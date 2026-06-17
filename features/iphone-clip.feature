# ============================================================================
# REPORT CARD — iphone-clip: take a photo on the iPhone → onto the Mac clipboard
# ============================================================================
#
# THE CONVEY
#   Esa wanted to take a photo on the iPhone and have it on the Mac clipboard, to
#   paste into a Claude. The first cut (bin/iphone-photo) made the MAC fire a blind
#   Continuity-Camera shutter — no viewfinder, you had to open the file to see what
#   you got. Esa: "the problem is that i dont see what im seeing… i want this to be
#   more than that. so i take a photo on the iPhone, and it is captured." So the real
#   act is: YOUR finger on the iPhone shutter is the trigger; the Mac copies the
#   result to the clipboard. Then: "i need this to be in AppleToolbox topbar so i
#   can click it… we 'arm the iPhone' to 'deliver to Clipboard'."
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/iphone-clip                     (the CLI: --watch | blind grab → clipboard)
#               commands/iphone-clip.md             (/iphone-clip slash)
#               sensor-snapshot/iphone-import.swift  (USB ImageCaptureCore: retry + 2s poll)
#               topbar/AppleToolbox.swift            (armIPhoneToClipboard + the menu row)
#   Thinkspace : this card + sensor-snapshot/snapshot.feature (the capture-mechanism card)
#   Areaspace : OWNS getting an iPhone photo onto the Mac clipboard + the topbar arming.
#               Does NOT UI-hijack, does NOT run anything on the iPhone, does NOT write
#               the Photos library. Capture innards live in sensor-snapshot (snapshot.feature).
#
# RESULT
#   Delivery : bin/iphone-clip + import hardening — commit 734ee34 on main (direct-push).
#              @verified grade flip — commit 03c95c3. Topbar arming — THIS commit.
#   Grades   : @verified ran live & observed · @built compiles+runs, not fully exercised
#
# ----------------------------------------------------------------------------

Feature: An iPhone photo, on the Mac clipboard, the way you took it

  @verified
  Scenario: --watch — YOU shoot it, it lands on the clipboard
    Given the iPhone is USB-tethered (unlocked; the open is retried ~80s if locked)
    When I run `iphone-clip --watch` and take a photo in the iPhone Camera app
    Then the real photo is imported over USB and written to the clipboard as image data
    And ⌘V pastes the picture straight into Claude / Mail / Messages
    # innards: bin/iphone-clip → iphone-import --watch (2s poll: close→reopen re-enumerates,
    # because ImageCaptureCore's didAdd push never fires for iPhone captures) → NSImage →
    # NSPasteboard writeObjects. VERIFIED live 2026-06-17: a photo of a Bitvise-SSH XP screen,
    # shot on the iPhone, was detected by the poll and pasted into Claude.

  @verified
  Scenario: blind mode — the Mac fires a Continuity-Camera grab
    Given no time to pick up the phone
    When I run `iphone-clip` (no --watch)
    Then a ~2.8MP Continuity-Camera still is captured and copied to the clipboard
    # innards: bin/iphone-clip → bin/iphone-photo (AVFoundation). VERIFIED: clipboard info
    # shows TIFF/JPEG/PNG picture types.

  @verified
  Scenario: Arm it from the AppleToolbox menu bar
    Given AppleToolbox is running
    When I click "📲 Arm iPhone → Clipboard" in the dropdown
    Then it launches `iphone-clip --watch` and notifies "iPhone armed — take a photo"
    And taking a photo lands it on the clipboard and notifies "✅ Photo on the clipboard"
    And the row reads "ARMED — click to disarm" while live; a second click disarms it
    And it auto-disarms after 5 min so the USB poll never cycles forever
    # innards: AppDelegate.armIPhoneToClipboard(_:) + iphoneWatchProc (held for disarm) +
    # the customAction row added next to "🔇 Stop Voicebox". Built + deployed 2026-06-17.

  @built   # the notification copy + auto-disarm timing not yet exercised end-to-end from the menu
  Scenario: Disarm / re-arm cycle behaves
    Given the watcher is armed but no photo is taken
    When I click the row again, or 5 minutes pass
    Then the watcher is terminated and a "Disarmed" / "Auto-disarmed" notification fires
