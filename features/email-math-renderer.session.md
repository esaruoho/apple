# Single email renderer — session record

Esa reported raw LaTeX in the Phase Conjugation Tri-Brain email and supplied the dossier and memory coordinates. He then required one renderer rather than multiple maintained implementations. The implementation moves Markdown, rich text and supported TeX to apple/shared/format_email.py; callers import it and the archive uses an import shim. Unsupported expressions remain exact and visible, and attachments preserve the source.

The screenshot regression failed before the fix. The full dossier contains 37 expressions, all rendered without fallback; the polarization equation was visually inspected. Concurrent delivery-policy work was discovered and preserved through AST-targeted caller migration. A concurrent older formatter replacement was caught by rerunning tests and restored from the tested payload. Attachment fallback tests were updated because outgoing replies now have generated source attachments. No duplicate email was sent.

## How to get back

Session ID: 01a16318-b685-7a51-bf10-e3350a44337d
Resume: `codex --resume 01a16318-b685-7a51-bf10-e3350a44337d`
Transcript: file:///Users/esaruoho/.codex/sessions/2026/10/22/rollout-2026-10-22T13-12-06-01a16318-b685-7a51-bf10-e3350a44337d.jsonl
Source session date: 2026-10-22 (filename); implementation verification: 2026-10-23. No inferred message timestamps.

RESULT: see email-math-renderer.feature and commit history.
