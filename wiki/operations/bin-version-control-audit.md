---
description: Audit of ~/bin scripts — which are version-controlled (symlinks into repos) vs untracked real files, and where the untracked ones should be filed. Zero-data-loss sweep started 2026-06-15.
---

# ~/bin version-control audit (2026-06-15)

`~/bin` is on PATH but is **not** a git repo. Most entries are symlinks into repos
(apple, cloudcity, comms, ray-studio-backend, PDFWorkshop, claude skills) — those are
tracked. This audit covers the **real files** that exist only in `~/bin` and are therefore
at risk of loss if `~/bin` is ever rebuilt.

## Already version-controlled (symlinks into a repo)
All `*-exporter`, the `voicebox-*` family (now apple/bin, 2026-06-15), `apple-*`, `ask`,
`ghc`, `hey-sal`, `invert`, `loom-status`, `md-to-clipboard`, `qr-wifi`, `read-aloud`,
`renoise`, `show`, `smart`, `mini-up`, `mirror-status`, `syncthing-status`, `ray-get`,
`ocr`, the `cloudcity*`/`cc*` screenshot aliases, `mlx_whisper`. ✓ No action.

## Untracked real files (the candidates)

| Script | What it does | References / data home | Suggested repo home |
|---|---|---|---|
| `bearden` | TTS/chat via Bearden cloned voice | now `convey/voices/bearden/` | **DONE → convey** (2026-06-16) |
| `esa` | TTS via Esa cloned voice | now `convey/voices/esa/` | **DONE → convey** (2026-06-16) |
| `milton` | TTS/chat via Erickson cloned voice | now `convey/voices/erickson/` | **DONE → convey** (2026-06-16) |
| `rob` | TTS/chat via McNeilly cloned voice | now `convey/voices/rob/` | **DONE → convey** (2026-06-16) |
| `ocr-vision` | `exec apple/bin/vision-ocr` (pure alias) | apple/bin/vision-ocr (tracked ✓) | symlink → apple/bin/vision-ocr |
| `vision-ocr` | `exec apple/bin/vision-ocr` (pure alias) | apple/bin/vision-ocr (tracked ✓) | symlink → apple/bin/vision-ocr |
| `ocrq` | Queue PDF/URL into Syncthing OCR inbox | `comms/queue/ocr-inbox` (comms IS git, has ocr-*.sh) | comms |
| `ray-dev.sh` | Launch local Ray w/ dev flags | `/Volumes/T9/chromium-ray-poc/...` (external volume) | ray-studio-backend? or dotfiles (machine-specific) |

`erickson` is already a symlink → `milton`.

## Separate, larger finding (flagged, not in scope here)
`~/work/merlib-dump` and `~/work/esa-voice` are **not git repos** — so the persona
`speak.py` scripts *and* their cloned-voice data live unversioned. The persona *CLIs* can be
tracked in apple/hyp regardless, but the voice data itself is a bigger zero-data-loss
question (may be large audio corpora). Decide separately.

## Plan (pending routing confirmation)
1. `ocr-vision`, `vision-ocr` → replace exec-wrappers with symlinks to apple/bin/vision-ocr
   (pure aliases, zero unique content lost). Safe, unambiguous.
2. `ocrq` → comms (next to ocr-status.sh / ocr-tail.sh), symlink back from ~/bin.
3. `bearden`, `esa`, `milton`, `rob` → home per user choice (apple/bin uniform, or hyp for
   milton/rob), symlink back from ~/bin.
4. `ray-dev.sh` → user choice (track in a repo, or leave as machine-specific).
