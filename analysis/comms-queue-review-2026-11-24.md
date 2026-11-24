# comms/queue review — 2026-11-24 (read-only, nothing deleted)

comms/queue = 55G on the laptop. It's a Syncthing folder, so deleting something here also deletes it on the Mini. Any cleanup should go through convey or .stignore, never a plain rm.

## ocr-results (14G, 2,571 top-level files + processed/ 2,205)
- The design is that Mini OCR results land here and `convey ocr-collect` "homes" them (copies them) next to their source in merlib-dump, using convey-ocr-manifest.jsonl.
- Live check of the `_ocr.pdf` files (the bulk of the bytes): 1,470 of them (7.6G) have a same-size .pdf already in merlib-dump/convey-packs/Downloads, so they're already homed and the queue copy is a leftover. 104 (0.6G) have no copy anywhere.
- `convey ocr-collect -n` today: 3 would be homed, 605 waiting for OCR, 13 skipped (their home is /Volumes/CLOUDCITY4TB/... _convey-book-intake/papers, which only exists on the Mini).
- ~~So ocr-collect copies the results but never removes them from the queue.~~ CORRECTED (same day, after reading roundtrip.py): collect MOVES the trios it homes. The leftovers are results homed by another route (the Mini filing beside the origin, ocr-results/processed/), skipped-dupes, and results from before the manifest existed. Nothing cleaned those up.
- 7 sync-conflict copies of convey-ocr-manifest.jsonl (2026-11-21..23): two machines are writing the manifest at the same time.

## convey-isolate-results (25G)
77 job folders (eftv-*-bedini, steve-jobs-*, john-bedini-*). 264 mp4 = 26G. Only 2.4G of those have a same-size copy in convey-packs. No file is newer than 14 days; the newest folder is from Aug 10. These are old intermediate clips from the isolate pass.

## Others
convey-forum-results 7.0G (aboveunity-com-* jobs), convey-isolate-source 5.3G (source videos for isolate), worker-status 2.6G (the live OCR queue; leave it alone).

## Suggested direction (not done)
1. Add a "prune after homing" step to `convey ocr-collect`: once a result is verified (size/hash) next to its source, move it out of the queue. Keep a list of the 104 that have no copy anywhere.
2. Make convey-isolate-results Mini-only via the laptop's .stignore (the same pattern as lenr/forum on 11-21) once the Mini copy is confirmed.
3. Fix the manifest write race (sync-conflicts).

## Done 2026-11-24
- convey a5d197d27 (pushed): per-host OCR ledger shards (manifest + to-be-analyzed) so laptop and Mini never write the same file; readers union legacy + shards + old conflict copies. ocr-collect now prunes byte-identical filed results (sha256, laptop only, every 6h).
- Prune ran: 3,010 files / 7.71 GB removed; ocr-results 14G -> 6.6G. Log: comms/queue/convey-ocr-pruned.host-RayMac.jsonl.
- convey-isolate-results + convey-forum-results made Mini-only: the Syncthing API confirmed the Mini holds all 1,334 + 3,290 files at the same size, they were added to the laptop's comms/.stignore, Syncthing confirmed them ignored, then the local copies were deleted. Afterwards Syncthing shows the Mini still has them (not deleted globally).
- Free space 44G -> 79G.
- Still to do: the Mini's long-running OCR panes need a Cloudcity-Boot restart to load the new code (until then the Mini still appends to the legacy file).
- 2026-11-24: Cloudcity restart sent via pakettibot-inbox .cmd (ran 11:52Z). Deleted the two stale Oct 23 restart .cmd files from the inbox. 11 other stale .cmd files remain (listed in chat); .cmd IS processed — stale ones are leftovers, not proof .cmd is ignored.
- 2026-11-24: deleted the remaining 11 stale .cmd files from pakettibot-inbox.
- 2026-11-24: pakettibot-agent 60f5cac: the file bridge used to skip every inbox file older than bot startup, silently and forever (Syncthing keeps mtimes). It now runs unanswered drops younger than 60 min, retires older ones to processed/stale/ with a NOT RUN note, and claims a file before running it (restart leftovers). Live after the next PakettiBot restart.
- 2026-11-24 ~16:55 EET: Why adams.pdf "vanished": it had been bumped, was being OCRd when the 13:52 restart hit, and the worker recovery put it back in FIFO pending (behind 431 jobs), losing its priority. PDFWorkshop a6842cc: interrupted jobs now go to priority/ and are touched so they resume first. Re-bumped adams; it is first in priority/. Second Cloudcity restart sent (picked up via .cmd). The Kron jobs the laptop shows in priority/processing are already deleted on the Mini; the laptop was just mid-sync.
