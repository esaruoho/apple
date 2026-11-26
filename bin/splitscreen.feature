# Report card: `cloudcity` = splitscreen 1 claude 2 cloudcity.sh   (bin/splitscreen, bin/cloudcity.sh)
Feature: Cloudcity dev split — claude on the left, the live BBS on the right

  @built @untested
  Scenario: splitscreen
    When I run "splitscreen 1 claude 2 cloudcity.sh" in iTerm
    Then claude runs in the current pane and cloudcity.sh in a vertical split, same cwd

  @built @sim-verified
  Scenario: cloudcity.sh boots the BBS
    Then it starts python3 server.py --port 8765 in ~/work/convey/projects/cloudcity
    And when :8765 answers, iTerm fills the screen and Safari covers the right half on the BBS page

  @built @untested
  Scenario: edits show up live
    Then a *.py change restarts the server and reloads Safari
    And a web/ change reloads Safari
    And a crashed server is restarted

  @built
  Scenario: always-on on the Mini (existing, not this script)
    Then Boot pane "Cloudcity BBS" runs comms/cloudcity-boot/start-cloudcity-bbs.sh (tailnet :8765)
    And pushing convey makes repo-puller kill 'server.py --port 8765' so the pane restarts on new code
