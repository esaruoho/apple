#!/usr/bin/env bash
# Headless test for MarkdownAttributed.swift — compile + run on the laptop (no GUI).
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
out="$(mktemp -d)/mdtest"
xcrun swiftc -O "$HERE/MarkdownAttributed.swift" "$HERE/markdown-attributed-tests.swift" \
  -o "$out" -framework Cocoa
"$out"
