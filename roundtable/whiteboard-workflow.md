# AIMEAT whiteboard review gate

`bin/aimeat-whiteboard` connects one selected `articles/boards/<folder>` to the existing Cloudcity roundtable and the installed Gemini whiteboard skill.

```sh
python3 ~/work/apple/bin/aimeat-whiteboard prepare 2026-08-05-perry-flyback-open-system
python3 ~/work/apple/bin/aimeat-whiteboard collect <job-id-printed-by-prepare>
# Read and edit ~/work/merlib-dump/articles/boards/<folder>/_whiteboard-preparation.md
python3 ~/work/apple/bin/aimeat-whiteboard yes-but-whiteboard 2026-08-05-perry-flyback-open-system
```

`prepare` includes the folder's existing Markdown with per-file SHA-256 provenance and makes one `.txt` request in the synced AIMEAT intake. The existing Cloudcity-Boot roundtable processes it using its full installed panel. `collect` finds the canonical hash-matched return in comms and writes a review file; it refuses to overwrite a prior review unless `--replace` is explicitly passed.

The returned transcript is a draft. The human can edit its claims, layouts, labels and evidence notes. The review file includes a suggested renderer count: existing numbered board sections plus the title slot required by the Whiteboard skill. Edit that line or pass `--count` to change it. Only `yes-but-whiteboard` calls `whiteboard-generate.sh`; that skill then handles Gemini text planning and image generation, and saves its PNGs, PDFs, synopsis, per-board Markdown and manifest in a dated child directory. No automatic scan of all board folders exists, and no `prepare` call invokes Gemini image generation.

Folders with no usable Markdown fail with a clear message. The command never runs OCR locally. Add or use Cloudcity OCR/text extraction before preparing an image-only PDF. The command limits each request to the existing roundtable's 1 MiB input limit and does not remove existing boards.

Implementation and current grades: [report card](../features/aimeat-whiteboard.feature).
