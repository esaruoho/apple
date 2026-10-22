# AIMEAT text drop → MLX roundtable → workspace result

Proposed integration, based on source inspection; not deployed or runtime tested.

Desired experience: upload a text file into an AIMEAT Roundtable Inbox. It becomes a request automatically. The existing Mini Qwen/MLX roundtable reads the source through its grounded persona roster (including Bearden and Prigogine), and returns its discussion to the same AIMEAT workspace beside the original. Status advances through queued, running, complete or failed. Start automatically; first-turn and final-result latency depend on Mini availability, queue depth and selected turn count.

Reuse confirmed in `/Users/esaruoho/work/convey/convey/cli.py`:
- `cmd_roundtable`: MLX is the fallback default brain; configurable roster, named seats, bounded turns, and JSONL headless turn output exist.
- `--board`: source-content grounding is exposed by the CLI; use an explicit source attachment, not just a topic derived from its filename.
- `_parse_roundtable_job` / `_run_roundtable_job`: existing `.roundtable` Syncthing jobs produce a transcript and per-turn audio under convey-results. The parser accepts roster/brain/turns/inject but does not carry board paths or named seats. It uses only the first free-text line as a fallback topic, so dropping arbitrary text as this job format would lose source content.
- The existing fleet runner forces audio rendering. For fast text results, either extend that runner with explicit text-only/source/seat fields or use the existing headless roundtable interface behind a bounded worker adapter. Do not invent a second debate engine.

AIMEAT's `node:aimeat-workspace-contracts` documents request/result spaces, published-record wake events, result references, retry-safe output checks, and lifecycle state. A literal file-upload/folder event still needs verification: publishing a workspace request is the documented wake mechanism. The intake must turn the uploaded file into that request automatically to deliver the promised one-drop experience.

Missing connection: AIMEAT reported no connectors during the preceding inspection. A Mini-side bridge must consume AIMEAT requests and return results. It belongs under Cloudcity-Boot and systems.yaml; existing internal transport remains Syncthing. Exact target AIMEAT workspace/folder and installed persona roster still need inspection before configuration or deployment.

Suggested first version: text transcript, named persona turns and source reference returned to the workspace, with a fixed bounded turn count and optional audio later. Streaming each turn can use existing JSONL output but forwarding and persistence in AIMEAT are new adapter work. Mark these as AI-generated persona interpretations grounded in the configured corpora, not quotations or statements by the historical people.

No inference jobs were launched, no AIMEAT writes were made, and no services were changed in this inspection.
