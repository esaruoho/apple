# Sal Soghoian Transcription Pipeline

End-to-end runbook for converting the discovered Sal Soghoian YouTube interviews
and Apple Podcasts episodes into searchable transcripts checked into the apple repo.

## Inventory

| Source | Count | List file |
|--------|-------|-----------|
| YouTube interviews | 16 | `analysis/sal/youtube-interviews-to-transcribe.txt` |
| Apple Podcasts episodes | 24 (high-confidence) | `analysis/sal/apple-podcast-episodes.txt` |
| Resolved MP3 URLs (after first run) | up to 24 | `analysis/sal/apple-podcast-mp3-urls.yaml` + `.txt` |

## Architecture

Two parallel tracks share the same trigger surface (Discord `!pk cloudcity`)
and converge on the same output layout in the apple repo.

```
┌──────────────────────────────────────────────────────────────────────┐
│  Track A: YouTube                                                    │
│                                                                      │
│  youtube-interviews-to-transcribe.txt                                │
│       │                                                              │
│       ▼ whisp-submit --file                                          │
│  ~/work/whisp-transcripts/queue/pending/<id>.url                     │
│       │                                                              │
│       ▼ whisp-worker daemon (already running on CloudcityMacMini)    │
│  ~/work/whisp-transcripts/transcripts/<date>_<slug>/transcript.txt   │
│       │                                                              │
│       ▼ sal-transcribe-youtube.sh (sync step)                        │
│  apple/sources/sal/transcripts/youtube/<date>_<slug>.txt             │
└──────────────────────────────────────────────────────────────────────┘

┌──────────────────────────────────────────────────────────────────────┐
│  Track B: Apple Podcasts                                             │
│                                                                      │
│  apple-podcast-episodes.txt                                          │
│       │                                                              │
│       ▼ sal-resolve-podcast-mp3s.py                                  │
│  apple-podcast-mp3-urls.yaml + .txt                                  │
│       │                                                              │
│       ▼ sal-transcribe-podcasts.sh                                   │
│  /tmp/sal-podcasts/<slug>.mp3 → ~/work/whisp/whisp <file>            │
│       │                                                              │
│       ▼                                                              │
│  apple/sources/sal/transcripts/podcasts/<show-slug>/<slug>.txt       │
└──────────────────────────────────────────────────────────────────────┘
```

## Files

| Path | What |
|------|------|
| `bin/sal-resolve-podcast-mp3s.py` | Apple Podcasts URL → MP3 enclosure URL via iTunes Lookup + RSS XPath |
| `bin/sal-transcribe-podcasts.sh` | Track B orchestrator: download → whisp → organize → commit |
| `bin/sal-transcribe-youtube.sh` | Track A orchestrator: whisp-submit batch + transcript sync + commit |
| `analysis/sal/youtube-interviews-to-transcribe.txt` | Track A input (16 URLs) |
| `analysis/sal/apple-podcast-episodes.txt` | Track B input (24 Apple Podcasts URLs) |
| `analysis/sal/apple-podcast-mp3-urls.yaml` | Track B intermediate (resolved MP3 URLs + status per episode) |

## How to fire it from Discord

The `!pk cloudcity` agent already runs Claude Code on CloudcityMacMini with full Bash. One Discord message kicks off either track or both.

### Track A — YouTube only
```
!pk cloudcity bash /Users/esaruoho/work/apple/bin/sal-transcribe-youtube.sh
```
By default this submits the URLs and exits without waiting. Set `POLL_TIMEOUT_SEC=7200` in the agent prompt if you want it to block until the queue drains.

### Track B — Apple Podcasts
```
!pk cloudcity bash /Users/esaruoho/work/apple/bin/sal-transcribe-podcasts.sh
```
Resolves MP3 URLs, downloads, transcribes, organizes, and commits in one pass. Skips episodes whose transcript already exists.

### Both tracks
```
!pk cloudcity bash -lc "cd /Users/esaruoho/work/apple && bin/sal-transcribe-youtube.sh && bin/sal-transcribe-podcasts.sh"
```

### Optional: post a Discord summary at the end
```
!pk cloudcity bash -lc "POST_DISCORD=1 /Users/esaruoho/work/apple/bin/sal-transcribe-podcasts.sh"
```
Drops a `.cmd` into `~/work/comms/queue/pakettibot-inbox/` containing a summary which the file-drop bridge then renders into Discord as if it had been typed as `!pk ask "..."`.

## How to fire it without Discord

Both scripts work standalone on CloudcityMacMini:

```bash
ssh CloudcityMacMini.local "/Users/esaruoho/work/apple/bin/sal-transcribe-podcasts.sh"
```

Or directly when you're on the Mac Mini.

## Output layout

```
sources/sal/transcripts/
├── youtube/
│   ├── 2018-11-15_sal-soghoian-standing-up-to-steve-jobs.txt
│   ├── 2018-09-06_triangulation-359-sal-soghoian.txt
│   └── ...
└── podcasts/
    ├── mac-power-users/
    │   ├── mac-power-users-automation-with-sal-soghoian.txt
    │   ├── mac-power-users-macos-services-with-sal-soghoian.txt
    │   └── mac-power-users-automation-update-with-sal-soghoian.txt
    ├── automators/
    │   ├── automators-sal-soghoians-control-panel.txt
    │   └── ...
    ├── chit-chat-across-the-pond/
    ├── the-omni-show/
    ├── macbreak-audio/
    └── ...
```

Each transcript file is plain text with a YAML frontmatter block carrying provenance (source URL, MP3 URL, pub date, slug, transcribed_at, transcriber).

## Known limitations and design choices

- **Audio MacBreak only.** The pipeline ignores the duplicate `MacBreak (Video)` feed — same content as `MacBreak (Audio)`, no value in transcribing twice.
- **Lower-confidence matches skipped by default.** `Examining #64` and `Gig Gab — The Value of Prep Time` are not auto-processed — they may not be primary Sal interviews. Add their lines back to `apple-podcast-episodes.txt` if you want to verify them anyway.
- **Title matching threshold = 0.45 similarity.** If `sal-resolve-podcast-mp3s.py` reports `status: no-match` for an episode, the RSS feed's titles diverged from the iTunes track names. Inspect the YAML, add a manual override (set `mp3_url` directly) if needed.
- **MP3s are deleted after transcription.** Saves disk space; if you want to keep them for re-processing, add `KEEP_MP3=1` in `sal-transcribe-podcasts.sh` (currently always deletes).
- **No git-lfs.** Large media stays gitignored under the existing `sources/sal/**/*.{mp3,m4a,mp4,...}` rules. Transcripts are tiny text files and live in the repo.
- **Per-show subfolder slugs.** Show name is lowercased and hyphenated; ambiguous shows ("Let's Talk Apple" with two feed IDs) collapse to the same folder, which is correct.

## After transcripts arrive

1. Run `bin/sal-archive-status.py --write analysis/sal/current-status.md` to refresh the dashboard.
2. Update `indexes/sal-interviews-discovered.yaml` to add `transcript_path:` next to each interview entry.
3. Cross-link the transcripts into `indexes/sal-lessons.yaml` where they support a curriculum module.
4. Send the follow-up email to Sal listing what was preserved and asking for any remaining gaps.

## Adding new sources later

To extend the pipeline:

- **More YouTube URLs:** append to `analysis/sal/youtube-interviews-to-transcribe.txt` and re-run Track A. `whisp-submit` dedupes by video ID.
- **More Apple Podcasts episodes:** append to `analysis/sal/apple-podcast-episodes.txt` and re-run Track B. Resolver dedupes by `episode_id`; transcriber dedupes by output filename existence.
- **Other audio sources (Vimeo, direct MP3, m4a downloads):** drop the file into `/tmp/sal-podcasts/<slug>.mp3` manually and re-run Track B (it skips anything already transcribed).
