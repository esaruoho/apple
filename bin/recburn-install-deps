#!/bin/bash
# REPORT-CARD >> features/recburn-whisper-deps.feature
# Install/check the Python dependencies used by the actual whisper executable.
set -euo pipefail
MODE="${1:-install}"
PIP_FLAGS=()
case "$MODE" in
  --check) ;;
  install) ;;
  --break-system-packages) PIP_FLAGS+=(--break-system-packages) ;;
  *) echo "Usage: $0 [--check|--break-system-packages]" >&2; exit 2 ;;
esac

resolve_python() {
  PYTHON="${RECBURN_PYTHON:-}"
  if [ -z "$PYTHON" ] && command -v whisper >/dev/null 2>&1; then
    local header
    IFS= read -r header < "$(command -v whisper)" || true
    header="${header#\#!}"
    # pip-generated console scripts have an absolute interpreter shebang.
    if [[ "$header" = /* && "$header" != *" "* && -x "$header" ]]; then
      PYTHON="$header"
    fi
  fi
  PYTHON="${PYTHON:-python3}"
  command -v "$PYTHON" >/dev/null 2>&1 || { echo "Python 3 not found." >&2; exit 1; }
}

check_whisper() {
  command -v ffmpeg >/dev/null 2>&1 || { echo "ffmpeg missing: brew install ffmpeg" >&2; exit 1; }
  command -v whisper >/dev/null 2>&1 || { echo "whisper missing: run this installer without --check." >&2; exit 1; }
  whisper --help >/dev/null
  "$PYTHON" - <<'PY'
import whisper  # Match the CLI import order (torch before Numba).
import numpy, numba, llvmlite
f = numba.njit(lambda x: x.sum())
assert f(numpy.array([1., 2., 3.])) == 6.
print(f"✓ Whisper import + JIT: NumPy {numpy.__version__}, Numba {numba.__version__}, llvmlite {llvmlite.__version__}")
PY
  echo "✓ whisper CLI and ffmpeg ready."
}

resolve_python
if [ "$MODE" != --check ]; then
  echo "==> Installing compatible Whisper dependencies with $PYTHON…"
  "$PYTHON" -m pip install --upgrade openai-whisper 'numba>=0.67,<0.68' 'numpy<2.6' "${PIP_FLAGS[@]}"
fi
check_whisper
