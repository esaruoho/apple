# Session: safari-hogs

## How to get back
- Transcript: `~/.claude/projects/-Users-esaruoho-work-apple/480ed8ef-d841-4077-9b49-7aa23cc7bfc2.jsonl`
- Session ID: `480ed8ef-d841-4077-9b49-7aa23cc7bfc2`
- Resume: `claude --resume 480ed8ef-d841-4077-9b49-7aa23cc7bfc2`
- Verified: 2026-11-10 18:36 EET

## Ask
Esa: "what do you think is the possibility of us reading WHICH TAB is eating the most in Safari … identify the power-hungry tabs and even select them or open the worst offender and let me close it … codify this as a skill."

## Findings
- No public PID->tab API; lsappinfo says only "Safari Web Content". Service workers carry their domain.
- 568 tabs ran in ~13 WebContent processes.
- `do JavaScript` on a sleeping background tab reloads it (age 0 s), so probing is front-tab-only.
- A CPU-burn fingerprint maps a tab to its PID reliably.
- AppleScript `tab` inside the Safari tell block means the tab class, so the script uses `character id 9`.

## Built
bin/safari-hogs, commands/safari-hogs.md, wiki/concepts/safari-tab-power.md, this card.
