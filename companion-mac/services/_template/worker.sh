#!/usr/bin/env bash
# worker.sh — generic inbox → process → outbox worker. Runs ON the companion.
# Implements the file-drop bridge contract:
#
#   1. local side drops a file into  $QUEUE_DIR/<svc>-inbox/   (Syncthing carries it over)
#   2. this worker claims it (moves it out of the inbox so it's processed once)
#   3. runs process_one (defined in service.conf) → writes result to <svc>-outbox/
#   4. moves the consumed input to <svc>-processed/
#   5. writes a heartbeat every loop so preflight.sh sees it's alive
#
# Launch from the boot-app pane (see pane.applescript.snippet) or detached:
#   nohup bash worker.sh > worker.stdout 2>&1 & disown

set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"

# Find the package root so we can reach lib/ and companion.conf.
PKG="$(cd "$here/../.." && pwd)"
. "$PKG/lib/common.sh"
load_config || exit 1

[ -f "$here/service.conf" ] || die "no service.conf in $here (copy service.conf.example)"
# shellcheck disable=SC1091
. "$here/service.conf"

: "${SERVICE_NAME:?set SERVICE_NAME in service.conf}"
INBOX="${INBOX:-$QUEUE_DIR/${SERVICE_NAME}-inbox}"
OUTBOX="${OUTBOX:-$QUEUE_DIR/${SERVICE_NAME}-outbox}"
PROCESSED="${PROCESSED:-$QUEUE_DIR/${SERVICE_NAME}-processed}"
POLL_INTERVAL="${POLL_INTERVAL:-5}"
HB="$PKG/lib/heartbeat.sh"

mkdir -p "$INBOX" "$OUTBOX" "$PROCESSED"
log "worker '$SERVICE_NAME' watching $INBOX (poll ${POLL_INTERVAL}s)"

while :; do
  for f in "$INBOX"/*; do
    [ -e "$f" ] || continue
    base="$(basename "$f")"
    case "$base" in .gitkeep|.*) continue ;; esac

    # Claim: move out of inbox first so a re-scan can't double-process it.
    claim="$PROCESSED/$base.processing"
    mv "$f" "$claim" 2>/dev/null || continue

    out="$OUTBOX/${base%.*}.out"
    if process_one "$claim" "$out"; then
      mv "$claim" "$PROCESSED/$base"
      log "done: $base → $(basename "$out")"
    else
      mv "$claim" "$PROCESSED/$base.failed"
      warn "failed: $base"
    fi
  done
  bash "$HB" "$SERVICE_NAME" ok "watching ${SERVICE_NAME}-inbox" 2>/dev/null || true
  sleep "$POLL_INTERVAL"
done
