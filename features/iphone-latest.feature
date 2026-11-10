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
