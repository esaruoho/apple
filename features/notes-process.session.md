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

## Round 3 — generated Shortcut failed; linked notes are the live path
9. Generated Shortcut popped a text dialog (Esa typed "what is reactive power?" / "tell me about reactive power
   extraction" into it) and then a "which note?" picker of all notes. Esa: "i don't want it to touch these notes."
   Shortcut path disabled by default (--shortcut ''), append read-back verification + 45s cap added.
10. Brain: notes-brain → Flubuild Qwen2.5-7B (→ MLX Qwen → Apple FM). "katsotaampa toimiiko tämä #process"
    answered as linked note p13588; 2nd pass no-op. Hand-built Shortcut documented in
    wiki/concepts/notes-process-append-shortcut.md (not yet built/verified).

## Ledger crash fix — 2026-11-15

Esa supplied a Cloudcity screenshot showing notes-consensus repeatedly crashing in ledger()
with JSONDecodeError: Unterminated string, and asked for a quick fix preventing recurrence.
The first response inferred malformed JSON; inspection also found str.splitlines() breaks
valid JSON containing Unicode separators. A regression reproduced this exact exception.
The fix uses LF boundaries, locked reads/appends, fsync, damage backups and recovery of
complete leading keys. Watch mode catches pass errors and retries. Tests run on both
local Python interpreters without contacting Notes or generating replies.

### How to get back
- Transcript: file:///Users/esaruoho/.codex/sessions/2026/11/15/rollout-2026-11-15T00-06-22-01a1dc4f-d609-7e50-abc7-7655000ad9d4.jsonl
- Session ID: 01a1dc4f-d609-7e50-abc7-7655000ad9d4
- Resume: codex --resume 01a1dc4f-d609-7e50-abc7-7655000ad9d4
- Session timestamp: 2026-11-14T23:06:22.124Z (verified transcript session_meta).
- Work clock checked: 2026-11-15T00:57:05+01:00.

### RESULT
- Fix commit: 33e9dee9, direct push to main, no PR. Fast-forward pulled on Cloudcity.
- Mini diagnosis: splitlines yielded 32 valid + 2 invalid fragments; LF yielded 33 valid
  records and zero invalid records. The ledger was intact, not corrupt.
- Mini verification: ledger() loaded all 33 keys; all 11 tests passed under /usr/bin/python3.
- Changes: bin/notes-process, test_notes_process.py, features/notes-process.feature,
  features/notes-process.session.md; generated features/README.md and STATUS.md.
- Syncthing diagnostic bridge did not return. Used verified Tailscale SSH fallback
  for read-only diagnosis and a fast-forward pull; existing Boot wrappers relaunched workers.

## Complete source + Vision + Processing ID

Esa reported the Keely note's image and text appeared missing from its Re: note.
Read-only inspection found the original p12480 still has its complete 2,896-character
text and a 3,103,922-byte PNG; the separate response p12497 only quoted hashtags.
The old pipeline had no image input and dropped the first plaintext line.

Esa requested: integrate Apple Vision, fix text insertion, and log model inputs with
an ID shown in the response so the run can be revisited. Implemented full stored-note
reading using the existing notes-variants decoder; on-Mini Vision OCR/classification;
full source text in the new rich-text reply; source/image/input/backend/output/delivery
records; visible NP Processing IDs; Syncthing run archives and --show-run inspection.
An explicit --once --reprocess NOTE_ID supports a deliberate new reply without resetting
the at-most-once ledger. Source notes are never rewritten. Tests mock Vision locally.

Codespace: bin/notes-process, bin/notes_input.py, bin/notes-brain, test_notes_process.py.
Thinkspace: this session, with the existing verified transcript link above.
Areaspace: Notes input preparation, evidence, request audit and additive reply delivery;
no changes to the shared LLM service or the original Notes content.
Delivery/live Vision verification pending at authoring time.

Live Keely run NP-20261115T060856Z-43018e9b80fc successfully archived the full
2,894-character source (inline placeholders removed), a 3,103,922-byte image,
Vision OCR/classification results, 3,284-character prompt, exact Flubuild messages
and model reply. Vision found no text in this photograph; classifier labels were
material/tool/mousetrap at 0.15 confidence. Notes delivery failed with -609 Connection
is invalid. The error remained visible, revealing another problem: periodic forced
Notes restarts can race another worker's write. Default refresh changed to off;
one-shot errors now return nonzero, and delivery errors are marked uncertain.
