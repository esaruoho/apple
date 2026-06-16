# FEATURE CARD — Live HomePod climate read on the laptop (no Mini round-trip)
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/homepod-now (the reader + --live poller + persister)
#               bin/fm-chat     (mlx-here REPL: /climate trigger + quit variants)
#               ~/.bash_profile (the `homepod` alias seam)
#   Thinkspace: features/homepod-live-climate.session.md (the spawning dialogue)
#   Areaspace : OWNS — on-demand local climate read on a non-hub Mac, and writing
#               the result back into the shared daily JSONL in the watcher's shape.
#               MUST NOT TOUCH — the Mini's 15-min watcher loop, HomeKit hub config,
#               the calibration constants' source-of-truth (homepod skill SKILL.md).
#
# REPORT-CARD LEGEND (grades in use)
#   @runtime-verified  ran it on this Mac this session, observed the stated output
#   @built             code in place, target confirmed, but not exercised in its
#                      final runtime form (e.g. alias needs a fresh shell)
#   @runtime-untested  path written but not triggered this session
#
# RESULT (as of 2026-06-15, EEST)
#   Status      : UNCOMMITTED working-tree changes (awaiting Esa's go to commit)
#   Innards     : bin/homepod-now  (M) — live() poll+parse+calibrate+persist; --live dispatch
#                 bin/fm-chat       (M) — quit/exit/bye/q (slash optional); /climate handler; help
#                 ~/.bash_profile   (edit, outside repo) — homepod alias repointed
#   Base commit : b6656c8
#   PR          : none (working tree)
#   Session     : features/homepod-live-climate.session.md  (transcript bundled beside it)

Feature: Read HomePod temperature + humidity from the laptop, live and on demand
  The HomePod is a HomeKit thermo-hygrometer. The always-on Mini logs it every
  15 min into a Syncthing-shared daily JSONL; any joined Mac reads that file. This
  card adds a live on-demand path so the laptop can poll the sensor itself (it is a
  HomeKit client; the HomePod is the hub) and fold the fresh reading back into the
  same shared log.

  @runtime-verified
  Scenario: Default read returns the latest synced reading, offline
    Given the Syncthing share ~/work/comms/queue/homepod-climate/ has today's JSONL
    When I run `homepod-now`
    Then it prints the calibrated temp + humidity and the reading's age
    And it touches neither SSH nor the Mini
    # cite: bin/homepod-now (tail of newest 20*.jsonl; calibrated fields) ~line 59-82

  @runtime-verified
  Scenario: --live polls the sensor directly via the local Shortcut
    Given the "HomePod Sensors" Shortcut is installed on this Mac and the hub is up
    When I run `homepod-now --live`
    Then it runs `shortcuts run "HomePod Sensors"`, parses the Finnish-locale
         "<humidity>, <temp>,<dec>°C" output, applies calibration (+0.45°C, +4.5%)
    And prints "...(calibrated, live): 23.95°C, 58.5% ... Polled just now"
    # cite: bin/homepod-now live() ~line 27-72; --live dispatch ~line 77

  @runtime-verified
  Scenario: --live persists the fresh reading so the default read reflects it
    Given a live poll has produced raw 23.5°C / 54%
    When --live writes today's JSONL line in the watcher's exact shape
    Then a subsequent `homepod-now` reports it as "0 min ago"
    And the line is {"timestamp","temperature_c","humidity_pct","temperature_cal","humidity_cal"}
    # cite: bin/homepod-now live() persist block (rec + append to <today>.jsonl)

  @built @runtime-untested
  Scenario: --live falls back to the synced file when it can't read live
    Given the home hub is unreachable OR the Shortcut output won't parse
    When I run `homepod-now --live`
    Then it prints a fallback notice and reads the synced file instead of erroring
    # cite: bin/homepod-now live() returns False -> fall-through to file read

  @runtime-verified
  Scenario: /climate in mlx-here surfaces a live reading with zero LLM tokens
    Given an mlx-here session
    When I type `/climate`
    Then it runs `homepod-now --live` directly and prints the reading
    And no prompt is sent to the model (no token, no Mini round-trip)
    # cite: bin/fm-chat REPL /climate handler ~line 391-402; help ~line 22, ~351

  @runtime-verified
  Scenario: quit leaves mlx-here, with or without a slash
    Given an mlx-here session
    When I type any of: quit /quit exit /exit bye q (any case)
    Then the session prints "bye." and exits 0
    # cite: bin/fm-chat line 373 (line.lstrip("/").lower() in (...))

  @built
  Scenario: `homepod` in the terminal shows the climate (alias repaired)
    Given the old alias pointed at a deleted health/environment script
    When the alias is repointed to bin/homepod-now and the shell re-sourced
    Then typing `homepod` prints the calibrated synced reading
    # cite: ~/.bash_profile:109 — alias homepod="/Users/esaruoho/work/apple/bin/homepod-now"

  # CAVEAT (areaspace boundary): the daily JSONL is also appended by the Mini's
  # watcher every :00/:15/:30/:45. Two peers editing one file -> Syncthing keeps one
  # and drops the other into a .sync-conflict-*.jsonl (no data loss, occasional stray
  # file). Acceptable for an append-only climate log; switch to a separate
  # laptop-live.jsonl the reader also scans if conflict files become annoying.
