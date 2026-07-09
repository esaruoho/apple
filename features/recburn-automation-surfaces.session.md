# Session — recburn automation surfaces + typed handoff

Spawning conversation for `features/recburn-automation-surfaces.feature`. Faithful, not flattering:
the record of what was asked, what was decided, and what is honestly NOT yet verified.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/1170db2b-51c3-4d96-89a1-2815ccd73656.jsonl`
- Session ID: `1170db2b-51c3-4d96-89a1-2815ccd73656`
- Resume: `claude --resume 1170db2b-51c3-4d96-89a1-2815ccd73656`
- Dates: work done 2026-07-09 (EEST); conversation opened 2026-07-08.

## The ask
Turn 1 — Esa: boot the apple skill; the recburn/rec feature, "call it a multimedia recording
pipeline — is that what it is, or is it not?"; update the apple-rec repo with that; and "we haven't
spoken to Sal for a while — what's the Sal take for recburn."

I verified the code (engine `screen-audio-record.swift`, `recburn` = `rec --mic --pip --burn`,
`RecBurnController` parsing stdout), confirmed "multimedia recording pipeline" is accurate (with the
caveat that "recording" undersells the burn/production half), framed it in the README, and gave a
Sal reading. Sal's two critiques: (1) the stages hand off by scraping stdout strings — he wanted
typed data between actions; (2) there's no system-level verb — no Shortcuts action, no Services /
Quick Action — so the pipeline is invisible to the layer where non-scripters compose workflows.

Turn 2 — Esa: "expose recburn as a shortcuts action. expose recburn as a services menu, or quick
action. and fix the typed-handoff-fix and deploy to apple/ and apple-rec repos. make it far more
robust. and … tell me what would sal add to this molecule."

## Decisions (and why)
- **One control seam.** Everything (Shortcuts, Services, Siri, hardware, terminal) funnels through a
  `recburn://` URL routed by `RecBurnController.handleURL()`. No duplicated start/stop lifecycle.
  Chosen over per-surface logic because it's the robust, testable, single point of truth.
- **Typed handoff = a manifest.** The engine (the pipeline's orchestrator — it alone knows every
  artifact) writes `<stem>.recburn.json` + prints `RECBURN-MANIFEST: <path>`. The app decodes the
  struct. Kept the human "✓ …" prose for terminal users; kept the old scraping + dir-scan as
  fallback tiers 2 & 3 so an old engine binary still works. Contract round-trip unit-tested headless.
- **Shortcuts via App Intents, but URL is load-bearing.** App Intents give the native Shortcuts/Siri
  experience, but SwiftPM-without-Xcode may not extract the App Intents metadata that powers gallery
  discovery. So the intents are THIN shims over the URL, and the guaranteed path is a one-action
  "Run Shell Script → `open recburn://toggle`" (or `recburn-url`). Graded @built, not @hw-verified.
- **Services via NSServices in the app**, not a hand-generated Automator `.workflow`. Self-contained,
  fully in our control, assignable to a global hotkey. A fragile generated `.workflow` would not have
  been "more robust"; rejected it. Manual Quick-Action creation documented instead.

## Honest gaps (what I did NOT verify — see STATUS.md)
- No live recording was started this session (it would capture Esa's real screen), so:
  producing + consuming a REAL manifest end-to-end is unit-verified only; the `open recburn://…`
  → app → start/stop round trip was not fired; the Services trio was not click-tested in the menu;
  App Intents were not confirmed to appear in the Shortcuts gallery.
- What IS verified: clean Swift-6 build of engine + App Intents + Services provider; Info.plist
  carries the URL scheme + NSServices (plutil -lint OK); bundle re-registered (lsregister -f);
  manifest strings present in the rebuilt binary; the manifest Codable contract round-trips both ways.

## Deploy (Ship 1)
Engine source mirrored identical into `apple/bin` and `apple-rec/Engine`; apple/bin binary rebuilt;
app + build.sh + README + STATUS in apple-rec (canonical); `recburn-url` in both. Direct-push to main
in each repo, no PR.

## Turn 3 — Ship 2 (chaining + YouTube)
Esa: (1) I'd left 9 tasks stuck on `pending` — called out, fixed. (2) "RecBurn to upload to YouTube
would be fantastic." (3) The start phrase should be **"Record"**, not "Record my screen" — keep it
understandable. (4) "make the intents return the artifact, make manifest metadata as chainable
shortcuts values."

Decisions:
- **Chain source of truth.** The app persists the completed manifest to a single
  `~/Library/Application Support/RecBurn/last.recburn.json` on stop (written only on a real result,
  after any video-first remux). The value intents read that — no "newest file" guessing.
- **Return an entity, not just a file.** `RecBurnRecording: AppEntity` exposes file / durationSeconds
  / hasSubtitles / subtitleFile / micRecorded, so downstream actions can branch on the metadata —
  that's "manifest metadata as chainable values." `Get Latest` (instant) + `Stop and Return File`
  (stops, polls the manifest until the pipeline finishes, ~20min budget) are the chain entry points.
- **"Record"** is the start intent's title; Siri phrase "Record with RecBurn" (App Intents phrases
  must contain the app-name token, so the bare verb lives in the title/shortTitle).
- **YouTube = pure stdlib.** `recburn-youtube` does OAuth installed-app loopback + resumable chunked
  upload with urllib/http.server — no Google SDK, matching the no-third-party ethos. Chose it over a
  Swift/URLSession port for speed-of-correctness. The Publish intent shells to it (bundled in
  Contents/MacOS). Needs the user's one-time Google Desktop OAuth client — documented, not shippable.

Honest gaps (turn 3): App Intents compile + titles are in the binary; `recburn-youtube` py-compiles
and its CLI/error paths run. NOT run-verified: a live recording writing last.recburn.json, the entity
returning through Shortcuts, and a real OAuth + upload (no client provisioned). Correct-by-
construction, untested end-to-end — see STATUS.md "run-verified" gap.
