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
