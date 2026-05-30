# AppleToolbox energy hog — mail-flag-worker stuck in a no-progress loop

**Diagnosed 2026-05-30.** AppleToolbox.app itself sits at 0% CPU, but it spawns
`bin/mail-flag-worker --tick` on every Mail FSEvent, and that worker has been
pinning a CPU core ~24/7 while doing **zero useful work**. That is the battery
drain and the heat.

## The evidence

- `mail-flag-worker --tick` caught at **97.8% CPU** (child of AppleToolbox pid).
- `~/work/comms/queue/mail-flag-runner.log`: **3,502 ticks in 28 hours**
  (2026-05-29 04:43 → 2026-05-30 09:05), cadence ~25–30 s.
- **Every single tick** logged `done: ok=0 failed=0 skipped=20 (remaining=947)`.
  3,499 of 3,502 ticks did `ok=0`. Zero messages ever routed. Queue never drained.
- `mail-flag-state.json`: `skipped_temp` = 20 ROWIDs, all `.partial.emlx` in
  Gmail's `[Gmail]/All Mail` virtual mailbox.

## The mechanism (two compounding bugs)

1. **Poison-pill batch window.** `cmd_tick` builds
   `new = [r for r in rows if r["ROWID"] not in processed_set]` then
   `batch = new[:MAX_PER_TICK]` (MAX_PER_TICK = 20). The 20 stuck `.partial.emlx`
   messages are never added to `processed_set` (they return `skipped_temp`), so
   they stay at the **front of `new` forever** and fill the entire batch window
   every tick. The worker never reaches the other 947 flagged messages, and the
   20 partials can never be force-downloaded — they live in a Gmail *virtual*
   mailbox, where force-download is (correctly) refused because it hangs Mail
   (see mail-app-internal-behaviors gotcha). Permanent stalemate.

2. **Trigger fires far too often for a zero-work tick.** The FSEvents watcher on
   `~/Library/Mail/V10/MailData` fires on every `Envelope Index-wal` /
   `Envelope Index-shm` write. Mail rewrites those every few seconds while
   syncing IMAP. Each fire → debounced → a fresh **Python 3.14 interpreter**
   that runs `fetch_flagged()` (full SQLite scan of all 967 flagged rows) +
   reads/parses 20 `.partial.emlx` headers for early dedup → ~98% of a core for
   the tick duration, ~every 25 s, all day. No backoff when ticks do no work.

Same class of bug as the stickies-watcher energy hog: a high-frequency trigger
doing heavyweight per-item work, here made permanent by a non-draining queue.

## Fixes

**Immediate relief (no rebuild):** unblock the batch window so live mail still
routes — exclude `skipped_temp` ROWIDs from the front of `new`:

```python
new = [r for r in rows
       if r["ROWID"] not in processed_set
       and r["ROWID"] not in skipped_set]
```

…and retry `skipped_temp` only on the slow 5-min safety timer, not on every
FSEvent. (The 20 Gmail partials will still never download automatically; either
open them once in Mail.app to drain them, or park them in a permanent-skip set.)

**Durable fix:** back off the tick cadence when consecutive ticks return ok=0
(exponential up to e.g. the 5-min safety interval), and short-circuit a tick if
the flagged-ROWID set is unchanged since the last scan. Move virtual-mailbox
partials into a "do-not-auto-retry" bucket so they don't churn every pass.

See also: `wiki/concepts/mail-flag-pipeline.md`,
`feedback_stickies_watcher_energy_hog.md`.
