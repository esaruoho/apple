# Automatic transcript analysis in Transcript Vault

Run `convey video <url>` as usual. The existing Cloudcity video worker transcribes the source and runs its default analysis/email station. That station saves the exact outgoing response beside the flat transcript before attempting delivery. Its separate receipt records the actual model, source hash, recipient, and delivery result. A matching sent receipt avoids generating and sending the same transcript analysis again on a normal retry.

The existing text-only Syncthing return path brings the transcript, analyses, and receipts home. The laptop's existing five-minute collector imports them and refreshes the vault. Analysis may appear on a later refresh than the transcript because files travel independently.

```text
Transcript Vault/Transcripts/Person Name/
  Transcript title.md
  Transcript title/
    analysis/
      email-<run-id>.md
      fm-mlx.md
      freellmapi.md
      convey-synopsis.md
```

Only existing results are shown: unavailable model legs do not produce invented notes. Each transcript links its analysis children; each child links back to its transcript, person, and canonical analysis. The emailed response is stored unchanged inside its vault projection. Its delivery status is separate from the response itself. Source revisions are flagged against the saved source hash.

The collector accepts speaker-attributed machine sidecars and results keyed on the flat transcript. Its receipt preserves local corrections, and the vault generator preserves personal notes. Machine results do not mark the deep-analysis backlog complete. An analysis/send failure is reported as a failure instead of a successful plain done-notice. The mail CLI now propagates its actual exit status to the video worker.

Local verification: 29 checks pass across exact-payload persistence, failed sends, process exit status, late analysis arrivals, retry deduplication, text-only sync upgrade, stable names, graph links, source preservation, and archive/backlog behavior. Cloudcity deployment uses the existing Syncthing command bridge, checks all release hashes and destination preimages, and keeps backups. No new daemon or worker is required.

Runtime status and commit references are recorded in the [report card](../features/transcript-vault-email-analysis.feature) and its [session](../features/transcript-vault-email-analysis.session.md). Historical emails are not reconstructed; existing available analysis sidecars are projected immediately, while exact email responses are retained for new runs.
