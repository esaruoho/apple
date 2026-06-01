---
description: RESOLVED 2026-06-01 — PDFWorkshop's buildOcrPdf corrupted CCITTFax-G4 images (pdf-lib copyPages) → 7 blank _ocr.pdf. All 7 rebuilt with PyMuPDF; root cause fixed upstream so future OCRs are clean.
---

# Blank / corrupt _ocr.pdf outputs — RESOLVED

**Root cause:** PDFWorkshop `buildOcrPdf` used pdf-lib `copyPages`, which corrupts
**CCITTFax-G4** image streams → blank `_ocr.pdf` for fax-scanned books (7 of 371).
The `.txt` OCR text was always intact; only the PDF packaging was broken.

**Fix (upstream, permanent):** `buildOcrPdf` now assembles the searchable PDF with
**PyMuPDF** (`build_ocr_pdf.py`) — preserves the page images, adds an invisible text
layer. PDFWorkshop commit `1589f05` (2026-06-01). Future OCR runs are clean.

**Recovery tool:** `bin/ocr-pdf-rebuild` (`/ocr-pdf-rebuild`) — clean scan + the
`.txt` → proper searchable PDF, via PyMuPDF.

## All 7 rebuilt (proper searchable PDFs, placed next to their source as `_ocr.pdf`)
- [x] `merlib-dump/sources/kron/1959 - Tensors for Circuits (Dover 2nd edition)_ocr.pdf` (270 pp)
- [x] `merlib-dump/sources/kron/kron-equivalent-circuits-electric-machinery-GE-series_ocr.pdf` (303 pp)
- [x] `merlib-dump/sources/geet/01 Book of GEET_ocr.pdf` (172 pp)
- [x] `merlib-dump/sources/steinmetz/hunt-stein-1963-static-electromagnetic-devices-full-book_ocr.pdf` (391 pp)
- [x] `merlib-dump/sources/shinichi-seike/seike-principles-of-ultra-relativity_ocr.pdf` (188 pp)
- [x] `merlib-dump/sources/davson-schappeller/davson-physics-primary-state-of-matter-1955_ocr.pdf` (340 pp)
- [x] `merlib-dump/sources/eclipse-gravity/allais-1999-NASA-memoir-allais-effect-paraconical-pendulum_ocr.pdf` (167 pp)

All verified: render (images present) + searchable (text layer). The new files live
in the merlib-dump archive — commit/sync per that repo's workflow.
