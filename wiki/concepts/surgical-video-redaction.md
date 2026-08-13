# Surgical Video Redaction — Editing One Second Out of a 34-Minute Capture

> Esa, 2026-08-13, about to publish a recburn screencast to Instagram + YouTube:
> *"you are gonna blur the frames.. they are at .. 19:58->19:59 ... we need to be able to
> run this on a recburned video, where i specify something like that."*

## What it is

A pattern for removing a region of *picture* from an already-finished recording — a Stripe
account id in the URL bar, a bank last-4, an API key, someone else's email — **without
re-encoding the rest of the file**. Only the keyframe-aligned span containing the offending
frames is re-encoded; everything else is a bit-exact stream copy and the audio track is
remuxed untouched.

Tool: [`bin/recburn-redact`](../../bin/recburn-redact) · slash: `/recburn-redact` ·
card: [`features/recburn-redact.feature`](../../features/recburn-redact.feature)

On the first real use: **57 of 61760 frames re-encoded**, 61703 stream-copied bit-exact,
audio never touched. A full re-encode would have cost a generation of quality across 34
minutes of small high-contrast UI text to fix 0.9 seconds.

## Why not just re-encode the whole thing

Because screen captures are the worst case for generational loss — small text, hard edges,
high contrast. And because it is unnecessary: h264 is already cut into independently
decodable GOPs. Find the GOP boundaries around the problem, re-encode that slice, copy the
rest.

## Minimum viable shape

```bash
recburn-redact video.mov --scan 19:55-20:02          # WHICH frames (10fps contact sheet)
recburn-redact video.mov --probe 19:58.2            # WHERE (full frame + 10x10 grid)
recburn-redact video.mov --at 19:57.8-19:58.7 --box urlbar
```

Three video segments, joined as MPEG-TS, with the original audio muxed back in one pass:

```
head : ffmpeg -i IN -map 0:v:0 -c copy -frames:v <N> -bsf:v h264_mp4toannexb -f mpegts A.ts
span : ffmpeg -noaccurate_seek -ss <kf_lo> -i IN -frames:v <M> -filter_complex <cover> \
              -map "[vout]" -c:v libx264 -crf 15 -an -bsf:v h264_mp4toannexb -f mpegts B.ts
tail : ffmpeg -ss <kf_hi> -i IN -map 0:v:0 -c copy -bsf:v h264_mp4toannexb -f mpegts C.ts
mux  : ffmpeg -f concat -safe 0 -i list.txt -i IN -map 0:v:0 -map 1:a:0 -c copy OUT.mov
```

## The five traps — every one of these bit on 2026-08-13

**1. `enable='between(t,…)'` silently never fires after an input `-ss`.**
The filtergraph's `t` is offset by the seek, so a timeline gate written in seconds never
becomes true and the span comes out completely unredacted — with no warning. Gate on **frame
number** instead: `enable='between(n,<lo>,<hi>)'`, where `n` starts at 0 for the first frame
handed to the graph.

**2. Never pass both `-map 0:v:0` and `-map "[vout]"`.**
ffmpeg writes **two** video streams — the unfiltered source as v:0 and the filtered picture
as v:1 — so every verification that reads v:0 shows crisp, unredacted content and sends you
hunting a filter bug that does not exist. Assert the output has exactly one video stream.

**3. `-to` overshoots on a copy cut.** Asking for a head ending at a keyframe returned
**35902** frames where 35900 were wanted. Two duplicated frames put video 66 ms out against
the audio for the remaining 14 minutes. Cut the head by exact count: `-frames:v <N>`.

**4. `-ss` does not always land on the `pts_time` you asked for.** On a file carrying an
edit list, a tail cut at a probed keyframe started **16 frames early**, producing a file 16
frames too long. So: **never compute a cut point from timestamps — measure it.**

```bash
# how many frames does a stream-copy from T actually yield? (decodes nothing, ~2s on 2GB)
ffmpeg -v error -stats -ss T -i IN -map 0:v:0 -c copy -f null -   # parse the last frame=
```
Then `start_frame(T) = total - that count`. Derive the span from measurements.

**5. The container's frame count can be a lie.** An excerpt cut with `-ss … -c copy`
reported `nb_frames=1802` while really holding 1814. Treat metadata as advisory; measure.

Also: **MOV/MP4 carries one `avcC` per track**, so joining a copied segment to a freshly
encoded one can produce a track whose parameter set does not describe every frame. Write each
segment as MPEG-TS with `-bsf:v h264_mp4toannexb` (in-band SPS/PPS) and join with the concat
**demuxer** (it offsets each file's timestamps), not the concat protocol.

## Cover it properly

A soft gaussian over 30 px UI text can stay legible. Mosaic **then** blur:

```
crop=W:H:X:Y,scale=<W/24>:<H/24>,scale=W:H:flags=neighbor,boxblur=10:2
```

One block per ~24 source px destroys the glyphs; the trailing blur takes the block edges off
so it does not read as a deliberate censor bar. `drawtext` is **not** compiled into this
ffmpeg 8.1 build — `drawbox` and `drawgrid` are.

## Verify, or you have not done it

Frame counting alone cannot catch a span that started at the wrong frame, because the tool
controls the counts. Five checks, all of which must pass:

| Check | Proves |
|---|---|
| frame count == source | no frames added or dropped |
| duration == `frames / fps` | not the container's duration field, which can be edit-list-skewed |
| audio packet count == source | the track was remuxed, never cut or re-encoded |
| frame hash 2 frames either side of the span matches source | **no frame shift** — those are stream copies, so they must be pixel-identical |
| decode span ±3 s with no stderr | the splices are clean |

Count **packets**, not frames: `-count_frames` decodes the whole file and turned a 20-second
verification into 7m15s on a 34-minute capture, for no extra truth.

Then still look at the picture. `--scan` the output over the same window and read the contact
sheet — the checks prove the file is structurally intact, not that you covered the right
pixels.

## Boundaries

- **Never overwrite the source.** A 34-minute render has no undo, and at the moment an
  in-place edit would happen the replacement is not yet verified.
- **Check disk first.** The output is about the size of the input; a full disk trips
  Syncthing's `minDiskFree` guard and freezes every Cloudcity heartbeat (`/bridge-doctor`).
- **Verify on a 60 s excerpt, not the 2 GB file** — it exercises head-copy, encode,
  tail-copy, concat, audio-remux and all five checks for ~100 MB. But cut the excerpt by
  **re-encoding**: a `-ss … -c copy` excerpt carries an edit list and will fail the
  timestamp-based checks for reasons that are the test file's fault, not the tool's.
- **This redacts a copy, not the past.** Only useful before publishing, or alongside taking
  the published copy down.
- **The tool cannot judge whether you found the only exposure.** A screencast can also show a
  customer's name and email — which, unlike your own account id, is not yours to publish.

## Neighbours

- [`recburn-redact.feature`](../../features/recburn-redact.feature) — graded claims + what is NOT verified
- [`recburn-redact.session.md`](../../features/recburn-redact.session.md) — the four bugs, in the order they bit
- [`recburnclick.feature`](../../features/recburnclick.feature) — the recording side of recburn
- `bin/rec` → `bin/screen-audio-record` — what produced the `-flat-subtitled.mov` in the first place
