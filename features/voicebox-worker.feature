# =============================================================================
# REPORT CARD: voicebox-worker — the Mini's TTS queue drainer (crash-durable)
# Skin: queue worker (claim = a job file in → a WAV out, or an honest failure)
# Convention: ~/.claude/skills/report-card/SKILL.md  ·  GHERKIN-FEATURE-WIKI-PATTERN.md
# SESSION >> features/voicebox-worker.session.md   (the vibe diff that spawned this)
#
# STATUS OF THIS CARD: born of a real incident. On 2026-06-06 a 153-sentence
# Bearden clone render reported "done / pending=0" while 7 sentences were silently
# stranded as .inflight orphans. The fix (boot-time recovery, capped) was built,
# tested, deployed and verified live THIS session; this card is authored in the
# same motion. It also retro-grades the synth hang-fix that shipped just before it.
#
# ── WHAT THIS CARD SPAWNS ───────────────────────────────────────────────────
#   Codespace : bin/voicebox-worker.py (this unit). Reads jobs from
#               ~/work/comms/queue/voicebox-inbox/<id>.json, hits local Voicebox
#               (:17493), writes voicebox-results/<id>.wav, moves spec to
#               voicebox-processed/ or voicebox-failed/. State: heartbeat +
#               voicebox-log.jsonl + .inflight-recoveries.json.
#   Thinkspace: features/voicebox-worker.session.md (incident → diagnosis → fix).
#   Areaspace : OWNS draining the inbox, per-job synth budget, and crash-recovery
#               of in-flight jobs. MUST NOT own: the synth model / Voicebox.app
#               (separate process), the LIVENESS supervision (comms voicebox-
#               guardian.sh restarts the worker), or the input text (narrate's
#               split_sentences strips it). This unit makes the QUEUE durable,
#               not the model reliable.
#
# ── report-card legend (grades in use) ──────────────────────────────────────
#   @built          - code exists and is committed
#   @verified-live  - exercised against the real Mini this session
#   @self-test      - verified by a standalone deterministic check (no Mini)
#   @caveat         - works but has a known sharp edge
#
# ── innards cited by this card (bin/voicebox-worker.py, post cfb2b2d) ─────────
#   constants        INFLIGHT_SUFFIX (62), RECOVERY_STATE (63), MAX_INFLIGHT_RECOVERIES (64)
#   voicebox_synth   def (111); bounded budget timeout_s (135) + deadline escape in
#                    the SSE loop (~133) ; _cancel_generation (174) on timeout
#   process_one      def (183); text = spec.text.strip() (191)
#   claim_jobs       def (222) — scans ONLY .json/.txt, never .inflight (root of the masquerade)
#   recover_inflight def (257); orphan glob (270); strip .inflight → original (279);
#                    cap → voicebox-failed/ (288); state auto-prune (316-318)
#   main             def (323); recover_inflight() at boot (334); heartbeat pending (338);
#                    claim → rename .inflight BEFORE synth (342-344); move to PROCESSED/FAILED (349-360)
#   trigger (not ours): comms/scripts/voicebox-guardian.sh kickstarts the worker
#                       LaunchAgent com.esa.voicebox-worker on a stale heartbeat
#
# ── RESULT (third leg: spec + session + what shipped) ────────────────────────
#   Feature delivery :
#     • synth hang-fix (per-job wall-clock budget + cancel-on-stall) — 2f4c80c
#       "more so nothing lost" — pushed to esaruoho/apple main, no PR.
#     • in-flight recovery (this card's headline) — cfb2b2d
#       "voicebox-worker: re-queue stale .inflight jobs at boot (capped)" — direct
#       to main, no PR; push pending at authoring time.
#   Deploy           : apple does NOT Syncthing-sync, so bin/voicebox-worker.py was
#                      scp'd to the Mini; LaunchAgent kickstarted (boot 2026-06-06
#                      20:08:54Z). recover_inflight verified live on the Mini's
#                      Python 3.9.6 against a temp queue: PASS.
#   This card authored: (pending commit of the triad + the bin back-link)
#   Triad status     : .feature = THIS · .session = present · RESULT = here. COMPLETE.
# =============================================================================

Feature: voicebox-worker — a TTS queue that survives the worker dying mid-job
  As the operator of the Mini's clone-voice render pipeline,
  I want a job the worker crashed on to be retried, not silently lost,
  And one poison job to never wedge the whole queue,
  So that "render complete" means every sentence is really rendered or really failed.

  @built @verified-live
  Scenario: A job the worker died on mid-synth is re-queued at boot
    # cite: claim_jobs (222) renames <id>.json → <id>.json.inflight BEFORE synth (342-344)
    # cite: recover_inflight (257) re-queues every .inflight at boot (270,279)
    Given a job was claimed (renamed .inflight) and the worker then died mid-synth
      (a crash, or the guardian kickstarted it because a hung synth starved the heartbeat)
    When the worker next boots
    Then the orphaned .inflight is renamed back to .json and retried
    And it is no longer invisible to claim_jobs
    # verified-live 2026-06-06 on the Mini (Python 3.9.6): a.json.inflight → a.json

  @built @verified-live
  Scenario: A poison input that orphans every time is capped, never wedges the queue
    # cite: recover_inflight cap (288) — n > MAX_INFLIGHT_RECOVERIES → voicebox-failed/
    # cite: .inflight-recoveries.json counts per-job recoveries, auto-pruned (316-318)
    Given a job that hangs or crashes synth every single time it is claimed
    When it has been recovered MAX_INFLIGHT_RECOVERIES times (default 2) and orphans again
    Then it is moved to voicebox-failed/ with a "_worker_error" explaining it was given up
    And the worker does not restart forever on it, so the rest of the queue keeps draining
    # this is exactly the 2026-06-06 trailing-newline sentence that restarted the worker 3×
    # verified-live on the Mini: b.json (prior count 2) → voicebox-failed/b.json + error

  @built @self-test
  Scenario: A non-JSON (.txt) job's content is preserved on recovery
    # cite: recover_inflight only rewrites spec when it parsed as JSON; .txt re-queued verbatim
    Given a .txt job orphaned as <id>.txt.inflight
    When recover_inflight re-queues it
    Then its raw text body is unchanged (never overwritten with a JSON recovery stub)
    # self-test 2026-06-06: c.txt.inflight → c.txt, content byte-identical

  @built @verified-live
  Scenario: A stalled generation is bounded and cancelled so one job can't freeze the queue
    # cite: voicebox_synth timeout_s (135) + the "if time.time() > deadline: break" in the
    #       SSE loop (~133) + _cancel_generation (174) — escape a never-terminating stream
    Given Voicebox accepts a generation but its status SSE never closes (model stuck)
    When the per-job wall-clock budget (VOICEBOX_SYNTH_TIMEOUT, 240s) elapses
    Then the worker cancels that generation and raises, moving the job to failed
    # verified-live earlier this session via a controlled 40s timeout test (timed out,
    # cancelled, exited cleanly) — shipped in 2f4c80c

  @built @caveat
  Scenario: pending counts only UNCLAIMED jobs — an orphan reads as done until next boot
    # cite: heartbeat pending = len(claim_jobs()) (338); claim_jobs ignores .inflight (222)
    Given a job is stranded .inflight while the worker keeps running (no reboot yet)
    When you read voicebox-heartbeat.json
    Then pending shows 0 even though that sentence is not rendered
    # CAVEAT: recovery fires at BOOT, not continuously. The honest "render done" check is
    # ".json AND .inflight both 0", not "pending==0". (A continuous reaper is still open.)

  @built @caveat
  Scenario: The guardian can kickstart the worker before its own synth budget
    # cite (not ours): comms/scripts/voicebox-guardian.sh restarts on a stale heartbeat
    Given a synth that makes NO SSE progress (so the worker heartbeat goes stale ~57s in)
    When the guardian's stale threshold trips before voicebox_synth's 240s budget
    Then the worker is force-restarted mid-synth and the job is left .inflight
    # CAVEAT: this is the failure that strands jobs; boot recovery (scenario 1) is the
    # backstop. A fuller fix would heartbeat during a no-progress synth so the guardian
    # waits out the 240s budget instead of killing it early. Open.
