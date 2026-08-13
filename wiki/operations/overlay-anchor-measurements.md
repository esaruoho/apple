---
description: Measured answers to the SDD's anchoring questions — window fingerprint stability, minimise behaviour, and AX selector uniqueness across three apps. Numbers, not claims.
---

# Anchoring — measured, 2026-08-13

The SDD asked for numbers and was right to: *"do not claim semantic persistence without
numbers."* Tool: `bin/overlay-anchor-probe`. Machine: MacBook, macOS 15.6.1, a busy
desktop (179 on-screen windows, 161 addressable, ten-plus Finder windows).

## Q1 — how stable is a window fingerprint during one process lifetime?

**100%.** 23 samples at 4 Hz against `Finder — "puthoff-stockholm-1994"`:

```
1 candidate(s)   23   100.0%  → resolved
distinct frames   1
```

An app+title fingerprint resolved to exactly one window on every sample. No flapping,
no drift. Tier A (CGWindowList, no permission at all) is sufficient for within-session
window anchoring.

## Q7 — what happens when the target is minimised?

**It leaves `CGWindowList` entirely.** Measured across a minimise: 179 on-screen → 178,
addressable 161 → 160. So the specific selector finds zero candidates, which is the
correct signal.

**This exposed a design flaw of mine.** The anchor carries a broad app-only selector for
reacquisition, and with a naive fallback that selector matched *all ten* Finder windows
— reporting "ambiguous among 10" when the truthful answer is "the window you meant is
gone". Both are non-actionable, but only one is useful to read. Fixed: a broader
selector is a reacquisition aid, accepted only when it names exactly one window.

That fix then exposed a second one: the broad selector happily adopted a *sibling*
window of the same app. Silent sibling-rebinding is exactly what the acceptance criteria
forbid. Resolved by using the window number as **corroboration, never identity** —

- same number, different title → the same window, retitled (a browser navigated) → adopt
- different number, different title → a different window → refuse
- same title after a restart → adopt, even with a new number

## Q3/Q4 — which AX attributes are stable enough, and how different are the trees?

`role + name` uniqueness among *addressable* controls (buttons, checkboxes, menu items,
links, text fields, pop-ups):

| App | elements | named | addressable controls | **uniquely named** |
|---|---|---|---|---|
| Calendar | 606 | 83% | 383 | **95%** |
| Finder | 4000 (cap) | 40% | 323 | **89%** |
| Safari | 3631 | 67% | 2298 | **67%** |

**I was wrong, and I want that on the record.** Before measuring I predicted AX would be
weak — "most apps fail, Electron unstable, terminals expose nothing". Within-session
uniqueness is *good*: 67–95% of controls a person would actually point at are uniquely
addressable by role+name. Semantic anchoring is more viable than I expected, and the
prediction was recorded precisely so it could be checked.

Caveats, stated rather than buried:

- Finder hit the 4,000-element walk cap, so its numbers are a lower bound.
- Safari's 33% collision rate is mostly repeated link text on one page — a real problem
  for anchoring to page content, not to chrome.
- **Restart reacquisition is NOT yet measured.** That is the remaining unknown and the
  one that decides whether an anchor is durable or merely long-lived.
- Terminals and Electron apps are unmeasured.
- The first Calendar run measured `CalendarWidgetExtension` because the probe matched
  processes by substring, and reported a one-element tree as if it were the app's. A
  measurement artefact that would have quietly become a finding. The probe now prefers
  an exact name match and says when several processes matched.

## What now works, end to end

- Attach a mark to a window (`overlay attach`, or ⌘A in draw mode).
- **Move the window, the mark follows.** Verified live: window +250 in x, mark +250;
  window down 80, mark −80 in AppKit space, with the coordinate flip handled.
- Resize scales the mark proportionally (unit-tested).
- Target lost → the mark stays put, dashed and dimmed, labelled `anchor unavailable`,
  and never silently rebinds.
- Every resolution transition is appended to the Converse livefile as
  `spatial.anchor.resolved` / `.ambiguous` / `.unavailable`.

## Next measurement to run

Restart reacquisition: persist a selector, quit and relaunch the app, resolve again,
across Safari / TextEdit / a terminal / an Electron app. Until that number exists, call
this **session-durable anchoring**, not semantic persistence.
