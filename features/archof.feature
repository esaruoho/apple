# FEATURE CARD — archof
# The architecture of ANY git repo, whitelabeled. The reusable capability behind Filee's
# "Show architecture" — but callable from the terminal, a skill, or anything.
#
# WHAT THIS CARD SPAWNS
#   Codespace : ~/work/apple/bin/archof (standalone bash; git + awk + sh, no deps)
#   Thinkspace: this conversation — "create an architecture out of any repository, whitelabeled,
#               so we can see the architecture" (Esa, 2026-06-17). The report-card doctrine
#               applied to repos: one skeleton, repo-specific skin.
#   Areaspace : OWNS — extracting a repo's SHAPE (composition/modules/entry/hubs/wiring) +
#               emitting it as text or a durable ARCHITECTURE.md. MUST NOT touch — the repo's
#               contents (read-only except the one ARCHITECTURE.md it writes on --write).
#
# RESULT (as of 2026-06-17)
#   Files     : apple/bin/archof. Filee's FolderModel.showArchitecture()/writeArchitecture()
#               now DELEGATE to it (one source of truth) instead of an embedded sh script.
#   Delivery  : working tree, UNCOMMITTED. apple repo.
#   Verified  : ran live on TWO different-language repos —
#               · ~/work/convey (Python): hubs graph/fleet/relay; wiring cli→graph(11)/fleet(9)/molecule.
#               · ~/work/paketti (Renoise-Lua): composition 4358 wav/244 lua; main→~187 Paketti* (hub-spoke);
#                 cParseXML→slaxdom. Wrote paketti/ARCHITECTURE.md (130 lines, 1 mermaid diagram).
#   BACK-LINK : archof header carries `FEATURE-CARD >> ~/work/apple/features/archof.feature`.

Feature: The architecture of any repository, whitelabeled
  As Esa, wanting to point ONE tool at ANY repo and see its architecture in a consistent
  shape — the report-card doctrine (same skeleton, repo-specific skin) applied to codebases.

  @built @verified
  Scenario: Read a repo's shape, language-agnostic
    Given any git repository path
    When `archof <repo>` runs
    # cite: bin/archof render() — git ls-files / git grep over a broad language glob set
    Then it prints composition (files by type), top-level modules, entry points,
         structural hubs (most-imported modules), and the module→module wiring edges
    # VERIFIED 2026-06-17 on convey (Python) AND paketti (Lua) — both produced full, correct output.

  @built @verified
  Scenario: The wiring is drawn, not just listed (so you can SEE it)
    Given a repo with import-style dependencies
    When `archof <repo> --write` runs (or the "## The wiring, drawn" section renders)
    # cite: bin/archof mermaid() → ```mermaid graph LR``` with sanitised node ids + edge weights
    Then ARCHITECTURE.md contains a Mermaid graph that renders as a node-edge DIAGRAM in any
         markdown viewer (GitHub / Obsidian / VS Code) — zero dependencies, just text
    # VERIFIED 2026-06-17: paketti/ARCHITECTURE.md written, 1 mermaid block, main→Paketti* fan-out.

  @built @verified
  Scenario: Custom require-wrappers are understood (not just bare import)
    Given a repo that loads modules via a custom loader (e.g. Renoise-Lua `timed_require("X")`)
    # cite: bin/archof IMPORT_RE — `[A-Za-z_]*require` matches require/timed_require/lazy_require/…
    Then those loads count as edges too
    # VERIFIED 2026-06-17: paketti's 187 timed_require() calls became main→Paketti* edges
    #   (before broadening, only ~12 bare edges were seen — the fix lit up the real wiring).

  @built @verified
  Scenario: Safe and bounded (no laptop-cooking grep)
    Given a large repo
    Then archof uses ANCHORED import regex + `grep -wFc` FIXED-STRING whole-word counts (no
         catastrophic backtracking), skips module stems < 3 chars, bounds the hub scan to 2000
         files, and does NOT `set -e`/pipefail (grep-no-match exit 1 is normal for an analysis pass)
    # cite: bin/archof header NOTE + `set -u` only; the IMPORT_RE + grep -wFc choices.

  @built @verified
  Scenario: Reusable everywhere — one source of truth
    Given Filee's repo-box widget "Show architecture" / "Write ARCHITECTURE.md"
    # cite: Filee.swift FolderModel.showArchitecture()/writeArchitecture() → runProcess(archofBin, …)
    Then Filee shells out to the SAME archof binary the terminal uses — no duplicated logic
    # so improving archof improves every caller at once (the whitelabel).

  @stock
  Scenario: Apple-native, dependency-free
    Given bin/archof
    Then it uses only git + awk + sh — no Homebrew, no Python, no Graphviz
