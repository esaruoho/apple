# =============================================================================
# REPORT CARD: image-playground — Apple Image Playground as prose's visual twin
# Skin: API / pipeline (claim = prompt → on-device render → image artifact)
# Convention: ~/.claude/skills/report-card/SKILL.md · GHERKIN-FEATURE-WIKI-PATTERN.md
# SESSION >> features/image-playground.session.md  (the vibe diff that spawned this)
#
# Two units, one feature: (1) the `image-create` CLI, (2) the "Illustrate" path
# wired INTO FoundationModelsChat (Converse) so a reply's prose (FoundationModels)
# arrives with a picture (Image Playground) drawn from the same prompt.
#
# ── WHAT THIS CARD SPAWNS ───────────────────────────────────────────────────
#   Codespace : bin/image-create.swift (worker, builds into ImageCreate.app)
#               image-create/build.sh   (bundles the worker as a foreground .app)
#               bin/image-create        (bash wrapper: open -W + sidecar result;
#                                        also bin/create-image symlink)
#               ~/work/converse/main.swift  (PRIMARY in-app integration — ⌘2
#                                        Illustrate Selection + /image, inline
#                                        NSTextAttachment; this is the app Esa uses)
#               FoundationModelsChat/main.swift (earlier integration — Illustrate
#                                        toggle + /image + WebView data-URI render;
#                                        a DIFFERENT app, kept but not the target)
#   Thinkspace: features/image-playground.session.md
#   Areaspace : OWNS on-device image synthesis + inline display in Converse.
#               MUST NOT own: the prose model (fm.swift / fm-submit / the Mini),
#               nor the whiteboard pipeline (that is Gemini, ~/.claude/skills/whiteboard).
#
# ── THE LOAD-BEARING FINDING ────────────────────────────────────────────────
#   Apple's ImageCreator REFUSES to render from a background/headless process:
#   "Image creation is not available when the application is hidden or running in
#   the background." A bare CLI (activation policy .prohibited, no bundle id) is
#   always background to the WindowServer — even with .regular + activate + a
#   visible window + a full run loop, it still fails. ONLY a real foreground .app
#   bundle works. Hence: the CLI drives a bundled ImageCreate.app via `open -W`,
#   and inside Converse (already a foreground window) ImageCreator is called direct.
#
# ── report-card legend ──────────────────────────────────────────────────────
#   @built          - code exists on disk
#   @verified-live  - exercised end-to-end this session on this Mac (15.6.1)
#   @caveat         - works but has a known sharp edge
#   @untested       - path exists, not exercised here
#
# ── innards cited ───────────────────────────────────────────────────────────
#   bin/image-create.swift  --result-file freopen (early), GenDelegate (foreground
#                           window+run loop), styleFor, run(), writePNG, numbered
#   image-create/build.sh   ImageCreate.app bundle (Info.plist bundle id, 15.4 min)
#   bin/image-create        OUT detection, open -W --args, sidecar read-back
#   main.swift              toggleIllustrate / setIllustrateStyle / pngDataURI /
#                          illustrateFriendly / startIllustration / setImageBubble /
#                          makeIllustration (15.4) / imageCommand ; send() image
#                          placeholder-before-assistant ; render() image role ;
#                          buildMenu() Image menu ; export paths image role
#
# ── RESULT (third leg) ──────────────────────────────────────────────────────
#   Files added : bin/image-create.swift, bin/image-create (+create-image symlink),
#                 image-create/build.sh
#   Files changed: ~/work/converse/main.swift + build.sh  (PRIMARY: ⌘2 + /image),
#                 FoundationModelsChat/main.swift + build.sh (earlier, different app)
#   Verified-live 2026-06-07: CLI (tiger/owl/robot), stale-guard, retry, distill
#                 caveat, content-filter msg; Converse ⌘2 robot rendered inline + saved.
#   Commits     : (pending — not committed; user did not ask to commit)
#   Triad status: .feature = THIS · .session = features/image-playground.session.md · RESULT = here
# =============================================================================

Feature: image-playground — on-device pictures, locally, as the prose's twin
  As someone asking Apple's on-device models about the world,
  I want a picture drawn from the same prompt to arrive with the words,
  So that "what does a tiger look like?" gives me the tiger AND the prose.

  @built @verified-live
  Scenario: The CLI generates an image from a prompt
    # cite: bin/image-create (open -W ImageCreate.app, sidecar read-back)
    # cite: bin/image-create.swift GenDelegate (foreground window) + writePNG
    Given Apple Intelligence is enabled and the Image Playground model is present
    When the user runs: image-create "a tiger" -o /tmp/tiger.png -s illustration
    Then a PNG of a tiger is written to /tmp/tiger.png
    # verified-live 2026-06-07: 1.4-1.7 MB PNGs, illustration + sketch styles

  @built @verified-live
  Scenario: Bare prompt → derived filename, auto-open
    # cite: bin/image-create slugify + default-OUT + DO_OPEN default on
    When the user runs: image-create robot
    Then it writes robot.png in the cwd and opens it (suppress with --no-open)
    # verified-live 2026-06-07 ; `create-image` symlink also resolves

  @built @verified-live
  Scenario: A failed run never opens a stale same-named file
    # cite: bin/image-create success = grep -Fxq "$OUT" "$RESULT" (the app prints
    #       the path only on real success) — NOT an mtime check (1s granularity lied)
    Given a stale pussycat.png already exists
    When generation fails (content block or transient)
    Then exit 1, the stale file is untouched, and nothing is opened
    # verified-live 2026-06-07: 6-byte stale file unchanged, exit 1

  @built @verified-live
  Scenario: Transient "image creation failed" is retried, not surrendered
    # cite: bin/image-create.swift retry loop (default 8, --retries N) with backoff
    # cite: ~/work/converse makeIllustration retry (8) ; main.swift (FMChat) retry (8)
    Given the same prompt fails intermittently with Apple's vague error
    When image-create runs
    Then it retries up to 8× before giving up (a background error fails fast)
    # discovered 2026-06-07: same prompt gave FAIL/OK/FAIL across 3 runs — transient,
    # NOT a deterministic content block; 4 retries was sometimes too few, so 8

  @built @caveat
  Scenario: Image Playground distills — it does not honor detailed prompts
    # NOT a bug: Apple's on-device model is a concept-distiller, not a prompt-follower
    Given the prompt "a feral cat with whiskers made of gold and platinum that glow"
    When image-create renders it
    Then the result is a plain cat — material/lighting/compositional detail is dropped
    # verified-live 2026-06-07. For prompt fidelity use Gemini, not Image Playground.

  @built @verified-live
  Scenario: Illustrate Selection in Converse (⌘2) inserts a picture inline
    # cite: ~/work/converse main.swift illustrateSelection (⌘2) → startIllustration
    #       → insertInlineImage (NSTextAttachment append to NSTextStorage)
    # cite: ~/work/converse main.swift sendSelectionToFM intercepts "/image …" (⌘1)
    Given Converse is frontmost with a line "a friendly robot waving hello"
    When the user presses ⌘2 (or types "/image …" and presses ⌘1)
    Then an Image Playground picture renders inline AND is saved to
      sessions/<stamp>/images/<slug>-<span>.png
    # verified-live 2026-06-07: robot rendered inline; PNG saved to the session dir

  @built @verified-live
  Scenario: The image loop — every message in Converse also draws a picture
    # cite: ~/work/converse main.swift illustrateEveryMessage (default ON) +
    #       Engines ▸ "Illustrate Every Message" toggle
    # cite: hook 1 — sendSelectionToFM (⌘1 FM path) illustrates the selection
    # cite: hook 2 — askBrain (typed-Enter + voice chokepoint) illustrates the utterance
    Given the image loop is ON (default)
    When the user sends any message (⌘1, Enter, or voice)
    Then a picture is drawn from that message AND the model still answers in prose
    # verified-live 2026-06-07: "a vintage red bicycle leaning on a brick wall" →
    # bicycle rendered inline + FM-on-Mini prose, both in the same turn.
    # An explicit "/image …" draws only (no model call).

  @built @verified-live
  Scenario: A relative -o path lands in the user's cwd, not "/"
    # cite: bin/image-create abspath() — `open` gives the app cwd "/", so the
    #       wrapper absolutizes -o against $PWD before forwarding
    Given the user is in /tmp
    When the user runs: image-create "a tiger" -o tiger.png
    Then the file is written to /tmp/tiger.png
    # verified-live 2026-06-07 (regression: relative path failed with "cannot create PNG")

  @built @verified-live
  Scenario: Apple's content guardrail is explained, not echoed
    # cite: bin/image-create.swift run() catch → maps "creation failed" to a hint
    # cite: main.swift illustrateFriendly → same mapping for the in-app bubble
    Given a prompt containing a word the on-device filter blocks (e.g. "pussycat")
    When generation fails with Apple's vague "The image creation failed."
    Then the user is told it's the content filter and to rephrase, not just "failed"
    # verified-live 2026-06-07: "a cat" OK, "a pussycat" blocked, "a feral cat" OK —
    # isolated to the "pussy" substring; "feral" is fine

  @built @verified-live
  Scenario: A question phrase still yields the subject
    # cite: ImagePlaygroundConcept.text extracts the subject from a sentence
    When the user runs: image-create "what does a tiger look like" -o q.png
    Then the image is a tiger, not literal text
    # verified-live 2026-06-07

  @built @verified-live
  Scenario: --check reports availability and the styles this Mac supports
    # cite: bin/image-create.swift run() checkOnly branch (no window needed)
    When the user runs: image-create --check
    Then it prints "available" and: animation, illustration, sketch
    # verified-live 2026-06-07 on macOS 15.6.1

  @built @caveat
  Scenario: Headless generation is impossible by Apple's design
    # cite: THE LOAD-BEARING FINDING above
    Given no foreground app context (a plain CLI process)
    When ImageCreator.images(for:) is called
    Then it throws "not available when ... in the background"
    And the only fix is a real foreground .app bundle (what build.sh produces)
    # verified-live 2026-06-07: failed direct, failed with .regular+activate+window,
    # succeeded only inside ImageCreate.app via `open`

  @built @verified-live
  Scenario: /image draws a one-off picture inside Converse, no model call
    # cite: main.swift imageCommand + send() image-command branch
    # cite: main.swift render() image role injects <img data-uri> raw
    Given Converse is the foreground window
    When the user types "/image a majestic Bengal tiger" and presses Enter
    Then a tiger renders inline as an Image Playground bubble
    # verified-live 2026-06-07: rendered inline; user then drove it with their own
    # prompts ("a miniskirt", "a black cat") — three /image turns in the transcript

  @built @untested
  Scenario: Illustrate ON pairs every reply with a picture
    # cite: main.swift toggleIllustrate (⌘I) ; send() inserts the image bubble
    #       BEFORE the assistant bubble so updateLastBubble keeps targeting prose
    # cite: main.swift startIllustration runs concurrently with the prose stream
    Given the Image ▸ Illustrate Replies toggle is ON
    And FoundationModels is reachable (local macOS 26, or a configured bridge)
    When the user asks "what does a tiger look like?"
    Then prose streams from FoundationModels AND a tiger renders beside it
    # untested end-to-end: THIS Mac is macOS 15.6.1 (no local FM); the image half
    # is verified, the simultaneous prose+image needs the Mini/bridge to confirm

  @built @caveat
  Scenario: A picture can't be drawn while Converse is in the background
    # cite: main.swift illustrateFriendly maps the background error to guidance
    When Image Playground fails because the window isn't frontmost
    Then the image bubble shows "Bring this window to the front …"
    # same Apple limitation as the CLI; surfaced as a friendly bubble, not a crash

  @built @verified-live
  Scenario: Images embed without file-system access
    # cite: main.swift pngDataURI (CGImage → base64 data: URI)
    # cite: render() loads HTML with baseURL nil — file:// would be blocked
    Given the transcript WebView loads with baseURL nil
    When an image bubble renders
    Then the <img> uses a self-contained data: URI and displays
    # verified-live 2026-06-07: tiger displayed in-app
