# Stage 2 — Sessions (imported from features/me-address.session.md)

# Session — "Where is my home" address lookup (spawning conversation)

Faithful, not flattering. Audit trail for `me-address.feature`.

## How to get back

- **Same session as the dictation card** (one continuous working session):
  `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/fde596bb-669f-493a-8a43-04a4e33cd964.jsonl`
- **Bundled transcript (local-only, gitignored — repo is public):**
  `features/dictation-button.transcript.jsonl` / `.md` (the same session backs both cards)
- **Session ID:** `fde596bb-669f-493a-8a43-04a4e33cd964`
- **Resume:** `claude --resume fde596bb-669f-493a-8a43-04a4e33cd964`
- **Card authored:** 2026-06-03 (EEST).

## How this unit was spawned

Esa: *"'where is my home' still says temperature of my ohme. my home is at
inkiväärikuja 6 b 20. you have access to it from Esa Juhani Ruoho Contact card."*

Two problems, both fixed here:
1. **Routing collision** — "where is my home" was matching the `home` CLIMATE action
   (the word "home" dominated the embedding) and returning the HomePod temperature.
2. **No address capability** — there was nothing that reads the postal address.

## What shipped

- `bin/me-address` — AppleScript `tell application "Contacts" … formatted address of
  (home address of my card)`, on-device, no deps. Exposed as `apple-do address`.
- `bin/apple-intent` — a new `address` intent whose phrasings ("where is my home",
  "where do i live", "what is my home address") out-score the climate `home` examples;
  `{raw}` whitelabel template (the formatted address is already human).
- `shared/test-intent-routing.sh` — executable guard: asserts the place-question routes
  to `address` and the thermostat-questions stay on `home`. **Passes.**

## Honest status

- Routing is `@verified` (headless test passes).
- The address fetch is `@built` and **hand-verified 2026-06-03** — returns
  `Inkiväärikuja 6 B 20 …` cold + warm. Three bugs were found and fixed on the way:
  1. `osascript - "$OWNER"` (passing the name as argv) is the wrong invocation for a
     stdin heredoc → parse failure. Fix: pass the name via env + `system attribute`.
  2. `system attribute` was placed INSIDE `tell application "Contacts"`, so it got
     dispatched to Contacts (which ignores it) and returned empty → name fallback never
     fired. Fix: read it at top level, before the tell block.
  3. Contacts AppleScript queries need Contacts.app running, else `-600`. Fix: launch it
     hidden+background (`open -gja`, no window/focus steal) when not already up.
- No "me" card was set; the **name fallback** (`id -F` → "Esa Ruoho", matched against
  "Esa Juhani Ruoho") is what made it work without Esa configuring anything.
