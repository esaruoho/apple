# Session — freellmask-mail: at-most-once replies + never guess at a video

CARD >> features/freellmask-mail-anti-loop-and-video-gate.feature

## How to get back
- Transcript: file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-convey/3ce499e9-d472-4024-b17b-a6efa757dcb1.jsonl
- Session ID: `3ce499e9-d472-4024-b17b-a6efa757dcb1`
- Resume: `claude --resume 3ce499e9-d472-4024-b17b-a6efa757dcb1`
- Started 2026-07-28 ~22:15 EEST, ran past midnight into 2026-07-29 (cwd `~/work/convey`).

## What Esa reported

Two things, with a screenshot of the second:

1. "we should be not looping the emails (we are looping the emails, i send a response,
   and i get 10-15 emails back, especially on Schaffranke emails" — and he noted he has
   specified this multiple times before.
2. He emailed a YouTube video expecting a transcript, and got: *"because we do not
   possess the full transcript, we must treat the video's specific claims as unknown"* —
   "i am being given the runaround".

## What was found, in order

- The mailer runs as a Cloudcity-Boot pane on the Mini (`start-freellmask-mail.sh`), so
  its state file is Syncthing-mirrored and readable locally.
- Local state: `seen` sat exactly at the 500 cap. Cross-checking the live AgentMail inbox
  showed answered message-ids MISSING from `seen`, including the one that drew 25 replies.
  Cause: `st["seen"]=list(seen)[-500:]` over a plain **set** — no order, so each save kept
  an arbitrary 500. Evicted ids were still inside the newest-50 listing → re-answered
  every poll, ~1 reply/75s.
- The bare-video gate existed and was correct in intent, but `video_only` tested the
  residue of `question`, and the thin-body fallback had already copied the SUBJECT into
  `question`. A Finnish video title read as a long question. `fa-video-pending.jsonl` was
  0 bytes since Jul 4 — the gate had not fired once in three weeks.
- After fixing that, replies STILL went out to bare video mail. The real mechanism:
  `fetch_url_content` fetches every linked URL, including the YouTube watch page, and
  pulls its og: title+description into `extra`. Non-empty `extra` silently disabled the
  gate, AND handed the model the blurb it then reasoned from. That is verbatim what the
  screenshot shows: "The only concrete material we have is the Finnish description".
- Two of the three videos had failed to download (yt-dlp 403, yt-dlp 2026.03.17, >90 days
  old) and could never be retried: `whisp-submit`'s dedup grepped the whole `queue/` tree,
  so `queue/failed/` — and `queue/events/`, which stores `"status": "failed"` records —
  made a dead job look queued. Silent permanent drop.
- Every local Cloudcity heartbeat was frozen at 13:29 because the laptop disk is at 0.48%
  free, tripping Syncthing's 1% guard. A `!pk run` file-drop probe got no answer, which is
  why SSH (preflighted, kill-and-let-the-pane-relaunch only, no nohup) was used to deploy.

## Esa's question mid-session, and the answer

> "is it possible that the cloudcity-llm is actually responding to its own email that it
> sends out and thats why the content is duplicated?"

No — and the headers settle it. All ~40 storm sends carry the same
`in_reply_to: <8EBB6FBC-703F-486E-8C71-584AEC9600D3@gmail.com>`, a message from Esa. Sent
mail is already excluded by label. It re-answered ONE inbound repeatedly, regenerating the
answer each time — which is why the replies are near-1:1 in substance but differ in
wording and length (sha1 differs per send), rather than being identical duplicates.

## Decisions Esa made

- Disk: **"Just report, delete nothing."** So a report was written and nothing was removed.
  Syncthing therefore stays frozen, queue channels stay dead, SSH remains the channel.
- Rate ceiling: he asked the question above instead of picking a number; 4/hour per thread
  was kept as shipped (env `FREELLMASK_MAIL_THREAD_MAX_HOUR`).

## What was NOT done / still open

- `WAiTGKhf6Go` ("Do You Like Tomorrow?", a 50-second Short) fails with "no transcript
  files produced" — probably no speech. The requester is told nothing; carried as
  `@untested` on the card.
- `whisp-worker.log` shows its own `git pull` failing with "Cannot rebase onto multiple
  branches" since 16:25 — noted, not fixed, out of scope here.
- A `git stash pop` in `~/work/whisp-transcripts` could not restore untracked files (they
  already existed on disk via Syncthing); `stash@{0}` was left in place rather than dropped.
- The laptop disk is still ~10 GB free. Until it is above ~18 GB, Syncthing will not sync
  comms and file-drop control of the Mini stays broken.
