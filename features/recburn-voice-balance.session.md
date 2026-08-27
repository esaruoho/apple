# Session — recburn: make the voice audible against the app audio

Card: [`recburn-voice-balance.feature`](recburn-voice-balance.feature)
Sibling card it completes: [`recburn-loudness.feature`](recburn-loudness.feature)

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/f6b36e8e-f9ea-4a77-af51-f4674a93172e.jsonl`
- Session ID: `f6b36e8e-f9ea-4a77-af51-f4674a93172e`
- Resume: `claude --resume f6b36e8e-f9ea-4a77-af51-f4674a93172e`
- Date: **2026-08-27**, 15:0x–15:4x EEST (Helsinki). The recording under discussion was
  made at 14:44:28 the same day and delivered at 15:00.

## What Esa asked for

> "i just used recburn to make a video. but it turns out the microphone was wayy too
> quiet. i still have the original files, so is there any chance you could increase the
> volume of the microphone and rebake the audio into the finished video? … can ya fix the
> volume of the mic since we have them as separate channels so i think you could increase
> the volume to something bearable. don't make it distort."

Then, after auditioning the hand-made fix:

> "the micfix is perfect. how about you turn that into a recburn feature so when i
> recburn, it'll do that. this is great. fold into recburn, and then give me the full
> video with the fixed audio. i mean, the subtitles written thing. just replace the wav
> inside it, okay? thanks!"

Two distinct asks, in order: repair one delivered file, then make the repair automatic.
The second one is why this card exists at all — the first was a one-off.

## The diagnosis, before any code

`2026-08-27-14-44-28.mov`, 461 s, two AAC tracks:

| | integrated | true peak | whole-file RMS |
|---|---|---|---|
| track 1 — system audio | −9.2 LUFS | +0.5 dBTP | −14.1 dB |
| track 2 — microphone | −35.3 LUFS | −10.6 dBTP | −38.7 dB |

26 dB apart. The system audio has a flat factor of 20.4 — it is a dense wavetable synth
already pinned at full scale. The mic's noise floor sits at −64.6 dB, i.e. 26 dB below its
own speech, which is what made a 21 dB lift viable at all.

The important realisation is negative: **recburn's existing normaliser was working
correctly and could never have fixed this.** `recburn-loudness.feature` says in its own
Areaspace that it "MUST NOT TOUCH … the balance between mic and system audio". The
delivered file measured −15.8 LUFS, a perfectly normal listening level, with an inaudible
voice inside it. A single gain is structurally incapable of closing a gap between two
sources it multiplies equally.

## Round one — the hand-made fix (ffmpeg), and what it taught

Built the chain in ffmpeg first to find out what "bearable, not distorted" actually meant
in numbers, and shipped two variants for Esa to pick between:

- mic boost only (system −4 dB flat)
- mic boost + the system sidechain-ducked by the mic  ← the one he approved

Three things were learned here that went straight into the Swift version:

1. **A first attempt at ducking was far too aggressive** — threshold 0.02, ratio 8 pulled
   the system down 21 dB, from −14 to −34.9 RMS. That is not ducking, that is deleting the
   demo. Measured, seen, backed off.
2. **Heavy limiting alone squashed the voice.** +21 dB into a −3 dBFS limiter took the
   mic's crest factor from 26 dB to 15 dB. Adding a compressor that only touches
   transients (threshold −14 dBFS, 4:1) kept it at ~20 dB.
3. **A 185 ms sync error** appeared in the very first render and was only caught by
   cross-correlating the output against the original mix. Cause: the two tracks have
   different `start_time`s (0.119 s and 0.2996 s), ffmpeg's filter graph dropped them, and
   the mov muxer then wrote its own AAC-priming offset on top. Fix was `adelay` per track
   plus `asetpts=N/SR/TB`, verified back to lag 0.000 at correlation 1.000.

That third one is the reason `TimelineTrackReader` exists rather than "just decode both
tracks and add them".

## Round two — folding it in

The blocker in `flatten` was that it used `AVAssetReaderAudioMixOutput`, which **sums**
the tracks into one PCM stream before anything can see them separately. So the audio path
was rewritten as: one `AVAssetReader` with two `AVAssetReaderTrackOutput`s, each wrapped
in a `TimelineTrackReader` that maps every sample buffer's PTS to an absolute frame index
and silence-fills gaps; then `RebalancedMixer` runs the chain and sums; then hand-built
`CMSampleBuffer`s stamped at exact frame positions.

Building the sample buffers by hand (rather than reusing a decoded one as a carrier) is
what makes the output start at frame 0 with the two tracks in their true relative places.
Measured result: **0.00 ms** against the original mix — better than the ffmpeg version's
−13 ms, which carried the lookahead latency of two limiters.

The old path is kept intact behind `plan == nil` and reachable via `--no-rebalance`.
Verified bit-equivalent: correlation **1.00000** against the previously-delivered file.

## Corrections made during the build, in order

1. **`level` printed the filename twice.** Trivial, fixed by hoisting the plan out of the
   early-print block.
2. **Peak 5.2 dBFS before normalisation.** The compressor's 10 ms attack lets transients
   through by design, so keyboard clicks reached the sum 10 dB over. Added a stateless
   soft ceiling at −3 dBFS on the mic before the sum → peak 0.7 dBFS.
3. **"the app audio was under the voice 99% of the recording".** The speech gate was 12 dB
   below the mic's gated loudness, which in a *tracker* walkthrough counts the keyboard as
   speech. Tightened to 6 dB. Also changed the reporting: the percentage alone was hiding
   the truth, so `meanDuckDb` was added and the line now says "98% of the recording,
   5.4 dB deep on average". The SRT says he narrates ~55% of the time, so 98% engagement
   is the ducker's 400 ms release bridging sub-second pauses — which is correct behaviour,
   just badly described by a percentage.

## Verification

| check | result |
|---|---|
| Swift output vs hand-made version Esa approved | −15.58 vs −15.82 LUFS · LRA 11.10 vs 11.00 |
| true peak | −1.24 dBTP |
| sync vs original mix | **0.00 ms** |
| `--no-rebalance` vs previously-delivered flat | correlation **1.00000** |
| single-audio-track recording | unchanged path, no NaN on silence |
| `rec-audio --self-test` | 20/20, gated by `build.sh` |
| delivered subtitled video stream | MD5 **identical** — only the audio changed |

`build.sh` now runs `rec-audio --self-test` alongside the existing
`rec-subtitle --self-test`, for the same reason: this is pure arithmetic, so it gets
asserted in a second at build time rather than three minutes into a screencast.

## Delivery of the repaired file

Esa asked to "just replace the wav inside it". Done literally: the burned-subtitle video
stream was **stream-copied** out of the existing deliverable and remuxed against the new
rebalanced audio, so the video he already approved is bit-for-bit untouched (MD5 verified)
and no second generation of encoding was introduced. Both `-flat.mov` and
`-flat-subtitled.mov` were replaced in `~/Downloads`; the previous versions went to the
Trash with an `-OLDAUDIO` suffix rather than being deleted.

## Boundaries deliberately not crossed

- The **original recording is never touched** — every path reads it and writes elsewhere.
- The **video is always passthrough**. This feature re-encodes no pixels.
- Overall loudness stays `recburn-loudness.feature`'s job and runs after this, unchanged.
- Nothing here is tuned to Esa's Renoise take. The one place a number from that recording
  appears is a self-test assertion, where it is a regression fixture on purpose.
