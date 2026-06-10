# Session — image-playground (Image Playground in Converse)

The spawning conversation for `features/image-playground.feature`. Faithful, not
flattering — it is the audit trail behind the grades.

## How to get back
- Transcript: this Claude Code session in `~/work/sofia` (Sofia project dir).
- Date: 2026-06-07 (work began 2026-06-06 night, rolled past midnight EET).
- Resume: `claude --resume <session-id>` — session id not captured at write time;
  recover from the project's transcript dir if needed.

## The arc
1. Tail end of a whiteboard task (Sofia "Uskontojen Dialogi" boards, Gemini).
2. Esa: "does apple have an image generator." → Answered: yes — Image Playground /
   Genmoji / Image Wand, plus the `ImageCreator` developer API (macOS 15.4+).
   Made the case it's the WRONG tool for whiteboards (can't render legible text),
   RIGHT for illustrative imagery. Offered an Apple-native ImageCreator CLI.
3. Esa: "can we take Converse and add image playground to it so that we could get
   an image of a tiger while FoundationModels responds with what a tiger looks
   like in prose" — the real feature ask.
4. Esa (while I worked): "yeah prototype imagecreator cli please" — green-lit the CLI.

## What was discovered (the load-bearing finding)
ImageCreator refuses to run headless: "not available when the application is
hidden or running in the background." Tried, in order, all on macOS 15.6.1:
- bare CLI call → failed (background)
- + NSApplication .regular + activate(ignoringOtherApps:) + RunLoop pump → failed
- + full app lifecycle: visible window, NSApp.run(), generate in
  didFinishLaunching → STILL failed
- bundled as ImageCreate.app, launched via `open -W` → SUCCEEDED.
Conclusion: a genuine foreground .app bundle is mandatory. The CLI therefore
drives a bundled worker; Converse (already a foreground window) calls direct.

## Decisions
- Feed the user's raw prompt to ImagePlayground — verified it extracts the subject
  from a question ("what does a tiger look like" → a tiger), so NO FM round-trip
  to pre-extract a noun. Simpler and lower-latency.
- Display via base64 `data:` URI (transcript WebView loads baseURL nil → file://
  is blocked). Self-contained, no read-access plumbing.
- Image bubble inserted BEFORE the assistant bubble so the streaming
  updateLastBubble (targets the last `.bubble`) keeps hitting the prose, not the
  picture.
- Two entry points: Image ▸ Illustrate Replies (⌘I) toggle for prose+picture;
  `/image …` (also draw:/picture of) for a one-off picture with no model call.

## Honest gaps (reflected in grades)
- Illustrate-ON simultaneous prose+image is @untested end-to-end: THIS Mac is
  macOS 15.6.1 with no local FoundationModels, so the prose half needs the Mini or
  a configured bridge to confirm the two render side by side. The IMAGE half is
  verified-live; the pairing is not.
- Not committed — Esa did not ask to commit. RESULT block notes pending.
- The bundled-app `open` flash: image-create briefly shows a 240×80 window. Cost
  of Apple's foreground requirement for a CLI.

## Verified live (2026-06-07)
- image-create --check → available; animation, illustration, sketch.
- image-create generated tiger.png (illustration), tiger2.png (sketch),
  q.png (from a question phrase) — all real PNGs, 1.4–1.7 MB.
- Inside Converse: `/image a majestic Bengal tiger` rendered inline; Esa then
  typed his own prompts ("a miniskirt", "a black cat") — three /image turns in
  ~/Documents/FoundationModelsChat/2026-06-07-001821/chat-*.md.
