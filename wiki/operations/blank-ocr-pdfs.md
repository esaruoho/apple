---
description: PDFWorkshop produced 7 blank/corrupt _ocr.pdf outputs (corrupt CCITTFax). Text .txt is intact; page images need re-OCR. Checklist of affected docs + recoverability, pending a buildOcrPdf fix.
---

# Blank / corrupt _ocr.pdf outputs (PDFWorkshop buildOcrPdf bug)

Found 2026-06-01. Of **371** OCR'd PDFs, **7 render blank** — `buildOcrPdf`
re-embedded the page images as **CCITTFax-G4 that's corrupt** (CoreGraphics AND
MuPDF both fail: "invalid code in 2d faxd"). The `.txt` OCR text is **intact** for
all 7 — only the searchable-PDF packaging is broken. NOT a repair: the images in
the `_ocr.pdf` are unrecoverable; must re-OCR from the original scan.

**Order:** fix `buildOcrPdf` (CCITTFax re-encode) FIRST — re-OCR before that just
reproduces the corruption.

## Re-OCR-able from the Mini (original still in PDFWorkshop/queue/uploads/)
- [ ] `kron-equivalent-circuits-electric-machinery-GE-series`
- [ ] `hunt-stein-1963-static` …
- [ ] `allais-1999-NASA-memoir-allais-effect-paraconical-pendulum`

## Originals DELETED — must be re-supplied from the source archive
- [ ] `1959_-_Tensors_for_Circuits__Dover_2nd_edition_`
- [ ] `01_Book_of_GEET`
- [ ] `seike-principles-of-ultra-…`
- [ ] `davson-physics-primary-…`

## Detection
`ssh cloudcity` → PyMuPDF render each `_ocr.pdf` page; <0.2% non-white = blank.
See `bin/bridge-doctor` neighbours; root-cause write-up in this session's log.
