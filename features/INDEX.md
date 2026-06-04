# AppleBar — Gherkin feature list

The single index of what AppleBar does. Two parts: the **capability catalog**
(every action you can type, from `shared/intents.json`) and the **behaviour
scenarios** (graded Given/When/Then, from `features/*.feature`).

## Capabilities — 27 actions (shared/intents.json → bin/apple-do)

| action | needs arg | what it does |
|---|---|---|
| `home` | — | temperature + humidity at home (HomePod) |
| `directions` | yes | directions home in Apple Maps |
| `address` | — | your home address (Contacts) |
| `now` | — | current date, time, weekday |
| `battery` | — | battery level + charging state |
| `wifi` | — | current Wi-Fi network |
| `clipboard` | — | what's on the clipboard |
| `lock` | — | lock the screen |
| `desktop` | yes | hide (or show) all Desktop icons |
| `dock` | yes | hide the Dock (auto-hide) or always show it |
| `dark` | — | toggle dark / light mode |
| `sleep` | — | put the display to sleep |
| `disk` | — | disk space overview |
| `mute` | — | toggle audio mute |
| `screenshot` | — | screenshot the screen to the clipboard |
| `eject` | — | eject removable disks |
| `caffeinate` | — | keep the Mac awake for an hour |
| `report` | — | this Mac's hardware report |
| `mini` | — | is the Mini/bridge reachable |
| `uptime` | — | system uptime |
| `keywords` | — | keywords from the clipboard text |
| `entities` | — | named entities in the clipboard text |
| `sentiment` | — | sentiment of the clipboard text |
| `fleet` | — | status of the Mini's workers |
| `spotlight` | yes | find files by name (Spotlight) |
| `search` | yes | semantic search of your notes |
| `ocr` | yes | extract text from a PDF/image (Vision) |

Plus three LLM paths typed as a prefix: `? <q>` (grounded in your learned
rules), `chat <q>` / `converse <q>` (general on-device LLM on the Mini).

## Behaviour scenarios (features/*.feature)

### applebar-session.feature — AppleBar — what the session accomplished
- `@shipped @verified` Headless Markdown renderer test (stop screenshotting render bugs)
- `@shipped` FoundationModelsChat exports the conversation
- `@shipped @verified` apple-intent — the embedding intent router (non-Tahoe twin of fm)
- `@shipped` AppleBar — the Spotlight-style command bar
- `@shipped` One shared catalog + one shared dictation engine (DRY)
- `@shipped @built` Capabilities wired (the "Conveys")
- `@verified` Each unit carries its own report card (the discipline)
- `@leak-fixed` Incidents closed

### dictation-button.feature — On-device dictation button
- `@verified` A fresh engine is idle
- `@verified` On-device recognition is preferred (audio stays local)
- `@verified` Stopping an idle engine is a safe no-op
- `@built @untested` Tapping the mic authorises, listens, and streams text into the field
- `@built @untested` Return stops the mic, then runs what was heard
- `@built @untested` A final result arriving after stop is dropped (no duplicate text)
- `@built` AppleBar consumes the shared engine, not its own copy (DRY)
- `@todo` AppleToolbox's SpeechDictationController sits on top of the shared engine
- `@note` Converse is a separate path, not a consumer

### directions-home.feature — Directions home via Apple Maps
- `@verified` Navigation phrases route to directions, not the thermostat
- `@verified` Temperature words ONLY hit the climate sensor (narrowed)
- `@built` directions opens Maps.app (not the browser) from current location to home
- `@note` The Maps URL pattern is reused from ray-graph, not re-invented

### fm-converse.feature — fm-converse — a remembering conversation with the on-device LLM
- `@built @verified-live` A follow-up question keeps the prior context
- `@built @verified-live` Replay stays inside the 4096-token FoundationModels window
- `@built @self-test` Markdown renders as ANSI on a terminal, plain when piped
- `@built @verified-live` A worker/guardrail/timeout error is surfaced, not swallowed
- `@built @untested` A file path is read and summarised instead of sent literally
- `@built @untested` Context-overflow self-heal retries without history
- `@built @caveat` The conversation is keyed to the newest Converse session dir
- `@built @caveat` Stored conversation is volatile and reportcard-less

### me-address.feature — Home address from the Contacts me-card
- `@verified` "where is my home" routes to the address lookup, not the thermostat
- `@verified` Climate questions still route to the HomePod sensor
- `@built` The address resolves from the me-card, or by name if none is set
- `@verified` Resolve once, then serve from cache (no repeated Contacts prompts)
- `@built` The address reads through unstyled (whitelabel passthrough)
- `@note` It uses Contacts AppleScript, not the network

### shell-toggles.feature — Desktop & Dock visibility from the command bar
- `@verified` "hide … desktop" and "hide the dock" route to their actions
- `@built` desktop hides (or shows) all Desktop icons
- `@built` dock auto-hides (or stays shown)

### spotlight-suggestions.feature — Live Spotlight-style suggestions in AppleBar
- `@built` Typing shows a ranked, navigable suggestion list
- `@verified` The picked suggestion runs exactly that action (no re-routing)
- `@verified` One catalog, two readers (DRY)
- `@verified` More Apple capabilities recognised
- `@note` "?" stays converse, not a suggestion
