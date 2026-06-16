# FEATURE CARD — Filee
# The bottom rung of the convey ladder: a folder's files, rendered as boxes.
# "Filee" (Finnish): a fish fillet AND "lots of files".
#
# WHAT THIS CARD SPAWNS
#   Codespace : ~/work/apple/filee/{Filee.swift, build.sh, Filee.app} + ~/work/apple/bin/filee
#   Thinkspace: Filee.session.md (the cloud→waterdrop→seed conversation that drove this)
#   Areaspace : OWNS — rendering a folder as a grid of boxes, keyboard/mouse selection,
#               navigation, open/reveal. MUST NOT touch — the convey CLI, the Mini
#               factory, Fleet.app's peer logic.
#
# RESULT (as of 2026-06-16)
#   Files     : apple/filee/Filee.swift, apple/filee/build.sh, apple/bin/filee (launcher).
#               Built: Filee.app (signed, 456K). Convey side: convey/molecule.py mark_from_url()
#               + cli.py `molecule --from-url URL` (the online `references` bond).
#   Delivery  : working tree, UNCOMMITTED (awaiting Esa's "commit"). apple + convey repos.
#   Verified  : (orig) 820x600 window live; ~/work/convey as file/folder boxes; arrow-key nav.
#               (bonds) /tmp/filee-demo — research.pdf & research.txt wear "⋈ N" chips.
#               (auto-convey) LIVE through the running app 2026-06-16: dropped a file into an
#               armed folder → its .molecule.json appeared in ~1s (cheap molecule --json only).
#               (url-bond) convey molecule --from-url → `references` bond persisted + reloaded.
#               Render of url rows + folder-memory/commits sheets are code-verified (Spaces +
#               context-menu make headless screenshots unreliable; argv/data all verified).
#
# THE LADDER (same box primitive, bigger noun each rung)
#   rung 1  file   ← THIS CARD (@built @verified)
#   rung 2  folder ← THIS CARD (@built @verified — folders are boxes you enter)
#   rung 3  repo   (@built — BoxKind.repo + badge + "git repo" subtitle + "Show commits"
#                   widget (git log → sheet); richer commits/gates/architecture view still @todo)
#   rung 4  skill+memory (@built-seed — folder box "Folder memory" widget: build/show .memory.md
#                   + "Talk to this folder" (mlx-here in Terminal); BoxKind.skill reader still @todo)
#   rung 5  machine (@built ELSEWHERE — Fleet.app already renders peers-as-boxes)
#   edges   molecule bonds (@built @verified — load() decodes <name>.molecule.json → ⋈ chip +
#                   Bonds▸ submenu navigates target_path/opens URLs; LOCAL + ONLINE (references) edges)
#   auto    smart-folder-that-conveys (@built @verified — ⚡ arm → new files auto-get molecule --json,
#                   live-tested; OCR/belt stays manual. Saved-query smart folder still @todo)

Feature: A folder's files are boxes on a screen
  As Esa, conveying the half-baked idea that we should re-invent the GUI where WE
  define what a box is, so we can later automate what happens to each filee.
  The simplest possible thing that locks the idea down by being SEEN to work.

  @built @verified
  Scenario: Boot into a folder and see its filees as boxes
    Given Filee.app launched with a folder path
    # mechanism: script `filee <folder>` → open -n Filee.app --args <folder> (apple/bin/filee)
    When the window opens
    Then each file and folder is a box in an adaptive grid
    # cite: Filee.swift FileeView.body LazyVGrid(columns:) + ForEach(model.items)
    And each box shows the real Finder icon, the name, and a size/“N items” subtitle
    # cite: Filee.swift BoxView.body ; FolderModel.load() NSWorkspace.icon(forFile:)
    And folders sort before files, each alphabetical
    # cite: Filee.swift FolderModel.load() items.sorted{...}

  @built @verified
  Scenario: Arrow keys move a highlight across the grid; Return opens it
    Given a folder of boxes with the first box selected on load
    # cite: Filee.swift FolderModel.load() selection = items.first?.id
    When the ←/→/↑/↓ arrow keys are pressed
    # mechanism: AppKit NSEvent.addLocalMonitorForEvents(.keyDown) → FolderModel.move
    # cite: Filee.swift FolderModel.installKeyMonitor() + move(_:columns:)
    Then the accent-ring highlight moves to the neighbouring box (cols from window width)
    # cite: Filee.swift BoxView selected overlay/fill
    And pressing Return opens the highlighted box
    # cite: Filee.swift FolderModel.openSelected() (keyCode 36/76)
    # NOTE: SwiftUI .focusable()/.onMoveCommand()/@FocusState suppressed the window on
    # this macOS build → keyboard handled at the AppKit layer instead.

  @built @verified
  Scenario: A double-click or single-click selects/opens the box
    Given the grid of boxes
    When a box is single-clicked it becomes the selection; double-clicked it opens
    # cite: Filee.swift FileeView .onTapGesture(count: 2/1); FolderModel.enter(_:)
    Then a folder/repo box navigates into that folder; a file opens in its default app

  @built @verified
  Scenario: Right-click is "the whole widget"
    Given any box
    When it is right-clicked
    # cite: Filee.swift FileeView .contextMenu { widget(for: box) }
    Then a menu offers Open/Enter, Reveal in Finder, and Copy Path

  @built @verified
  Scenario: A git repo box is marked as connected (rung 3 seed)
    Given a folder that contains .git
    Then its box uses BoxKind.repo, shows a connection badge, and a "git repo" subtitle
    # cite: Filee.swift FolderModel.load() (.repo when .git exists); BoxView repo badge
    But a commits/gates/architecture view inside the repo is NOT yet built  # @todo

  @built @verified
  Scenario: A box carries molecule bonds as visible, navigable edges
    Given a file with a co-located <name>.molecule.json sidecar (written by `convey molecule`)
    When the folder loads
    # cite: Filee.swift FolderModel.load() decodes MoleculeSidecar beside each url → BoxItem.bonds
    Then the box wears a "⋈ N" count chip
    # cite: Filee.swift BoxView .overlay(alignment: .topTrailing) bonds chip
    # VERIFIED 2026-06-15: /tmp/filee-demo — research.pdf & research.txt show "⋈ 2"; notes.md none.
    #   screencapture -R of window 1 (CGWindowList nil from headless shell → System Events bounds).
    And right-clicking shows a "⋈ Bonds (N)" submenu, one row per bond
    # cite: Filee.swift widget(for:) Menu("⋈ Bonds …") ForEach(box.bonds)
    #   row label = arrow+kind+targetName: → produces / ← derived_from / ⊂ part_of / ↔ associated_with
    And selecting a bond walks into the bonded folder or reveals the bonded file
    # cite: Filee.swift FolderModel.goToBond(_:) ; dead targets greyed via Bond.exists
    But the submenu/navigation half is code-verified, NOT yet screenshot-verified  # @honesty
    # NOTE: BoxItem.links now derives from bonds' target paths (no longer always empty).

  @built @verified
  Scenario: A box carries an ONLINE edge to a URL (the local↔online half)
    Given a file's widget "Link to URL… (online edge)" → a URL
    # cite: Filee.swift FolderModel.linkURL() → convey molecule <file> --from-url <url>
    # cite: convey/molecule.py mark_from_url() writes a `references` bond, target_path = the URL
    When the folder reloads
    Then the box's "⋈ Bonds" submenu shows "↗ references · <host>" and selecting it opens the browser
    # cite: Filee.swift Bond.isURL / .arrow "↗" / goToBond() NSWorkspace.open(url)
    # VERIFIED 2026-06-15: convey molecule research.txt --from-url <youtube> → references bond in
    #   research.txt.molecule.json. Filee render+open is code-verified (context menu, hard to shoot).

  @built @verified
  Scenario: A smart folder conveys new files automatically as they land (Finder-level, SAFE)
    Given a folder armed for auto-convey (header ⚡ toggle writes .filee-autoconvey)
    # cite: Filee.swift FolderModel.toggleAutoConvey(); header bolt.fill/bolt.slash button
    When a NEW file lands in the watched folder
    # cite: Filee.swift load() delta (knownIds/knownIdsDir) → quietConvey() on genuinely-new files
    Then Filee auto-runs the CHEAP `convey molecule <file> --json` and its ⋈ chip appears
    # VERIFIED 2026-06-16 LIVE through the running app: dropped /tmp/filee-demo/dropped-note.txt
    #   → dropped-note.txt.molecule.json (part_of bond) created in ~1s, no screenshot needed.
    But ONLY molecule --json fires (writes a sidecar) — OCR / belt --run stay MANUAL  # no CPU/OCR burn
    # Loop-free: a conveyed file gains a sidecar → has bonds → no longer "fresh"; conveyingIds dedupes.
    # The full belt-per-rule (trustees 0029 + belt 0007/0049) auto-run is deliberately NOT wired
    #   (would risk local OCR/CPU); the visible-surface + cheap-molecule half is what's @built.

  @built @verified
  Scenario: A folder box can speak — folder-memory + talk (rung 4 seed)
    Given a folder/repo box widget "Folder memory" submenu
    # cite: Filee.swift widget(for:) Menu("Folder memory"); FolderModel.buildFolderMemory/showFolderMemory/talkToFolder
    Then "Build / refresh" runs ~/work/apple/bin/folder-memory <dir> (the .memory.{md,savedSearch,json} triad)
    And "Show .memory.md" opens it (building first if absent)
    And "Talk to this folder (Terminal)" opens Terminal in the dir running `mlx-here` (skill auto-armed)
    # VERIFIED 2026-06-16: folder-memory binary invocable; argv produces output.
    #   Sheet/Terminal display is code-verified (heavy embed run not triggered, to spare CPU).

  @built @verified
  Scenario: A repo box opens into its commits (rung 3 interior)
    Given a .git folder box (BoxKind.repo)
    When "Show commits (git log)" is chosen
    # cite: Filee.swift widget(for:) repo branch; FolderModel.showCommits() → git -C <repo> log --oneline --decorate -40
    Then the commit list renders in the ConveyOutputView sheet
    # VERIFIED 2026-06-16: argv produces real output on ~/work/convey. Sheet display reuses the
    #   verified ConveyOutputView path. The richer commits/gates/architecture view is still @todo.

  @built @verified
  Scenario: Do something with a filee, using convey (the widget runs convey verbs)
    Given a box's right-click widget
    When "convey molecule" / "convey ask…" / "convey belt (plan)" is chosen on a file,
         or "convey changed" on a folder
    # cite: Filee.swift FileeView.widget(for:); FolderModel.runConvey()/askConvey()
    Then Filee runs ~/work/apple/bin/convey <verb> <path> (async, cwd=~/work/convey)
    And shows the output in a ConveyOutputView sheet (spinner while running, selectable text)
    # cite: Filee.swift ConveyOutputView ; "convey ask…" prompts for the question via NSAlert
    # verified live: folder ~/work/apple/filee shown; `convey molecule Filee.swift` → its bonds
    # This is the Filee↔convey bridge: the folder is where you SEE files AND act on them.

  @built @verified
  Scenario: OCR a PDF from the widget and watch the result appear, live
    Given a PDF box and "convey belt — RUN ▶"
    When chosen
    # cite: Filee.swift widget(for:) → runConvey(["belt", path, "--run"])
    Then convey runs the belt for real: small PDF → Apple Vision (vision-ocr) on-device,
         large PDF → Cloudcity OCR worker (per media.filerule routing — never local tesseract)
    And the produced <stem>.txt (and .analysis.md / _ocr.pdf when the chain completes)
        appear as new boxes beside the source — LIVE, no manual refresh
    # cite: Filee.swift FolderModel.watchDir()/scheduleReload() (DispatchSource on the dir fd)
    # verified live: /tmp/ocrdemo scan.pdf → "belt --run" → scan.txt box appeared (1→2 filees)

  @stock
  Scenario: Built Apple-native, no Homebrew, no Xcode
    Given build.sh
    Then `xcrun swiftc -O -parse-as-library Filee.swift -framework SwiftUI -framework AppKit`
    # cite: apple/filee/build.sh ; same idiom as apple/fleet/build.sh

  # BACK-LINK: Filee.swift header carries `FEATURE-CARD >> ~/work/apple/filee/Filee.feature`
  # VERIFY NOTE: do NOT verify a window with System Events `count windows` — it is
  # focus-dependent and reads 0 for live windows. Use CGWindowListCopyWindowInfo +
  # screencapture -l <windowID>. Launch via `open`, not the bare binary from a shell.
