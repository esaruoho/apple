---
description: Rebuild a proper SEARCHABLE PDF from a clean scan + OCR text, using PyMuPDF (fixes PDFWorkshop's blank _ocr.pdf — pdf-lib copyPages corrupts CCITTFax). Usage `/ocr-pdf-rebuild <clean-source.pdf> <ocr.txt> <out.pdf>`.
allowed-tools: Bash
argument-hint: "<clean-source.pdf> <ocr.txt> <out.pdf>"
---

Rebuild a searchable PDF that renders (images preserved) + has an invisible text layer.

Use Bash to execute:

```
/Users/esaruoho/work/apple/bin/ocr-pdf-rebuild $ARGUMENTS
```

Why: PDFWorkshop's `buildOcrPdf` uses pdf-lib `copyPages`, which corrupts CCITTFax-G4
image streams → blank `_ocr.pdf`. This rebuilds with PyMuPDF (fitz), which preserves
the images and adds the OCR text as an invisible layer (render mode 3). See
`wiki/operations/blank-ocr-pdfs.md`.
