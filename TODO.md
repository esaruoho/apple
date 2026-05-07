# Apple Repo TODO

Working state. Cross items off as they land. Updated 2026-05-07.

## Right now — transcription pipeline (built, not yet fired)

- [ ] **Fire Track A from Discord:** `!pk cloudcity bash /Users/esaruoho/work/apple/bin/sal-transcribe-youtube.sh`
  - Submits 16 YouTube interview URLs to whisp-worker queue
  - whisp-worker daemon runs through them autonomously
  - Sync step copies transcripts into `sources/sal/transcripts/youtube/` and commits
  - Wall-clock estimate: ~3-4 hours of audio across 16 videos → ~1 hour of transcription on M2 Pro turbo
- [ ] **Fire Track B from Discord:** `!pk cloudcity bash /Users/esaruoho/work/apple/bin/sal-transcribe-podcasts.sh`
  - First run resolves the 24 Apple Podcasts URLs to MP3 enclosure URLs via iTunes Lookup + RSS XPath
  - Then downloads each MP3, runs `whisp`, organizes transcripts under `sources/sal/transcripts/podcasts/<show>/`
  - Wall-clock estimate: ~25 hours of audio across 24 episodes → ~2 hours of transcription + ~30 min download
- [ ] **Verify resolver coverage:** after Track B's first run, inspect `analysis/sal/apple-podcast-mp3-urls.yaml` — any entries with `status: no-match` or `status: feed-fetch-failed` need manual mp3_url override before re-running.
- [ ] **Optional: enable Discord summary** — set `POST_DISCORD=1` when invoking the podcast script so a `.cmd` lands in pakettibot inbox at completion.

## After transcripts arrive

- [ ] Re-run `bin/sal-archive-status.py --write analysis/sal/current-status.md` to refresh the dashboard.
- [ ] Update `indexes/sal-interviews-discovered.yaml` to add `transcript_path:` next to each YouTube + podcast entry.
- [ ] Cross-link transcripts into `indexes/sal-lessons.yaml` where they support a curriculum module.
- [ ] Spot-check 3 transcripts for proper-noun accuracy (Soghoian variants, Ray Robertson, Allison Sheridan, etc.). If hallucinations are bad, re-run that subset with explicit `--prompt` containing the proper-noun registry.
- [ ] Send the follow-up email to Sal Soghoian: thank him for the 2026-04-03 deliveries, list what was preserved (3 of 6 missing files recovered + transcripts soon to follow), and ask whether his backup drives might still hold `aperturepdfworkflows.zip` / `Script_Geek.zip` / `Script_Geek_old.zip`.

## Sal archive — remaining gaps (3 dead URLs)

- [ ] `https://macosxautomation.com/405/us/media/apple/applescript/2008/aperturepdfworkflows.zip` — Wayback only has 404 captures, Apple CDN dead, Sal-only recovery path
- [ ] `https://macosxautomation.com/applescript/apps/Script_Geek.zip` — same; try MacUpdate, oldapps.com, MacRumors forum threads before nudging Sal
- [ ] `https://macosxautomation.com/applescript/apps/Script_Geek_old.zip` — same as Script_Geek.zip

## CMD-D conference site mirror (not yet done)

`bin/sal-discover-interviews.py` surfaced 75 Wayback snapshots of `cmddconf.com` including the 2017 program page, bootcamp materials, and speaker headshots. Worth mirroring like we did `dictationcommands/`.

- [ ] Add `cmddconf.com` to `bin/sal-mirror.py` (or whatever site-mirror tool is canonical) and pull a clean offline copy under `sources/sal/cmddconf.com/`
- [ ] Index the bootcamp materials (`Alert-Utilities.zip`, `FileManagerLib_stuff.zip`, `installer.zip`) in `indexes/sal-download-targets.yaml` so they're cross-referenced with the conference page

## Discovery script — known limitations to fix later

- [ ] Wayback CDX `twitter.com/macautomation` rate-limits to 503 even with backoff. Use a different scraper (`snscrape` is broken since Twitter API change; `nitter` mirrors are mostly down). Defer until a working tool surfaces.
- [ ] Most Mac journalism site searches now resolve via the DDG fallback (TidBITS, MacStories) but Six Colors / Daring Fireball / MacRumors still return 0 hits. Try Google Custom Search proxy or per-site sitemap.xml parsing.
- [ ] PodcastIndex.org has an API but requires signup. If the iTunes Search results miss any episodes, integrate it as another source.
- [ ] Add YouTube channel-handle probe (e.g. `@macautomation` or whatever Sal's own channel is) instead of relying on keyword search.

## Skill / tooling refinements

- [ ] Codify the discovery + transcription workflow into a section of `skill.md` once the first transcripts land and the runbook is proven end-to-end.
- [ ] Generate whiteboards for the new sections: Sal preservation pipeline, the @cloudcity remote-run pattern, the file-drop bridge.
- [ ] Add `sal-archive-status.py` to the skill's boot protocol if not already there. (It is — line ~33 of skill.md.)

## Lower-confidence Apple Podcasts matches (verify before processing)

- [ ] **Examining #64 — Mac Mini M1 & AI Retrospective** — likely mentions Sal in retrospective context, may not be a primary interview. Verify by listening to the first ~5 minutes before adding to `apple-podcast-episodes.txt`.
- [ ] **Gig Gab — The Value of Prep Time** — Working Musician's Podcast; matched the Sal filter via a passing "Apple"/"automation" mention. Probably false positive. Verify or drop.

## Deferred / nice-to-have

- [ ] Build `bin/sal-mirror.py` site auto-mirror so adding new Sal-related domains is one command (`sal-mirror cmddconf.com`).
- [ ] Add a per-show RSS-feed monitor: when a show that's hosted Sal once publishes a new episode mentioning him, auto-queue.
- [ ] Wire the @macautomation Twitter archive recovery via a different route (snscrape unreliable; consider a paid TwitterAPI relay just for one-time historical scrape).
