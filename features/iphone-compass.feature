# =============================================================================
# WIKI PAGE / REPORT CARD: iPhone Compass heading → the Mac command line
#
# WHAT THIS CARD SPAWNS:
#   codespace  — bin/compass (orchestrator), bin/compass.py (parser + math),
#                reuses bin/iphone-screen (CoreMediaIO frame) + bin/vision-ocr
#   thinkspace — iphone-compass.session.md (the conversation that produced it)
#   areaspace  — OWNS: reading a Compass screenshot and computing turn-to-East
#                MUST NOT TOUCH: iphone-screen/vision-ocr internals (stock deps)
#
# Report-card legend (grade tags, weakest -> strongest):
#   @designed @built @code-verified @build-verified @sim-verified
#   @runtime-verified @hw-verified   |   @untested @runtime-untested
#   @hw-untested @todo @partial   |   @stock (pre-existing, not ours)
#
# Innards linked back to this card (grep "iphone-compass"):
#   bin/compass          - read_once(): iphone-screen -> vision-ocr -> parser
#   bin/compass.py       - parse(): OCR text -> (degrees, cardinal)
#   bin/compass.py       - turn_to_east(): shortest rotation to 90°
#
# SESSION:      iphone-compass.session.md
# RESULT:       (pending commit)
#
# WATCH: compass turn_to_east iphone-screen
#
# RESULT-LOG >> (auto-maintained by the report-card hooks — newest below)
#   2026-10-16  direct-commit  touched: compass turn_to_east iphone-screen
# =============================================================================

Feature: Read the iPhone Compass onto the Mac and point out East
  As an automation user with a tethered iPhone, I want the phone's magnetic
  heading on my Mac terminal, So that I can tell which way is East without a
  magnetometer in the Mac and without writing a custom iOS app.

  # --- Why not the "obvious" direct route: documented as a negative claim ---
  @stock @runtime-verified
  Scenario: The Mac cannot read iPhone heading via CoreLocation
    # cite: tested in-session — CLLocationManager.headingAvailable() == false
    Given a Mac with no magnetometer
    When CLLocationManager.headingAvailable() is queried
    Then it returns false
    And no public Apple API tunnels iPhone CLHeading/CMHeadingData over USB
    And therefore the heading must come from the phone's SCREEN, not a sensor API

  @built @code-verified
  Scenario: Parse the heading from Compass OCR text
    # cite: bin/compass.py parse() — 11/11 selftest PASS in-session
    Given OCR text "237° SW" from the Compass app screen
    When bin/compass.py parses it
    Then it reports heading 237° with cardinal SW

  @built @code-verified
  Scenario: Compute the rotation to face East
    # cite: bin/compass.py turn_to_east() — selftest PASS (0/90/180/270/89/91)
    Given a heading of 237°
    When turn_to_east(237) is computed
    Then it returns -147 (turn 147° LEFT), because East is 90°
    And a heading of 90° returns 0 ("already pointing East")

  @built @hw-verified
  Scenario: Launch Compass on the phone from the Mac (no custom app)
    # cite: bin/compass open_compass() — devicectl launch, exit 0 in-session
    # CORRECTS the earlier claim that remote app launch was "NOT solved".
    Given a paired iPhone visible to `xcrun devicectl list devices`
    When the user runs `compass --open`
    Then `devicectl device process launch com.apple.compass` opens Compass
    And it works even when screen-capture is unavailable (launch != capture)

  @built @hw-untested
  Scenario: End-to-end live read from a tethered phone
    # cite: bin/compass read_once() — UNTESTED: no iPhone was connected in-session
    Given a tethered, unlocked, trusted iPhone with Compass open (large readout on)
    When the user runs `compass`
    Then bin/iphone-screen grabs a frame of the phone screen
    And bin/vision-ocr reads the degree readout
    And compass prints the heading and the turn-to-East instruction
    # GRADE HONESTY: this scenario has NOT been run against real hardware.
