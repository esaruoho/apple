# =============================================================================
# REPORT CARD: folder-memory — give a folder a voice (the per-folder sidecar triad)
# Skin: CLI tool (claim = a directory in → {.memory.md + .memory.savedSearch +
#       .memory.json} out, auto-formulated from the files' own metadata +
#       on-device embeddings, then talkable / diffable / vault-able / repo-able)
# Convention: ~/.claude/skills/report-card/SKILL.md
# SESSION >> features/folder-memory.session.md
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/folder-memory (the tool), commands/folder-memory.md (slash),
#               wiki/concepts/folder-memory.md (doctrine)
#   Thinkspace: the .session.md — Esa's ask: "drag smartfolders into obsidian,
#               file, convey, understanding … a folder we can talk to with a
#               model, and a diff … understand a github repository. We start with
#               the file. We make it smarter."
#   Areaspace : OWNS the folder→triad pipeline (enumerate → embed → cluster →
#               hub-rank → render → savedSearch). Does NOT own the embedder
#               (bin/apple-embed), the model transport (fm-mlx / fm-submit), the
#               tag stamping (bin/tag), or Spotlight — it consumes all of them.
#
# RESULT
#   feature commit(s): <pending — uncommitted; awaiting Esa's review/commit>
#   PR: <none yet — direct-push expected, no PR>
#   files changed: bin/folder-memory (new), commands/folder-memory.md (new),
#                  wiki/concepts/folder-memory.md (new doctrine),
#                  .gitignore (+ .memory.* / UNDERSTANDING.md),
#                  features/folder-memory.feature (+ .session.md)
# =============================================================================

Feature: Give a folder a voice — the per-folder sidecar triad
  As Esa, I want every folder (especially code) to carry an auto-formulated
  memory of itself — what it is, its load-bearing files, its subsystems — that
  Finder, Obsidian and the on-device model can all read, so a filesystem
  becomes navigable and talkable instead of opaque.

  Background:
    Given bin/apple-embed produces on-device 512-dim NLEmbedding vectors
    And the Mini exposes an MLX brain (fm-mlx --raw) and FoundationModels (fm-submit)
    And the target is a directory readable on this Mac

  @built @verified
  Scenario: Build the triad for one folder
    When I run `folder-memory <dir> --no-model`
    Then it writes <dir>/.memory.md, <dir>/.memory.savedSearch and <dir>/.memory.json
    And .memory.md lists the load-bearing (most-referenced) files
    And .memory.savedSearch is a valid plist scoped to <dir> querying the key files
    # verified 2026-06-15: github-watcher → repos.json ranked hub #1 (5 inbound)

  @built @verified
  Scenario: Auto-formulate the architecture with the on-device model
    Given a folder of code
    When I run `folder-memory <dir> --brain mlx`
    Then the model is given the cluster/hub/type structure (never raw dumps)
    And .memory.md opens with a 3-5 sentence architecture summary naming real files
    And no files absent from the inventory are invented
    # verified 2026-06-15: github-watcher summary correctly named repos.json as the
    # data hub, dashboard.html as frontend, prbuild.py/github-watcher.sh as pipeline

  @built @verified
  Scenario: Talk to the folder
    When I run `folder-memory <dir> --chat`
    Then .memory.md is loaded as the system context ("you ARE this folder's memory")
    And the model answers questions naming real files from the memory
    # verified 2026-06-15: "what serves the dashboard?" → "dashboard.html" (5.3s, MLX)

  @built @verified
  Scenario: Vibe diff across time
    Given a prior .memory.json snapshot
    When I run `folder-memory <dir> --diff`
    Then it reports added / removed / changed files and hub shifts deterministically
    And (with a model) narrates the ARCHITECTURAL meaning of the change
    # verified 2026-06-15: added gamma.md + changed alpha.md detected; model narrated

  @built @verified
  Scenario: Fold into an Obsidian vault
    When I run `folder-memory <dir> --recursive --vault <vaultdir>`
    Then each folder's .memory.md is copied into the vault mirroring the tree
    And links render as [[wikilinks]] so the Obsidian graph picks them up
    # verified 2026-06-15: /tmp/fm-tree → core/ ui/ root notes mirrored into vault

  @built @verified
  Scenario: Understand a whole repository
    When I run `folder-memory --repo <url|path>`
    Then it clones (if a URL), sidecars every folder, and writes UNDERSTANDING.md
    And UNDERSTANDING.md carries a model overview + a folder map linking each memory
    # verified 2026-06-15: local-path repo → UNDERSTANDING.md with navigable map

  @design @todo
  Scenario: Self-refresh on commit
    Given a pre-commit hook (zero-token auto-regen principle)
    When a folder's tracked contents change in a commit
    Then that folder's .memory.md is regenerated as part of the same commit
    # NOT BUILT — proposed; would keep the snapshot honest about "current"

  @known-limitation
  Scenario: Clustering of topically-homogeneous prose is weak
    Given a folder of near-identical prose (e.g. 87 Apple-automation wiki pages)
    When clustered with the light NLEmbedding model
    Then one large cluster dominates regardless of threshold
    And the HUB ranking + model summary carry the architecture instead
    # honest: embedding clusters are a SECONDARY signal; code folders separate well
