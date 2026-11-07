# Report Card — fm-converse — a remembering conversation with the on-device LLM

> Source: `features/fm-converse.feature` · printable rendering · regenerate with `python3 print-card.py`

**Intent:** As someone talking to Apple's FoundationModels model on the Mac Mini, I want each message to carry the prior dialogue and come back rendered, So that Converse's Cmd-1 is a real conversation, not unrelated one-shots.

**Grades:** @built × 11 · @untested × 2

**Scenarios: 11**


---


## 1. A follow-up question keeps the prior context

`@built @verified-live`


- Given a session whose store already holds "what is a tiger" + its answer
- When the user sends "and how big do they get"
- Then the replay includes the tiger turns and the reply is about tiger size

<sub>cite: bin/fm-converse build_replay (136) replays turns newest→oldest under budget · bin/fm-converse main (252-254) persists [user,assistant] to the store</sub>


## 2. Replay stays inside the 4096-token FoundationModels window

`@built @verified-live`


- Given prior dialogue larger than the model window
- When a new turn is assembled
- Then the assembled prompt is capped so a trivial question no longer overflows

<sub>cite: bin/fm-converse REPLAY_BUDGET=6000, FILE_CAP=5000, MAX_INPUT_CHARS=9000 (74-76) · bin/fm-converse main (224-226) trims to just-the-question if over ceiling · bin/fm.swift useTools (22) — tools OFF by default removes the ~4600-token preamble</sub>


## 3. Markdown renders as ANSI on a terminal, plain when piped

`@built @self-test`


- Given the model replies with **bold**, # headings and - bullets
- When the reply is printed to a TTY
- Then it shows ANSI styling; when piped (Converse capture) it stays plain text

<sub>cite: bin/fm-converse md_to_ansi (45) bold/italic/code/headings/bullets/links/fences · bin/fm-converse emit_reply (63) styles only when sys.stdout.isatty()</sub>


## 4. A worker/guardrail/timeout error is surfaced, not swallowed

`@built @verified-live`


- Given fm-submit returns non-zero (worker down, guardrail, or overflow)
- When fm-converse finishes
- Then the user sees "[FM-on-Mini] <reason>" instead of a silent empty reply

<sub>cite: bin/fm-converse main (242-247) prints fm-submit's last stderr line as the reply</sub>


## 5. A file path is read and summarised instead of sent literally

`@built @untested`


- Given the message is a path to a txt/md/rtf/pdf/image file
- When fm-converse runs
- Then the file's extracted text (capped) is sent with a summarise instruction

<sub>cite: bin/fm-converse maybe_file_to_text (110) → bin/file-to-text, FILE_CAP cap (131) · bin/fm-converse main (209-214) neutral "here is some text…" framing</sub>


## 6. Context-overflow self-heal retries without history

`@built @untested`


- Given fm-submit reports exceededContextWindowSize despite the budget caps
- When fm-converse detects an overflow marker in stderr
- Then it retries once with only the new question (no replayed history)

<sub>cite: bin/fm-converse self-heal (228-235) re-calls fm with build_replay([], turn)</sub>


## 7. The conversation is keyed to the newest Converse session dir

`@built @caveat`


- Given no explicit --session is passed
- When fm-converse resolves which conversation to continue
- Then it uses the most-recently-modified ~/work/converse/sessions/ dir

<sub>cite: bin/fm-converse current_session_key (79) = max(sessions/*, key=mtime)</sub>


## 8. Stored conversation remains replay memory while the livefile is the durable artifact

`@built @caveat`


- Given any fm-converse exchange completes
- When you look for a durable record of it
- Then ~/.cache/fm-converse still holds replay memory and livefile.jsonl holds the capturable record

<sub>cite: bin/fm-converse STORE = ~/.cache/fm-converse, save() · bin/fm-converse _append_capture_turn writes livefile.jsonl</sub>


## 9. A terminal fm-converse turn becomes a Converse-shaped livefile

`@built @self-test`


- Given fm-converse gets a successful answer outside Converse.app
- When the turn is persisted
- Then it writes session.created, talk.heard and agent.responded events with one request_id

<sub>cite: bin/fm-converse _append_capture_turn creates manifest.json + livefile.jsonl · test_fm_converse.py test_successful_turn_writes_livefile_pair</sub>


## 10. Converse.app-owned turns are not duplicated by fm-converse

`@built @self-test`


- Given Converse.app already wrote the user turn to livefile.jsonl
- When its fm-converse child returns the answer
- Then fm-converse does not write another copy of that same turn

<sub>cite: bin/fm-converse _recent_app_already_owns_turn checks recent talk.heard · test_fm_converse.py test_existing_converse_app_turn_is_not_duplicated</sub>


## 11. Captured fm-converse turns are pushed to Scaff

`@built @self-test`


- Given a successful fm-converse turn was appended to a livefile
- When ~/work/scaff has semantic-convey-file available
- Then Scaff receives linked session and turn Markdown under ConverseInbox

<sub>cite: bin/fm-converse _push_capture_to_scaff shells into semantic-convey-file converse-push</sub>

