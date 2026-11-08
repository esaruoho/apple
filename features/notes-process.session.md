# notes-process — session

## How to get back
- Transcript: `~/.claude/projects/-Users-esaruoho-work-apple/86265a9a-f9a3-4edf-9750-98c4a6179061.jsonl`
- Session ID: `86265a9a-f9a3-4edf-9750-98c4a6179061`
- Resume: `claude --resume 86265a9a-f9a3-4edf-9750-98c4a6179061`
- Date: 2026-11-08 ~21:58 EET (verified with `date`)

## Audit trail
1. Esa: a user-definable hashtag (e.g. #process) in a Note sends that content verbatim to cloudcity-llm,
   appends the reply non-destructively, and marks it #done so there's no feedback loop.
2. "cloudcity-llm" here = the Mini's on-device LLM via `bin/fmremote` (the agentmail cloudcity-llm@ inbox
   is an email front-end; --llm can point at any stdin→stdout command).
3. fmremote round-trip verified (pong, 6.9s).
4. Built bin/notes-process with guards (see .feature). Test note p13471: dry-run → real pass → reply
   "The capital of Finland is Helsinki." appended, #process→#done, 2nd pass no-op, backup written.
5. test_notes_process.py: 5 pure-logic tests pass.

## RESULT
- direct-push, no PR. Files: bin/notes-process, test_notes_process.py, features/notes-process.*

## Round 2 — Esa: "well it really didn't work, did it?" + "you're not supposed to rewrite a note but to safely append"
6. No watcher was running; and a hand-typed orange #process is an inline object: U+FFFC in plaintext,
   ABSENT from body HTML → v1's `set body` would have deleted it. The note was never touched (v1 found nothing).
7. Notes AppleScript has no append verb. Esa chose "Both": Shortcut append when installed + unique title,
   else linked note "Re: <title>".
8. Rewrote notes-process: read-only SQLite discovery of hashtag objects, no `set body` anywhere,
   ledger keyed by tag ZIDENTIFIER. Real run: p13544 → reply note p13583; 2nd pass no-op. 7 tests pass.
