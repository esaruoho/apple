# Whiteboard Integration

The user-owned Whiteboard skill at `~/.agents/skills/whiteboard/` generates visual boards through Gemini. For archive work, `bin/aimeat-whiteboard` adds a one-folder, two-stage path:

1. `python3 ~/work/apple/bin/aimeat-whiteboard prepare <folder>` packages only that folder's existing Markdown and submits it to the existing Cloudcity AIMEAT/Convey roundtable. It does not make images.
2. Once the Mini finishes, `python3 ~/work/apple/bin/aimeat-whiteboard collect <job-id>` files the returned panel transcript as `<folder>/_whiteboard-preparation.md`. Review and edit this file.
3. `python3 ~/work/apple/bin/aimeat-whiteboard yes-but-whiteboard <folder>` is the explicit Gemini image-generation trigger. It reads the reviewed Markdown and uses the source-aware count in its review checklist (editable with `--count`), plus the skill's synopsis, per-board Markdown and manifest.

Only one selected folder is processed per `prepare` call. It does not recurse over the entire boards archive as a batch. Existing PDFs and images are listed as context only through the selected Markdown; the command does no local OCR. A folder without usable Markdown is refused, leaving image-only PDFs to Cloudcity OCR first. Generated files stay in a dated subfolder beside the selected folder's source material. Existing generated boards are not removed or replaced.

