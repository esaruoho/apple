# Email into the AIMEAT workspace

The proposed entry point is the existing cloudcity-llm@agentmail.to inbox. Its current handler, `bin/freellmask-mail`, already reads email bodies, fetches ordinary web pages and linked PDFs, and extracts text from PDF/image attachments on the Mini. There is no AIMEAT-folder handoff in that handler yet. These are source-code findings, not verification of the current running Mini mail service.

The missing bridge should preserve each inbound message and its original attachments/downloads durably, with message ID, sender, subject, URL and content hashes. It should produce a complete UTF-8 source text in `~/work/merlib-dump/aimeat`, then let the existing Mini-only roundtable watcher do its job. Deduplicate by message and asset identity so polling/retries cannot launch repeated discussions. Use an approved-sender or explicit routing rule because the inbox is public.

For URLs, save the fetched source and extracted article text. Route video URLs through transcription. For PDFs, extract embedded text first and send scans through the existing Mini OCR pipeline. For photographs, retain the original and OCR visible writing; a visual description of diagrams or objects needs a separate vision treatment and must not be represented as OCR.

Do not reuse the current mail extraction result as a complete archive: `_extract_one` and `fetch_url_content` limit PDF OCR to 20 pages and clip extracted text to MAX_CHARS; attachment temporary files are deleted. Archive ingestion needs its own durable, full-document path with explicit failures/coverage, independent of successful email reply generation.

The existing roundtable produces named turns and status beside its text input and returns those files through the comms share to the laptop. A proposed completion step could reply in the original email thread with a receipt and the finished transcript, if authorized as part of implementing that workflow. Searchable indexing and links to related archive material should be explicit downstream outputs, with generated interpretations kept distinct from source evidence.

This describes the Syncthing-backed local AIMEAT workspace. Publishing into the connected AIMEAT website/node is an additional destination requiring its own mapped workspace and upload/indexing integration; the current folder watcher does not provide that.

Source pointers: `bin/freellmask-mail` (`_att_bytes`, `_extract_one`, `extract_attachments`, `fetch_url_content`, `poll_once`); `roundtable/README.md`; `roundtable/bridge.py`.

Status: proposed bridge; not implemented or live-tested by this note.

Implementation update: the owner PDF attachment/direct-PDF-URL path is now built
and deployed. See `features/aimeat-email-pdf.feature` and `roundtable/README.md`
for actual behavior and verification. Generic webpage/photo archival intake and
publishing into the AIMEAT website remain separate work.
