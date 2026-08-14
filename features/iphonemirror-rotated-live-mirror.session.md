# Session — iPhoneMirror: a live mirror QuickTime refuses to rotate

Spawning conversation for `features/iphonemirror-rotated-live-mirror.feature`.

## How to get back

- Session ID: `d20eb49b-5ec9-41a8-a4fa-958a31dfd873`  (named "iPhoneMirror")
- Resume: `claude --resume d20eb49b-5ec9-41a8-a4fa-958a31dfd873`
- Date: 2026-08-14, ~11:00–13:10 EEST
- Transcript dir: `file:///private/tmp/claude-501/-Users-esaruoho-work-apple/d20eb49b-5ec9-41a8-a4fa-958a31dfd873/`

## How it started

Esa plugged an iPhone X into a USB hub: do you see it, is it charging, pinpoint it. The goal behind
it — use the phone as a camera, record via QuickTime, and put that beside DOSBox and Schism Tracker
in a RecBurn take.

## Phase 1 — four blind instruments, and me trusting them

The worst part of the session, and worth keeping in full because the failure mode is reusable.

1. **`system_profiler SPUSBDataType` returned an empty tree** — 0 devices, and it had also dropped a
   hub that was genuinely present. I read that as "no iPhone". Twice.
2. **`/var/db/lockdown/` "empty"** — it is `drwx-----x` owned by `_usbmuxd`; I cannot list it. I used
   a permissions artifact as evidence of never-paired.
3. **`AVCaptureDevice` showed no iPhone** — correct output, wrong conclusion. iOS screen-capture DAL
   devices are hidden until `kCMIOHardwarePropertyAllowScreenCaptureDevices` is set.
4. **I argued from spec that an iPhone X can't be a webcam.** Esa: *"i have been using the iPhone X
   as a camera. a webcam. and you are essentially lying to me."* He was right.

What broke the loop: taking a screenshot and READING it. Ground truth beat four inferences. The
lesson is in `wiki/concepts/iphone-usb-capture-probe.md`, top section.

The real blocker turned out to be pairing — `iOSScreenCaptureAssistant` failing with `0xe800001a`
while the phone auto-locked mid-handshake. Esa set Auto-Lock to Never and found the source himself.

## Phase 2 — the thing QuickTime cannot do

The mirror came out portrait while the phone was held landscape.

> "i cant rotate cos i want to record the computer screen, showing the flipped camera. […] i dont
> want to record and then edit. this needs to be done oneshot."

I probed QuickTime's menus instead of guessing: Rotate/Flip all `enabled=false` during live capture,
no rotate terminology in the sdef. So the app got built. Then:

> "i should just need to say phonemirror without all the commandline junk. […] it should be able to
> detect, using visionOCR, what it is seeing, and then act accordingly"

That reframed it from flags to inference.

## Phase 3 — the crop, which took SIX wrong answers

Each cost a build and a screenshot:

1. Blocking on a semaphore for the first frame **starves the CMIO plugin** — 0 frames in 5s.
2. Scoring rotation on **upright chrome** picked 0°: upright chrome means upright *iOS UI*, and with
   Rotation Lock on the scene is 90° off from the UI. Wrong target entirely.
3. Counting any non-chrome text as scene text picked 180°, fooled by OCR **inventing** words from
   the upside-down chrome band: `IYVNUS`, `IIVIIITIOD`, `OIOHD`, `OAAIA`, `OW-OIS`.
4. **Mean luminance** left the icon control row in shot — white glyphs lift a black band's mean.
5. **Relative/max threshold** cropped to a 0.156-wide sliver, because one overexposed window
   dominated `max`.
6. **Median luminance** ate the middle of the feed (`w=0.523`, clipping the `E:\` off the prompt) —
   because the SUBJECT is a black DOS CRT. No brightness test can separate "black control band"
   from "black subject".
7. Sliding a 4:3 window to maximise contained image picked the **chrome band**, whose white shutter
   circle and colour thumbnail outweigh a dark subject.

What works is **geometry**: the viewfinder spans the full short edge, PHOTO mode is 4:3, the mode
wheel is located BY NAME via OCR, plus one measured gap constant (`0.040`, bracketed between `0.012`
which left a bar and `0.062` which pulled the icon strip in).

Then a regression Esa caught: *"the cropping has stopped working. it used to be automatic."* — the
Vision pass was **one-shot on the first frame**. Tick a device while the phone shows the home screen
and it never re-evaluates. Now continuous, gated by a 16×16 signature + 1.2s throttle + manual
override.

## Phase 4 — multi-device, and two crashes

Two or three phones needed a controller per device. Unticking one crashed the app: `EXC_BAD_ACCESS`
in `objc_release` during `objc_autoreleasePoolPop`. Read from the `.ips` report, not guessed, and it
was TWO lifetime bugs — `isReleasedWhenClosed` defaulting to true (double release under ARC) and
`mirrors.removeAll()` running inside the Mirror's own `windowWillClose`.

Then three UX bugs Esa found in a row, all fair:

- rows **swapping slots** when ticked (unsorted enumeration → sort by name)
- the Continuity Camera **vanishing** from the menu (persisted roster, `(not connected)` rows)
- windows coming up **portrait** (a saved calibration was suppressing detection; now it only seeds)

And the one that looked like magic: with the Continuity Camera open, BOTH phones read as
disconnected. `iOSScreenCaptureAssistant` **exits when no screen mirror is in use**, and enumeration
does not respawn it — only re-setting the CMIO property does.

## Phase 5 — framing for the take

`⌘1/⌘2` tile, `⌘3` cycles full screen forever (`"if im looking at one, pressing cmd-3 will always
show the other"`), `⌘B` drops the title bar, `⌘0` rescues minimised windows, `Space` solos the app.

`⌘B` exposed the last real bug: a **borderless NSWindow cannot become key**, so after hiding the
title bar every front-window command hit the wrong window.

## Things I did badly

- Reported blind-instrument output as fact, four times, before looking at the screen.
- Argued from spec against Esa's direct experience.
- Shipped v1 without the **shared Help/donate panel**, which is an explicit project ground rule. He
  had to ask.
- Shipped a **full-bleed icon** when `guidance/` and `topbar/` already had the right constants — the
  convention existed, undocumented, and I ignored it. Now documented.
- Ran the app **out of the build directory** at first, so every rebuild was a different app to macOS.
- Called the multi-device work a "refactor" while he was out of time.

## Honest state

Everything in the card is `@hw-verified` except: click-to-focus (driven via System Events, not a real
mouse click), a yanked cable mid-session, and the single-client failure message. `recburn
--pip-camera` still cannot see a Lightning iPhone — it resolves names through `AVCaptureDevice`
without the CMIO flag. That is the open `@todo`.
