# PREVIEW-001: Default PDF Viewer Has Zero AppleScript Support

**App:** Preview.app
**Intent:** Programmatically open, annotate, convert, or export PDFs and images
**Severity:** Architectural gap — the default document viewer is invisible to AppleScript
**Status:** Open
**Filed:** 2026-03-07

---

## The Friction

Preview has **17 App Intents** and **35 Siri phrases** — but **zero AppleScript commands**. No scripting dictionary at all.

This is the default PDF viewer and image viewer on every Mac. It handles annotations, signatures, form filling, format conversion, and cropping. None of this is scriptable.

| Task | Can AppleScript Do It? | Can Shortcuts Do It? |
|------|:----------------------:|:--------------------:|
| Open a PDF | No (use `open -a Preview`) | Yes |
| Annotate a PDF | No | No |
| Export as PNG/TIFF | No | Partial (via Intents) |
| Fill a form field | No | No |
| Add a signature | No | No |
| Merge PDFs | No | No |
| Crop an image | No | No |
| Resize an image | No | Partial |

---

## What Sal Would Say

Sal's Principle #6: **Use the whole toolkit.** But Preview isn't IN the toolkit. It has no sdef, so AppleScript can't talk to it. It has Intents but they're shallow — mostly "open" and "show." The most useful operations (annotate, export, convert) are GUI-only.

Sal's Principle #7: **Think in workflows.** A publishing workflow needs: open PDF -> annotate -> export -> email. Today each step requires manual GUI interaction with Preview.

---

## The Automation Surface

| Layer | Status |
|-------|--------|
| AppleScript (sdef) | None |
| App Intents | 17 actions, 35 Siri phrases |
| URL Schemes | None |
| CLI equivalent | `sips` (images), `qlmanage` (Quick Look), `mdls` (metadata) |

The CLI tools cover image processing (`sips`) but not PDF annotation, form filling, or document manipulation.

---

## Fix Paths

1. **Apple (ideal):** Add a scripting dictionary to Preview — open, annotate, export, convert, merge. Preview already has the internal capabilities; they just need an sdef surface.
2. **Shortcuts (partial):** Expand Preview's App Intents beyond navigation — add "Export as PDF," "Merge Documents," "Add Annotation."
3. **`sips` + `qlmanage` (workaround):** Image resizing, format conversion, and Quick Look rendering work from CLI. No PDF annotation.
4. **System Events UI scripting (hack):** Click through Preview menus. Fragile, breaks with UI updates.
5. **Third-party (escape hatch):** `poppler` (`pdftotext`, `pdftoppm`), `ghostscript`, or Python `PyPDF2` for PDF manipulation. Not Apple-native.

---

*Part of the [Apple Automation Atlas](../README.md).*

**Filed by [@esaruoho](https://github.com/esaruoho)** -- software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator.
