# Imported by convey from features/shell-toggles.feature on 2026-06-04.
# Ungraded scenarios were defaulted to @untested (honest — not a pass).
# Bind verify/steps.py to make scenarios runnable; until then they are UNRUN.

# ============================================================================
# REPORT CARD — Desktop / Dock visibility toggles
# ============================================================================
#
# WHAT THIS CARD SPAWNS
#   Codespace : bin/desktop-icons (Finder CreateDesktop), bin/dock-autohide
#               (com.apple.dock autohide), shared/intents.json (+2 intents),
#               bin/apple-do (+2 cases), shared/test-intent-routing.sh (+4 cases)
#   Thinkspace: this session (same transcript as the other AppleBar cards)
#   Areaspace : OWNS = toggling Desktop-icon and Dock visibility. MUST NOT TOUCH =
#               the Dock-item manager (bin/dock), Finder windows beyond the restart.
#
# WHY THIS CARD EXISTS
#   "desktop" / "dock" typed in AppleBar had no real capability. Add the two macOS
#   shell toggles people actually want from a command bar: hide Desktop icons, and
#   auto-hide the Dock. Demonstrates the DRY win — adding a capability is now just a
#   shared/intents.json entry + an apple-do case + a small tool; AppleBar's live
#   suggestions pick it up at next launch, no Swift change.
#
# REPORT-CARD LEGEND
#   @verified  passes shared/test-intent-routing.sh (headless)
#   @built     wired + runnable; not run in tests (restarts Finder/Dock — disruptive)
#
# RESULT
#   Direct-push to main, no PR. Files: bin/desktop-icons (new), bin/dock-autohide
#   (new), shared/intents.json (+desktop,+dock), bin/apple-do (+2 cases + caps),
#   shared/test-intent-routing.sh (+4 cases), this card.
# ============================================================================

Feature: Desktop & Dock visibility from the command bar

  @verified
  Scenario: "hide … desktop" and "hide the dock" route to their actions
    Given the catalog
    When I ask "hide all icons on desktop" / "clean up my desktop"
    Then it routes to `desktop`
    And "hide the dock" / "auto-hide the dock" route to `dock`
    # cite: shared/intents.json desktop+dock intents; test shared/test-intent-routing.sh

  @built
  Scenario: desktop hides (or shows) all Desktop icons
    When `apple-do desktop` runs (or "...show..." to reveal)
    Then `defaults write com.apple.finder CreateDesktop -bool false|true` + restart Finder,
      so the Desktop icons disappear (or come back)
    # cite: bin/desktop-icons (phrase → state, killall Finder)
    # not run in tests: killall Finder is disruptive mid-session — trigger from the bar

  @built
  Scenario: dock auto-hides (or stays shown)
    When `apple-do dock` runs (or "...show..." to keep it visible)
    Then `defaults write com.apple.dock autohide -bool true|false` + restart Dock
    # cite: bin/dock-autohide (phrase → state, killall Dock); distinct from bin/dock (item manager)
