# Report Card — `fm-converse`

**Unit:** stateful sender to Apple FoundationModels on the Mac Mini
**Skin:** API / pipeline (claim = input → assembled prompt → reply artifact)
**Status of this card:** retrofit study — `fm-converse` shipped over three commits *without* a card. Grades below describe what exists **today**.
**Source card:** [`features/fm-converse.feature`](fm-converse.feature) · **Session:** _MISSING (gap G2)_

---

## What this card spawns

- **Codespace** — `bin/fm-converse` → `bin/fm-submit` (Syncthing round-trip) → `[Mini]` `fm-worker` → `bin/fm` + `bin/fm.swift` (FoundationModels). State: `~/.cache/fm-converse/<session-key>.json` `{system, turns[]}`.
- **Thinkspace** — held in `features/fm-converse.session.md` — **missing**.
- **Areaspace** — OWNS the stateful replay + prompt assembly + terminal rendering. MUST NOT own the model (`fm.swift`), the transport (`fm-submit`), or the tool preamble. Stateless one-shots belong to `fm-submit`.

## Grade legend

| Tag | Meaning |
|---|---|
| `@built` | code exists and is committed |
| `@verified-live` | exercised end-to-end against the real Mini this session |
| `@self-test` | verified by a standalone deterministic check (no Mini) |
| `@untested` | code path exists but was never exercised |
| `@caveat` | works but has a known sharp edge |

## RESULT (what shipped)

- **Feature delivery:** `408a628` (initial) · `b66f39d` (budget + tools-opt-in fix) · `c122a61` (markdown render) — all direct-push to `esaruoho/apple` main, no PR.
- **This card authored:** _pending commit_
- **Triad status:** `.feature` = partial · `.session` = **missing** · RESULT = present.

---

## Scenarios (the Gherkin report)

### ✅ `@built @verified-live` — A follow-up question keeps the prior context
> **Given** a session whose store already holds "what is a tiger" + its answer
> **When** the user sends "and how big do they get"
> **Then** the replay includes the tiger turns and the reply is about tiger size

- **cite:** `bin/fm-converse` `build_replay` (136) replays turns newest→oldest under budget
- **cite:** `bin/fm-converse` main (252-254) persists `[user, assistant]` to the store
- *verified-live 2026-06-03: reply was "up to ~10 feet, 220–660 pounds"*

### ✅ `@built @verified-live` — Replay stays inside the 4096-token window
> **Given** prior dialogue larger than the model window
> **When** a new turn is assembled
> **Then** the assembled prompt is capped so a trivial question no longer overflows

- **cite:** `REPLAY_BUDGET=6000`, `FILE_CAP=5000`, `MAX_INPUT_CHARS=9000` (74-76)
- **cite:** main (224-226) trims to just-the-question if over ceiling
- **cite:** `bin/fm.swift` `useTools` (22) — tools OFF by default removes the ~4600-token preamble
- *was the 4685 > 4096 bug; root cause was `fm.swift` forcing 16 tools (`b66f39d`)*

### ✅ `@built @self-test` — Markdown renders as ANSI on a terminal, plain when piped
> **Given** the model replies with `**bold**`, `# headings` and `- bullets`
> **When** the reply is printed to a TTY
> **Then** it shows ANSI styling; when piped (Converse capture) it stays plain text

- **cite:** `md_to_ansi` (45) bold/italic/code/headings/bullets/links/fences
- **cite:** `emit_reply` (63) styles only when `sys.stdout.isatty()`
- *self-test 2026-06-03: standalone `md_to_ansi` over a mixed sample rendered correctly*

### ✅ `@built @verified-live` — A worker/guardrail/timeout error is surfaced, not swallowed
> **Given** fm-submit returns non-zero (worker down, guardrail, or overflow)
> **When** fm-converse finishes
> **Then** the user sees `[FM-on-Mini] <reason>` instead of a silent empty reply

- **cite:** main (242-247) prints fm-submit's last stderr line as the reply
- *verified-live: the 4685-token error surfaced verbatim before the fix*

### ⚠️ `@built @untested` — A file path is read and summarised instead of sent literally
> **Given** the message is a path to a txt/md/rtf/pdf/image file
> **When** fm-converse runs
> **Then** the file's extracted text (capped) is sent with a summarise instruction

- **cite:** `maybe_file_to_text` (110) → `bin/file-to-text`, `FILE_CAP` cap (131)
- **cite:** main (209-214) neutral "here is some text…" framing
- **UNTESTED this session** — no file-path round-trip was run

### ⚠️ `@built @untested` — Context-overflow self-heal retries without history
> **Given** fm-submit reports `exceededContextWindowSize` despite the budget caps
> **When** fm-converse detects an overflow marker in stderr
> **Then** it retries once with only the new question (no replayed history)

- **cite:** self-heal (228-235) re-calls fm with `build_replay([], turn)`
- **UNTESTED-IN-ANGER:** the one time it fired, the real cause was `fm.swift` tools, so the retry **also failed**; never re-exercised after the fix. **Suspect-but-unproven.**

### 🔶 `@built @caveat` — Conversation keyed to the newest Converse session dir
> **Given** no explicit `--session` is passed
> **When** fm-converse resolves which conversation to continue
> **Then** it uses the most-recently-modified `~/work/converse/sessions/` dir

- **cite:** `current_session_key` (79) = `max(sessions/*, key=mtime)`
- **CAVEAT:** if another session dir was touched more recently than the one you're actually typing in, the wrong conversation is continued. Mtime ≠ "the window I'm in".

### 🔶 `@built @caveat` — Stored conversation is volatile and reportcard-less
> **Given** any fm-converse exchange completes
> **When** you look for a durable record of it
> **Then** there is only a flat `~/.cache` JSON buffer — not dated, not titled, not in the vault, not synced, no per-conversation transcript, no grade, no event log

- **cite:** `STORE = ~/.cache/fm-converse` (69), `save` (106)
- *this is the "reportcard-less RESULT": the TOOL has no card **and** its OUTPUTS have no durable card either.*

---

## Where `fm-converse` fails the four properties

| Property | Status | Why |
|---|---|---|
| **P1** verifiable claims | ✗ → ✅ | lived only as code + comments until this card |
| **P2** linked to innards | ✗ → ✅ | no citation structure existed before this card |
| **P3** honestly graded | ✗ → ✅ | nothing recorded tested-vs-assumed (self-heal was quietly unproven) |
| **P4** two-way back-link | ✗ | `fm-converse` / `fm-submit` / `fm.swift` carry **no** `# FEATURE-CARD >>` marker |
| **Triad** | partial | `.feature` partial · `.session` **missing** · RESULT present |

**⇒ By the report-card definition, `fm-converse` is an INCOMPLETE unit:** it shipped without its card, and the back-links + session capture are still owed before the retrofit is complete.
