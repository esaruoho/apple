# =============================================================================
# REPORT CARD: freellmask-mail — at-most-once replies, and never answering a
#                                 video nobody has watched
# Skin: mail agent (AgentMail inbox → FreeLLMAPI → reply), poll loop
# SESSION >> features/freellmask-mail-anti-loop-and-video-gate.session.md
#
# WHY THIS CARD EXISTS
#   2026-07-28, reported by Esa: cloudcity-llm@ sent him 25 "Re: Schaffranke"
#   replies to ONE email in 45 minutes (and 5 to another), and when he emailed a
#   YouTube link expecting a transcript he got a hedge instead — "because we do not
#   possess the full transcript, we must treat the video's specific claims as
#   unknown". He had asked for the looping to stop more than once before.
#
#   His hypothesis was that the agent was answering its own outgoing mail. The
#   headers disprove that: all ~40 storm replies carry the SAME
#   in_reply_to: <8EBB6FBC-703F-486E-8C71-584AEC9600D3@gmail.com>. It re-answered
#   ONE inbound email over and over, regenerating a fresh answer each time — hence
#   near-1:1 repetition with different wording, not byte-identical duplicates.
#
# CONVEY MEANING
#   Two invariants this agent must hold, both violated:
#     1. AT-MOST-ONCE: one inbound email earns at most one reply, forever.
#     2. NEVER GUESS AT MEDIA: a video's content is what the transcript says. Until
#        the belt produces one, the agent has nothing to say about the video.
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/freellmask-mail                        (poll loop, gate, ledger)
#               ~/work/comms/queue/freellmask-mail-replied.jsonl   (anti-loop ledger)
#               ~/work/comms/queue/fa-video-pending.jsonl          (deferred analysis)
#               bin/fa-video-analysis-mailer               (part 2 — replies from the
#                                                           real transcript)
#   Thinkspace: this card + its session; the header evidence above.
#   Areaspace : OWNS reply-once bookkeeping and the bare-media gate for this inbox.
#               MUST NOT own transcription (whisp-transcripts owns that), and MUST
#               NOT own what the analysis SAYS (fa-video-analysis-mailer / convey
#               email-transcript own that).
#
# RESULT
#   apple  be0d150  OrderedSeen + replied ledger + per-thread ceiling; body-only
#                   bare-video residue via _bare_link_body()
#   apple  4982d08  replied-ledger self-seeds from the inbox (200-msg window,
#                   original timestamps so history can't trip the ceiling)
#   apple  5c41cd1  fetch_url_content no longer scrapes YouTube og: text — the
#                   actual mechanism behind the "we do not possess the transcript"
#                   reply, and what silently defeated the gate
#   whisp  b2ddc68f  whisp-submit: a FAILED job stays retryable (dedup skips
#                   queue/failed/)
#   whisp  b7c23998  whisp-submit: dedup also skips queue/events/ (it logs
#                   "status": "failed")
#   Direct-push to main, no PR. Deployed to the Mini by repo-puller + a pane
#   relaunch (pkill -9 the loop; Cloudcity-Boot's wrapper restarts it).
#   Files: bin/freellmask-mail, whisp-transcripts/whisp-submit
# =============================================================================

Feature: freellmask-mail answers each email once, and never speaks for an untranscribed video

  Background:
    Given the agent polls the cloudcity-llm@agentmail.to inbox every 45 seconds
    And it only considers messages whose labels do not include "sent"

  @built @verified-against-live-inbox
  Scenario: handled message-ids are persisted in insertion order
    Given more handled message-ids exist than the persistence cap
    When the state file is written
    Then the NEWEST cap-many ids are kept
    And no already-answered id is evicted while newer ids remain
    # Was: `list(seen)[-500:]` over a plain set — a set has no order, so each save
    # kept an ARBITRARY 500 and dropped answered ids that were still inside the
    # newest-50 API listing, so the next poll answered them again. Proven: the mid
    # that drew 25 replies was MISSING from the persisted seen list.
    # Innards: bin/freellmask-mail → class OrderedSeen, SEEN_CAP=5000

  @built @verified-against-live-inbox
  Scenario: a message that has been answered can never be answered again
    Given an inbound message-id recorded in the replied ledger
    When a later poll sees that same message
    Then no reply is sent
    And the message is marked handled
    # The ledger is append-only and independent of the state file, so losing,
    # truncating, or rolling back state cannot resurrect an answered email.
    # Innards: bin/freellmask-mail → replied_load / replied_add / REPLIED

  @built @verified-against-live-inbox
  Scenario: the ledger builds itself on a machine that has never had it
    Given no replied ledger exists
    When the agent polls
    Then every received message whose thread already contains a LATER sent message
         is recorded as replied
    And each seeded record keeps its ORIGINAL timestamp
    # Original timestamps matter: stamping "now" would make seeded history trip the
    # per-thread hourly ceiling and suppress genuinely new mail.
    # Verified: 30 seeded from the live inbox, 0 of them inside the last hour.
    # Innards: bin/freellmask-mail → replied_seed

  @built
  Scenario: a thread cannot exceed its hourly reply ceiling
    Given 4 replies have been sent in one thread within the last hour
    When another message arrives in that thread
    Then no reply is sent
    And the suppression is written to the debug log
    # Belt-and-braces: stops a storm whatever future cause produces one.
    # Ceiling is FREELLMASK_MAIL_THREAD_MAX_HOUR (default 4).
    # Innards: bin/freellmask-mail → THREAD_MAX_PER_HOUR, poll_once anti-loop 2

  @built @verified-against-live-inbox
  Scenario: an email that is just a YouTube link is a convey request, not a question
    Given an email whose body is a YouTube URL plus a signature
    And whose subject is the video title
    When the agent handles it
    Then the video is queued on the whisp transcript belt
    And NO immediate reply is sent
    And the requester is recorded in fa-video-pending.jsonl
    # The subject of a shared video mail IS the title, never a request. The old gate
    # tested the residue of `question`, which the thin-body fallback had already
    # filled with the subject — so a Finnish video title read as a long question.
    # Verified: all 8 bare video mails in the live inbox now gate to video_only.
    # Innards: bin/freellmask-mail → _bare_link_body, body_is_bare, video_only

  @built @verified-against-live-inbox
  Scenario: a video's page is not the video
    Given an email containing a YouTube URL
    When linked-URL content is fetched for the answer context
    Then the YouTube page is NOT fetched
    And no og: title or description enters the context
    # This was the true mechanism. Scraping the watch page put the blurb into
    # `extra`, which (a) made `extra` non-empty and silently defeated the gate above
    # — replies still went out after the residue fix — and (b) gave the model
    # something to reason from, producing "the only concrete material we have is the
    # Finnish description … we do not possess the full transcript".
    # Verified: extra == 0 chars for all five overnight video mails.
    # Innards: bin/freellmask-mail → fetch_url_content (skip beside patreon skip)

  @built @verified-on-mini
  Scenario: the answer about a video comes from the real transcript
    Given a video recorded in fa-video-pending.jsonl
    And its transcript has landed in whisp-transcripts
    When fa-video-analysis-mailer runs on its cadence
    Then the requester is emailed an analysis grounded in the transcript
    And the transcript is attached
    # Verified 2026-07-28: Esa's Tesla video answered from a 2488-word transcript,
    # no hedging language present.
    # Innards: bin/fa-video-analysis-mailer, driven by comms/scripts/fa-wiki-grow-worker.sh

  @built @verified-on-mini
  Scenario: a failed transcription job stays retryable
    Given a whisp job that previously failed
    When the same URL is submitted again
    Then it is queued, not skipped
    And the retry is announced
    # Two of the three videos were permanently stuck: whisp-submit's dedup grepped
    # the whole queue tree, so queue/failed/ (and queue/events/, which logs
    # "status": "failed") made a dead job look queued — silently no transcript, and
    # nothing said so. Root cause of the failures themselves: yt-dlp 403 on a
    # >90-day-old yt-dlp, upgraded 2026.3.17 → 2026.07.04 on the Mini.
    # Innards: whisp-transcripts/whisp-submit → queue_dedup_hit, clear_previous_failure

  @untested
  Scenario: a Short with no speech reports itself
    Given a 50-second YouTube Short with no transcribable speech
    When the belt processes it
    Then the requester learns the video produced no transcript
    # Today it fails with "no transcript files produced" in queue/failed/ and the
    # requester is told nothing. WAiTGKhf6Go ("Do You Like Tomorrow?") is in exactly
    # this state and is the one thing from Esa's three videos still undelivered.
