---
description: On-device OCR via Apple's Vision framework (Neural Engine) — no pipeline, no deps. Reads an image or PDF and prints recognized text. Usage `/vision-ocr <file> [--lang en,fi] [--fast] [--pages N]`.
allowed-tools: Bash
argument-hint: "<image-or-pdf> [--lang en,fi] [--fast] [--pages N] [--langs]"
---

Run Apple's on-device OCR on a file and print the text.

Use Bash to execute (one call):

```
/Users/esaruoho/work/apple/bin/vision-ocr $ARGUMENTS
```

Notes:
- Same engine as macOS Live Text, on the Apple Silicon Neural Engine — Apple-native,
  no Homebrew/pip, no network.
- Images (png/jpg/tiff/heic/…) and PDFs (rendered page-by-page) are supported.
- ~1–2 s per page; a fast local first-pass for text-bearing scans before the
  heavier Cloudcity LLM-OCR pipeline. See `wiki/concepts/apple-silicon-ml.md`.
- First run compiles `bin/vision-ocr.swift` to `~/.cache/apple/` via `xcrun swiftc`.
