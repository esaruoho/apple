# Notes processing: complete text, Apple Vision and Processing IDs

`bin/notes-process` reads the stored note text from read-only NoteStore.sqlite using
`notes-variants`' existing gzip/protobuf reader. It preserves the first paragraph,
even when Notes treats that paragraph as the title. Source notes are never rewritten.
The separate rich-text reply includes the complete source text and a Processing ID.
The image stays in the original note; an evidence copy is saved in the run archive.

On Cloudcity, downloaded image attachments are copied into the run archive and passed
to the existing `bin/vision-ocr` twice: accurate text recognition and `--classify`.
These are Apple Vision OCR and classification labels, not a multimodal LLM's detailed
interpretation of wiring or geometry. Missing images, unsupported attachments, empty
results, timeouts and subprocess errors are recorded. No OCR runs on the laptop.

Each run gets `NP-<UTC timestamp>-<random suffix>`. Find that ID in the response and in:

- `~/work/comms/queue/notes-process-runs/<ID>/` (Syncthing shared when comms exists).
- Otherwise `~/.local/share/notes-process/runs/<ID>/`.
- Override with `NOTES_PROCESS_RUNS` if needed.

The directory contains `source.json` (including original compressed note data),
`source.txt`, copied images and hashes, `vision.json`, exact assembled `prompt.txt`,
`model-NNN/request.json`, backend request/response records, `reply.raw.txt`, `reply.md`
and `status.json` with the delivery result or failure. Each consensus sample has its
own model directory. Log persistence happens before the model request. The ledger
also records the Processing ID.

Inspect with `bin/notes-process --show-run <ID>`. This prints status and exact input.
These archives contain private source material; they live outside the public repo.

Previously processed notes are not automatically replayed. To deliberately generate
one new audited reply: `bin/notes-process --once --reprocess '<exact note id>'`.
This requires the original trigger tag and leaves previous replies intact.

Related: [append Shortcut](notes-process-append-shortcut.md),
[report card](../../features/notes-process.feature).
