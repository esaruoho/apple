# =============================================================================
# REPORT CARD: arm-apple-skill — chat with the Mini's MLX/FM brain ARMED with the
#                                Apple skill + the folder you're standing in
# Skin: CLI tool (claim = a question in → a Mini-LLM answer grounded in skill.md +
#       this folder + the few wiki/ pages most relevant to the question)
# Convention: ~/.claude/skills/report-card/SKILL.md
# SESSION >> features/arm-apple-skill.session.md
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/arm_apple.py (the armer), bin/fm-chat (--apple flag),
#               bin/mlx-here + bin/mlx-chat (folder-aware wrappers),
#               commands/mlx-here.md (slash pointer)
#   Thinkspace: the .session.md — Esa's ask to stop "spinning our wheels" by
#               giving the stateless Mini brain the skill's knowledge, the way
#               Convey arms "What would Bearden say"
#   Areaspace : OWNS the Apple-skill arming (identity assembly + per-turn wiki
#               retrieval routing) and the folder-context snapshot. Does NOT own
#               the MLX/FM transport (fm-mlx / fm-submit) nor the retrieval engine
#               (convey.knows.retrieve) — it consumes both.
#
# RESULT
#   feature commit(s): <pending — same motion as the build>
#   PR: direct-push, no PR
#   files changed: bin/arm_apple.py (new), bin/fm-chat (+--apple),
#                  bin/mlx-here (new), bin/mlx-chat (symlink), commands/mlx-here.md (new),
#                  features/arm-apple-skill.feature (+ .session.md)
# =============================================================================

Feature: Arm the Apple skill into the Mini's on-device chat brain
  As Esa, standing in a repo folder, I want to chat with the Mini's MLX (or FM)
  LLM with the Apple skill's knowledge and my current folder already loaded, so I
  am not re-explaining the repo to a stateless model every turn — the same way
  Convey arms a roundtable persona with a corpus ("What would Bearden say").

  Background:
    Given the Mini runs the MLX server (Qwen3-4B) and the fm-worker (FoundationModels)
    And convey.knows.retrieve is importable for per-turn wiki retrieval
    And bin/arm_apple.py assembles identity + folder context + retrieval

  @built @hw-verified
  Scenario: mlx-here arms the skill from the current folder
    # MECHANISM: bin/mlx-here → fm-chat --mlx --apple --cwd "$PWD"
    Given I am in ~/work/apple
    When I run `mlx-here`
    Then the banner prints "🍎 Apple skill armed — apple context loaded · wiki retrieval ON"
    And the system instruction contains skill.md identity and the folder's CLAUDE.md
    And each question retrieves the few wiki/ pages most relevant to it

  @built @hw-verified
  Scenario: identity is set once, knowledge is retrieved per turn
    # MECHANISM: arm_apple.build_system() once; arm_apple.augment_prompt() each turn
    Given the chat is armed
    When I ask "how do I make a global keyboard shortcut that runs a script?"
    Then the prompt is prefixed with RELEVANT KNOWLEDGE drawn from wiki/concepts/*
    And NOT from the auto-generated wiki/INDEX.md or wiki/compiled/* catalogs

  @built @hw-verified
  Scenario: retrieval pulls real content, not the catalog
    # MECHANISM: arm_apple._CORPORA = concepts/entities/lessons/devices/operations
    Given a question about putting rich text on the clipboard
    When retrieve_context runs
    Then it returns passages from wiki/concepts/clipboard-rich-text.md (content)
    And the INDEX.md bullet lists do not crowd out the content pages

  @built
  Scenario: --apple works on the FoundationModels brain too
    # MECHANISM: mlx-here --fm → fm-chat --apple --cwd "$PWD" (no --mlx)
    Given I run `mlx-here --fm`
    Then the same identity + retrieval arming applies to the FM brain

  @built
  Scenario: graceful degrade when convey is absent
    # MECHANISM: arm_apple imports convey.knows.retrieve in a try/except
    Given convey.knows cannot be imported
    When the skill is armed
    Then identity + folder context still load
    And the banner says "identity only (convey not found → no retrieval)"
    And the chat still works without per-turn retrieval

  @built @hw-verified
  Scenario: the spoken reply uses Voicebox, not macOS say
    # MECHANISM: bin/voicebox-say (local Voicebox Kokoro/Heart) replaces say-karaoke
    # in BOTH fm-chat.speak_reply and fm-mlx's auto-speak.
    Given the Voicebox server is up and the speak switch is on
    When fm-chat (or fm-mlx) speaks a reply
    Then it synthesizes via POST /speak {profile:Heart, engine:kokoro} and plays the WAV
    And it does NOT use macOS `say` / say-karaoke (the "1980s robot" voice)
    And it stays silent if the server is down or ~/.config/voicebox/speak.state is off

  @built
  Scenario: voicebox-say integrates with the existing stop paths
    # MECHANISM: writes its afplay PID to /tmp/voicebox-speak.pid (the shared file)
    Given fm-chat is speaking a reply through voicebox-say
    Then /voiceboxstop and the ⇧⌥⌘. hotkey also stop it (same PID file as the Stop hook)

  @built @hw-verified
  Scenario: Ctrl-C never crashes the chat
    # MECHANISM: KeyboardInterrupt caught around ask/ask_mlx AND inside speak_reply
    Given a reply is being spoken, or the Mini is still "thinking"
    When I press Ctrl-C
    Then playback stops (voicebox-say terminated → afplay killed) OR the turn is cancelled
    And the chat returns to the `you ›` prompt without a traceback
    And a second Ctrl-C at the empty prompt exits cleanly with "bye."

  @built @hw-verified
  Scenario: armed chats answer live sensor/state questions
    # MECHANISM: bin/live_data.py routes a query to homepod-now (ambient climate)
    # and ~/work/comms/queue/machine-card-<host>.json (per-machine die temp, load,
    # memory, uptime, battery). augment_prompt() injects a LIVE DATA block first.
    Given the chat is armed
    When I ask "what is the temperature of the CloudcityMacMini you are running on?"
    Then a LIVE DATA block with the Mini's CPU die temp is injected into the prompt
    And the model answers with that number instead of "I have no sensor access"

  @built @hw-verified
  Scenario: live-data routing is precise
    Given bin/live_data.py
    When the query mentions humidity/room/climate
    Then it returns the HomePod ambient reading (homepod-now)
    When the query names a machine or says "you/running on"
    Then it returns that machine's card (the Mini for "you")
    When the query is not about live state
    Then it returns nothing (no spurious injection)

  @built @hw-verified
  Scenario: the spoken voice is the premium voice, not Eddy
    # MECHANISM: fm-chat.speak_reply + fm-mlx default to say-karaoke --voice "Zoe (Premium)"
    Given fm-chat or fm-mlx speaks a reply
    Then it uses say-karaoke (AVSpeechSynthesizer, per-word highlight)
    And the voice is "Zoe (Premium)" — the premium voice convey's roundtable uses
    And NOT Eddy (the `say` skill's friendly-robot default)
    And FM_MLX_VOICE / --voice can override it

  @built @hw-verified
  Scenario: the spoken reading can be stopped, paused, and resumed
    # MECHANISM: say-karaoke.swift writes /tmp/say-karaoke.pid and handles signals
    # via retained DispatchSource (SIGTERM/SIGINT=stop, SIGUSR1=pause⇄resume).
    # voicebox-stop also kills say-karaoke; speech-toggle sends SIGUSR1.
    # AppleToolbox: ⌃⌥⌘. (id 2) → voicebox-stop; ⌃⌥⌘, (id 8) → speech-toggle.
    Given fm-chat / fm-mlx is reading a reply aloud
    When I press ⌃⌥⌘. (the global stop)
    Then say-karaoke stops immediately and removes its PID file (interrupt)
    When instead I press ⌃⌥⌘, while it reads
    Then it pauses at the next word boundary and the process stays alive
    And pressing ⌃⌥⌘, again resumes from where it left off (continue later)

  @built @hw-verified
  Scenario: AppleToolbox's ~/bin helper symlink must exist
    # GOTCHA fixed live: ⌃⌥⌘, fired into the app (log: id=8 ~10×) but did nothing —
    # toggleSpeechGlobal runs $HOME/bin/speech-toggle, which wasn't symlinked (only
    # the repo copy existed), so the Process() silently failed. voicebox-stop worked
    # only because ITS ~/bin symlink existed.
    Given AppleToolbox shells out to $HOME/bin/<tool> for the global hotkeys
    Then topbar/build.sh links voicebox-stop + speech-toggle into ~/bin every build
    And a missing link no longer makes a hotkey fire into nothing

  @built @hw-verified
  Scenario: showing a reply is ONE shared call, never re-rolled (DRY)
    # MECHANISM: fm_render.present() bundles rich-markdown render + karaoke speech +
    # voice. fm-chat calls present(); fm-mlx calls `fm_render.py --present`. The
    # speak act used to be re-rolled per tool (the 9th-tool complaint) — now owned once.
    Given a tool needs to show a model reply
    When it calls present() / `fm_render.py --present`
    Then the reply renders as rich markdown (ANSI on a TTY) AND is spoken in Zoe (Premium)
    And no tool re-implements format_reply or wires its own say-karaoke/voicebox
    And the contract is documented in wiki/concepts/reply-presentation.md

  @observed
  Scenario: the controls act only on a live reading
    # Expected: when the spoken reply finishes, say-karaoke exits and removes its
    # PID file, so ⌃⌥⌘, / ⌃⌥⌘. then have nothing to act on. Not a bug — the demo
    # just ended. In fm-chat, every reply is controllable while it reads.
    Given a reply has finished being read aloud
    When I press ⌃⌥⌘, or ⌃⌥⌘.
    Then nothing happens, because there is no live speech to control

  @built
  Scenario: DispatchSource signal sources must be retained
    # GOTCHA fixed live: SIGTERM/SIGINT sources first created inside a for-loop
    # went out of scope → cancelled → SIG_IGN'd signal silently ignored → stop did
    # nothing. Fixed by binding termSrc/intSrc at top-level scope.
    Given say-karaoke installs its signal sources
    Then they are top-level lets, not loop locals, so they live for the process

  @observed
  Scenario: Qwen3-4B thinking mode is verbose
    # The MLX brain's reasoning can run 40s+ on a knowledge-heavy prompt; the
    # 180s fm-chat timeout covers it. Not a defect of the arming — inherent to the
    # model. FM brain (fm-submit) is the faster alternative for short asks.
    Given an armed MLX chat with a large knowledge prompt
    When I ask a substantive question
    Then the live timer may run tens of seconds before the reply lands
