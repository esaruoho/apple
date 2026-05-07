# Sal Soghoian YouTube Interviews — Transcription Queue

Generated: 2026-05-07 (extended discovery pass with full-name query)

Sixteen YouTube interviews/talks surfaced by `bin/sal-discover-interviews.py`.
Plain URL list for whisp / yt-dlp consumption: `youtube-interviews-to-transcribe.txt`.

## TWiT Tech Podcast Network (4 episodes)

| # | URL | Title |
|---|-----|-------|
| 1 | https://www.youtube.com/watch?v=UbJw-F6ckZs | Sal Soghoian: Standing up to Steve Jobs |
| 2 | https://www.youtube.com/watch?v=SdM-eRAlr0A | Sal Soghoian: The Accidental Apple Career |
| 3 | https://www.youtube.com/watch?v=mWwQhmazLzM | Sal Soghoian: Dictation Commands |
| 4 | https://www.youtube.com/watch?v=iwhQiRI2lKI | Sal Soghoian interview (umbrella episode) |

## MacVoices (Chuck Joiner)

| # | URL | Title |
|---|-----|-------|
| 5 | https://www.youtube.com/watch?v=YnqFRDE0AWA | MacVoices #17175 — Sal Soghoian On Automation and the CMD-D Conference |
| 12 | https://www.youtube.com/watch?v=LJkMqpeGBj8 | MacVoices #17148 — AltConf: Ken Case and Sal Soghoian Discuss Omni Automation |

## Triangulation (Leo Laporte)

| # | URL | Title |
|---|-----|-------|
| 9 | https://www.youtube.com/watch?v=NU31vZ6TTHs | Triangulation 359 — Sal Soghoian (Part 1) |
| 10 | https://www.youtube.com/watch?v=TFaVgYp5oP0 | Triangulation 360 — Sal Soghoian (Part 2) |

## MacTech Conference talks (Sal as speaker)

| # | URL | Title |
|---|-----|-------|
| 11 | https://www.youtube.com/watch?v=Ph-XKKYGqx4 | MTC2017 — Cross Platform Automation Magic for iOS and macOS |
| 16 | https://www.youtube.com/watch?v=ADyPtCBp0os | MTC2018 EndNote — A Modern Look at Auto-managing iDevices with a Mac |
| 7 | https://www.youtube.com/watch?v=RB3vfmFd3Is | MTC2019 — An Insider's Look at APU |
| 13 | https://www.youtube.com/watch?v=rlCxtdBbCcg | MTC2019 EndNote — Creating the Ultimate Set of Control Panels |

## Mac Power Users (Stephen Hackett, David Sparks)

| # | URL | Title |
|---|-----|-------|
| 14 | https://www.youtube.com/watch?v=VSNq65o-S58 | MPU 815 — Automation Update with Sal Soghoian |
| 15 | https://www.youtube.com/watch?v=u6b8xN83tP4 | MPU 588 — macOS Services with Sal Soghoian |

## Other

| # | URL | Title |
|---|-----|-------|
| 6 | https://www.youtube.com/watch?v=tfpFttRZ6aU | ProGuide Episode 067 — Apple's "Dean of Automation" |
| 8 | https://www.youtube.com/watch?v=wK0AVjgjprA | The Mac Observer — WWDC 2017 Interview with Sal Soghoian |

## Whisp / transcription notes

Proper-noun registry for whisp's hallucination filter:

**Sal-specific:** Sal Soghoian, Soghoian (often misheard "Sokoian", "Sokorian", "Soyoyan", "Saw-go-yan"), AppleScript, Automator, AppleScript Pro Utilities (APU), CMD-D, iWork, Keynote, Numbers, Pages, Dictation Commands, Aperture, iPhoto, WWDC, MacTech (MTC), AltConf.

**Conference / podcast hosts likely on these:** Leo Laporte (Triangulation), Chuck Joiner (MacVoices), Stephen Hackett, David Sparks / MacSparky (Mac Power Users / Automators), Rosemary Orchard (Automators), Ken Case (Omni Group), Andy Ihnatko, John C. Welch, Allison Sheridan, Don McAllister, Jason Snell, Brett Terpstra, Jon Pugh, Shelly Brisbin, Ray Robertson.

All sixteen are interview/talk format — single primary speaker (Sal) with one or two interviewers, except MacVoices #17148 which is a three-way (Ken Case, Sal, Chuck Joiner). Lower hallucination risk than panel discussions.

## Output destination

After transcription, place transcripts in:

```
sources/sal/transcripts/youtube/<YYYY>-<source>-<short-title>.txt
```

Examples:
- `sources/sal/transcripts/youtube/2018-twit-standing-up-to-steve-jobs.txt`
- `sources/sal/transcripts/youtube/2018-triangulation-359-sal-soghoian.txt`
- `sources/sal/transcripts/youtube/2017-mactech-cross-platform-automation.txt`

After transcripts land, update `indexes/sal-interviews-discovered.yaml` with `transcript_path:` next to each URL, then re-run `bin/sal-archive-status.py`.
