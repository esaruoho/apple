# Report card for bin/notes-variants — born 2026-11-11 from the notes-process duplicate loop
# (see bin/notes-process commit c249c94b). Session: this Claude Code session, apple repo.
@built
Feature: notes-variants — N near-duplicate notes → MASTER consensus + branches

  @sim-verified
  Scenario: extract duplicates read-only from NoteStore.sqlite
    Given notes whose title starts with "Re: Nikola Tesla"
    When I run notes-variants --prefix 'Re: Nikola Tesla' --out analysis/notes-variants/tesla-radio
    Then 293 variants are written to variants/NNN.md oldest-first (2026-11-10 22:27 → 2026-11-11 01:49)
    And NoteStore.sqlite is opened mode=ro and Notes.app is never touched

  @sim-verified
  Scenario: meaning-level alignment via apple-embed (NLEmbedding), Jaccard fallback
    Then 925 claims are found (vs 1537 with token Jaccard only) in ~32 s
    And the quoted question above "────" is excluded from the claims

  @built
  Scenario: outputs
    Then MASTER.md holds claims with support >= --quorum, ordered by median position
    And BRANCHES.md lists 2..quorum-1 support claims, FAMILIES.md clusters variants, claims.json is the full claim×variant incidence

  @todo
  Scenario: slot-level branching tree
    Then claims sharing a sentence stem ("Tesla's views were rooted in…") are shown as one fork with weighted alternatives
  @todo
  Scenario: variant families are too fragmented (234 families of 293) — needs a lower --family-sim or embedding-level variant vectors

  @sim-verified
  Scenario: ask N times on purpose — #consensus tag
    Given a note line "my question #consensus"
    When the "Notes Consensus" Cloudcity-Boot pane runs notes-process --tag '#consensus' --samples 25
    Then notes-brain is asked 25 times and the answers are aligned by notes-variants.run()
    And the reply note holds the MASTER consensus with [k/N] support plus the folder of all answers
    # verified headless 2026-11-11: 4 samples via flubuild Qwen, ~4 s each, /usr/bin/python3 pure-Python cosine
  @untested
  Scenario: the pane end-to-end on the Mini (first real #consensus note)

  @sim-verified
  Scenario: hysteresis duplicates — 292 variants → 41 MASTER claims (analysis/notes-variants/hysteresis)
