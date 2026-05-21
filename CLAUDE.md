# Apple Repo — Claude Code Instructions

Project-specific instructions for sessions in `/Users/esaruoho/work/apple/`. **Skill loader is `skill.md`**; **wiki index is `wiki/INDEX.md`**; **rules from `~/.claude/CLAUDE.md`** also apply.

## Session start

On the first turn in this repo, invoke the `apple` skill via the Skill tool before responding.

When the user says *"what's left"* / *"continue"* / *"boot up Apple skill"*: read the `🎯 Action queue` section at the top of `TODO.md`, separate items blocked-on-physical-action from items pickable unattended, surface those. Don't dump the whole TODO.md.

## Active work fronts (state as of 2026-05-07)

- **Sal archive recovery** — 235 of 359 download/media targets recovered, 3 dead URLs remaining. Sal replied 2026-04-03; hidden `dictationcommands/` subsite mirrored; CitrusPeel255.zip recovered.
- **Sal interview/article discovery** — `bin/sal-discover-interviews.py` probes 17 sources; pass 2 found 159 hits (16 YouTube interviews, 24 Apple Podcasts episodes, 75 cmddconf.com Wayback snapshots).
- **Transcription pipeline** — Track A: `bin/sal-transcribe-youtube.sh` submits via `whisp-submit`. Track B: `bin/sal-resolve-podcast-mp3s.py` resolves Apple Podcasts → MP3 → `bin/sal-transcribe-podcasts.sh`. Runbook: `analysis/sal/transcription-pipeline.md`. Trigger: `!pk cloudcity bash <script>` from Discord.

## Commit + push policy

- Commit logical groupings, not all-at-once dumps.
- Push immediately after committing — don't accumulate unpushed commits.
- HEREDOC commit messages for clean multi-paragraph wording.
- Always include `Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>`.

## Public/private split (see `.gitignore`)

- **Public:** code, indexes, correspondence, HTML mirrors, ZIPs under 100 MB, transcripts (text).
- **Private (gitignored):** `*.mp4`/`*.m4v`/`*.mov`/`*.mp3`/`*.m4a` under `sources/sal/**`, three oversized zips (AUTOWKSHP-03-Leader, EPUB-Demo-Kit-Lg, movies-from-dictations-comannds), `wiki/entities/bash-aliases.md`, `whiteboards/`, `icons/`, `__pycache__/`, GitHub Watcher runtime data, exporter runtime caches.

User declined git-lfs. Local-only preservation continues; transcripts go to GitHub.

## CloudcityMacMini infrastructure

- Always-on server. PakettiBot runs there via Cloudcity-Boot.app.
- Cloudcity agent at `~/work/pakettibot-agent/src/agents/cloudcity.js` runs Claude Code locally on the Mac Mini — no SSH needed.
- Whisp CLI: `~/work/whisp/whisp` (local files); whisp-worker daemon: `~/work/whisp-transcripts/whisp-worker` (YouTube queue).
- **File-drop bridge:** write `<command>` text into `~/work/comms/queue/pakettibot-inbox/<name>.cmd` — pakettibot processes it as if `!pk <command>` was typed in Discord. Output: `pakettibot-outbox/`.
