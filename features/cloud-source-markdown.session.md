# Readable cloud sources — session

## How to get back

- Transcript: file:///Users/esaruoho/.codex/sessions/2026/10/21/rollout-2026-10-21T22-16-28-01a15fe4-bcfd-7d82-bce6-1bae3e0d8dde.jsonl
- Session ID: `01a15fe4-bcfd-7d82-bce6-1bae3e0d8dde`
- Resume: `codex --resume 01a15fe4-bcfd-7d82-bce6-1bae3e0d8dde`
- Verified session_meta timestamp: `2026-10-21T19:16:28.605Z`.
- Card: [cloud-source-markdown.feature](cloud-source-markdown.feature).
- Lossless and readable source transcript bundles are stored beside this card, private and gitignored.

Esa requested readable Markdown sources for wordcloud, sentencecloud and ideacloud PNGs so an agent can use the underlying text without OCR. He also called out the prior email implementation's omission of sentencecloud and ideacloud, and asked whether returned email renders as readable rich text.

Inspection confirmed that the previous email path generated only wordcloud. Sentencecloud already existed as a standalone Convey action. Ideacloud existed in Convey video's `make_keyideas`: an extractive, deduplicated key-takeaways Markdown and poster. The integration reuses that implementation with optional text input and optional timestamp labels, preserving default behavior for audio/video while avoiding fabricated 0:00 timestamps on PDFs.

The renderers now save exact weighted text inputs to `.source.md` and `.render.json` before saving each PNG. The source Markdown embeds the checksummed JSON so it is sufficient to render again, without reading the image. Wordcloud uses a fixed seed for reproducible layout. The sentence/idea poster renderer uses black backgrounds. Single-file wrappers and folder commands copy source sidecars out of temporary directories. Generated source Markdown is excluded from corpus scans to avoid self-ingestion.

The existing `md_to_html` email formatter already supplies headings, bold, inline code, lists, links and tables in an HTML body with a plain-text fallback. A regression test checks those tags and the absence of visible Markdown markers in the formatted fixture. Cloud PNGs and source Markdown/JSON are separately attached and returned to the laptop through the established manifest collector. No live test email is sent by verification.

Forty-four behavioral tests pass before Mini runtime verification. The Mini probe will check all three cloud types and compare original/replayed pixels using only the saved Markdown as input. Runtime results and delivery commits must be recorded before claiming them.

Runtime verification passed on CloudcityMacMini for payload `ee890110f2619f17`. Wordcloud, sentencecloud and ideacloud each produced a black-background PNG, readable source Markdown and rendering JSON. The Mini replayed every image from its Markdown-only specification and compared equal pixels, using no OCR of the cloud images and making no model calls. The idea-cloud PDF output contained no fabricated 0:00 timestamp. Proof PNGs, Markdown/JSON and verification data are saved under `analysis/proofs/cloud-sources/`. The live mail heartbeat's four code hashes matched this checkout. Email transport remains simulated; the real formatter's HTML tags were checked without sending a test email.

The local Convey CLI had substantial pre-existing changes. Only the cloud sidecar preservation and generated-source exclusion hunks are selected for this task's commit, keeping unrelated CLI work out. Existing user changes and concurrent roundtable edits are preserved. The archive renderer is patched in place, while the versioned portable patch and canonical helper in Apple make its behavior reproducible.

Apple implementation/card commit `7e12d57f` was pushed directly to main. During approval waits the original Convey checkout entered a concurrent merge with an unrelated Gimme-Ledger conflict and a large staged change set. No commit was made from that index. A fresh temporary worktree at remote main received the same surgical patch, producing renderer commit `2a660677a`. Its first push encountered a newer Convey MCP update; isolated merge `d81d5fe51` preserved that work and was pushed successfully. The original checkout's merge was not resolved, reset or committed by this task. The earlier selected cloud files remain part of that checkout's concurrent index state; no attempt was made to rewrite another session's index after detecting the merge.

All three PNGs, exact Markdown sources, render JSON and the HTML formatting tests are complete. The live Mini mail heartbeat continues to match all four deployed code hashes. Verification sent no live email; attachment composition and HTML formatting were tested with simulated transport. New outputs are enabled; this work does not claim that every historical PNG has been backfilled.
