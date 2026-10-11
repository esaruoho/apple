---
description: PDF analysis must hand off empty text extraction to Cloudcity OCR and resume, rather than stop at a warning.
---
# PDF Analysis: Empty Text Needs a Cloudcity Handoff

## Diagnosed case

On 2026-10-10, selecting `John-Milewski-Superlight.pdf` in ScaffFinder produced an error beginning “No text was returned by the available extractors.” The failure came from `BrainEvidence.extract` in `~/work/FinderSearch/Sources/FinderSearch/MiniBrains.swift`. Native PDFKit and the Poppler fallback both require a usable existing text layer; neither performs OCR.

The selected file was a six-page, 5,391,907-byte PDF 1.0, unencrypted. `pdfimages -list` found a page-sized 300-DPI JPEG on each page. `pdftotext` returned six form-feed characters and no text. These observations explain why this particular file needs OCR. Empty extraction alone does not establish that every such PDF is scanned: blank pages, unsupported font encodings, and encryption are other possibilities.

## Required behavior

1. Attempt native extraction and the installed independent text decoder.
2. If a PDF still returns no text, automatically prepare a Cloudcity OCR request via Syncthing and the canonical manifest-writing Convey submitter.
3. Show document-reading progress, keep the interface responsive, and continue the original analysis action after readable text returns.
4. Persist the request so a retry reuses it. Cancellation stops waiting without deleting remote work. A bounded wait must distinguish pending work from failed extraction.
5. Cache by the SHA-256 of the actual selected bytes. Never reuse another document's text merely because its filename matches.
6. Reject OCR output containing only page headings. A nonzero text-file size is insufficient evidence of successful recognition.
7. Keep the original PDF unchanged and disclose that evidence comes from OCR.

The shared fallback belongs before model prompts and email composition, so Mini Brains, file email, and folder chat receive the same prepared evidence. No local OCR and no SSH are needed.

## Pipeline details learned

The BBS submit shim lives at `~/.agents/skills/bbs/bin/bbs-ocr-submit.sh` on this machine and forwards to `convey ocr-submit`. The canonical Python implementation is `~/work/convey/convey/roundtrip.py`.

Inspection of `submit` found that its active-entry dedup keys come from normalized basenames, despite its content-oriented docstring. The FinderSearch adapter stages a transport PDF named with the source SHA-256, uses canonical submission, and saves its exact returned stem. This avoids same-name collisions without changing the canonical pipeline.

The worker returns `<stem>.txt` in `~/work/comms/queue/ocr-results/`. Convey may home it beside the transport source before the app reads the results folder, so the adapter checks both destinations. `apple/bin/syncthing-nudge` requests an immediate local rescan after submission. Cloudcity's worker heartbeat is mirrored at `queue/ocr-heartbeat.json`; a queued request is not proof of completed recognition.

An older archive PDF with the same basename had a different SHA-256. Its text was not substituted. An older mirrored result contained only six page headings and was likewise not accepted.

## Implementation and verification

Implementation: `~/work/FinderSearch/Sources/FinderSearch/CloudcityOCR.swift`.
Report card: `~/work/FinderSearch/features/cloudcity-pdf-ocr.feature` with session and transcript artifacts alongside it.

Focused fixture checks passed for request reuse, canonical homed results, source fingerprints, cache separation, cancellation and page-heading rejection, plus the existing PDF/email checks.

Live GLM output then exposed a second failure: 62.4% of its long-line characters repeated. A bounded diagnostic using the model's documented `Text Recognition:` prompt also repeated paragraphs, so a prompt change alone was not claimed as a fix. The supported prompt is documented in the [GLM-OCR model card](https://huggingface.co/zai-org/GLM-OCR).

The adapter now rejects heavily repeated output and, after two minutes, enqueues a bounded call to the existing `apple/bin/vision-ocr` **on Cloudcity** through `pakettibot-inbox`. It validates the transported source SHA-256 and returns an atomic `vision.json`. This is a remote client call, not laptop OCR or a new long-lived process. The live native call finished in 2.7 seconds on the Mini and returned 25,999 characters spanning six page headings, the title and references. The app's live preparation test successfully consumed that evidence and cached it under the selected file's exact hash. Original PDF bytes remain unchanged.

The canonical GLM archive job may continue independently; analysis uses the first acceptable recognition result. Cancellation or timeout retains the durable requests. Native errors are reported without silently accepting repeated GLM text.

## Verified email attachment path

The [live Milewski proof](../../analysis/proofs/milewski-email-proof.md) establishes original-PDF receipt at `cloudcity-llm@agentmail.to`, a byte-for-byte downloaded attachment match, remote Apple Vision extraction, model analysis, and a matching reply in Gmail. This uses the actual received attachment rather than passing cached text to a compose command.

It exposed an independent delivery bug: returning the original 5.4 MB PDF as base64 caused AgentMail to reject the reply with HTTP 413, after which the at-most-once ledger suppressed retries. `bin/freellmask-mail::send_inbox_reply` now retries explicit 413 rejection without attachments. The live recovery exercised that fallback successfully. The tested repair is pushed; the Mini’s existing modified files blocked normal deployment, so recovery used an isolated committed snapshot. The long-running inbox worker still needs the repair integrated and reloaded. The proof client included all six-page OCR text; default inbox small-context truncation remains a separate limit.

## Related

- [AppleScriptObjective-C](asobjc.md)
- [Finder tag pipeline](finder-tag-pipeline.md)
