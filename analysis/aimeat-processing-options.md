# AIMEAT and Apple processing: initial inspection

Inspected 2026-10-21. This is a feasibility answer from source inspection, not a deployed or runtime-tested integration.

AIMEAT could act as an intake and coordination surface for the existing Apple processing system. The strongest first connection is AIMEAT request → a local bridge → an ingestion folder → Apple Harness using the private fleet configuration → results returned to AIMEAT.

Reusable pieces:

- `bin/apple-harness`, `harness/lib/harness/loop.py`, and `ledger.py`: scan files, extract text, identify entities, embed, majority-vote topical tags, write Obsidian Asset Notes, and record per-file state. Configuration binds providers. Useful both for feeding AIMEAT material into our processing and feeding processed knowledge back into AIMEAT.
- `bin/process` and `bin/process-router`: existing narrow dispatch for PDF and audio/video; URLs go to whisp-submit. The router does not handle arbitrary text or images, and unsupported extensions return success after skipping. It hardcodes the OCR submit script under `.claude/skills/bbs`; check that dependency before exposing this route.
- `bin/apple-ner`, `bin/apple-embed`, `bin/apple-semantic-match`, and `bin/apple-cluster-docs`: entity extraction and semantic organization. Apple embeddings must be compared within the same model/language space; availability varies by language. Local inference avoids paid cloud LLM calls but still uses computation.
- `bin/fmremote` and `bin/fm-submit`: existing Syncthing request/result bridge to Mini FoundationModels. Suitable for bounded tagging/summarization calls; harness reasoning currently requests topical tags, not arbitrary workflows.
- `bin/describe-submit`: existing Syncthing image-caption request/result path. Source exists; worker availability was not checked. Uses basename-based result matching and an un-bypassed cp, so it needs duplicate/stale-result and overwrite review before unattended integration.
- `bin/converse-to-obsidian`: exports conversation turns as linked Markdown. Candidate source of prior decisions and conversation context; currently untracked local work, not verified as shipped.

What AIMEAT can add: requests, shared records, workflow/schedule coordination, and a place to read returned processing results. Its handbook documents those surfaces. Its MCP integration skill documents attaching reachable HTTP/SSE MCP servers, with per-agent tool restrictions. CLI scripts do not become callable merely by attaching AIMEAT: a bridge/server must implement that boundary, and private/internal addresses are refused by the documented attach path.

Observed AIMEAT state: connector list returned no registered computers. Own-content discovery returned 29 entries (20 capabilities and 9 memories); this is a scoped discovery result, not proof that every other account surface is empty. Listing attached MCP servers was denied; existing attached servers therefore remain unknown. Optional access link: https://aimeat.io/v1/allow?agent=app&need=mcp%3Aread . No account changes were made.

Recommended first slice: one text document submitted from AIMEAT, materialized locally with an origin record, processed using fleet-configured Apple Harness, and returned as text/entities/tags/status plus a durable note reference. Add a request ID mapped to the local asset ID, explicit result acknowledgement, and retry handling. Current scan deduplication is by path, not content hash; source provenance and cross-system deduplication need an adapter.

Keep heavy OCR and transcription on Cloudcity through existing Syncthing/convey paths; never execute the harness's local OCR defaults on Esa's laptop. Any long-lived Mini bridge belongs in systems.yaml and Cloudcity-Boot.app. The adapter should expose bounded operations, not arbitrary shell execution.

No AIMEAT adapter was found in the searched bin/, harness/, wiki/, or features/ source content. Wiki doctrine contains contradictory historical build-status passages; executable source was used to establish the interfaces above. No ingestion jobs, OCR, transcription, inference, deployment, or commits were performed for this inspection.
