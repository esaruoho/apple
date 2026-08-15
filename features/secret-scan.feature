# ============================================================================
# REPORT CARD — secret-scan: the commit that leaks never happens
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/secret-scan, .secret-scan-allow, and the guard block at the top of
#               hooks/pre-commit.
#   Thinkspace: this card + the session it came from.
#   Areaspace : OWNS = refusing a commit that contains credential-shaped strings.
#               MUST NOT TOUCH = the working tree (it never edits, only refuses), and it
#               must never define its own patterns.
#
# WHY THIS CARD EXISTS
#   The tool built to hide a bank last-4 from a screencast shipped that exact last-4 in
#   its own --help output to a PUBLIC repo, together with the bank's name and a live
#   Stripe account id. It sat there until Esa asked "are Olga Ruoho / Nordea stuff leaking
#   to the redact?". Scrubbing and rewriting history fixed the past; only a hook fixes the
#   next one.
#
# REPORT-CARD LEGEND
#   @hw-verified  run live on this Mac; the claim was checked against real behaviour.
#   @note         a documented boundary.
#
# RESULT
#   Direct-push to main, no PR.
# ============================================================================

Feature: Refuse to commit an account id, bank last-4, key or token

  @hw-verified
  Scenario: it blocks the exact pair that leaked  (ran live 2026-08-16)
    Given a staged file containing the real masked last-4 and a live "acct_…" id
    When `git commit` ran
    Then the hook printed both hits with file:line and pattern name, and REFUSED
    And `git log` confirmed HEAD had not moved — nothing was committed
    # innards: bin/secret-scan `main()` + the guard block in hooks/pre-commit

  @hw-verified
  Scenario: the patterns are imported, never redefined  (2026-08-16)
    Given bin/recburn-redact already knows how to spot these things in a video frame
    When secret-scan starts
    Then it imports PATTERNS from that file via SourceFileLoader
    And a pattern added for the redactor is enforced by the hook for free
    # innards: `load_patterns()`
    # WHY: two copies of a secret regex drift, and the one that drifts is the one that
    #      stops catching things.

  @hw-verified
  Scenario: two of those patterns are wrong for a repo and are dropped  (measured 2026-08-16)
    Given the full 14-pattern set produced 150+ hits on a clean tree
    And they were almost entirely `email` — Esa's own published address, example.com
      samples, git@github.com — plus "icon_16x16@2x.png", which is not an email
    And `password-label` matched the string "Password:" in UI prompt text
    When those two are excluded
    Then a clean tree scans to exactly 0 hits in ~4 seconds
    # innards: `HOOK_EXCLUDE`
    # WHY THIS MATTERS MORE THAN IT LOOKS: a hook that blocks every commit is bypassed on
    #   day one and then protects nothing. Precision IS the feature.

  @hw-verified
  Scenario: deliberate examples can be kept  (2026-08-16)
    Given the cards legitimately document what a masked account looks like
    When a line carries `secret-scan: allow`, or its path is globbed in .secret-scan-allow
    Then that line is skipped
    And the four fake masked-digit examples in the docs are marked this way
    # innards: `ALLOW_MARK`, `allowed_paths()`

  @hw-verified
  Scenario: it reads what will be COMMITTED, not what is on disk  (2026-08-16)
    Given a staged version can differ from the working tree
    Then the scan uses `git show :<path>` for staged content
    # innards: `staged_text()`

  @note
  Boundary: it scans text, not history
    It stops the NEXT leak. Anything already committed needs a history rewrite — which is
    what was done for the bank last-4, the bank name, the Stripe id and the family name.

  @note
  Boundary: --no-verify still exists
    Deliberately. The point is to make leaking a decision rather than an accident.

  @note
  Boundary: the Sal archive is skipped
    sources/sal/* and indexes/sal-scripts.yaml are third-party transcripts and scraped
    scripts full of hashes and digit runs. Nothing of Esa's is authored there, and
    scanning them only produces noise.
