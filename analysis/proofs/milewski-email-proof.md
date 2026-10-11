# Milewski PDF → Cloudcity → Gmail: verified proof

The original `/Users/esaruoho/John-Milewski-Superlight.pdf` was sent from the configured Gmail account to `cloudcity-llm@agentmail.to`. AgentMail received the actual PDF attachment; its downloaded bytes exactly matched the selected file. A repaired, bounded client on Cloudcity then extracted the received PDF, generated its analysis, and delivered a reply that was independently found in Mail’s Gmail inbox.

| Evidence | Observed result |
|---|---|
| Subject | PDF pipeline proof a9d87eab12 — John-Milewski-Superlight |
| Original attachment | 5,391,907 bytes, six pages |
| Original and received SHA256 | `1e19b0a6ca62ee45c94f1c3b78eaa662383dac375b6715d2b4b7436e31c9b96c` |
| Inbound message | `<9C9858D8-8902-4D35-811B-CECB16D2CC2C@gmail.com>` |
| Thread | `826740b5-a4e6-460c-8ae0-e19a6e291b40` |
| Remote extraction | 25,998 characters; Apple Vision on Cloudcity |
| Model | `gemini-3.1-flash-lite` via Cloudcity’s FreeLLMAPI gateway |
| Reply message | `<010001a12b323185-79389d74-62a6-4b29-abfa-1334ad856942-000000@email.amazonses.com>` |
| Reply timestamp | 2026-10-11T13:41:12.084Z |
| Inbox receipt | Matching message ID, sender and subject found through Mail AppleScript |
| Full provider reply | 3,776 characters including service footer and quoted original email |
| Full reply SHA256 | `27afebd11bbb419e62e8da8cba5cfb4eb96afc9e619ae3dbb048af29fffe72af` |

Read the [returned analysis](milewski-email-proof-reply.md), [attachment fingerprint receipt](milewski-email-proof-attachment.json), and [remote execution/delivery receipt](milewski-email-proof-receipt.json). The saved public analysis omits the provider footer and quoted outgoing email; its body is the generated reply, not an independently verified scientific conclusion or exhaustive source audit.

## Failure found and repaired

The first worker attempt did read the PDF and generate a document-specific answer, but the reply POST returned **HTTP 413: Request Entity Too Large** when it tried to reattach the original PDF as base64. Its at-most-once ledger then suppressed retries. The [failure excerpt](milewski-email-proof-initial-failure.txt) records that rejection; it contains only the debug logger’s 1,500-character answer prefix.

`bin/freellmask-mail::send_inbox_reply` now retries an explicitly rejected HTTP 413 once without attachments, preserving the answer and thread and explaining that the originals remain in the original email. It adds no fallback retry for timeouts or other ambiguous failures. Four new unit tests plus four existing email-artifact tests passed. The live recovery reproduced HTTP 413 and succeeded through the attachment-free fallback.

The recovery extracted the received attachment anew on the Mini, rather than substituting another same-named document or laptop OCR. Its six-page text was allowed through in full by the bounded proof client. The ordinary inbox worker still has a 24,000-character small-context cap; this test does not establish complete reading for arbitrary documents through that default path.

## Delivery scope

Fix and report card: `d4fdb8f9`; isolated recovery client: `04d3e55a`; both pushed directly to main, no PR. Recovery ran from that committed snapshot and finished with exit 0 in 13.0 seconds. The Mini’s normal repository pull was blocked by existing modified and untracked files. Those were preserved. **The long-running inbox worker has not been replaced or restarted with this fix.** The successful recovery proves this PDF’s receipt, remote extraction, model analysis and real Gmail delivery, not unattended future worker deployment.

[Report card](../../features/mail-reply-attachment-fallback.feature) · [Session](../../features/mail-reply-attachment-fallback.session.md) · [Recovery client](milewski-email-proof-recover.py)
