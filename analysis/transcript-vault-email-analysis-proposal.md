# Transcript Vault: automatically retain emailed analysis

Status: inspected design proposal; no pipeline changes or email sends performed.

Cloudcity can analyze archived transcripts and retain the resulting emailed content beneath the corresponding Transcript Vault note. Use the existing Convey processing and Syncthing channels.

## Verified existing mechanisms

- `convey/convey/cli.py`, `_soft_analyze_file` (line 5496), writes model analysis sidecars beside the canonical source.
- Its email path calls `apple/bin/freellmask-mail compose` with `--source`, `--legs-from`, and `--attach`. The email is a separately composed answer, not simply the concatenated sidecars. Retaining sidecars alone does not retain exactly what was emailed.
- `convey/convey/transcript_intake.py` already collects machine-analysis sidecars into the archive.
- `convey/convey/transcript_vault.py` projects canonical transcripts into Obsidian and records source-to-note mappings in `.obsidian/convey-note-names.json`.
- The vault refresh retires generated Markdown absent from its generated set. New generated analysis pages must be included in that set.

## Proposed visible layout

```text
Transcript Vault/Transcripts/Person Name/
  Transcript title.md
  Transcript title/
    analysis/
      <run-id>-email.md
      <run-id>-fm-mlx.md
      <run-id>-freellmapi.md
```

The transcript note links to its analyses; each analysis links back to the transcript. A Markdown note and an adjacent folder with the same stem support the requested nested browsing without moving existing transcript notes.

## Proposed integration

Capture the final composed email body at the mailer's composition/send boundary, associated with the canonical source path. Persist it durably before attempting delivery; record confirmed send success or failure separately, including the provider message ID when available. A failed send must not be presented as a delivered email.

Store canonical results beside the source or in an associated analysis directory; project them into the generated vault using its existing source-to-note mapping. Use stable run IDs for retry deduplication and retain separate runs rather than overwriting history. Include the source content hash, actual model, analysis scope/truncation, and source link so an analysis remains attributable if the transcript changes.

Update the vault generator to discover, link, and preserve these pages. Trigger projection after persisted results arrive through Syncthing, allowing later refreshes to catch delayed files. Keep machine analysis distinct from verified deep analysis and preserve the current backlog semantics.

The exact emailed body is the primary attachment requested here. Model sidecars are useful additional children. This is a proposal grounded in local source inspection, not a claim that automatic email-to-vault attachment currently works.
