#!/usr/bin/env bash
# Headless test of the chat's Markdown→HTML renderer (Markdown.swift).
# RULE: run this BEFORE changing rendering AND before claiming a render fix works.
# Pure Foundation — no GUI, no FoundationModels, no Mini. Runs on any Mac.
# Exit 0 = all pass; nonzero = a rendering bug (read the FAIL lines).
set -euo pipefail
DIR="$(cd "$(dirname "$0")" && pwd)"
OUT="$(mktemp -d)/md-test"
trap 'rm -rf "$(dirname "$OUT")"' EXIT
swiftc "$DIR/Markdown.swift" "$DIR/markdown-tests.swift" -o "$OUT"
"$OUT"
