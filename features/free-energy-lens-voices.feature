# =============================================================================
# REPORT CARD: free-energy-lens-voices — one switch for Russell/Bearden/
#                                        Prigogine/Hilarion lens output
# Skin: AgentMail/free-energy replies + KeelyNet batch archive emails
# SESSION >> features/free-energy-lens-voices.session.md
#
# STATUS OF THIS CARD: authored from the 2026-07-21 request:
#   "isolate these as gherkin.features. i.e. if a user wants to get a response
#    by russell with a russell voice, then xyz. -> this way we can just flip a
#    switch and they are on for both situations."
#
# The rule is intentionally about a shared behaviour, not one script. The
# cloudcity-llm inbox and the KeelyNet mailer must read the same operator switch
# and interpret the same lens names.
#
# Switch:
#   FREE_ENERGY_LENS_VOICES=1   enable Russell/Bearden/Prigogine/Hilarion lens sections
#   FREE_ENERGY_LENS_VOICES=0   suppress the lens sections
#
# KeelyNet-compatible override:
#   KEELYNET_LENS_VOICES=1|0    overrides the global switch for the batch mailer
#
# Areaspace:
#   bin/freellmask-mail          inbound AgentMail / cloudcity-llm responder
#   bin/keelynet-energy-mailer   scheduled KeelyNet ENERGY digest mailer
#
# =============================================================================

Feature: Free-energy lens voices are a shared switch
  As the operator of Cloudcity's free-energy workflows
  I want Russell, Bearden, Prigogine, and Hilarion lens output to be controlled by one switch
  So that cloudcity-llm replies and KeelyNet batch emails can turn those voices on or off together

  Background:
    Given the shared switch is named `FREE_ENERGY_LENS_VOICES`
    And truthy values are `1`, `true`, `yes`, and `on`
    And falsey values are `0`, `false`, `no`, and `off`
    And the recognised lens names are `russell`, `bearden`, `prigogine`, and `hilarion`

  @built
  Scenario: cloudcity-llm includes lens voices for free-energy routed mail
    Given an inbound AgentMail message routes to the `free-energy` SpaceCard
    And `FREE_ENERGY_LENS_VOICES=1`
    When cloudcity-llm generates the reply
    Then the reply includes the normal answer
    And it includes sections for Walter Russell, Tom Bearden, Ilya Prigogine, and Hilarion
    And those sections are generated from the same source context as the answer

  @built
  Scenario: cloudcity-llm suppresses lens voices when the switch is off
    Given an inbound AgentMail message routes to the `free-energy` SpaceCard
    And `FREE_ENERGY_LENS_VOICES=0`
    When cloudcity-llm generates the reply
    Then the reply still uses the committed free-energy viewpoint
    But it does not require or emit Russell, Bearden, Prigogine, or Hilarion sections

  @built
  Scenario: KeelyNet batch emails can include the same lens voices
    Given the scheduled KeelyNet ENERGY mailer analyzes one archive file
    And `FREE_ENERGY_LENS_VOICES=1`
    When it builds the main prompt
    Then the main analysis includes a compact `Cross-Lens Reads` section
    And that section contains Russell, Bearden, Prigogine, and Hilarion lens reads
    And the lens reads do not repeat wrapper facts like `KeelyNet`, `ENERGY`, or `ASCII file`

  @built
  Scenario: KeelyNet can override the shared switch locally
    Given `FREE_ENERGY_LENS_VOICES=1`
    And `KEELYNET_LENS_VOICES=0`
    When the KeelyNet mailer builds the main prompt
    Then the KeelyNet email omits the lens reads
    But cloudcity-llm still follows the shared switch for inbound mail

  @built
  Scenario: a requested single lens maps to the same vocabulary
    Given a user asks for a response "by Russell" or "in Russell's voice"
    When the request is routed inside the free-energy space
    Then the selected lens is `russell`
    And the response uses Walter Russell's interpretive cadence without inventing facts
    And if a text-to-speech layer is used, it may select a matching voice profile by the same lens key

  @built
  Scenario: lens voice never weakens source fidelity
    Given a KeelyNet source file does not state a date, author, device result, or bibliographic locator
    When any lens voice comments on that file
    Then it must mark that detail as absent rather than inventing it
    And the lens may interpret the mechanism but must not fabricate measurements, demonstrations, or citations

  @built
  Scenario: off-topic mail does not summon the free-energy lens voices
    Given an inbound AgentMail message routes to `apple`, `admin`, `music`, `spirituality`, or `general`
    And `FREE_ENERGY_LENS_VOICES=1`
    When cloudcity-llm replies
    Then Russell, Bearden, Prigogine, and Hilarion sections are suppressed
    And the answer follows the routed space instead

