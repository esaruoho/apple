# FoundationModelsChat

A tiny, private chat app for **Apple's on-device LLM** (FoundationModels — the
model behind Apple Intelligence). It runs the model **in-process on your own
Mac**: no network, no account, no API key, no per-token cost. Everything you
type and everything it answers is **saved continuously**. Drag in a **PDF or
text file** and it's read and sent. Math renders natively as **MathML** via
WebKit. Fully whitelabeled — nothing here names a person, host, or service.

## Requirements

- **Apple Silicon Mac** on **macOS 26 (Tahoe)** with **Apple Intelligence enabled**
  (Settings ▸ Apple Intelligence & Siri) and the on-device model downloaded.
- The app *launches* on macOS 14+, but on anything below 26 it opens and tells
  you the model isn't available — it can't chat there.

## Build

```bash
./build.sh            # build into ./build and open
./build.sh --install  # also copy to /Applications
```

Apple-native only: AppKit, WebKit, FoundationModels, PDFKit, Vision, ImageIO.
No Homebrew, no pip, no npm, no bundled JS.

## Use

- Type, press **Enter** to send (**Shift-Enter** for a newline).
- Replies **stream in live** as the model generates them (local model).
- **Drag a PDF / .txt / .md / .rtf / image** onto the window → it's extracted to
  text (PDFKit text layer, or on-device **Vision OCR** for scans/images) and sent.
- **Paste a URL** or ask what a page says → the model calls the built-in
  **WebReader** tool to fetch it (URLSession + NSAttributedString, no third-party
  HTML parser) and answers from the text.
- The conversation **remembers** (one stateful `LanguageModelSession`). When it
  fills the on-device model's small context window, the app **summarizes and
  rebuilds the session** automatically so you can keep going.
- Equations: the model is asked to emit **MathML**, which WebKit renders with the
  system math font. (A small built-in LaTeX→MathML fallback covers `$…$` too.)

The model is **prewarmed** at launch so the first reply isn't slow.

## Where your chats go

Every turn is written immediately to:

```
~/Documents/FoundationModelsChat/<timestamp>/
  chat-<timestamp>.md     human-readable transcript
  events.jsonl            one JSON event per prompt/response
```

Nothing leaves your machine.
