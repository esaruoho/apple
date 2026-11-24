# Disk usage dry-run — 2026-11-21 (read-only, nothing deleted)
Free: 19 GiB of 1.8 TiB. Home = 1.5T.
- ~/work 466G (convey-packs 130G, merlib-dump 109G, comms 89G, videos 21G, merlib-mirror 19G, voicebox 16G)
- ~/Music 339G · ~/Library 331G · ~/Downloads 221G · ~/Soulseek Downloads 54G · ~/Pictures 48G · ~/Movies 25G · ~/.vault-embeds 24G · ~/.cache 9.2G
- /System/Library/AssetsV2/com_apple_MobileAsset_MetalToolchain 1.3G (SIP-protected; xcrun metal already reports it missing/unused)
Verdict: convey-packs is the largest single work folder, not the whole story. Music + Library + Downloads = ~890G.

## convey-packs videos >2GB (checked 2026-11-21)
All 3 are in john-bedini/corpus and are on the Mini at /Volumes/CLOUDCITY4TB/convey-packs with identical byte sizes:
- eftv-02-bedini/uJRNEChwNw4.mp4 3164869683
- eftv-01-bedini/8sVLtbuWZLU.mp4 2408244142
- eftv-07-bedini/PuVeZL63Hvs.mp4 2278822643
Total ~7.3 GiB. WARNING: convey-packs is a Syncthing send-receive folder, so deleting a file on the laptop also deletes it on the Mini. Add the files to the laptop's .stignore first, then delete them locally.

## Why convey-packs is 130G
131 top-level folders, no single giant. 52 eftv-* folders = 39G; john-bedini 27G (corpus 17G, clips 7.6G); .stversions 12G (Syncthing's old copies of deleted/replaced files: lenr 5.5G, free-energy 4.5G); steve-jobs 7.3G, lenr 6.2G, mike-clarke 5.3G, others smaller. Files over 50MB are 33 GiB of mp4; the rest is many smaller clips. Duplicate-looking: eftv-02-part-2-john-bedini-1080p vs eftv-02-energy-from-the-vacuum-part-2-john-bedini (2.2G each).

## Actions 2026-11-21
- Laptop .stversions emptied: 12G freed (only .DS_Store left; Syncthing never syncs .stversions).
- lenr/forum made Mini-only: added `/lenr/forum` to the laptop's .stignore after checking all 22,795 laptop files exist on the Mini with identical sizes. Syncthing confirmed the files as ignored, then the local copy was deleted (6.2G). The Mini still has 43,132 files afterwards.
- Free space went from 19G to 42G.

## eftv duplicate check (read-only)
- Byte-identical mp4s over 50MB: only 0.7GB in extra copies (bedini clip copies in _converse/ and corpus/, 2 sync-conflict clips in eftv-10, narrator.mp4 in clash-of-the-geniuses twice).
- eftv-01 (two folders, 1.7G each) and eftv-02 (two folders, 2.2G each): identical transcripts, but the clips were cut separately (different bytes), so these are the same episode processed twice. About 3.9GB is redundant.
- eftv-03 and eftv-09 pairs: different transcripts, so different sources/cuts; not straight duplicates.
- john-bedini/corpus/eftv-01/02/07 hold the full source videos of those same episodes (7.3GB, also on the Mini).

## eftv-01/02 dedupe (2026-11-21)
Kept (canonical): eftv-01-energy-from-the-vacuum-part-1-overview, eftv-02-energy-from-the-vacuum-part-2-john-bedini. They hold the source mp4s on the Mini and are linked from eftv-series/graph.json, the Bedini voice TRAIN-SUGGESTION and the merlib eftv02 postmortem article.
Wiped: eftv-01-part-1-overview-1080p, eftv-02-part-2-john-bedini-1080p (clips only, same transcript, unreferenced). The deletion syncs to the Mini (~3.9G freed on each machine).
Their YouTube ids (FEb3o6LnE4k, Qd3a9fjTHoU) were added as `alias_youtube_ids` in the kept manifests, so convey's _find_pack_for() resolves both uploads to the one pack and `eftv heal` won't recreate the duplicates. Checked with a python call.

## 30 largest files (2026-11-21)
Full list: /private/tmp/claude-501/-Users-esaruoho-work-apple/8a4100f8-db99-4dda-a2bf-6e8c13fb4c92/tasks/bgzs9k0ou.output
- Docker.raw claims 1995 GB but is a sparse disk image: it really uses 8.9 GB.
- Biggest real files: Downloads/VEEP.zip 25G; iCloud FE/erfinder Skypechat .mov 25.5G (an iCloud file, so it may be evictable); Claude VM images 10.7+10.7+2.2G; WhatsApp backups 5.3+2.1G; .git packs for comms 4.2G, remotion 3.8G, merlib-mirror 2.8G; .vault-embeds matrix 3.9G; Photos libraries 3.6+3.3G; Ruby ACT mp4s 2.5x3; bedini-whiteboard mp4 3.2G.
- Main finding: no single giant file. Space goes to many medium files, mostly media.

## Round 3 (2026-11-21)
- remotion: plain clone of public remotion-dev/remotion, main in sync, nothing local -> made shallow (depth 1, tags dropped, gc). History stays on GitHub.
- merlib-mirror: NOT touched. Unpushed commits: mirror/frankgermano.com 5, torkado.de 37, weathercreation.com 37, wikischool.org 42, vortex-world.org 42; .convey-ledger.jsonl modified. Making it shallow would destroy those commits; push them first.
- VEEP.zip: 3,050 files / 26.8GB (80 PMO, 01 Core, GU review, 99 Archive). Its folders are found nowhere in Spotlight or under ~, so it has never been unzipped. Being copied to cloudcity:/Volumes/CLOUDCITY4TB/laptop-offload/VEEP.zip (verify sha256 before deleting the local copy).
- .vault-embeds: 24G = _matrix.npy 3.9G + ~30,600 per-file .jsonl embeddings (Jun 2026). Waiting on Esa's decision.
- 23:4x: Claude Code killed both background jobs because memory was critically low.
  - VEEP scp: partial file on the Mini (4.8 of 26.8GB) at laptop-offload/VEEP.zip. The laptop copy is untouched. Needs a restart (rsync --partial can resume).
  - remotion: shallow fetch done, then killed between reset and gc, which left HEAD and the working tree out of step. Fixed with `git reset --hard origin/main` (clean, 1 commit). .git is still 3.7G until `git gc --prune=now` runs (non-aggressive, lighter on memory).

## merlib-mirror branch audit (2026-11-22)
The 5 "unpushed" branches (frankgermano.com, torkado.de, weathercreation.com, wikischool.org, www.vortex-world.org) are each N ahead / N behind origin. Their history was rewritten (each mirror landed by PR, then rebased). The mirrored site content is identical: local sites/<name> tree hash == origin/<branch> tree hash for all 5. The only file differences are sites/tom-c-1 and sites/tom-c-tesla (65 files, deletions only), which come from the old merge-base, not from new work. pharis, villesresearch.com-complete and vlpi-fix exist only locally but are already merged into origin/main.
=> Nothing unique would be lost. Fix: reset the 5 branches to origin/<branch>, delete the 3 merged local-only branches, then make the clone shallow. The working-tree edit to .convey-ledger.jsonl must be kept.

## .vault-embeds
Created by apple's bin/embed + bin/vault-grep (shared by vault-ask, vault-consilience, convergence). One JSONL per embedded .md/.txt (keyed by sha1 of its path) plus a _matrix.npy; on-device Apple NLEmbedding (512-dim) via apple-embed. It is a cache that can be rebuilt (`embed <dir>`); vault-* searches re-embed on demand.

## Vault tools last use + deletion (2026-11-22)
- The ~/.vault-embeds cache was last written 2026-07-18 23:36. Nothing has embedded since then.
- None of embed / vault-grep / vault-ask / vault-consilience / convergence appears in bash or zsh history. No Claude transcript since 2026-07-18 ran them, apart from this session's test.
- The scripts were last modified Jun 1 – Jul 4 2026. Their access times are all 2026-09-12 12:32–12:33 within one minute, which points to a bulk read (a backup or grep sweep), not real use.
- No LaunchAgent, cron or hook calls them. The only automatic callers are agent tools: mlx_agent_core.py (MLX agent `vault` tool) and fm.swift (FM vault tool).
- Deleted ~/.vault-embeds (24G). Kill switch: ~/.config/apple/vault-embeds-disabled + guard_embedding() in vault-grep (commit 07dab3cf, pushed). Tested: vault-grep and embed both exit 3 without writing anything.
- Final .git sizes: remotion 3.5G -> 323M (1 commit). merlib-mirror 4.2G, 1 commit: the history really is gone; the remaining 4.0G pack is the CURRENT snapshot (8.3G of mirrored site files, compressed), so it can't shrink while the repo exists. Free space now 55G.
- VEEP.zip copied to cloudcity:/Volumes/CLOUDCITY4TB/laptop-offload/VEEP.zip; SHA-256 matches on both sides (8e9fd32e…6aac). The laptop copy (26.8G) is still in ~/Downloads until Esa OKs deleting it.

## VEEP.zip contents (2026-11-22)
Jeroen's VEEP corpus. Its own work (953 MB) was extracted to ~/work/merlib-dump/sources/veep/ with a README, the full listing and the overlap report. The rest (03 Library 18.3G, Apps 2.9G, Archive 0.9G, experiment media) stays in the zip, which is verified on the Mini. Only ~2.3G of the library is already held elsewhere by exact size; the Thrive II film alone is 9.3G; 5.4G is duplicated inside the zip.
- ~/Downloads/02 VEEP THEORY.zip (35 MB): all 79 files are identical (same path and size) to 02 VEEP THEORY/ inside VEEP.zip, which is already extracted to merlib-dump/sources/veep/. Nothing unique in it.

## Memory hog audit (2026-11-22, read-only; nothing killed)
18 GB RAM, swap 22.1 of 23.5 GB used (swap files live on the data volume, which also costs disk).
Real footprints (top MEM, compressed included):
1. Python 38394, 10 GB after 10 min: ledger-verify.py PRIGOGINE-QUOTE-LEDGER against all of merlib-dump/sources. Started by the claude session in ~/work/convey (pid 89152, ttys025). Runaway: it seems to load the whole sources tree into RAM.
2. mds_stores 9.7 GB (Spotlight, up 7d18h): indexing the churn from today's deletes/extracts. Restarting it would give the memory back.
3. Sublime Text 8.3 GB (up 7d18h).
4. 21 Claude Code sessions × ~450 MB ≈ 9.5 GB. 18 are in merlib-dump, some up to 4 days old (ttys000–025).
5. WindowServer 5.8G, WebKit 2.1G, Terminal 1.8G, Finder 1.2G, Safari 1.0G, syncthing 0.44G.
- After quitting Sublime and stopping ledger-verify: memory 20% free, swap 15.0 of 16.4 GB (was 22.3 of 23.5), disk 85 GB free. Biggest left: mds_stores 9.7 GB.

## Memory report 2026-11-23
20% free, swap 18.3/19.0 GB (swap files take 19 GB of disk), disk 52 GB free.
Hogs: two ORPHANED ledger-verify.py runs at 10 GB each (parent = launchd; their sessions are gone):
- 59767 (up 3h13m) PRIGOGINE, started by `convey sync-ledgers --push` (pid 59765)
- 19939 (up 2h06m) STEINMETZ, started by `convey sync-ledgers --push` (pid 16340)
Root cause: convey/convey/sync_ledgers.py:88-90 always verifies against the ledger's own folder PLUS the whole ~/work/merlib-dump/sources tree. ledger-verify.py loads all of it into RAM, so each run reaches 10 GB. The prigogine run Esa stopped earlier was this same path.
Proposed fix: verify against the ledger's own source folder only (drop the shared sources root, or make it opt-in), and/or make ledger-verify stream one file at a time.
Others: mds_stores 3.6G (restarted, down from 10G), WindowServer 2.1G, Finder 1.5G, Terminal 1.1G, 18 claude sessions ~0.55G each.
- 2026-11-23: killed both orphaned runs (59767, 19939 and their sync-ledgers parents). Fixed convey (commit 198499827, pushed): verify only the ledger's own folder; single-instance flock; 5 GB RSS watchdog + 30-min timeout. Prigogine against its own folder: 14 s, 2,695 quotes, 2,667 verbatim, 28 SUSPECT.
- 2026-11-23 later: 22% free, swap 8.0/9.2 GB, disk 64 GB free; healthy. Top: mds_stores 3.6G, WindowServer 2.2G, Finder 1.5G, an rg search 0.8G, 17 claude sessions.
- 2026-11-23 14:42 memory report: 21% free, swap 8.1/9.2G, disk 62G free; mds_stores 4.2G, WindowServer 2.2G, Finder 1.5G, Terminal 1.1G; 16 claude sessions; no ledger-verify/sync-ledgers.
- 2026-11-23 15:48 memory report: 16% free, swap 10.2/11.3G, disk 60G free; sublime_text 7.0G (reopened), WindowServer 4.7G, mds_stores 4.2G, Finder 1.6G, Safari 0.9G; 16 claude; no ledger-verify.
- 2026-11-23 17:30 memory report: 13% free, swap 13.2/14.3G, disk 59G free; sublime 7.1G, WindowServer 6.6G, mds_stores 4.5G, Finder 1.6G, WebKit 1.2G, Safari 0.9G; 16 claude.
- 2026-11-23 19:15 memory report: 14% free, swap 12.5/13.3G, disk 52G free (-7G); sublime (new pid 17193) 7.1G, WindowServer 6.2G, mds_stores 5.0G, Finder 1.5G, WebKit 1.3G; 16 claude.
- 2026-11-23 19:20 after closing Sublime tabs: 17% free, swap 12.0G; sublime 6.9G (-0.16G), WindowServer 5.8G (-0.4G).
- 2026-11-23 19:25 Sublime diagnosis: 0 project folders; 166 open windows / 247 tabs restored from Auto Save Session (4.5 MB). Windows count = memory cause, not folders. Proposed: export open-file list, quit, set hot_exit/remember_open_files false or start fresh.
- 2026-11-23 19:30 CORRECTION: I wrongly said Sublime has no Merge All Windows. It does: Window ▸ Merge All Windows (macOS native tabbing). Esa's screenshot proved it.
- 2026-11-23 19:29 after Merge All Windows: 29% free, swap 12.8/14.3G; sublime 9.0G (UP from 6.9G), WindowServer 5.8G (flat), mds 5.0G; disk 51G.
- 2026-11-23 19:30 memory report: 24% free, swap 11.7/12.3G; sublime 8.7G, WindowServer 5.6G, mds 5.1G; disk 53G.
- 2026-11-23 23:06 memory report: 17% free, swap 13.9/14.3G (0.46G free); sublime 8.5G, WindowServer 6.0G, mds 5.8G, Terminal 1.4G, WebKit x3 3.5G; one sync-ledgers --push (pid 9414, another session, timeout 400) running; disk 51G.

## Check 2026-11-24 (read-only, nothing deleted)
Free 27G (was 42G after 11-21 cleanup). Where the space went:
- Swap: /System/Volumes/VM = 18G (swap 17.3/18.4 GB used). Memory pressure turns straight into disk use.
- ~/work/comms/.stversions = 19G (Syncthing old copies; never synced; safe to empty like convey-packs' was on 11-21).
- Downloads 197G, convey-packs 109G, Claude app support 10G, .cache 9.2G, Docker 9.0G, Library/Caches 4.3G.
Memory hogs: sublime_text 8.8G, mds_stores (Spotlight indexer) 8.6G, WindowServer 6.1G, Safari tabs ~4G, 30 claude processes ~0.5-0.6G each (many old 2.1.327/329).
- 2026-11-24: emptied comms/.stversions (19G freed).
- 2026-11-24: VEEP.zip is GONE (deleted days earlier). The 11-21 "30 largest files" list is stale; re-check files before citing them.

## Live scan 2026-11-24 (fresh du, ignore older lists)
Free 45G, swap 17.2G. Home: work 427G, Music 339G, Library 332G (Messages 154G, App Support 48G, Containers 47G, iCloud 34G, Mail 13G), Downloads 197G (FE 59G, EE 24G, SteveJobs_Watch_Free 8.3G, pori2026 7.6G, Screenshots 6.2G), Soulseek 54G, Pictures 48G, Movies 25G, .cache 9.2G.

## ~/work + Soulseek live scan 2026-11-24 (read-only)
~/work 427G: merlib-dump 114G (sources 74G [ge-review 8.8G, flickr 3.5G, OCR-orphans 3.3G, patent 2.9G], mirrors 15G, articles 8.7G), convey-packs 106G (john-bedini 27G, steve-jobs 7.3G, mike-clarke 5.3G), comms 73G (queue 55G: convey-isolate-results 25G, ocr-results 14G, convey-forum-results 7.0G, convey-isolate-source 5.3G, worker-status 2.6G; peers 12G; .git 3.9G; .stversions back to 474M), videos 21G, merlib-mirror 19G, voicebox 16G, Olga-videos 10G, apple 9.4G, ray-graph 8.1G, next 6.2G.
Soulseek 54G = complete/: MP3 27G (142 albums; Crydamoure 3.6G, J Dilla sets ~5G), Free Energy Research_SLSK 9.4G, m3Zz 8.8G, someone2 4.2G, mewinkler 3.3G. Files: 4086 pdf, 3325 mp3, 325 flac.
