---
title: Vocal Shortcuts session — six findings, 2026-05-11
date: 2026-05-11
status: codified — six observations from the coverage-tool build session
sources:
  - bin/vocal-shortcuts-suggest.py
  - bin/lib/apple_sqlite_snapshot.py
related:
  - analysis/sal/vocal-shortcuts-in-the-trigger-stack.md
  - analysis/sal/vocal-shortcuts-storage-format.md
  - analysis/sal/vocal-shortcuts-coverage.md
---

# Why this doc

During the build of `bin/vocal-shortcuts-suggest.py` on 2026-05-11, six
observations surfaced that were not captured in any existing analysis or
runbook. Codifying them here so they don't have to be rediscovered.

## 1. WAL/SHM snapshot pattern is reusable across every Apple SQLite store

Apple's first-party SQLite stores (Shortcuts, Photos, Notes, Mail, Safari,
Messages, Voice Memos, Calendar) all use WAL journaling, and the owning apps
typically stay running. A naive `sqlite3.connect(file:…?mode=ro)` either
contends with the writer or, with `?immutable=1`, ignores the `-wal` file
entirely and serves a stale snapshot.

The fix: snapshot the `.sqlite` + its `-wal` + `-shm` siblings to a temp dir
and open the copy read-only. That sees the live WAL state and never contends.

The pattern is now factored into `bin/lib/apple_sqlite_snapshot.py` and used
by `vocal-shortcuts-suggest.py` plus the seven first-party exporters. Per-store
defaults:

| Exporter        | Mode              | Reason                                           |
|---|---|---|
| Shortcuts (suggest) | snapshot       | Shortcuts.app always running, small file (2 MB)  |
| Notes              | snapshot        | Notes.app stays open, 85 MB                      |
| Safari             | snapshot        | Safari always running                            |
| Messages           | snapshot        | Messages.app writes constantly                   |
| Calendar           | snapshot        | Calendar agent writes deltas continuously        |
| Voice Memos        | immutable       | User typically closed the app; small file        |
| Mail               | immutable       | Envelope Index is ~1 GB — too costly to snapshot |
| Photos             | immutable       | Photos.sqlite is ~3 GB — too costly to snapshot  |

**Verification:** before the refactor, `vocal-shortcuts-suggest.py` reported
`2/277` live Shortcuts. After: `2/278`. The extra row was sitting in the WAL,
unreached by the previous `?immutable=1` path. Real value, observed.

## 2. The router-pattern math is 588× — and it's not optional

The skill.md docs treat the Hey Sal single-phrase router pattern as a polish
choice. The arithmetic says otherwise:

- **Direct binding** of Sal's 588 CitrusPeel phrasings: 588 phrases × 3
  training reps each = **1,764 manual training utterances**.
- **Router binding**: 1 phrase ("Hey Sal") × 3 reps = **3 utterances total**.
- Reduction: **588×** — three orders of magnitude.

There is no public API to install trained-audio models programmatically. UI
scripting can drive the Add flow in System Settings → Accessibility → Speech
→ Vocal Shortcuts, but each phrase still has to be physically spoken three
times. At 588 phrases, that's hours of throat work even with perfect UI
automation. The router collapses it to seconds.

This is now stated in `skill.md` as the quantitative justification for the
router pattern.

## 3. 0 orphans + 0 drift on first run is a real datapoint

The first coverage report showed `0 orphans, 0 drift` against the two live
entries (`Hey Sal`, `wheres olga`). This means UUID-stability isn't
theoretical — both bindings have survived whatever Shortcut edits have
happened in Shortcuts.app since `2026-05-07`.

The drift-detection branch of `vocal-shortcuts-suggest.py` is currently a
defensive net for a problem that hasn't materialized. It will still fire if
the user ever renames a bound Shortcut, but until then it's a "good news"
signal: the underlying schema design is robust.

## 4. The fuzzy-match heuristic has a 4-character floor

`vocal-shortcuts-suggest.py --audit-only` matches audit candidate filenames
against live Shortcut names by normalizing both (lowercase, strip
non-alphanumerics) and checking substring containment. The function
`audit_matches_shortcut()` requires the shorter normalized name to be **at
least 4 characters** before declaring a match.

Why: without the floor, short Shortcut names ("DND", "Wi-Fi" → "wifi") would
match against every audit candidate that happened to contain those letters
(e.g., "dnd" appears inside "dndaytimer" hypothetically). The floor cuts that
noise.

**Side effect:** any Shortcut with a normalized name shorter than 4 chars is
invisible to `--audit-only`. They still appear in the default (`all`) output.
If a short-named Shortcut should match a specific audit candidate, either
rename the Shortcut or lower the floor (`audit_matches_shortcut`,
`bin/vocal-shortcuts-suggest.py`).

## 5. Audit candidate filenames frequently match user Shortcut names verbatim

The `--audit-only` run produces a lot of exact-name matches, e.g.:

```
finder-compress-selected  ↔  finder-compress-selected
calendar-next-event       ↔  calendar-next-event
system-events-uptime      ↔  system-events-uptime
```

This is because `bin/build-sal-demo-shortcuts.py` names user Shortcuts after
the source `.applescript` filenames. The fuzzy matcher catches both the exact
cases and the divergent ones (`Bluetooth` ↔ `ax-system-settings-bluetooth`,
`Wi-Fi` ↔ `system-events-wifi-toggle`). The naming convention is doing
unintentional work here — keeps the audit↔binding cross-reference reliable
without any special manifest file.

If you ever rename built Shortcuts away from their filename convention,
suggest-tool match rate will drop. Worth a sanity check before bulk renames.

## 6. The 3-rep training requirement is the project ceiling

Every other piece of the Vocal Shortcuts stack has a software answer:

- **Read** — solved (`list-vocal-shortcuts.py`, plist + JSON)
- **Coverage detection** — solved (`vocal-shortcuts-suggest.py`)
- **Schema understanding** — mostly solved (siriShortcut verified; siriRequest +
  accessibility still inferred)
- **Plist write** — solved in principle (`defaults write` + `cfprefsd`),
  daemon-reload behavior unverified
- **Per-phrase training** — **no software answer.** The user has to speak
  each phrase three times in System Settings UI. Apple does not expose the
  trained-audio install API.

Two escape hatches exist:

1. **Router pattern** (current, deployed) — collapse N triggers into 1
   trained phrase. Works today. Sub-second latency added by the matcher.
2. **UI scripting** (`bin/vocal-shortcuts-ui-import.applescript`, skeleton)
   — drive System Settings via System Events. Still requires the human to
   speak; just automates the form-filling around it. Slow, fragile, bulk-capable
   in principle.

The ceiling is the project's only hard wall. Every architecture decision
around Vocal Shortcuts should be evaluated against "does this reduce the
training-utterance count?" The router does (588 → 3). Direct binding doesn't
(587 + N new shortcuts → 1,764 + 3N).

# Where each finding lives now

| Finding | Codified in |
|---|---|
| 1. WAL snapshot pattern | `bin/lib/apple_sqlite_snapshot.py` + 7 exporters refactored |
| 2. 588× router math | `skill.md` Vocal Shortcuts section + this doc |
| 3. 0 orphans = stability verified | this doc + coverage report |
| 4. 4-char fuzzy-match floor | `bin/vocal-shortcuts-suggest.py` docstring + this doc |
| 5. Filename↔Shortcut-name convention | this doc |
| 6. Training is the ceiling | `skill.md` Vocal Shortcuts section + this doc |
