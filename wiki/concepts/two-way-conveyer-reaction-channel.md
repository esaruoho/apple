# Two-Way Conveyer — the Reaction Channel (RBI)

> Design doc, 2026-06-04. Extends [Stickies → Claude Trigger](stickies-claude-trigger.md)
> from a one-way launcher into a **two-way conveyer belt**: for each action (a
> tagged request) there is an equal and opposite, **configured, automatic
> reaction** that comes back to a surface the user watches. This is Rhythmic
> Balanced Interchange applied to automation — a two-way universe, not a fire-and-
> forget trigger.

## The principle

The existing trigger is half a heartbeat: surface → watcher → `claude`. It inhales
(reads the request) but never exhales (the result never returns to a surface). RBI:
*for each action there is an equal and opposite reaction.* A balanced conveyer
closes the loop — the reaction lands automatically, configured per tag, so the user
writes a thought and later **sees the answer arrive** without going to fetch it.

## The five things (what "the conveyer belt" is)

1. **Action intake** — *exists.* Tagged surfaces → `stickies-claude-watcher` →
   `dispatch()`. Today the surface is Stickies; the chassis is surface-agnostic.
   Other surfaces (a todo-list, the Convey work-surface, a mail flag) feed the
   SAME dispatcher.

2. **Routing** — *exists, extend.* `etc/stickies-claude-tagmap.txt` maps
   `tag → cwd[|skill]`. EXTEND the line to `tag → cwd[|skill][|reaction-target]`
   so each project can declare WHERE its reactions land (back-compatible: no third
   field = default reactions queue).

3. **Reaction contract** — *NEW.* The dispatched prompt carries a configured
   "when done, report back to <reaction-target>" instruction. The action thus
   *contains its own reaction* (RBI-pure). Claude, finishing the task, writes a
   short outcome to the reaction surface as the last step — the same Claude that
   did the work, no fragile screen-scraping of an interactive REPL.

4. **Reaction surface** — *NEW.* Where results land automatically and visibly:
   - a reactions queue: `~/work/comms/queue/reactions/<uuid>.md` (mirrors the
     existing `stickies-claude.log` pattern; Syncthing-visible on the Mini);
   - and/or a result sticky / a "✅ done" line appended to the originating sticky;
   - and/or — for Convey work — the originating card's `@grade` flip + STATUS regen.
   AppleToolbox can surface "N reactions waiting" the same way it shows Whisp queue.

5. **Convey coupling** — *NEW, the keystone.* Convey **generates** the work-surface
   from card grades (`@runtime-untested` / `@todo` / `@blocked`, uncarded features in
   `INDEX.md`, `HW-FAILURES.md`). Those become ACTIONS (stickies / todo items).
   Completion writes the REACTION back to the card (grade change) and the generated
   `STATUS.md` regenerates. The full loop:

   ```
   cards ──gen──▶ work-surface ──action──▶ Claude ──reaction──▶ cards
     ▲                                                            │
     └────────────────── STATUS.md regenerates ◀──────────────────┘
   ```

   "Code conveys its own verified status" (Convey) + "every action has its
   reaction" (RBI) = the same loop seen from two sides.

## Surfaces are interchangeable (Stickies today, MCP todo tomorrow)

The action surface is pluggable. Stickies is the proven one (⌘N from anywhere). A
**local MCP todo-list** is the same chassis with a different intake: the watcher
becomes "poll the MCP `list_todos` tool," dispatch is unchanged, and the reaction
is "call the MCP `complete_todo` tool" instead of appending to a sticky. So the
earlier "can you MCP to a todo-list for Convey?" question and this one are the same
system: **the todo-list is just one more two-way surface on the conveyer.**

## Grades (honest, per the report-card doctrine)

- **Action intake + routing**: `@shipped` — `bin/stickies-claude-watcher`,
  `etc/stickies-claude-tagmap.txt`, AppleToolbox timer. Verified in use.
- **Reaction contract / reaction surface / Convey coupling**: `@designed` — this
  doc. No code yet. Do NOT describe these as working until the channel is built and
  a round-trip is observed.

## Smallest first increment (proposed)

The reaction queue + reaction contract, surface-agnostic:

1. `etc/stickies-claude-tagmap.txt`: optional 3rd `|`-field = reaction target
   (default `queue`).
2. `dispatch()`: append a fixed reaction-contract footer to `full_prompt` —
   "When finished, write a 5-line outcome to
   `~/work/comms/queue/reactions/<uuid>.md` (what you did, what shipped, what's
   left)." `<uuid>` ties the reaction to the originating action.
3. A tiny `bin/reactions-tail` (and an AppleToolbox row) so new reactions are
   visible without hunting.

That alone closes the loop for every existing tag. Convey coupling (grade flips,
STATUS regen) layers on top once the queue round-trips.

## The one real decision

How the reaction is captured:
- **(A) Prompt-convention** *(recommended)* — the dispatched Claude writes its own
  outcome back as its last step. Simple, works with the interactive session that
  already runs, RBI-pure (action carries reaction). Trust-based: relies on the
  prompt footer being honored.
- **(B) Harness-capture** — run `claude -p` headless and capture stdout to the
  reaction file. Fully automatic, but loses the interactive window Esa watches and
  changes the whole dispatch shape.

Recommendation: (A). It's additive, keeps the proven interactive launch, and
matches the existing "the prompt is the contract" design.
