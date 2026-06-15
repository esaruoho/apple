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
# RESULT (as of 2026-06-15)
#   Files     : apple/filee/Filee.swift, apple/filee/build.sh, apple/bin/filee (launcher).
#               Renamed from Boxes.* this session. Built: Filee.app (signed).
#   Delivery  : working tree, UNCOMMITTED (awaiting Esa's "commit"). apple repo.
#   Verified  : 820x600 window confirmed live via CGWindowListCopyWindowInfo +
#               screencapture -l <windowID>: ~/work/convey rendered as 85 file/folder
#               boxes (folders first, git repos badged "git repo · N items"), footer
#               "file → repo → skill → machine · same box, bigger noun". Arrow-key nav
#               verified: → moved the highlight from box 0 to box 1 (before/after shots).
#
# THE LADDER (same box primitive, bigger noun each rung)
#   rung 1  file   ← THIS CARD (@built @verified)
#   rung 2  folder ← THIS CARD (@built @verified — folders are boxes you enter)
#   rung 3  repo   (@built-partial — a .git folder gets BoxKind.repo + badge + "git repo"
#                   subtitle, verified on ~/work; the repo-INTERNAL commits/gates view is @todo)
#   rung 4  skill+memory (@designed — BoxKind.skill present; reader TODO)
#   rung 5  machine (@built ELSEWHERE — Fleet.app already renders peers-as-boxes)
#   edges   local↔online "connected data" (@designed — BoxItem.links field present, unused)
#   auto    smart-folder-that-conveys (@designed — see Filee.session.md "Finder-level")

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

  @designed @todo
  Scenario: A box carries local↔online edges ("convey the idea of connected data")
    Given a file that came from a known source (e.g. this video ← that YouTube)
    Then its box exposes BoxItem.links and renders an edge to the source
    # cite: Filee.swift BoxItem.links (field present, currently always empty)

  @designed @todo
  Scenario: A smart folder of filees gets conveyed automatically (Finder-level)
    Given a saved Spotlight/NSMetadataQuery predicate shown as a live grid of boxes
    When a new filee matches the query
    Then it appears as a box AND rides the convey belt (convey belt <file>) per its rule
    # The Finder-level target: a smart folder whose contents auto-convey. Reuses
    # convey's existing belt (0007/0049) + trustees (0029) — Filee is the visible surface.

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
