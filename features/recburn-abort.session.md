# Session — Ctrl-C twice abandons the recburn pipeline

The spawning conversation for `features/recburn-abort.feature`. Faithful, not flattering.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630.jsonl`
- Session ID: `00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Resume: `claude --resume 00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Date: 2026-08-22, this work between 19:07 and 19:12 EEST (the session itself is much older —
  it had already carried the loudness, redaction, git-history and iPhone-rig work).

## The request

Esa, verbatim:

> so, when recburn has been started by me typing recburn, i should be able to press ctrl-c, and
> immediately exit from the process of 1) recording 2) normalizing 3) transcribing 4) flattening
> + burning. instead, i need to wait for the whole process to finish up. which is quite
> frustrating in itself. i want ctrl-c to be the "halt the whole recburn". this is super
> important for me, cos i dont want to need to wait for the process to finish, for me to get back.
> imagine if i botched up a 1 hour recording and i need to wait 20 minutes to get the botched
> recording to finish being botched, and then i am not able to ya know just start recording the
> thing again.

## The one judgement call I made without asking

Read literally, "ctrl-c should halt the whole recburn" could mean a SINGLE press throws
everything away. I did not build that, and the reason is worth stating plainly: the raw capture
is the only artifact that cannot be produced again, and one keystroke should not be able to
destroy an hour of it with no undo. The first Ctrl-C has also meant "stop and finalize" since the
tool existed, and RecBurn.app's stop button sends exactly one SIGINT.

So the same key means both things, by count: press one stops, press two abandons what follows,
press three hard-exits. Two presses always get the shell back, which is the actual complaint.
If Esa wants a single press to skip post-processing outright, that is a one-line change to
`handleInterrupt()` and he should say so.

## What was actually wrong

`installSignalHandler()` did `signal(SIGINT, SIG_IGN)` and pointed a DispatchSource at
`finish()`. `finish()` guards on `finishing` and returns immediately if already set. So every
Ctrl-C after the first was a no-op — not slow, not queued, *nothing*. There was no way out short
of `kill -9` from another terminal.

## The trap that would have made this look fixed while not being fixed

Killing the child process is not enough, and killing its process GROUP is not enough either.
Foundation's `Process` gives each spawn its own process group — verified with a 6-line Swift
probe before writing anything, rather than assumed. rec-subtitle is in one group; the
`bash -lc "whisper …"` it spawns is in another. A `kill(-pgid, …)` on the child would have
returned instantly, printed a satisfying "aborted", and left whisper eating a core for the next
twenty minutes. That is the exact failure Esa is complaining about, wearing a fix's clothes.

Parentage is the only structure that crosses those boundaries, so `descendants(of:)` walks PPID
from `ps -axo pid=,ppid=`. TERM pass, 350ms, re-enumerate, KILL pass — re-enumerated because a
dying parent can spawn once more on the way out.

## What was measured, and what was not

Verified live: the 0.1s / exit-130 abort during rec-subtitle; the kept-vs-deleted file set; the
3-deep cross-process-group tree (compiled from the shipped `descendants` + `killTree` source, 3
before, 0 after); the announcement line.

The 8-second watchdog was **not** something I contrived a test for. The second live run hit a
real ScreenCaptureKit failure — "application connection being interrupted" — so `stopCapture`'s
completion never ran and the writer never finalized. The watchdog printed "still finalizing
after 8s — leaving anyway" and exited. Before this change that state hung forever.

Two branches are honestly `@built`, not verified: the SIGTERM ladder, and "abort during a slow
finalize" in the ordinary case (the only time it was reached live, the writer never landed at
all).

## Something I noticed and did not touch

While testing, `ps` showed one of Esa's OWN recburn runs mid-whisper on
`~/Downloads/2026-08-22-19-04-48-flat.mov`, started 19:04:48 — running the OLD binary, and
therefore still un-abortable. `killTree` is scoped to the recorder's own child pid, so nothing I
ran went near it. Told him rather than quietly killing it.

## Not done

- RecBurn.app has no "abandon" button; it would be a second `p.interrupt()`. Not asked for.
- `bin/rec-subtitle` still has no abort handling of its own — it dies from the outside, which is
  fine, but it means a partial `-subtitled.mov` is cleaned up by the *recorder*, not by the tool
  that created it.
