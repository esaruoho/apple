#!/usr/bin/env bash
# queues.sh — scaffold the Syncthing-mirrored file-drop queue folders.
# Safe to re-run: it only ever creates missing folders + .gitkeep files.
#
# For each service N in SERVICES (companion.conf) it creates:
#   $QUEUE_DIR/N-inbox/       drop a job here  → companion's worker picks it up
#   $QUEUE_DIR/N-outbox/      worker writes the result here → syncs back to you
#   $QUEUE_DIR/N-processed/   worker moves consumed inputs here
#
# Usage:  queues.sh            (scaffold from SERVICES)
#         queues.sh foo bar    (scaffold these names instead)

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_config || exit 1

names=("$@")
if [ "${#names[@]}" -eq 0 ]; then
  names=("${SERVICES[@]:-}")
fi
[ "${#names[@]}" -gt 0 ] || die "no services to scaffold (set SERVICES in companion.conf or pass names)"

for n in "${names[@]}"; do
  [ -n "$n" ] || continue
  for sub in inbox outbox processed; do
    d="$QUEUE_DIR/${n}-${sub}"
    mkdir -p "$d"
    [ -f "$d/.gitkeep" ] || : > "$d/.gitkeep"
    log "queue ready: $d"
  done
done
