# #process stall diagnosis — 2026-11-18 22:45 EET

Runs (comms/queue/notes-process-runs, local time):
- 17:15 — FAILED: notes-voices timed out after 900s
- 18:00 — stuck in "generating", never finished
- 19:43 "what is coral castle?" — FAILED: voices brain gave ungrounded sections (Keely/Dollard/Leedskalnin)
- 20:09 "coral castle and what does it do?" — DEFERRED: brain timed out after 1800s
- 21:39 retry of same — DELIVERED 22:06 (as linked note p12715); 15 voices on nemotron-3-ultra + openrouter/free
- 22:38 "electrolysis … high-voltage?" — currently "generating"

Verdict: the Mini watcher is alive and picking up #process notes. The bottleneck is the 15-voice
fan-out over free LLM endpoints (nemotron / openrouter free): slow, rate-limited, and sometimes
ungrounded, so runs time out (900s/1800s), defer, or fail. Successful replies land as a LINKED note,
not in the original.

Fix options: cut the voice count per run (e.g. 3–5), parallelise voices with a per-voice timeout and
deliver the ones that came back, and treat an ungrounded section as "drop that voice" not fail-the-run.
