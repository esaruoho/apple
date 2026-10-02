# WHAT THIS CARD SPAWNS
# Codespace: bin/recburn-install-deps; apple-rec/install-deps.sh (same installer).
# Thinkspace: recburn-whisper-deps.session.md; analysis/recburn-numpy-repair.md.
# Areaspace: Whisper dependency installation/checking; does not alter capture or mixing.
# SESSION: recburn-whisper-deps.session.md
# RESULT: Working tree update; delivery commits pending. No PR created.
# WATCH: resolve_python check_whisper
# RESULT-LOG >>
#   2026-10-02  direct-commit  touched: resolve_python check_whisper
Feature: Install and verify compatible Whisper dependencies
  @runtime-verified
  Scenario: Check the actual Whisper runtime without installing packages
    Given Whisper uses Homebrew Python 3.14 with NumPy 2.5.3 and Numba 0.67.0
    When the installer runs with --check
    Then Whisper CLI startup and Numba JIT compilation succeed
    And ffmpeg is present
    # cite: bin/recburn-install-deps resolve_python check_whisper

  @built
  Scenario: Install a compatible dependency family together
    Given subtitle dependencies need installation or repair
    When the installer runs without --check
    Then it installs openai-whisper with numba>=0.67,<0.68 and numpy<2.6
    And it checks the runtime before reporting success
    # cite: bin/recburn-install-deps pip install and check_whisper

  @runtime-verified
  Scenario: Real recording transcribes after dependency repair
    Given the user's saved 10.16-second flattened recording
    When Whisper small.en transcribes English with fp16 disabled
    Then transcription exits 0 and writes an SRT
    # cite: analysis/recburn-numpy-repair.md; temporary SRT in /private/tmp/recburn-numpy-check

  @runtime-verified
  Scenario: Subtitle burn-in exports the real recording
    Given a successful SRT from the user's saved recording
    When the Apple rec-subtitle binary burns subtitles with normal macOS framework access
    Then sample-subtitled.mov exports successfully
    # cite: bin/rec-subtitle.swift burn; /private/tmp/recburn-apple-check/sample-subtitled.mov
