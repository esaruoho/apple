---
title: Sal's Siri-on-Mac — Build Guide (Phase 6)
date: 2026-05-07
status: GENERATED — installable artifacts shipped, manual Shortcut-build remaining
prerequisites:
  - Apple Silicon Mac (Apple Intelligence + Vocal Shortcuts both require it)
  - macOS 15.1 or later (Apple Intelligence)
  - Sal's 18 .scptd libraries installed at ~/Library/Script Libraries/
---

# What Phase 6 builds

A 2026 functional equivalent of the killed Siri-on-Mac prototype Sal references in his ProGuide 2023 interview. The architecture is documented in `analysis/sal/sal-siri-on-mac-theory.md`. This guide is the build-and-deploy runbook.

```
"Hey Sal" (Vocal Shortcut)
   ↓
"Sal's Siri" Shortcut
   ↓
   1. Get text from input
   2. Use Model (Apple Intelligence Foundation Model, on-device)
        system prompt = ~/Library/Application Support/Sal-Siri/system-prompt.txt
        input         = user utterance
        output_format = json
   3. Run AppleScript ~/Library/Application Support/Sal-Siri/dispatch.applescript
        with the JSON result
        ↓
        looks up slug → applescript body in intents.json
        ↓
        run script <body>
        ↓
        tell script "DC-XXX" to handler() against installed library
        ↓
        target app does the thing
```

# Generated artifacts

`bin/sal-siri-on-mac-rebuild.py` produces:

| Artifact | Location | Purpose |
|---|---|---|
| Intent catalog | `scripts/sal/dictation-commands/sal-siri-intents.json` | 588 intents with slug, title, primary phrase, all phrases, scope, AppleScript body |
| System prompt | `scripts/sal/dictation-commands/sal-siri-system-prompt.txt` | LLM routing instructions + condensed catalog (60 KB) |
| Dispatcher | `scripts/sal/dictation-commands/sal-siri-dispatch.applescript` | AppleScript invoked by the Shortcut after Foundation Models routes |
| Shortcut spec | `scripts/sal/dictation-commands/sal-siri-shortcut-spec.yaml` | Spec for the master "Sal's Siri" Shortcut |
| Installer | `bin/sal-siri-install.sh` | Copies catalog + prompt + dispatcher to `~/Library/Application Support/Sal-Siri/` |

# Install

```bash
# 1. Make sure Sal's libraries are installed
bash bin/dictation-commands-install.sh

# 2. Install the Sal's Siri runtime files
bash bin/sal-siri-install.sh
```

After this, `~/Library/Application Support/Sal-Siri/` contains:
- `intents.json` — 588 intents
- `system-prompt.txt` — Foundation Models routing prompt
- `dispatch.applescript` — runtime dispatcher

# Build the Shortcut (manual — Shortcuts UI not scriptable for new actions)

The "Sal's Siri" Shortcut must be built once in Shortcuts.app. The spec at `scripts/sal/dictation-commands/sal-siri-shortcut-spec.yaml` describes the three actions:

1. **Open Shortcuts.app → File → New Shortcut**
2. Name it: **Sal's Siri**
3. Add three actions in order:

   **Action 1: Get Text from Input**
   - Action: "Text" → "Get Text from Input"
   - Input source: Shortcut Input
   - If the Shortcut is run with no input (typed start), prompt: "What would you like Sal to do?"

   **Action 2: Use Model (Apple Intelligence Foundation Model)**
   - Action: search for "Use Model" in the Apple Intelligence section
   - Model: "Apple Intelligence (on-device)" — also called "Apple's On-Device Model" depending on macOS minor version
   - System Instructions: paste the entire content of `~/Library/Application Support/Sal-Siri/system-prompt.txt`
   - Input: the output of Action 1
   - Response Format: JSON

   **Action 3: Run AppleScript**
   - Action: "Scripting" → "Run AppleScript"
   - Replace the default script body with the contents of `~/Library/Application Support/Sal-Siri/dispatch.applescript`
   - Input: pass the JSON output of Action 2 as the first argument

4. Set the Shortcut's **Use with Siri** phrase to: **Sal's Siri** (and optionally **Hey Sal**)
5. Save (⌘S)

# Bind to Vocal Shortcut

1. **System Settings → Accessibility → Speech → Vocal Shortcuts → Set Up**
2. Click **+**
3. Phrase: **Hey Sal**
4. Train it (say "Hey Sal" three times)
5. Action: **Run Shortcut → Sal's Siri**
6. Save

# Test

Say (or type into the Shortcut directly):

| You say | Foundation Models returns | Dispatcher runs |
|---|---|---|
| "Hey Sal, take my picture" | `{"slug":"take-my-picture","params":{},"confidence":0.95}` | `tell script "DC-Workspace" to takeMyPicture()` (or similar — slug-dependent) |
| "Hey Sal, give me a wide gradient presentation" | `{"slug":"<keynote-make-wide-with-template>","params":{"theme":"gradient"},"confidence":0.88}` | The matching DC-Keynote handler with `gradient` as theme |
| "Hey Sal, scale this down 25%" | `{"slug":"<scale-down-percent>","params":{"percent":25},"confidence":0.92}` | `DC-Keynote-Objects` scale handler with 25 |

# Known limitations & open work

## 1. System prompt size (60 KB) may exceed Foundation Models context

The on-device Foundation Model (Apple Intelligence small) has a context window of ~4K tokens depending on the variant. 60 KB ≈ 15K tokens. **The current prompt may need to be split.**

Two mitigation paths:

**A. Two-stage routing.** First call: pick the SCOPE (Keynote / Photos / Numbers / Pages / Calendar / Mail / Maps / Finder / QuickTime / Global). Second call: within-scope match. Each call sends ~1/10th the catalog. Implement by extending the dispatcher to do two model calls.

**B. Catalog compression.** Drop the `(scope=...)` annotation, abbreviate slugs, ship only the primary phrase. Cuts ~30% of tokens.

Path A is more accurate; Path B is simpler. Both are future work.

## 2. Parameter extraction (slot-filling) is currently passive

The dispatcher v1 ignores `params` from the model output and runs the deterministic AppleScript verbatim. v2 should template-substitute named parameters into the AppleScript body. Many of Sal's commands (`go to slide $slideNumber`, `scale down $percent percent`, `make a new presentation using the $theme theme`) have explicit parameters in `commandslist.html` that need wiring.

## 3. The "Use Model" action identifier may differ across macOS minor versions

As of macOS 15.1 the action identifier is reportedly `is.workflow.actions.useaimodel` but Apple has churned this between betas. The Shortcut build is currently manual; once the identifier stabilizes, `bin/shortcut-gen.py` can be extended to emit a signed `.shortcut` file directly.

## 4. Stateful conversation — IMPLEMENTED in v2 (2026-05-07)

Sal's pass-2 quote suggests the killed prototype handled "now scale them down" referencing previous selections. **The v2 dispatcher (regenerated 2026-05-07) implements stateful conversation:**

After every successful turn the dispatcher writes:

```
~/Library/Application Support/Sal-Siri/last-state.json
{
  "slug": "<the slug just executed>",
  "params": {<the params just used>},
  "frontmost_app": "Keynote" | "Photos" | "Numbers" | ...,
  "selection_count": "5" | "null",
  "timestamp": <epoch>
}
```

It also appends to a rolling history at `~/Library/Application Support/Sal-Siri/turn-log.jsonl` for cross-session auditing.

The Shortcut spec adds two new actions before `Use Model`:

1. **Get Contents of File** — reads `last-state.json` (continues with empty state on first run)
2. **Text** — composes:
   ```
   PREVIOUS TURN: {{read_state}}
   USER UTTERANCE: {{get_text}}
   ```

This combined string is what gets sent to Foundation Models. The system prompt has a new section ("STATEFUL DEIXIS RESOLUTION") instructing the model to:

- "now scale them down" → `them` = previous turn's selection
- "do that again" → repeat previous turn's slug
- "make it 25 percent" → previous turn's slug + new percent param
- "back to the photos" → previous turn's frontmost_app context
- "the same theme" → re-use previous turn's params.theme value

If the user uses a deictic reference but no previous turn is on disk, the model returns slug `""` with reason `deictic-no-state` — and the dispatcher speaks "I did not understand. deictic-no-state".

The dispatcher also now does **template-substitution** of params named `$foo` or `{foo}` into the AppleScript body before running it, so commands like `go to slide $slideNumber` and `scale down $percent percent` actually receive the slot-filled values.

**v3 capability matrix (this update):**

| Capability | v1 | v2 | v3 |
|---|---|---|---|
| Deterministic phrase matching | ✅ | ✅ | ✅ |
| Cross-app composition | ✅ | ✅ | ✅ |
| Slot-filling — model extraction | ✅ | ✅ | ✅ |
| Slot-filling — applescript substitution | ❌ | ✅ | ✅ |
| Stateful conversation — last-turn deixis | ❌ | ✅ | ✅ |
| Stateful conversation — multi-turn history | ❌ | ⚠ logged | ✅ read into prompt |
| Cross-session memory | ❌ | ⚠ logged | ✅ filtered by staleness window |

## v3 — multi-turn history is now read into the prompt

The Shortcut's previous "Get Contents of File" action (which only read `last-state.json`) is replaced with a **Run Shell Script** action that calls:

```
python3 ~/Library/Application Support/Sal-Siri/read-recent-turns.py 5 30
```

Arguments: `<num-turns> <stale-minutes>`. Default 5 turns, 30-minute staleness window.

The reader emits a single text block:

```
PREVIOUS TURN: {"slug": "scale-down-percent", "params": {"percent": 10}, "frontmost_app": "Keynote", "selection_count": "5"}
RECENT TURNS:
  -1: scale-down-percent params={"percent":10} @ Keynote:5 (ok) 2s ago
  -2: apply-magic-move params={} @ Keynote:5 (ok) 4s ago
  -3: make-wide-presentation params={"theme":"gradient"} @ Keynote:5 (ok) 8s ago
```

Both blocks are then spliced into the model input alongside the user utterance. The system prompt has a new **MULTI-TURN HISTORY (v3)** section instructing the model to use `RECENT TURNS` for queries that span more than one previous turn:

| User says | Model resolves via |
|---|---|
| "go back two steps" | re-runs turn -2's slug + params |
| "do those last three again" | runs turns -3, -2, -1 in sequence |
| "the photo I edited a minute ago" | scans RECENT TURNS for the most recent Photos-scope edit |
| "undo that" | turn -1's known undo slug, or `slug=""` reason `no-undo` |
| "what did I just do" | special slug `describe-recent` (handled by dispatcher — v4 work) |

Multi-turn references take precedence over single-previous-turn deixis when both could apply.

**Staleness filter:** turns older than 30 minutes are excluded by default. Voice users typically resume context within minutes, not hours — including a 4-hour-old turn would more often confuse than help. The filter is parameterized in the Shell Script call so future tuning is one edit.

**Cross-session memory:** because `turn-log.jsonl` is append-only and survives reboots, the next-day "what did I do yesterday" query is technically possible — the staleness filter just needs to be widened (or removed) for that intent. Currently outside the default behavior on grounds of prompt economy.

## What's left (v4 sketch)

- **`describe-recent` special slug** — the dispatcher would route this to a TTS narration of the last 3 turns instead of running an AppleScript. Useful for "what did I just do".
- **Cross-session "today" / "yesterday" queries** — widen the staleness window dynamically based on detected time references in the utterance.
- **Two-stage routing** for the prompt-size limit — first call picks scope, second call picks within-scope slug. Would also tighten `RECENT TURNS` filtering to "same-scope only" for sharper deixis.
- **Confidence threshold** — if Foundation Models returns confidence < 0.5, the dispatcher should ask "did you mean X?" via TTS rather than blindly running.

These are nice-to-haves. The v3 build closes the four-capability gap from Sal's killed prototype.

# What this preserves of Sal's prototype

Concretely, Phase 6 reproduces three of the four capability differences theorized in `sal-siri-on-mac-theory.md`:

| Capability | CitrusPeel had it? | Phase 6 has it? |
|---|---|---|
| Deterministic phrase matching | ✅ | ✅ (via slug lookup) |
| Slot-filling natural language | ❌ | ⚠ partial (model extracts params; dispatcher doesn't yet substitute) |
| Stateful conversation | ❌ | ❌ (future v2) |
| Cross-app composition from free-form intent | ❌ | ✅ (any catalog entry can chain apps; Foundation Models picks the chained one) |

The fourth — stateful conversation — is the one that would have most distinguished Sal's killed prototype from a deterministic phrase matcher. Adding it requires the state-file pattern above and is the obvious next sub-phase.

# Why this matters

This is the most direct publicly-buildable reconstruction of what Apple killed in 2016. The 18 `.scptd` libraries Sal wrote are unchanged. The trigger surface routes through Apple's own 2024+ on-device LLM. The phrase-to-action wiring is generated from Sal's own command catalog. **Apple's eight-year detour to ship Apple Intelligence has, paradoxically, made Sal's Siri-on-Mac prototype buildable in a way it wasn't even at Apple in 2016**, because Foundation Models obviates the bespoke NLU layer Sal had to hand-write.

WWSD #16 in action: **primitives compose; rewrites don't.** Sal's primitives (the 18 libraries) compose with Apple Intelligence. Apple's rewrite war (iOS Siri vs Mac voice) didn't kill the primitives.
