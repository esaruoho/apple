# Report card — default-changer (bin/default-changer + default-changer/DefaultChanger.swift)
Feature: The default changer — per-extension default app via Launch Services

  @hw-verified
  Scenario: Show the current default for an extension
    When I run "default-changer md"
    Then it prints "net.daringfireball.markdown<TAB>com.sublimetext.4"

  @hw-verified
  Scenario: Flip markdown between Sublime Text and TextEdit
    When I run "default-changer md flip" twice
    Then the default goes Sublime Text -> TextEdit -> Sublime Text  # LSSetDefaultRoleHandlerForContentType, no dialog

  @built
  Scenario: Set any extension to any app by name or bundle id
    When I run "default-changer txt TextEdit"
    Then the app name is resolved via osascript "id of app" and set for role .all

  @hw-verified
  Scenario: List candidate handlers with the current one starred
    When I run "default-changer md list"

  @untested
  Scenario: Dynamic UTIs (extensions with no declared type) bind correctly
