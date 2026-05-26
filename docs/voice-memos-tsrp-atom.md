---
layout: default
title: "Voice Memos tsrp atom + ZFLAGS bit 3 = transcript marker"
---

---
description: Apple's auto-generated Voice Memo transcripts ARE persisted to disk — appended to the m4a file as a `tsrp` JSON atom; ZFLAGS bit 3 (mask 0x08) on ZCLOUDRECORDING marks presence. Discovered 2026-05-08.
---


# Voice Memos tsrp atom + ZFLAGS bit 3 = transcript marker


[← Back to home](./)
## Where Apple stores Voice Memos auto-transcripts

- **Detection**: `ZCLOUDRECORDING.ZFLAGS & 0x08` is the "has transcript" bit. SQL: `SELECT ZUNIQUEID, ZPATH FROM ZCLOUDRECORDING WHERE (ZFLAGS & 8) != 0;`
- **Storage**: appended to the .m4a file itself (NOT in the SQLite DB, NOT in Biome streams, NOT in `.composition` bundles). Marker is the 4-byte ASCII string `tsrp` near the end of the file, followed by a JSON object: `{"locale": ..., "attributedString": {"attributeTable": [...], "runs": [...]}}`.
- **Decoding `runs`**: flat array alternating `[text_str, attribute_index, text_str, attribute_index, ...]`. Each `attribute_index` indexes into `attributeTable`, where every entry has `{"timeRange": [start_sec, end_sec]}`. Concatenate even-indexed strings → full transcript text with per-fragment time alignment.

**Why**: Esa wanted to know which Voice Memos already had Apple transcripts without running Whisper. Initial probe missed the format and incorrectly reported "no transcript archive exists." Re-probing the m4a tail bytes uncovered it.

**How to apply**:
- For "which Voice Memos already have transcripts" questions, use the ZFLAGS-bit-3 check, not a Biome / Sage / SQLite-column search.
- Implementation: `voice-memos-export transcripts` and `voice-memos-export transcripts --extract`.
- Apple's transcript engine on macOS 15.6.1 is **English-only and poor on Finnish-mixed speech** (a 13-min Finnish recording yielded 541 chars of fragmented text). For real transcription, route through Whisper (`whisp --fi`). Apple's transcripts are kept primarily for inventory and quality comparison.

**Other ZFLAGS bits observed**: `0x04` always set on synced recordings; `0x200` and `0x400` set on iPad recordings; `0x02` rare. Semantics of those higher bits not yet confirmed but the transcript bit (0x08) is verified across 13 recordings on Esa's Mac.

**Lesson**: when an Apple feature exists in the binary (symbols like `RCLiveTranscription`, `_beginFileTranscriptionIfNeeded`, `RCCopyTranscriptActivity`) but no obvious SQLite column or sidecar file holds the data, **scan the asset file's trailer**. Apple sometimes appends ML-generated metadata directly to the media file in a custom atom rather than to a separate store.
