# Report card: splitscreen + cloudcity topic boot  (bin/splitscreen, cloudcity-topic, cloudcity-claude, cloudcity.sh)
Feature: Boot Cloudcity straight into a simulation or topic
  `cloudcity [topic]` (function in ~/.bash_profile) = splitscreen 1 cloudcity-claude 2 cloudcity.sh

  @built @untested
  Scenario: splitscreen splits the current iTerm pane
    Given iTerm is the terminal
    When I run "splitscreen 1 <cmd> 2 <cmd>"
    Then pane 1 runs in place and pane 2 opens as a vertical split in the same cwd

  @built @sim-verified
  Scenario: topic resolution
    Then "cloudcity-topic bedini-ssg kind" is "sim" because ~/work/convey/buildloop/bedini-ssg exists
    And an unknown topic is "topic" and falls back to the BBS at :8765
    And topics.tsv rows (name, dir, url, prompt) override both

  @built @untested
  Scenario: cloudcity bedini-ssg
    Then pane 1 claude starts in the sim dir with a prompt to read its card and report state
    And pane 2 starts the BBS server (or reuses a running one) and opens the sim page
