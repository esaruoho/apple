# Session — recburn-redact: taking one second of a screencast back

Spawning conversation for `bin/recburn-redact` and `features/recburn-redact.feature`.
Faithful, not flattering: this session contains four of my own bugs, two of which I
chased in the wrong direction, and one factual claim I got wrong out loud.

## How to get back

- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-convey/26dc4064-76b3-4811-b847-3108118412c7.jsonl`
- Session ID: `26dc4064-76b3-4811-b847-3108118412c7`
- Resume: `claude --resume 26dc4064-76b3-4811-b847-3108118412c7`
- Date: Thursday 2026-08-13, ~10:15–11:55 EEST (Helsinki). Working dir was
  `~/work/convey`, not `~/work/apple` — the tool was written across repos.

## How it started

Esa had just finished a 34-minute recburn screencast and was about to post it to
Instagram and YouTube. He sent two frames and asked, plainly: *"is this a bad idea"*.

The frame showed `dashboard.stripe.com/acct_<REDACTED>/payouts` in the Safari
URL bar, with `a bank name •••• 1234` repeated down the Destination column of a payouts
table, fourteen rows of it, amounts from €3.87 to €56.14.

My read, which I still stand by: the Stripe **account** id is a semi-public identifier
— it ships in client-side Connect code — and is not a credential; nobody logs in or
moves money with it. The piece with actual leverage is bank-name + last-4, a classic
weak verification factor in phone-support flows. And the bigger risk in any 34-minute
screen recording is not the frame you noticed: it is a Customers view or a receipt
showing someone else's name and email, which unlike your own account id is not yours
to publish. The payout amounts I explicitly left alone — that video is about streaming
income transparency, so the numbers ARE the point.

Esa's answer was not "should I?" but an instruction:

> "what you are gonna do is you are gonna blur the frames.. they are at .. 19:58->19:59.
> you are gonna blur them. i think you can edit the .mov itself directly. r u able to do
> that please"

## The thing I got wrong out loud

While hunting the exact window I sampled frames with `ffmpeg -ss` at 1s spacing, got
misleading hits, and told him Stripe was on screen for **~10 seconds**. It is not.

> "stripe is not on screen for ~10 seconds.. what the fuck?"

He was right and I said so. The real window is frames 35931–35964 — about **0.9
seconds**, exactly the "19:58->19:59" he had given me from the start. His timestamp was
better than my measurement. The lesson that went into the tool: a 1-second sample grid
cannot resolve a 1-second event, so `--scan` samples at 10fps and shows you a contact
sheet instead of making you trust my sampling.

## Four bugs, in the order I hit them

1. **`enable='between(t,...)'` never fired.** With an input `-ss`, the filtergraph's `t`
   is offset by the seek, so the gate silently never became true and the span came out
   completely unredacted. Fixed by gating on frame number `n`, which starts at 0 for the
   first frame handed to the graph. This is now load-bearing and commented as such.

2. **Two video streams.** I had written both `-map 0:v:0` and `-map "[vout]"`, so ffmpeg
   wrote the unfiltered source as stream 0 and the redacted picture as stream 1 — and
   every check I ran read v:0 and showed me crisp, unredacted text. I spent three rounds
   convinced the blur filter was broken, testing it on a still frame (where it worked
   perfectly) before I looked at my own command line. This is the bug I'm least proud of
   and the reason the tool now asserts the encoded span's stream count and frame count
   before proceeding.

3. **`-to` gave the head two extra frames.** 35902 where 35900 were wanted, which would
   duplicate two frames and put video 66ms out against audio for the remaining 14
   minutes. Fixed by cutting the head with `-frames:v <exact count>`.

4. **`-ss` on the tail landed 16 frames early.** Found only because I built a test
   excerpt with `-ss ... -c copy`, which carries an edit list — so `pts_time` described a
   timeline the seek did not use. The concatenation came out 16 frames long. This one
   changed the design: cut points are no longer computed from timestamps at all. They are
   **measured** with `copy_frame_count()`, which counts what a stream-copy from that point
   actually yields. The same excerpt also reported `nb_frames=1802` while holding 1814, so
   the container's own count is treated as advisory too.

Bug 4 is why the verification block exists in the shape it does. Counting frames cannot
catch a span that started at the wrong frame, because the tool controls the counts — so
verification also hashes the decoded frame either side of the span, where both files are
stream copies and must be pixel-identical.

## What the verification refuses to do

When I ran the tool against the deliberately edit-list-skewed excerpt, two checks
failed: duration, and the shift hashes. Both were artifacts of my synthetic test file,
not of the tool — that file's own metadata duration disagrees with its own frame count by
12 frames, so comparing by timestamp is meaningless on it.

The temptation was to loosen the tolerances until it passed. Instead the checks now test
the invariant that actually matters (`frames / fps`), detect the skew explicitly, and
**say** they are skipping the timestamp comparison and why. A check that quietly passes
on a broken file is worse than no check.

## Decisions worth keeping

- **Never overwrite the source.** Esa said "edit the .mov itself directly"; I wrote a new
  file instead and told him he could swap the names. A 34-minute render has no undo, and
  the redacted copy was not verified at the moment the overwrite would have happened.
- **Verify on an excerpt, not on the 2.27GB file.** His disk was at 14.7GB free (I flagged
  that separately — a full disk is what trips Syncthing's minDiskFree guard and freezes
  every Cloudcity heartbeat). A 60s excerpt exercises head-copy, encode, tail-copy,
  concat, audio-remux and all five checks for ~100MB.
- **Mosaic then blur, not blur.** A soft blur over small high-contrast UI text can stay
  legible. Down to one block per ~24px with `flags=neighbor`, then blur the block edges.
- **Speed matters because it decides whether verification runs at all.** The first
  full-file run took 7m15s, nearly all of it `-count_frames` decoding both files to count.
  Packet counts decode nothing and gave the same truth: 60s clip now verifies in 5.9s.

## What is NOT verified

Graded honestly in the card: `--method black` and `--method blur` are wired but never run
against a real capture; the no-audio path and the two edge cases (window touching frame 0
or EOF) are code paths only; and the `urlbar` / `stripe-destination` presets were measured
on exactly one layout — full-screen Safari on a 3024x1964 capture. `--probe` exists
because those presets will be wrong for any other layout.

## Round two — "do i need to tell it times or something"

Once the tool shipped, Esa asked the question that mattered:

> "okay. now. do we have this as a skill. can i run recburnredact or something and .. do i
> need to tell it times or something"

Three things fell out of that one sentence.

**The name was wrong.** `recburn` and `recburnclick` carry no hyphen. He typed
`recburnredact`, which is the family spelling, and it did not exist. Added `bin/recburnredact`
as a one-line wrapper so muscle memory works either way.

**"Do I need to tell it times" was a complaint, not a question.** The answer had been yes,
and that is the whole cost of using the tool — you have to go hunt a timestamp by hand
first. So `--find` now sweeps the entire recording with on-device Apple Vision OCR
(`bin/vision-ocr`, Neural Engine, nothing leaves the Mac), matches 14 exposure patterns, and
prints padded windows plus the exact `--probe` / `--at` commands to run next. No times
required at all.

**Every setting in it had to be measured, and two of my first guesses were wrong.**

- I started with half-resolution `--fast` OCR because it was 8x cheaper. It read
  `a bank name` fourteen times and **never saw the `acct_…` id** — the primary target. So:
  full resolution, always.
- Full-res `--fast` did catch the account id, so I nearly shipped it. Then I checked the
  bank rows properly and found `--fast` returns `a bank name` while **silently dropping the
  `•••• 1234` after it**. It finds the account id and loses the last-4, which is the piece
  with actual leverage. Accurate is now the default; `--fast-ocr` exists and says in its own
  help that it will miss masked digits.
- My masked-account regex `[•·*]{3,}\s*\d{4}` matched **nothing**. Vision reads the mask as
  U+2022 with some bullets misrecognised as `.` — the real lines were `•• .• 1234` and
  `• .. • 1234`. The first `--find` run therefore reported the account id and quietly missed
  all fourteen bank rows that were right there on screen. This is the same failure shape as
  the `-map` bug earlier in the session: a check that looks like it passed.

**What I deliberately did not build.** `--find` reports; it never redacts. A regex cannot
tell a real exposure from Esa's own public account name, nor decide how much around it to
cover. And it never says "clean" — with no matches it prints "That is NOT a clean bill of
health" and lists the patterns it checked, because it cannot see an exposure shorter than the
sample step, one rendered as a picture rather than text, or one that is only an exposure in
context. A customer's name on a receipt matches no regex at all.

Matched secrets print truncated. Printing a live key to the terminal copies it into
scrollback and from there into whatever transcript is running — which would be a fresh
exposure created by the tool built to prevent them.

## Result

`recburn-redact <file> --at 19:57.8-19:58.7 --box urlbar --box stripe-destination`
re-encoded 57 of 61760 frames, stream-copied the other 61703 bit-exact, never touched the
audio, and passed all five checks: frames 61760, duration 2058.666667s, audio 96499
packets, no shift, clean decode across both splices.
