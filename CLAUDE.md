# Apple Repo — Claude Code Instructions

This is the canonical orientation file for Claude Code sessions in `/Users/esaruoho/work/apple/`. The full skill definition lives in `skill.md`; this file is the working-state index — it tells you what's in flight and what to read first.

## What this repo is

Open-source preservation + automation skill for the Apple ecosystem, anchored in **Sal Soghoian's** automation legacy and **Esa Ruoho's** Loupedeck / Stream Deck / hardware-controller workday. See `skill.md` for the canonical 13-layer probe, 288 workflow scripts, 31 scripting dictionaries, and Sal Hand-Crafted Conformance rules.

## Boot protocol

On every Apple-related turn:

1. Run `python3 bin/sal-archive-status.py --write analysis/sal/current-status.md`
2. Read `analysis/sal/current-status.md` and report archive state in plain language
3. Treat that file as the live Sal archive dashboard for the session

If the user says "what's left" / "continue" / "boot up Apple skill", refresh the status first.

## Active work fronts (state as of 2026-05-07)

### Sal Soghoian archive recovery
- 235 of 359 download/media targets recovered, 3 remaining (all dead URLs on macosxautomation.com)
- Sal replied 2026-04-03 to Esa's outreach email; deliveries processed 2026-05-06
- Hidden `dictationcommands/` subsite mirrored, CitrusPeel255.zip recovered (Sal's last installer)
- Wired article (Jordan McMahon, 2018-06-02) archived in three formats under `sources/sal/articles/`

### Sal interview/article discovery
- `bin/sal-discover-interviews.py` probes 17 sources (sites, IA, Wayback, YouTube via yt-dlp, HN Algolia, Apple Podcasts iTunes Search, Reddit, DDG site search)
- Two pass results: 159 hits, including 16 YouTube interviews + 24 Apple Podcasts episodes + 75 cmddconf.com Wayback snapshots
- Disambiguation filter built in (Sal vs Christopher Soghoian)

### Transcription pipeline (active)
- See `analysis/sal/transcription-pipeline.md` for the full runbook
- **Track A — YouTube:** `bin/sal-transcribe-youtube.sh` submits 16 URLs via `whisp-submit` and syncs transcripts into `sources/sal/transcripts/youtube/`
- **Track B — Apple Podcasts:** `bin/sal-resolve-podcast-mp3s.py` resolves Apple Podcasts URLs to direct MP3 enclosures via iTunes Lookup + RSS XPath; `bin/sal-transcribe-podcasts.sh` downloads, runs `whisp`, organizes transcripts under `sources/sal/transcripts/podcasts/<show>/`, commits
- **Trigger:** `!pk cloudcity bash <path-to-script>` from Discord — pakettibot's cloudcity agent runs Claude Code with full Bash on CloudcityMacMini

## Read-first for any session

| Topic | Start here |
|-------|-----------|
| Skill definition | `skill.md` |
| Sal archive state | `analysis/sal/current-status.md` (regenerate first) |
| What's currently being worked on | This file's "Active work fronts" + `TODO.md` |
| Transcription workflow | `analysis/sal/transcription-pipeline.md` |
| Sal correspondence | `analysis/sal/correspondence/` |
| Discovery results | `analysis/sal/interviews-discovered.md` |

## Commit + push policy

- Commit logical groupings, not all-at-once dumps. Today's session split into 6 commits by topic.
- Push immediately after committing — don't accumulate unpushed commits.
- Use HEREDOC commit messages for clean multi-paragraph wording.
- Always include `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.

## Public/private split

See `.gitignore`. In summary:

- **Public:** code, indexes, correspondence, HTML mirrors, ZIPs under 100 MB, transcripts (text)
- **Private (gitignored):** `*.mp4`/`*.m4v`/`*.mov`/`*.mp3`/`*.m4a` under `sources/sal/**`, three named oversized zips (AUTOWKSHP-03-Leader, EPUB-Demo-Kit-Lg, movies-from-dictations-comannds), `bash-aliases.md`, `whiteboards/`, `icons/`, `__pycache__/`, GitHub Watcher runtime data, Apple Notes / iMessage exporter runtime caches

User declined git-lfs ("don't want to pay extra"). Local-only preservation continues; transcripts go to GitHub.

## CloudcityMacMini-specific notes

- This Mac is the always-on server. PakettiBot runs there via Cloudcity-Boot.app.
- The cloudcity agent in `~/work/pakettibot-agent/src/agents/cloudcity.js` runs Claude Code locally on the Mac Mini — no SSH needed.
- Whisp CLI: `~/work/whisp/whisp` (handles local files); whisp-worker daemon: `~/work/whisp-transcripts/whisp-worker` (handles YouTube queue).
- File-drop bridge: write `<command>` text into `~/work/comms/queue/pakettibot-inbox/<name>.cmd` and pakettibot processes it as if `!pk <command>` was typed in Discord. Output to `pakettibot-outbox/`.

## When the user says "Sal" / "WWSD" / triggers Apple skill

Refresh the status, report the state, then ask what they want to work on. Don't moralize about archive completeness — report honestly and continue when asked.

See user-global `~/.claude/CLAUDE.md` for the rules around archive completion-framing, time-of-day stopping, and the Free Energy / archive-work pattern that applies to Sal preservation too.
