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

---

## Round 2 — the mic, the app setting, and a repo that had forked in two

Three things at once:

1. **"why is recburnclick microphone off?"** Because I chained it to `rec`, not to
   `recburn`. `recburn = rec --mic --pip --burn`; wrapping `rec` quietly delivered a strict
   SUBSET when the ask had been "in addition to everything else". Fixed:
   `recburnclick → recburn → rec → screen-audio-record`. The apple repo turned out to have
   no `bin/recburn` at all — only the standalone did — so that came across too.
   Verified: `recburnclick --no-pip --no-burn` prints "🎤 microphone: ON" and writes 2
   audio tracks.

2. **Negation flags.** Every wrapper in the chain only ADDS, so there was no way to drop
   one without rebuilding the command from `rec`. Added `--no-mic` / `--no-pip` /
   `--no-burn` / `--no-clicks`; parsing is sequential so a trailing negation wins. This is
   also what let me test the mic without switching Esa's webcam on.

3. **The corner as a RecBurn.app setting.** Menu now has "Click Counter (CLICKS: n, burned
   in)" + a "Click Counter Position" submenu, chosen independently of the webcam's corner
   (they share the `PiPCorner` type but never the value — you want them opposite). Persists
   in UserDefaults, settable per-recording over the `recburn://` URL scheme.

### The repo question was the real find

Esa asked whether this belonged in `~/work/recburn` "or the recburn-only repo on github".
There is no `~/work/recburn`. The standalone is `~/work/apple-rec` → `esaruoho/apple-rec`,
and it had **forked into two different projects**:

- local: 30 commits never pushed — all of RecBurn.app (vocabulary editor, YouTube upload,
  icon, Shortcuts/Services). **The app's sources existed nowhere else.**
- remote: 15 commits the local didn't have, having been re-created from scratch as a flat,
  CLI-only "source-only repo" with `Engine/` and `Sources/RecBurn/` deleted.

`git merge` refused outright — **unrelated histories**. Either direction of blind copying
would have destroyed real work, so I stopped and asked rather than guessing. Esa chose to
publish the app back.

Resolution: one commit built on top of `origin/main`, re-adding the app in the *remote's*
flat layout (no `Engine/`, no `bin/` — both now gitignored build artifacts), with a
`build.sh` that produces CLI + app from the flat sources. The old line is preserved on
`backup-local-app-20260810`.

One thing that needed checking rather than assuming: the public engine sources had been
**pared** (no typed handoff manifest, no `--burn-prompt`) and RecBurn.app depends on both.
Diffed first, confirmed local was a strict superset, then replaced. Also scanned everything
being published for personal paths and credentials before pushing — `recburn-youtube` reads
its OAuth client from disk, nothing baked in.

Published: `ffdaa92`, 21 files, local `main` now equals `origin/main`.
