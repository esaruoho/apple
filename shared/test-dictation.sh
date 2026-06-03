#!/usr/bin/env bash
# Headless test of the shared OnDeviceDictation engine (shared/Dictation.swift).
# The executable half of features/dictation-button.feature — the mic-free scenarios.
# Runs on any Mac: no GUI, no microphone, no TCC prompt. Exit 0 = pass.
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mktemp -d)/dictation-test"
trap 'rm -rf "$(dirname "$OUT")"' EXIT
xcrun swiftc -O -target arm64-apple-macos11.0 \
  "$DIR/Dictation.swift" "$DIR/dictation-tests.swift" \
  -o "$OUT" \
  -framework Foundation -framework Speech -framework AVFoundation
"$OUT"
