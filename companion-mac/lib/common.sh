#!/usr/bin/env bash
# common.sh — shared helpers + config loading for the companion-mac fabric.
# Source this from every other script:  . "$(dirname "$0")/common.sh"
# Apple-native only: bash, ssh, git, osascript, nc, /usr/bin/python3 stdlib.

set -uo pipefail

# Package root = the dir that contains this lib/ folder.
COMPANION_PKG="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export COMPANION_PKG

log()  { printf '[companion] %s\n' "$*" >&2; }
warn() { printf '[companion] WARN: %s\n' "$*" >&2; }
die()  { printf '[companion] ERROR: %s\n' "$*" >&2; exit 1; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

# Load companion.conf. Falls back to the .example only to print guidance.
load_config() {
  local cfg="${COMPANION_CONF:-$COMPANION_PKG/companion.conf}"
  if [ ! -f "$cfg" ]; then
    warn "no companion.conf found at $cfg"
    warn "copy companion.conf.example → companion.conf and fill it in."
    return 1
  fi
  # shellcheck disable=SC1090
  . "$cfg"
  : "${COMPANION_HOST:?set COMPANION_HOST in companion.conf}"
  : "${QUEUE_DIR:?set QUEUE_DIR in companion.conf}"
  return 0
}

# Epoch helpers (BSD date / stat — macOS native).
now_epoch() { date +%s; }
file_mtime() { stat -f %m "$1" 2>/dev/null || echo 0; }

# Run a command on the companion over SSH, ALWAYS with the alias.
# Caller is responsible for absolute paths — SSH lands in ~, never a repo dir.
companion_ssh() {
  : "${COMPANION_SSH_ALIAS:?set COMPANION_SSH_ALIAS in companion.conf}"
  ssh -o ConnectTimeout=8 -o BatchMode=yes "$COMPANION_SSH_ALIAS" "$@"
}
