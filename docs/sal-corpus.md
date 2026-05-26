---
layout: default
title: How the Sal corpus is kept alive
---

# How the Sal corpus is kept alive

[← Back to home](./)

Sal Soghoian held the Product Manager of Automation Technologies position at Apple from 1997 to November 2016. Across those twenty years he gave WWDC sessions, ran the *Mac Automation Made Simple* training program, wrote books, ran the cmddconf.com automation conference site, and quietly shaped how a generation of power users understood that *the power of the computer should reside in the hands of the one using it*.

When Apple eliminated his position, the institutional record started to thin. WWDC session 717 (his last) was pulled a week after he gave it. The cmddconf.com site went offline in 2018. Interviews scattered across podcasts that themselves get archived or deleted.

This repo treats the corpus as worth preserving and continues the lineage operationally. Five pipelines:

---

## 1. Download recovery

The cmddconf.com material lives in two places in this repo: archived ZIPs of every download Sal hosted ([235 of 359 targets recovered](https://github.com/esaruoho/apple/blob/main/analysis/sal/current-status.md), 3 confirmed dead), and the hidden `dictationcommands/` subsite mirrored locally. Recovery work is logged in [`analysis/sal/`](https://github.com/esaruoho/apple/tree/main/analysis/sal).

The pulled WWDC 2016 Session 717 video was recovered from archive.org on 2026-05-07: [direct .mp4 on archive.org](https://archive.org/details/wwdc2016videos/717_hd_beyond_dictation__enhanced_voicecontrol_for_macos_apps.mp4), [524-line transcript in repo](https://github.com/esaruoho/apple/blob/main/sources/sal/wwdc2016-session-717/717-transcript.txt), [line-by-line analysis](https://github.com/esaruoho/apple/blob/main/analysis/sal/wwdc2016-session-717-transcript-analysis.md), [CitrusPeel-engine deep dive](https://github.com/esaruoho/apple/blob/main/analysis/sal/wwdc2016-session-717-deep-analysis.md), [replication plan for current macOS](https://github.com/esaruoho/apple/blob/main/analysis/sal/wwdc2016-session-717-replication-plan.md).

## 2. Interview / article discovery

[`bin/sal-discover-interviews.py`](https://github.com/esaruoho/apple/blob/main/bin/) probes 17 sources (YouTube, Apple Podcasts, Wayback Machine snapshots of cmddconf.com, etc.) for new material. Pass 2 surfaced 159 hits — 16 YouTube interviews, 24 Apple Podcasts episodes, 75 cmddconf.com Wayback snapshots. Full discovery log in [`analysis/sal/interviews-discovered.md`](https://github.com/esaruoho/apple/blob/main/analysis/sal/interviews-discovered.md).

## 3. Transcription

Two pipelines, runbook in [`analysis/sal/transcription-pipeline.md`](https://github.com/esaruoho/apple/blob/main/analysis/sal/transcription-pipeline.md):

- **Track A** — YouTube: [`bin/sal-transcribe-youtube.sh`](https://github.com/esaruoho/apple/blob/main/bin/) submits to the `whisp-submit` pipeline (OpenAI Whisper local, with hallucination-loop stripping + YouTube-caption merging for proper-noun accuracy).
- **Track B** — Apple Podcasts: [`bin/sal-resolve-podcast-mp3s.py`](https://github.com/esaruoho/apple/blob/main/bin/) resolves Apple Podcasts URLs → real MP3 URLs → [`bin/sal-transcribe-podcasts.sh`](https://github.com/esaruoho/apple/blob/main/bin/) hands off to whisp.

Triggered from Discord: `!pk cloudcity bash <script>`. The Mac Mini does the work; results sync back via the Syncthing comms share.

## 4. WWSD voice-signature extraction

Every transcript gets walked for "Sal-like" lines — quotable principles, decision rules, characteristic cadence. The accumulated catalog is [`analysis/sal/wwsd-updates-from-2003-transcripts.md`](https://github.com/esaruoho/apple/blob/main/analysis/sal/wwsd-updates-from-2003-transcripts.md), which feeds the [`what-would-sal-say`](https://github.com/esaruoho/apple/tree/main/sources/sal) skill grounding.

54+ WWSD principles currently catalogued. WWSD #54 (the [Roundtrip Rule](https://github.com/esaruoho/apple/blob/main/wiki/entities/sal-soghoian.md#L632)) is the operational synthesis articulated 2026-05-11. New principles get appended whenever a fresh transcript surfaces one.

## 5. Voicebox synthesis

The repo POSTs to ray-graph's voicebox endpoints (`/api/person/voicebox/synthesize` for solo, `/api/voicebox/dialogue` for multi-speaker scenes), producing SPOKEN-Sal output assembled from Sal's actual interview recordings. Zero-roundtrip from this Mac to a local Voicebox running on Mac Mini via Syncthing-mediated job queue.

Use cases: WWSD-pain-point voice pieces, Cloudcity BBS persona-tutor scenes, automation-domain commentary.

---

## The person, the philosophy

For the biographical / philosophical pages:

- [`wiki/entities/sal-soghoian.md`](https://github.com/esaruoho/apple/blob/main/wiki/entities/sal-soghoian.md) — the person, the 20-year arc at Apple, the 54+ WWSD principles
- [`wiki/concepts/sal-cross-decade-lineages.md`](https://github.com/esaruoho/apple/blob/main/wiki/concepts/sal-cross-decade-lineages.md) — 8 design patterns traceable across WWDC 2003–2015
- [`wiki/entities/sal-like.md`](https://github.com/esaruoho/apple/blob/main/wiki/entities/sal-like.md) — tools in this repo that follow Sal's "one verb, one result" pattern

---

[← Back to home](./) | [Triggers ←](./triggers) | [Tiers ←](./tiers) | [Trigger→worker chassis →](./chassis)
