# PDF reply attachment failure — session

## How to get back

Transcript: file:///Users/esaruoho/.codex/sessions/2026/10/10/rollout-2026-10-10T22-44-47-01a12758-b74f-7690-852a-5dd49d02433d.jsonl
Session ID: 01a12758-b74f-7690-852a-5dd49d02433d
Resume: `codex --resume 01a12758-b74f-7690-852a-5dd49d02433d`
Transcript session started 2026-10-10T19:44:47.992Z; metadata recorded 2026-10-10T19:45:05.434Z (verified from the first transcript record).

## Requests and findings

Esa reported a PDF extraction warning and asked for it to just work. After remote OCR repair, Esa asked: “prove to me that the PDF can be sent to cloudcity-llm and that we can thus see how it works.”

The agent sent the original PDF via the configured Gmail account using Mail AppleScript. AgentMail received it in thread 826740b5-a4e6-460c-8ae0-e19a6e291b40. Downloading the received attachment proved an exact SHA256 match. The initial worker generated document-specific analysis, but its reply POST failed with HTTP 413 while reattaching the original PDF. Its at-most-once ledger prevented automatic recovery, leaving the user without a reply. The synced debug log contained only the first 1500 characters of the lost analysis, so that excerpt cannot substitute for a full reply.

The fix adds a single smaller-payload retry only on explicit HTTP 413 and only when attachments were present. Ambiguous failures are not retried by this new helper. Four unit tests cover size rejection, analysis/recipient preservation, ambiguous errors, attachment-free rejection, and normal success. A bounded recovery client will regenerate the analysis on Cloudcity and record its send result. This is an explicit recovery of the existing request, not evidence that the already-running worker has reloaded the new code.

## Verified outcome

The normal Mini pull was blocked by modified bin/freellmask-mail and untracked files. No changes were stashed or overwritten. The bounded client used a temporary committed snapshot at 04d3e55a. It downloaded and fingerprinted the actual received attachment again, extracted 25,998 characters remotely, allowed the six-page text through without the ordinary 24k prompt cap, and generated an analysis with gemini-3.1-flash-lite. The first reply attempt reproduced HTTP 413; the attachment-free fallback succeeded. AgentMail and the actual Gmail inbox both reported the same reply message ID. The worker itself remains on its existing uncommitted code. Durable proof: analysis/proofs/milewski-email-proof.md.
