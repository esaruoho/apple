# Missing voices: correction session

## How to get back

Transcript: file:///Users/esaruoho/.codex/sessions/2026/10/10/rollout-2026-10-10T22-44-47-01a12758-b74f-7690-852a-5dd49d02433d.jsonl
Session ID: 01a12758-b74f-7690-852a-5dd49d02433d
Resume: `codex --resume 01a12758-b74f-7690-852a-5dd49d02433d`
Verified source metadata: 2026-10-10T19:45:05.434Z; session start 2026-10-10T19:44:47.992Z.

## User correction and cause

Esa said the cloudcity-llm emailer was not doing the proper edit: Prigogine, Russell, Bearden, Hilarion and the skeptic were missing. The earlier proof delivered an analysis but bypassed the actual document editorial contract. That was an agent implementation mistake, not a model refusal: the recovery called fm_research without viewpoint or material mode. Its generic quality check therefore never required the expected sections. The normal inbound document path also failed to set material mode, though it did route the Free Energy viewpoint.

The correction introduces one shared research_email_material entry point for inbound documents, compose, and recovery. It selects the viewpoint from an explicit routed space, always enables document mode, and checks all required material/voice headings before permitting a sendable answer. Existing fm_research validates section substance and verification table. Recovery explicitly selects the Free Energy space, retrieves wiki context, enables the requested voices, and includes the complete six-page extracted text. A prior incomplete email cannot suppress this requested correction; a prior complete correction suppresses duplicate sends.

Eleven tests pass across document editor, attachment fallback, and existing email artifacts. Live corrected delivery remains pending until the actual reply and inbox receipt are observed. Cloudcity's existing uncommitted files remain untouched; the correction runs from a temporary committed snapshot rather than replacing its live worker.
