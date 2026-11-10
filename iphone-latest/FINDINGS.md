# iPhoneLatest — what the hardware logs proved (2026-11-10)

Log: `~/Library/Logs/iphone-latest-app.log`. Card: `features/iphone-latest.feature`.

## Proven
- Over USB, ImageCaptureCore sees new iPhone photos only when iOS publishes them.
  The photos arrive in a single-file queue, about one every 5–7 s, with 15–60 s from shot to arrival (EXIF vs didAdd, IMG_5727–5735).
- When a photo does arrive (didAdd), download + JPEG takes <1 s and the notification fires.
- Reopening the session on the same device object returns the SAME stale catalog (5327 items / IMG_5736 across many reopens).
- Rebuilding the ICDeviceBrowser in-process: the device never came back (cam=false for minutes). Reverted.
- A connection opened while the phone is locked gets -9943 and then a restricted, stale catalog.
- Neither Image Capture.app running hidden nor app restarts reliably surfaced new photos.

## Not reliable from the Mac side
"Photo on the cable → instantly on screen" depends on iOS's publish timing, which we can't control.

## Reliable alternative (Apple-native, instant)
Continuity Camera: the Mac triggers the iPhone camera and gets the image back directly,
with no catalog involved. `bin/iphone-photo` / `bin/iphone-clip` (≈2.8 MP blind grab), or
Finder ▸ right-click ▸ Import from iPhone ▸ Take Photo (full camera UI on the phone, lands instantly).
