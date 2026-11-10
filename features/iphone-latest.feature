@apple @iphone
Feature: Latest iPhone photo → chat in one click (USB cable, no AirDrop/iCloud)
  Implementation: bin/iphone-latest ; topbar/AppleToolbox.swift grabLatestIPhonePhoto + LatestPhotoPanel
  Session: 80e0eb8a-1733-48c4-8ec5-10bc261249c6 (claude --resume 80e0eb8a-1733-48c4-8ec5-10bc261249c6), 2026-11-10

  @built @hw-verified
  Scenario: CLI grabs newest photo as JPEG onto the clipboard
    Given the iPhone is USB-cabled and unlocked
    When I run bin/iphone-latest
    Then the newest HEIC is converted to ~/Pictures/iPhone-Latest/<name>.jpg via sips
    And the clipboard holds the image AND its file URL (verified: IMG_5684.jpg, JPEG+TIFF+file on pasteboard)

  @built @untested
  Scenario: Menu-bar "📱 Latest iPhone Photo" shows a draggable thumbnail
    When I click 🧰 ▸ 📱 Latest iPhone Photo
    Then a floating panel shows the thumbnail top-right
    And dragging it into Terminal / Claude drops the .jpg file

  @built @untested
  Scenario: Standalone 📱 menu-bar icon (iphone-latest/main.swift, own app — not AppleToolbox)
    When I click the 📱 icon in the menu bar
    Then it shows ⏳, runs bin/iphone-latest, and pops a draggable thumbnail under the icon
    And right-click offers Help / Support Esa (shared/SupportHelp.swift), Open folder, Quit

  @built @untested
  Scenario: Thumbnail auto-refreshes on a new photo
    Given the 📱 thumbnail popover is open
    When I take a new photo on the cabled iPhone
    Then `iphone-latest --watch` imports it → jpg → clipboard and the thumbnail swaps in place ("🆕 name")
    And closing the popover stops the watcher with no orphan iphone-import (@hw-verified teardown)

  @built @hw-verified
  Scenario: --latest sees photos newer than iOS's cached PTP catalog
    Given the cached catalog stops at an older photo (was IMG_5693)
    When iphone-import --latest waits for didAdd items to stop streaming (2.5s settle, 25s cap)
    Then it downloads the true newest (verified IMG_5701, ~4s)

  @built @untested
  Scenario: --watch keeps ONE session open (no 2s close→reopen, which killed iOS's item stream)
    Then each new photo arrives via didAdd and is printed as a path line, session stays open
