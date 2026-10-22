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

Verified on CloudcityMacMini with two documents: 36 real turns, all nine default
seats twice per discussion, matching source/result hashes and automatic local
filing. Nineteen behavioral tests cover sectioning, retries, version safety,
transport integrity, full-panel enrollment and the Mini-only execution guard.
See [verification.json](verification.json).
