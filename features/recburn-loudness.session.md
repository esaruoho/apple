# Session — recburn loudness normalisation

Card: [`features/recburn-loudness.feature`](recburn-loudness.feature)
Innards: `bin/rec-audio.swift` (`Levels`, `gainFor`, `softLimit`, `measureLevels`,
`applyGain`, the `level` + `normalize` verbs), `bin/screen-audio-record.swift` (`--no-normalize`)

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630.jsonl`
- Session ID: `00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630` (named "recburnclick")
- Resume: `claude --resume 00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Date: 2026-08-14, cwd `/Users/esaruoho/work/apple`, macOS 15.6.1

## The request (verbatim)

> i want you to improve recburn in such a way that it shows the volume of the recording, so
> that we can normalize it so its good volume overall, in total. do you see? so when it
> flattens, before it delivers the flattened video, and before it starts burning in the
> subtitles, it will actually increase the volume. … please prove it on this specific video.

## Three measurements, two of them wrong

The gain is trivial arithmetic. Choosing *what to measure* was the whole problem, and Esa's
own 78-minute file disproved the first two candidates:

1. **Absolute peak — useless.** The file peaks at **0.0 dBFS** while its 99.99th percentile
   is **-7.6 dBFS**. That full-scale sample is one click. Peak normalisation, the obvious
   first implementation (and the one I shipped first), computed `min(peakGain, rmsGain)` and
   therefore proposed **-1.0 dB**: attenuating a video whose problem is that it is inaudible.
2. **Whole-file RMS — nearly as bad.** The median sample is **-51.8 dBFS**, because a
   screencast is mostly pauses. Whole-file RMS read -32.1 dBFS, i.e. mostly a measurement of
   the silence between sentences.
3. **Gated loudness — right.** 400 ms blocks, an absolute gate at ~-60 dBFS, then a relative
   gate 10 dB below the mean of what survived — EBU R128's shape. Reads **-29.6 dBFS**, the
   loudness of the material that is actually playing.

The 4096-bin amplitude histogram earns its place twice: it exposes the peak as an outlier,
and it lets the gain be capped by the 99.9th percentile instead of the peak, so only the top
0.1% ever needs limiting.

## The bug my own output caught

First limiter mapped overs with `tanh` into `[knee, 1.0]`, so the normalised excerpt measured
**-0.0 dBFS** while the tool printed "ceiling -1 dBFS". That is a false claim, and true-peak
overshoot after AAC encoding is exactly how a "normalised" file clips in someone's player.

Found by running `rec-audio level` on the tool's **own output**. Measuring the input proves
nothing about what shipped. Knee and ceiling are now separate values (knee 5 dB below), tanh
approaches the ceiling asymptotically, and the same excerpt re-measures at exactly -1.0 dBFS.

## Proof, on the file he named

A 90 s excerpt cut losslessly (stream copy) from `2026-08-14-13-26-01-flat-subtitled.mov`:

| | before | after |
|---|---|---|
| loudness (gated) | -34.6 dBFS | **-18.1 dBFS** |
| peak | -13.4 dBFS | -1.0 dBFS |
| whole-file RMS | -35.5 dBFS | -18.9 dBFS |

+16.6 dB, 1.1 seconds, video stream-copied. Re-measuring the output: "+0.1 dB → -18.0", i.e.
already at target. A separate 6 s end-to-end recording confirmed the recorder prints the
measurement during flatten, and that a silent room (-58.2 dBFS) caps at +30 dB and says so
rather than amplifying hiss.

## Where it sits in the pipeline

`makeYouTubeVersion` (flatten) → `makeSubtitledVersion`. Normalisation happens inside flatten,
so the flattened file is already lifted when subtitles are burned from it — one pass, both
deliverables normalised, exactly the ordering asked for.

## Deliberate non-goals

One constant gain for the whole recording: nothing pumps, nothing breathes, and the balance
between voice and app audio is untouched. The limiter is stateless with no look-ahead — fine
for speech at these gains, wrong for music mastering. And the gating shape is R128's but there
is no K-weighting, so the number is not a true LUFS reading; it normalises consistently
against itself, which is what this pipeline needs.
