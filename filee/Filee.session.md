# Boxes — spawning session (the cloud → waterdrop → seed)

Faithful, not flattering. This is the dialogue that drove the build, including the
long detour and the mistake that caused it.

## How to get back
- Transcript: `file:///Users/esaruoho/.claude/projects/-Users-esaruoho-work-convey/56d3f081-909f-4131-9be6-cfeada7532af.jsonl`
- Session id: `56d3f081-909f-4131-9be6-cfeada7532af`
- Resume: `claude --resume 56d3f081-909f-4131-9be6-cfeada7532af`
- Date: 2026-06-15, working dir `/Users/esaruoho/work/convey` (build target `~/work/apple/boxes`)

## The request (Esa, dictated, long-form)
"Use convey to convey the idea of a method of showing architectural wiring — the
graph/data-warehouse way of showing parents and children in connected node systems —
as a communication tool the MLX AI understanding can use. But the convey of it is
simple: I need to SEE something work, because that locks it down. Start with the
simplest possible thing: visualise what a folder's file system looks like. Boxes on a
screen. You boot up, you're in a folder, the files are boxes next to each other in a
grid, name underneath. Click to open, right-click for the whole widget. We're
re-inventing the GUI — but where WE define what a box is and what can be done to it,
Apple-natively. The moment we can show a file the best/simplest way, we can automate
what happens to it. Then it scales: file → repo (commits/gates) → skills + memory →
what the MLX reader looks at → the vault ('convey the idea of connected data') → link
local files to what's online (this video ← that YouTube). It starts with the file
system. Also: I'm at the workspace with a fleet — a 2015 MacBook Pro, an M2 Pro Mac
mini, an old Mac Pro, this laptop — and I need to visualise how they talk amongst
themselves."

## The waterdrop (distilled)
Two threads, one is the seed of the other:
- **Thread A (seed):** an Apple-native GUI rendering a folder's files as boxes. Own
  the "render a file as a box" primitive → own everything downstream.
- **Thread B (ladder):** same box primitive, bigger nouns — file → folder → repo →
  skills+memory → MLX-reader view → fleet (peers) → online edges.
Key constraint Esa stated: **must be SEEN to work.**

## Decisions
- Build a standalone **SwiftUI app** (Esa said "Apple natively" repeatedly), modelled
  on the proven Fleet.app idiom (`xcrun swiftc -O -parse-as-library … -framework
  SwiftUI -framework AppKit`, no Homebrew). NOT extend the existing web `convey serve`
  / `canvas`, which are Python HTTP surfaces.
- **Don't reinvent Thread B's top rung:** Fleet.app already renders peers-as-boxes.
  Boxes is deliberately the same idiom one rung lower. Honest symmetry, not duplication.
- Make `BoxItem.kind` generic (file/folder/repo/skill/machine) from line one, so the
  ladder is real in the code, not just promised in prose. Online edges = `BoxItem.links`
  (present, @designed, currently empty — not faked).

## The detour and the mistake (faithful)
After the app built and launched, `System Events ... count windows` reported **0
windows**, and full-screen screenshots showed only Esa's fullscreen chat app. I took
that at face value and spent a long sequence "fixing a no-window bug": deferred work
out of the `@StateObject` init into `boot()`/`.onAppear` (a real improvement, kept),
cleared saved window state, tested `open --args` vs bare-binary vs env-var launch,
compared signing identities and Info.plist shapes, and bisected via Mini/Mini2/Mini3
test apps. Every reading was `0` or flaky.

**Root cause: the measurement, not the app.** `System Events count windows` is
**focus-dependent** — it returned `1` right after launch (frontmost) and `0` once the
app was backgrounded, for windows that demonstrably existed. The screenshots were
landing on a different Space than where Boxes opened. The app had a real window the
whole time.

**The fix that ended it:** a focus-independent oracle —
`CGWindowListCopyWindowInfo([.optionAll], …)` filtered to the owner + layer 0 + size —
which immediately showed `Boxes win='Boxes' 820x600 layer=0`. Capturing that window by
its `kCGWindowNumber` via `screencapture -l <id>` produced the real screenshot: the
folder rendered as boxes. Lesson saved to memory.

## What shipped
Boxes.swift (generic BoxItem + FolderModel + LazyVGrid grid + double-click + context
menu + up/pick/hidden), build.sh (Fleet idiom), apple/bin/boxes launcher. Verified
live. Uncommitted pending Esa's word. See Boxes.feature for graded claims + RESULT.

## Open next rungs (Esa to steer)
- rung 3: open a repo box into a commits/gates/architecture view.
- edges: populate BoxItem.links (local↔online) — the vault / MLX-reader meeting point.
- packaging: a `/filee` skill (build+open) mirroring `/fleet`, if wanted.

---

## Turn 2 (2026-06-15) — rename to Filee + keyboard selection + Finder-level question

### Esa's request
"Boxes app should be renamed to **Filee.app**. Filee on suomeksi sekä kalan filee, että
'paljon tiedostoja'. cursor up/down/left/right do not highlight content. And: what is
the feasibility of getting to **Apple Finder.app level**, so we can run these things
automatically — like smart folders full of filees, which get conveyed?"

### Done
- **Rename** Boxes→Filee everywhere: dir `apple/boxes`→`apple/filee`, Boxes.swift→
  Filee.swift, build.sh, launcher `bin/boxes`→`bin/filee`, card + session. Bundle id
  `com.esaruoho.filee`, window title "Filee", fish header icon, footer "N filees".
  Kept BoxItem/BoxView/BoxKind as the generic *box* primitive (a "filee" is what sits
  in a box at rung 1) — boxes hold different nouns up the ladder.
- **Keyboard selection** (the "arrows don't highlight" fix): added `selection` to the
  model, accent-ring highlight on the selected box, first box selected on load, and
  ←→↑↓ movement + Return-to-open.

### The faithful part: a real implementation detour
First attempt used SwiftUI's idiomatic keyboard path — `.focusable()` + `.focused(
@FocusState)` + `.onMoveCommand` + a GeometryReader for column count + a hidden
`.keyboardShortcut(.defaultAction)` button. **The window stopped appearing.** I removed
GeometryReader/focusable — still no window. I nearly went down another long bisect.

Two findings ended it:
1. **The window WAS there** — `open Filee.app` showed `Filee 820x600` in CGWindowList.
   The "no window" reading came from launching the **bare Mach-O from a non-GUI shell**,
   which is flaky for window creation here. Lesson (again): launch via `open`; verify
   with CGWindowList, never AX `count windows`. Launcher switched to `open -n … --args`.
2. To avoid any risk from SwiftUI's focus machinery, keyboard nav now runs at the
   **AppKit layer**: `NSEvent.addLocalMonitorForEvents(.keyDown)` → `move`/`openSelected`,
   columns computed from the key window width. Robust, window unaffected.

Verified live: → moved the highlight box 0 → box 1 (before/after window-id captures).
Also visible: git-repo boxes render their connection badge + "git repo · N items".

### The Finder-level feasibility answer (recorded for the next rung)
Feasibility is **high**, because Filee is the *visible surface* and convey already owns
the *engine*. Finder-parity has three layers; we don't need all of Finder, only the
spine:
- **Browse** (done): list a folder as boxes, navigate, open, reveal. NSWorkspace +
  FileManager give us icons, Quick Look, default-app open for free.
- **Smart folders** (next, very doable): a Finder Smart Folder is a saved Spotlight
  query (`.savedSearch` = an `NSMetadataQuery`/`kMDItem…` predicate). Filee can run the
  same query and render results as live boxes — Apple-native, no new infra.
- **Auto-convey** (the payoff): each box already maps to a file; wire "a filee that
  enters this smart folder rides `convey belt <file>`" using convey's EXISTING belt
  (principles 0007/0049) + trustees (0029, the bounded watched-folder triggers). So
  "smart folder full of filees that get conveyed" = Filee(grid) + NSMetadataQuery(live
  membership) + convey-trustee(per-folder belt rule). No piece is missing; it's
  assembly. What we will NOT clone: Finder's file ops (move/copy/trash/rename), column/
  gallery chrome, tags UI — unless a rung needs them.

### Open next rungs (unchanged + sharpened)
- smart-folder rung: render an `NSMetadataQuery` predicate as a live box grid.
- auto-convey rung: attach a convey trustee/belt-rule to a (smart) folder.
- rung 3 interior: open a repo box into commits/gates.
- a `/filee` skill mirroring `/fleet`.

---

## Increments 2026-06-15/16 — bet end-to-end + four designed items + last three
## (ran from ~/work/h5i; same Filee codebase. The .feature card is the source of truth.)

1. **Connect the eye:** BoxItem.bonds decoded from <name>.molecule.json in makeBox(); ⋈N chip;
   "⋈ Bonds" submenu follows edges (goToBond). VERIFIED screenshot.
2. **Online edges:** convey molecule.py mark_from_url() + cli `molecule --from-url` → `references`
   bond (target = URL). Filee opens URL in browser. VERIFIED (research.txt youtube bond).
3. **Auto-convey (SAFE):** ⚡ arms .filee-autoconvey; load() delta → cheap quietConvey
   (molecule --json only; OCR/belt manual). VERIFIED LIVE: dropped file → sidecar in ~1s.
4. **Folder voice:** widget "Folder memory" build/show .memory.md + "Talk to folder" (mlx-here).
5. **Magic search-folder:** header query → NSMetadataQuery (Spotlight) scoped to folder → live
   grid via shared makeBox(); new matches self-appear; armed → auto-convey. VERIFIED: field
   renders (screenshot), Spotlight 22 hits for "molecule" in convey.
6. **Skill insides:** makeBox detects SKILL.md → BoxKind.skill "skill · <desc>"; "Show skill
   (insides)" = frontmatter + 📁/📄 layout. VERIFIED LIVE screenshot (~/.claude/skills).
7. **Fancier history:** showCommits = status+graph+churn+contributors(+h5i) via sh -c. VERIFIED
   live on convey.

Refactor: makeBox() is the single box-builder (listing + search share it).
Verified by screenshot/live: bonds, auto-convey, search field, skill boxes, history.
Code-verified (headless can't drive menus/fields across Spaces): url-row render, Bonds nav,
live search fill, skill-insides sheet, folder-memory/commits sheets.
Still @todo: a SAVED .savedSearch file; gates/architecture repo view; nested sub-skill expand.
Uncommitted: apple (Filee.swift/.feature/.session) + convey (molecule.py/cli.py).

## Increment 2026-06-16 (c) — the ARCHITECTURE repo view (Esa: "most important")

showArchitecture() — a repo box's "Show architecture (modules + wiring)" → sh -c over
git ls-files / git grep, language-agnostic, for ANY repo:
- composition (tracked files by extension)
- top-level modules (dir · count)
- entry points (main/index/app/cli/lib/__main__ across common langs)
- structural HUBS: unique module stems ranked by import-line references = the wiring backbone
  (boilerplate dropped: steps/__init__/conftest/…); the load-bearing modules everything hangs off
- orientation docs (README/atlas MAP/UNDERSTANDING/CLAUDE/AGENTS)
SAFE: anchored import regex + `grep -wFc` fixed-string whole-word counts (no catastrophic
backtracking, per the global rule), stems<3 skipped, bounded 2000 files, async off main thread.
VERIFIED 2026-06-16: exact logic on ~/work/convey → composition 2713 md/139 py; modules
analyses/principles/kb/convey; hubs fleet 17, graph 15, canvaslive, dynamic, yamlish, relay,
roster, principle (convey's real load-bearing modules). Built 564K.
@todo deeper: explicit module→module edge graph + a gates/health view (tests/CI).
Also re-demoed bonds live (full-screen shot): research.pdf/research.txt/dropped-note.txt wear
⋈ chips; notes.md + the .molecule.json files don't.
UNCOMMITTED: this increment (Filee.swift + Filee.feature + Filee.session).
