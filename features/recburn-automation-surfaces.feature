# ============================================================================
# REPORT CARD — recburn automation surfaces + typed handoff
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : ENGINE (shared, both repos — apple/bin + apple-rec/Engine):
#                 screen-audio-record.swift — RecBurnManifest struct + writeManifest()
#                 emitting <base-stem>.recburn.json AND a "RECBURN-MANIFEST: <path>" line.
#               APP (apple-rec/Sources/RecBurn/):
#                 RecBurnController.swift  — RecBurnManifest decoder + 3-tier final-file
#                   resolution (manifest → printed paths → dir-scan); handleURL() router.
#                 RecBurnApp.swift         — kAEGetURL Apple-Event handler; ServiceProvider
#                   (NSServices toggle/start/stop) + NSUpdateDynamicServices().
#                 RecBurnShortcuts.swift   — App Intents (Toggle/Start/Stop) + AppShortcuts,
#                   thin shims that open recburn:// .
#               SEAM: Engine/recburn-url (open "recburn://$action"), mirrored to apple/bin.
#               build.sh — Info.plist gains CFBundleURLTypes(recburn) + NSServices trio;
#                 installs recburn-url alongside rec/recburn.
#   Thinkspace: features/recburn-automation-surfaces.session.md (the spawning conversation).
#   Areaspace : OWNS = how a recording is TRIGGERED (Shortcuts/Services/Siri/URL/hardware,
#               all funnelled through one recburn:// router) and how the pipeline's RESULT is
#               HANDED OFF (typed manifest, not stdout prose). MUST NOT TOUCH = the capture /
#               flatten / transcribe / burn mechanics themselves (that is the
#               screen-audio-record card) — this card only adds a typed exit + typed entrances.
#
# WHY THIS CARD EXISTS
#   Sal reading of RecBurn (2026-07-08): the pipeline was programmable from the shell but
#   INVISIBLE to the Shortcuts/Services layer where non-scripters live, and the app learned its
#   result by SCRAPING the engine's "✓ …" prose off stdout (brittle risk #3 in STATUS.md). Fix
#   both: give the molecule typed entrances (one URL seam behind Shortcuts + Services + Siri) and
#   a typed exit (a JSON manifest). "Structured data flows between actions; nobody greps prose."
#
# REPORT-CARD LEGEND
#   @hw-verified  compiled AND exercised on this Mac (macOS 15.x); output inspected.
#   @built        wired + compiles clean; that runtime branch not click-driven this session.
#   @note         a documented boundary, not an executable claim.
#
# RESULT
#   Deployed to BOTH repos on 2026-07-09 (engine source identical in each; app lives in apple-rec).
#     apple-rec (canonical): screen-audio-record.swift manifest, RecBurnController/App/Shortcuts,
#       Engine/recburn-url, build.sh (URL scheme + NSServices), README + STATUS.
#     apple (dev): bin/screen-audio-record.swift + rebuilt binary, bin/recburn-url.
#   Build: apple-rec/build.sh compiled engine + App Intents + Services provider CLEAN under
#     Swift 6 (-parse-as-library); RecBurn.app assembled, ad-hoc signed, lsregister-refreshed.
#   Commits: see git log of each repo for this card's ship (direct-push to main, no PR).
#   Live build machine: macOS 15.x (Apple Silicon).
# ============================================================================

Feature: Trigger recburn from anywhere through one seam, and hand off a typed result

  @hw-verified
  Scenario: the engine emits a typed manifest that round-trips into the app's decoder  (contract ran)
    Given the producer struct (screen-audio-record) and consumer struct (RecBurnController)
    When a full-pipeline manifest (base+flat+subtitled+srt) and a bare-`rec` manifest (nils) are
      encoded by the producer and decoded by the consumer
    Then every field survives (final/subtitled/micRecorded/lengthSeconds/schema) for BOTH cases
    And the headless contract test printed "✓ manifest contract round-trips both ways"
    # cite: RecBurnManifest in bin/screen-audio-record.swift + RecBurnController.swift;
    #       /tmp round-trip harness (both structs) exited 0

  @built
  Scenario: on stop the engine writes <stem>.recburn.json and prints its path
    Given a finished recording (any mode)
    When finish() completes writing
    Then writeManifest() encodes {schema:"recburn/1", base, flat?, subtitled?, srt?, final,
      lengthSeconds, micRecorded} to <base-stem>.recburn.json and prints "RECBURN-MANIFEST: <path>"
    And the human "✓ saved / YouTube version / subtitled" lines still print for terminal users
    # cite: writeManifest() + finish() manifest block; binary strings confirm "RECBURN-MANIFEST:".
    # @built — a live recording producing a real manifest file is not yet user-confirmed.

  @built
  Scenario: the app reads the manifest instead of scraping prose, with a two-level fallback
    Given the recorder exited
    When pump() resolves the final artifact
    Then TIER 1 decodes the sentinel-reported path then the deterministic <stem>.recburn.json;
      TIER 2 uses the printed "✓ …" paths; TIER 3 dir-scans — first hit wins
    And gotSubs is taken from manifest.subtitled != nil (not from a filename substring)
    # cite: RecBurnController.pump() manifest block + fallback; @built — logic verified, the live
    # decode-from-a-real-recording path awaits the end-to-end sign-off in STATUS.md.

  @hw-verified
  Scenario: recburn:// is the single control seam and routes toggle/start/stop  (compiled + registered)
    Given RecBurn.app declares CFBundleURLTypes scheme "recburn" (plutil -lint OK, lsregister -f done)
    When a recburn://{toggle|start|stop}[?mic&pip&burn&corner] URL is opened
    Then AppDelegate's kAEGetURL handler forwards it to RecBurnController.handleURL(), which
      toggles/starts/stops and applies query overrides to recordMic/webcamPiP/burnSubtitles/pipCorner
    # cite: applicationWillFinishLaunching kAEGetURL + handleGetURL + handleURL(); Info.plist verified.
    # @hw-verified for scheme registration + build; the actual start/stop side-effect of opening the
    # URL was NOT triggered this session (would record Esa's live screen) — see STATUS "click-verified".

  @built
  Scenario: Services menu exposes Toggle/Start/Stop, assignable to a global hotkey
    Given Info.plist carries an NSServices trio (NSMessage toggleRecording/startRecording/stopRecording)
    When the app launches
    Then it sets NSApp.servicesProvider = ServiceProvider(c:) and calls NSUpdateDynamicServices()
    And each @objc service method funnels into the same recburn:// router (one seam)
    # cite: RecBurnApp ServiceProvider + didFinishLaunching wiring; Info.plist NSServices verified.
    # @built — menu appearance may need one relaunch after NSUpdateDynamicServices; not click-verified.

  @built
  Scenario: App Intents surface Toggle/Start/Stop to Shortcuts + Siri
    Given RecBurnShortcuts declares AppShortcut phrases over Toggle/Start/Stop intents
    When each intent's perform() runs
    Then it opens the matching recburn:// URL (thin shim — no duplicate lifecycle)
    # cite: RecBurnShortcuts.swift; compiles clean under swift build. @built — automatic Shortcuts
    # gallery discovery may need the App Intents metadata Xcode extracts; the recburn-url
    # Run-Shell-Script path is the guaranteed fallback (documented in README).

  @hw-verified
  Scenario: recburn-url is the portable seam for hardware buttons + shell  (installed)
    Given bin/recburn-url on PATH (installed by build.sh next to rec/recburn; mirrored to apple/bin)
    When `recburn-url` runs with no args
    Then it exec's `open "recburn://toggle"`; `recburn-url start|stop|'start?mic=1&burn=1'` pass through
    # cite: Engine/recburn-url; @hw-verified it exists, is executable, and contains the open call.
    # The open→app→toggle round trip itself was not fired this session (live-screen side effect).

  @note
  Scenario: this card adds entrances + an exit, not new capture mechanics
    Given the capture/flatten/transcribe/burn engine is owned by the screen-audio-record card
    Then nothing here re-encodes video, spawns rec-audio/rec-subtitle differently, or changes flags;
      the only engine change is additive (manifest emission), so terminal `rec`/`recburn` behave as before
