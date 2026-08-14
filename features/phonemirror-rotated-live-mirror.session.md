# Session — PhoneMirror: a live mirror QuickTime refuses to rotate

Spawning conversation for `features/phonemirror-rotated-live-mirror.feature`.

## How to get back

- Session ID: `d20eb49b-5ec9-41a8-a4fa-958a31dfd873`
- Resume: `claude --resume d20eb49b-5ec9-41a8-a4fa-958a31dfd873`
- Date: 2026-08-14, ~11:00–11:45 EEST
- Transcript dir: `file:///private/tmp/claude-501/-Users-esaruoho-work-apple/d20eb49b-5ec9-41a8-a4fa-958a31dfd873/`

## How it started

Esa plugged an iPhone X into a USB hub and asked three things: do you see the device, is it
charging, can you pinpoint it. The goal behind it: use the phone as a camera, record via
QuickTime, and put that next to DOSBox and Schism Tracker in a RecBurn take.

## What I got wrong, in order

This session was mostly me using blind instruments and reporting their blindness as fact.

1. **`system_profiler SPUSBDataType` returned an empty tree** — 0 devices, and it had also dropped
   a hub that was genuinely present. I read that as "no iPhone connected". Twice.
2. **`/var/db/lockdown/` "empty"** — it is `drwx-----x` owned by `_usbmuxd`. I cannot list it as
   esaruoho. "total 0" was a permissions artifact and I used it as evidence of never-paired.
3. **`AVCaptureDevice` enumeration showed no iPhone** — correct output, wrong conclusion. iOS
   screen-capture DAL devices are hidden until `kCMIOHardwarePropertyAllowScreenCaptureDevices`
   is set. My probe couldn't see the phone even when it was working.
4. **I argued from spec that iPhone X can't be a webcam.** Esa: *"i have been using the iPhone X
   as a camera. a webcam. and you are essentially lying to me."* He was right. I should have
   screenshotted the screen first. When I finally did, the feed was there.
5. **I inferred trust from `en21` coming up** and stated it as fact. Over-claimed.

The correction that actually worked: take a screenshot and Read it. Ground truth beat four
consecutive inferences.

## What was actually wrong on the machine

`iOSScreenCaptureAssistant` — the component that publishes a Lightning iPhone as a QuickTime
source — was failing to pair: `Could not pair with the device 11: 0xe800001a`, alongside
`0xe8000016 Cannot retrieve value from the passcode-locked device`. Auto-Lock was racing the
handshake. Esa set Auto-Lock to Never, replugged, and found the source himself under
New Movie Recording ▸ "Screen iPhone".

## The actual ask, once the device worked

The mirror came out portrait while the phone was held landscape. Esa wanted it landscape, live:

> "i cant rotate cos i want to record the computer screen, showing the flipped camera. […] if i
> have the 'live feed' i cant flip it. i dont want to record and then edit. this needs to be done
> oneshot."

I probed QuickTime's menus instead of guessing: Rotate Left/Right/Flip all exist and are all
`enabled=false` during live capture, and the sdef has no rotate terminology. Esa's screenshot
confirmed it. So the app got built.

Then:

> "i should just need to say phonemirror without all the commandline junk. […] it should be able
> to detect, using visionOCR, what it is seeing, and then act accordingly […] so 'default to
> removing camera controls' got it??"

That reframed the design from flags to inference, and is what the Vision pass exists for.

## Dead ends worth keeping (each cost a build)

- **Blocking on a semaphore** to grab the first frame starved the CMIO plugin — 0 frames in 5s.
  Detection had to become asynchronous.
- **Scoring rotation on upright chrome** picked 0°, exactly wrong: upright chrome means upright
  *iOS UI*, and with Rotation Lock on the scene is 90° off from the UI.
- **Scoring on any non-chrome text** picked 180°, fooled by OCR inventing words from the
  upside-down chrome band: `IYVNUS`, `IIVIIITIOD`, `OIOHD`, `OAAIA`, `OW-OIS`. Fixed by only
  counting text whose box lands inside the detected viewfinder.
- **Mean luminance** left the icon control row in shot — white glyphs lift the mean above any
  black threshold.
- **Relative/max luminance threshold** cropped to a 0.156-wide sliver, because one overexposed
  window in the scene dominated `max`. Median + absolute threshold is immune to both.

## Honest state at hand-off

Verified on screen: device discovery, 90° live rotation (CRT reading `E:\ITNU2026>_` upright and
landscape), mode-wheel crop, and bare-invocation adaptivity (home screen → 0°, no crop).

NOT verified: the median-luminance crop of the *icon* control row. The phone was on the home
screen when that build landed, so the Camera path never ran. The card grades it `@untested` and
it stays that way until a screenshot proves it.

Also outstanding: `recburn --pip-camera` cannot see a Lightning iPhone, because it resolves names
through `AVCaptureDevice` without setting the CMIO flag. Working Swift for the flag is in
PhoneMirror.swift, not yet ported.
