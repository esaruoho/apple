# Session — surviving a ScreenCaptureKit failure

The spawning conversation for `features/recburn-stream-recovery.feature`. Faithful, not
flattering.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-apple/00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630.jsonl`
- Session ID: `00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Resume: `claude --resume 00cf1a54-2fe3-4be0-ac2a-5ffd17bd5630`
- Date: 2026-08-22, immediately after the Ctrl-C abort work (`features/recburn-abort.feature`),
  roughly 19:14–19:25 EEST.

## The question

> does recburn have some way of "oh no you dropped frames, im gonna exit the recording", cos
> thats not good.

Then, after the answer:

> yeah, please build the reconnect, and make the failure loud, and the expectation is that
> recburn.app is rebuilt.

## Answering the question honestly, and where it led

The literal answer was **no** — `checkHealth()` writes to stderr and does nothing else. But
"I read the code and it doesn't" is a weaker claim than it sounds, so I flooded all 12 cores
for 15 seconds mid-take instead. It fell to 38 fps of 60, warned, and kept going. That is the
answer, and it cost one 25-second test.

The investigation then turned up the thing he was *actually* right to worry about, arriving by
a different door: `stream(_:didStopWithError:)` called `finish()`. That is ScreenCaptureKit
ending the stream, not us reacting to drops — and it had ended one of my own test recordings an
hour earlier, at 20 seconds, with the log line "Failed during stream due to application
connection being interrupted". Worse than losing the take: it then ran the entire flatten +
whisper + burn pipeline on the truncated result, unasked.

So the honest answer was "no, but here is the real one, and it bit us today."

## What I did not assume

I did not claim the reconnect worked because it compiled. `replayd` is the daemon behind SCK,
so `kill -9` on it reproduces the exact failure on demand. Killed it six seconds into a
recording: reconnect in 0.3s, recording carried on to 31 seconds.

And I did not stop at "the process survived", because a process that survives while writing a
broken file is worse than one that dies. ffprobe on the result: one continuous file, 1218
frames, 0.00 → 31.49s, with a **single 0.28s gap at t=5.47** — precisely the outage, nothing
lost after it. That number is the whole claim.

## The design decision worth writing down

Two failures are deliberately not retried through: the display resolution changing, and the
`--app` being recorded quitting. Both mean the recording that was asked for no longer exists,
and the writer is already committed to fixed dimensions. Retrying through either would produce
a file that is worse than an honest stop, and "it kept going" is not a virtue when what it kept
going with is wrong. Both are `@built`, not verified — I did not stage a resolution change.

The reconnect also re-fetches `SCShareableContent` on every attempt rather than reusing the
`SCDisplay` it started with, because after a replayd restart the old object can belong to a
session that no longer exists.

## RecBurn.app

Rebuilt via `apple-rec/build.sh` and installed to `/Applications`. I did **not** use
`build.sh --install`: that also symlinks the CLI into `~/.local/bin` or `/usr/local/bin`, which
would silently repoint Esa's `recburn` from `~/work/apple/bin` to the apple-rec checkout. Same
content today, different repo tomorrow. He asked for the app to be rebuilt, not for his CLI to
move, so I did the app steps by hand and left the PATH alone.

Bundle id stayed `com.esaruoho.recburn` and `lsregister -f` ran afterwards, so TCC grants
should survive.

## Not done, and why

`AppleToolbox.app` bundles its own engine copy, dated Jul 3, now stale. Replacing a nested
helper invalidates the outer signature, and re-signing AppleToolbox risks its Screen Recording
and Full Disk Access grants — the exact trap documented in
`feedback_tcc_bundle_sck_helper_same_identity`. Flagged rather than done unasked.
