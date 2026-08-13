---
description: Blur/redact something out of a finished recburn video — `--find` sweeps the whole recording with on-device OCR so you need no timestamps at all, then it re-encodes ONLY the affected keyframe span, stream-copies the rest bit-exact, and never touches the audio or the source. Usage `/recburn-redact <video> [19:58-19:59] [what to cover]`.
allowed-tools: Bash, Read
argument-hint: <video> <mm:ss-mm:ss> [region description]
---

Redact part of the picture in an already-finished recburn recording — a Stripe account id
in the URL bar, a bank last-4, an API key, someone else's email — without re-rendering the
whole video.

Arguments: `$ARGUMENTS` — a video path, a time window like `19:58-19:59` (or `19:58->19:59`),
and optionally a description of what to cover.

The tool is `/Users/esaruoho/work/apple/bin/recburn-redact` (also spelled `recburnredact`,
matching `recburn` / `recburnclick`). Work in this order:

**0. If Esa has not given a time — don't ask him for one.** Sweep the whole recording with
on-device OCR and let it find the windows itself:

```
/Users/esaruoho/work/apple/bin/recburnredact <video> --find --ignore "esa@raybrowser|esaruoho"
```

~15 min for a 34-minute capture (Apple Vision, nothing leaves the Mac). It prints each
suspect window already padded, plus the exact `--probe` / `--at` commands to run next.
Add `--every 1` for a final pass — the default 2s step can step over a shorter exposure.
Report the windows and let Esa decide which are real; never auto-redact from a regex match,
and never call a sweep with 0 hits "clean" — it means no sampled frame matched 14 patterns.

**1. Find WHICH frames.** If Esa did give a time, don't trust a coarse sample grid — a
1-second sample cannot resolve a 1-second event, so scan at 10fps:

```
/Users/esaruoho/work/apple/bin/recburn-redact <video> --scan 19:55-20:02
```

Read the contact sheet it opens (`Read` the PNG it prints). It prints the row→time map, so
read off the first and last row that show the thing. Trust Esa's stated timestamp — on the
first run of this tool his "19:58->19:59" was right and my own sampling was wrong.

**2. Find WHERE.** If the region is not already a preset (`--list-presets`), probe one frame:

```
/Users/esaruoho/work/apple/bin/recburn-redact <video> --probe 19:58.2
```

`Read` that PNG too — it carries a 10x10 red grid, so count cells to the region and convert
to `--box x,y,w,h`. Presets are stored as fractions and were measured on a full-screen Safari
window at 3024x1964; any other layout needs a probe.

**3. Do the edit.**

```
/Users/esaruoho/work/apple/bin/recburn-redact <video> --at 19:57.8-19:58.7 --box urlbar
```

Add `--dry-run` first if the plan is worth reading before 2GB gets written. Repeat `--box`
for each region. Output defaults to `<input>-redacted.mov`; the source is never overwritten.

**4. Confirm before it ships.** The run prints five checks — frames, duration, audio packets,
no-shift, decode. **All five must say ok.** Then `--scan` the OUTPUT over the same window and
actually look at the contact sheet, because the checks prove the file is structurally intact,
not that you covered the right pixels.

Notes worth carrying:

- Only the keyframe-aligned span containing those frames is re-encoded (57 of 61760 frames on
  the first real run). Everything else is a bit-exact stream copy and the audio is remuxed
  untouched, so a screencast full of small text does not lose a generation of quality.
- Check disk before writing: the output is about the size of the input, and a full disk trips
  Syncthing's `minDiskFree` guard and freezes every Cloudcity heartbeat (`/bridge-doctor`).
- This redacts a copy, not the past. If the video is already uploaded, redaction only helps
  alongside taking that copy down.
- The tool cannot judge whether you picked the only exposure. A 34-minute screencast can also
  show a customer's name and email — which, unlike your own Stripe account id, is not yours to
  publish. Offer to sweep the whole recording.

Full rationale, the four bugs behind the design, and what is NOT verified:
`features/recburn-redact.feature` + `features/recburn-redact.session.md`.
