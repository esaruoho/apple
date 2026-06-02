#!/usr/bin/env bash
# build-minilm.sh — one-time build of the MiniLM CoreML model.
#
# Creates a python3.12 venv (torch has no 3.14 wheels), installs the build-time
# deps (coremltools + transformers + torch — used ONCE, never shipped), and runs
# bin/minilm-convert.py to produce models/minilm/MiniLM.mlpackage + vocab.txt.
# Heavy (multi-hundred-MB download); run it nohup'd and tail the log.
#
# Usage: bash bin/build-minilm.sh   (run on a machine with /opt/homebrew/bin/python3.12)
set -euo pipefail
APPLE="/Users/esaruoho/work/apple"
VENV="$APPLE/.minilm-venv"
OUT="$APPLE/models/minilm"
PY="/opt/homebrew/bin/python3.12"

echo "[build-minilm] $(date '+%T') python: $PY ($("$PY" --version 2>&1))"
mkdir -p "$OUT"
if [ ! -x "$VENV/bin/python" ]; then
    echo "[build-minilm] creating venv at $VENV"
    "$PY" -m venv "$VENV"
fi
echo "[build-minilm] upgrading pip"
"$VENV/bin/pip" install --quiet --upgrade pip
echo "[build-minilm] installing coremltools transformers torch (the big step) …"
"$VENV/bin/pip" install --quiet coremltools transformers torch
echo "[build-minilm] $(date '+%T') converting …"
"$VENV/bin/python" "$APPLE/bin/minilm-convert.py" "$OUT"
echo "[build-minilm] $(date '+%T') DONE"
ls -la "$OUT"
