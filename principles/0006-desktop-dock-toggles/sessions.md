# Stage 2 — Sessions: how this folder was conveyed

> The folder `bin` may be modified by several sessions at once (fm-converse,
> Claude, a human) while this principle is described. This is their narrative —
> faithful, not flattering. The hard record of which commits by which session
> touched the folder is read from git by `convey done`.

## Session log
- **Session: <fm-converse / claude / human>** — <what it was asked to do>
  - **Prompt:** <what was asked>
  - **Result:** <what it changed / proposed>

## Decisions reached
- <decision and why>

## Dead ends
- <what was tried and rejected>

## How to get back
<Run `convey bundle 0006-desktop-dock-toggles --transcript <path-to.jsonl>` to copy the spawning
transcript beside this card (lossless `.jsonl` + readable `.md`) and fill this
block. Until then the click-back is pending. Never fabricate a session id.>

- Transcript: <file://… — filled by `convey bundle`>
- Session id: <filled by `convey bundle`, or "unconfirmed">
- Resume: `claude --resume <session-id>`
- Window: <first … last timestamp>
