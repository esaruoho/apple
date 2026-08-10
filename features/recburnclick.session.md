# Session — recburnclick (click counter burned into the video)

Card: [`features/recburnclick.feature`](recburnclick.feature)
Innards: `bin/recburnclick`, `bin/screen-audio-record.swift`, `commands/recburnclick.md`

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630.jsonl`
- Session ID: `00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630` (named "apple-wav")
- Resume: `claude --resume 00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Date: 2026-07-29, ~16:40 EEST (Helsinki), cwd `/Users/esaruoho/work/apple`
- Machine: macOS 15.6.1 (24G90)

## The request (verbatim)

> yo yo yo yo recburn .. i wanna have a special one thats recburnclick - and all it does
> is, in addition to everything else, it calculates the amount of clicks. and shows it
> visibly. so this is a method of calculating the amount of clicks, i.e. CLICKS: 3, 4 -
> i.e. everytime i click, the counter goes up. got it? so thats in the video, too.

Note this is the *video* recorder (`rec` / `screen-audio-record`), not the `wav` audio tool
this session had been living in. "in addition to everything else" = keep all of rec.

## The decision that shaped it

The obvious implementations are a **CGEventTap** or an **NSEvent global monitor**. Both
require Accessibility permission, both hand us the entire mouse-event stream just to
increment an integer, and the tap would need its own run loop because the recorder uses
`dispatchMain()` rather than an NSRunLoop.

macOS already keeps the number: `CGEventSource.counterForEventType(.combinedSessionState,
eventType:)` returns how many events of a type the login session has seen. Probed it before
writing anything — left 7576, right 90, other 413, **no permission dialog**. So the whole
feature is a baseline subtraction, with no tap, no entitlement, no event stream, and no
extra thread.

Badge rendering: NSAttributedString → CGContext → CIImage, composited in the existing
Core Image chain. Two details worth keeping:
- **monospaced-digit font** — proportional digits make the badge width jitter as the number
  climbs, which reads as a glitch in a demo video.
- **cache by (count, width)** — re-laying out text 60×/sec would be wasteful and would
  shimmer; the badge only changes when the number does.

`compositePiP` was renamed `compositeFrame`, because it now composes more than PiP, and
`setupWriter`'s adaptor condition widened from `if opts.pip` to `if opts.pip || opts.clicks`.

## Verification

Recorded, then **read the pixels back** rather than eyeballing a video:
- `--clicks --clicks-seed 42` → extract frame @2s (AVAssetImageGenerator) → crop top-left →
  `bin/vision-ocr` → **"CLICKS: 42"**.
- `recburnclick --clicks-corner br --clicks-label TAPS --clicks-seed 7` → crop
  bottom-right → **"TAPS: 7"**. Placement and relabelling both confirmed in the encoded file.
- Regression: plain `rec` still produces 3024x1964 / 1 audio track / 3.2s — checked because
  widening a shared condition is exactly how an unrelated feature breaks.

## What is NOT verified, and why

**The increment itself.** It needs a real click. Synthetic clicks posted to my own pid
(`CGEvent.postToPid`) were tried and do **not** move the session counter — probe confirmed
delta 0. The only synthetic click that *would* count is one posted to the session, which
lands in whatever app Esa currently has focused: the exact UI-hijack that is forbidden
while he is at the keyboard. Graded `@built` and left for his one-click check rather than
faked or hand-waved.

`--clicks` + `--pip` is likewise `@built` — `--pip` turns the webcam on, and the camera
light during his working session is not a side effect worth a test run.

## Side effects surfaced

- Three short screen recordings of Esa's actual desktop were made into the session
  scratchpad (visible in the OCR output: Ray Nightly, Live). Not committed, not moved.
