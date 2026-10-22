# AIMEAT folder roundtables

Drop a UTF-8 `.txt` into `~/work/merlib-dump/aimeat`. Syncthing carries it to
CloudcityMacMini. Its visible **AIMEAT Roundtable** Cloudcity-Boot pane runs
Convey's existing Qwen/MLX **full panel**, including Bearden, Prigogine, Russell,
Hilarion, Rigel and the other installed participants.
No inference runs on the laptop; the worker explicitly refuses there.

Results return through the two-way comms share. The existing AppleToolbox
tag-watcher tick files them beside the local source (normally within its
60-second tick after Syncthing delivery). The archive's send-only configuration
is preserved. This local step only copies verified files; it runs no inference.

Results beside the source:

- `example.txt.roundtable.md`: named turns, updated as they arrive.
- `example.txt.roundtable.json`: status, source hash and completed section ranges.
- `.roundtable/<job-id>/`: source snapshot, per-section JSONL and archived results.

The default is two full panel rounds per section, two turns per persona. The
full bench comes from the Mini's `all.yaml`, or Sages plus Classic on an older
installation; a nine-person bench produces eighteen turns. Files longer than
6,000 characters are split losslessly into explicit sections, each discussed
separately. This is a section-by-section discussion, not a claim that the entire
document fits in one shared context. Completion requires all expected turns and
all selected seats in every section. Failed sections retry with backoff, up to
three attempts; finished sections survive restarts. Inputs are limited to 1 MiB.

The watcher waits five seconds after an input's last modification. Generated
`.text.txt`, `.transcript.txt` and `.speakers.txt` sidecars are excluded, so
existing extracted PDFs do not automatically launch hundreds of discussions.
To process one deliberately, use `submit` on the Mini.

```sh
# Read saved status on either computer; no model call.
python3 ~/work/apple/bin/aimeat-roundtable status

# Mini only: deliberate submission or failed-job retry.
python3 ~/work/apple/bin/aimeat-roundtable submit /absolute/path/note.txt --retry
```

The panel reads the Mini's canonical roster configuration and quote-ledger
corpora. A derived `aimeat-sages.yaml` preserves multiline persona instructions
for Convey's dependency-free parser. Russell's existing RBI text is included
as a private grounding snapshot when the Mini lacks its legacy skill path.
Historical voices are labelled as
AI-generated interpretations, not quotations.

Deployment uses `python3 roundtable/install.py stage`: source files and a fixed
installation request travel through the Syncthing/PakettiBot bridge. On the Mini,
the installer backs up changed files, compiles Boot there, adds its systems.yaml
entry and installs the Boot applet. Activation is a separate
`python3 roundtable/install.py stage --action activate`, which sends the existing
`cloudcity restart` command. No SSH launch, detached worker or LaunchAgent.

On an older Mini, the installer also backs up and updates only Convey's
`cmd_roundtable` function from the existing local source, adds its missing seat
flag and checks that corpus retrieval is available. It does not replace the
whole Convey checkout. Source files are syntax-checked before installation.
The verified compatibility function is bundled for a clean older checkout,
so reproducing the upgrade does not depend on uncommitted Convey changes.

The service targets Mini-local HTTP inference at `127.0.0.1:8080`; it disables
fm-mlx's SSH fallback and bounds subprocess groups. It reuses Convey's engine,
corpus retrieval and knowledge recording rather than introducing another model
runtime.

This implementation watches the **local Syncthing folder**, not uploads on the
AIMEAT website. Website intake would need its own authorized connection.

Verification and deployment grade: [report card](../features/aimeat-roundtable.feature).

## Email PDFs

Email a PDF attachment or an explicit `.pdf` URL to `cloudcity-llm@agentmail.to`
from a configured owner address (currently Esa's Gmail or iCloud address).
The existing Mini mail pane durably queues the message, saves the original PDF,
extracts all pages with embedded text or Mini-side Vision OCR, and records pages
where no text was recognized. OCR provides text, not interpretation of diagrams.
The attachment byte-size limit remains explicit (25 MiB by default); there is no
twenty-page limit. Locked or unreadable files produce an honest error, not an
analysis of missing content.

Every bounded source section receives a checkpointed reading. All readings are
retained; large sets are reduced in stages for the final archive-grounded
synthesis. Large extracted documents are split losslessly into multiple
roundtable input files rather than rejected by the watcher's per-file limit.
The full panel runs on each input. Completion therefore takes longer for books.

Originals, extraction/page records, analysis, roundtable transcripts and new
black-background wordcloud, sentencecloud and ideacloud artifacts return through the comms share and are filed beside
one another in the laptop's `merlib-dump/aimeat`. The final threaded email includes
the analysis, describes its analysis types, and attaches the saved analysis and
all three cloud PNGs plus their readable rendering sources alongside originals
when the service size limit permits. Markdown analysis is rendered as HTML in
the email body, with a plain-text fallback; Markdown source files remain separate
attachments for agents.

Each cloud has `<stem>.<type>.png`, `<stem>.<type>.source.md` and
`<stem>.<type>.render.json`. The source Markdown lists the exact weighted text
and embeds the complete checksummed JSON input. It is written before the image.
Ideacloud also retains the extractive takeaways in `<stem>.ideacloud.md`.
The existing video key-takeaways path keeps its timestamps and `.keyideas.md`;
its poster now gains `.keyideas.source.md` and `.keyideas.render.json` too.
Single-file/folder Convey cloud commands preserve sources, and corpus scans skip
generated `.source.md` files to avoid counting their own prior output.

On the Mini, regenerate an image without reading its PNG:

```sh
python3 ~/work/apple/bin/cloud-assets render /absolute/path/paper.ideacloud.source.md --out /absolute/path/recreated.png
```

Build all three types for an existing extracted text with
`python3 ~/work/apple/bin/cloud-assets build /absolute/path/paper.txt`.
These are extractive views, not additional model analyses. If no suitable prose
exists for a sentence or idea cloud, the missing artifact is reported explicitly.

Pending jobs live in `comms/queue/aimeat-mail-jobs/<message-hash>/state.json`.
The Mini keeps processing artifacts in that job's `workspace`, and the existing
roundtable pane reads those inputs directly. It can finish while the laptop is
asleep. The laptop's collector is the sole writer of returned artifacts into
its archive; the Mini consumes the canonical roundtable return channel.
The existing mail pane advances one checkpoint per poll. Failed steps back off;
after three failures, one failure email describes the incomplete work. A send
with an ambiguous outcome is held as `sending-unconfirmed` for inspection and
is never automatically repeated. `aimeat-mail-heartbeat.json` identifies the
running host, PID and code hashes. Deployment uses `roundtable/install_mail.py`
and activation uses Cloudcity-Boot's existing restart control. Future mail code
updates reload within that existing pane after the current poll.

This PDF intake is separate from the ordinary shorter email-answer path.
Generic webpage and photo archival intake remains future work.
See [email PDF report card](../features/aimeat-email-pdf.feature).

Verified on CloudcityMacMini with two documents: 36 real turns, all nine default
seats twice per discussion, matching source/result hashes and automatic local
filing. Nineteen behavioral tests cover sectioning, retries, version safety,
transport integrity, full-panel enrollment and the Mini-only execution guard.
See [verification.json](verification.json).
