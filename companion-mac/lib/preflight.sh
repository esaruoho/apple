#!/usr/bin/env bash
# preflight.sh — "is the companion reachable?" without paying SSH cost.
# Reads Syncthing-mirrored heartbeats first (zero network when healthy);
# falls back to ONE short TCP probe on :22. Mirrors the cloudcity `mini-up`
# pattern, whitelabeled.
#
# Usage:
#   preflight.sh            # prints status, exits 0 if up
#   preflight.sh --quiet    # no output, just exit code
#   preflight.sh --ssh      # also verify SSH actually resolves+auths for THIS shell
#   preflight.sh --reap     # kill orphaned ssh/scp procs to the companion, then exit
#
# Exit 0 = reachable, 1 = not reachable.

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_config || exit 1

quiet=0; check_ssh=0; reap=0
for a in "$@"; do
  case "$a" in
    --quiet) quiet=1 ;;
    --ssh)   check_ssh=1 ;;
    --reap)  reap=1 ;;
  esac
done
say() { [ "$quiet" -eq 1 ] || printf '%s\n' "$*"; }

# --reap: clean up zombie ssh/scp to the companion (the "no zombie SSH" rule).
if [ "$reap" -eq 1 ]; then
  pat="ssh.*${COMPANION_SSH_ALIAS:-$COMPANION_HOST}\|scp.*${COMPANION_SSH_ALIAS:-$COMPANION_HOST}"
  pids="$(pgrep -f "$pat" 2>/dev/null || true)"
  if [ -n "$pids" ]; then
    say "reaping orphan ssh/scp: $pids"
    kill $pids 2>/dev/null || true
  else
    say "no orphan ssh/scp to ${COMPANION_HOST}"
  fi
  exit 0
fi

# 1. Heartbeat freshness — any *-heartbeat.json newer than HEARTBEAT_MAX_AGE.
fresh=0
if [ -d "$QUEUE_DIR" ]; then
  now="$(now_epoch)"
  max="${HEARTBEAT_MAX_AGE:-300}"
  for hb in "$QUEUE_DIR"/*-heartbeat.json; do
    [ -e "$hb" ] || continue
    age=$(( now - $(file_mtime "$hb") ))
    if [ "$age" -lt "$max" ]; then
      fresh=1
      say "up: $(basename "$hb") is ${age}s old (< ${max}s)"
      break
    fi
  done
fi

if [ "$fresh" -eq 0 ]; then
  # 2. Fallback: one short TCP probe on :22 (nc is Apple-shipped).
  if nc -z -G 5 "$COMPANION_HOST" 22 >/dev/null 2>&1; then
    say "up: tcp :22 reachable on $COMPANION_HOST (heartbeats stale)"
    fresh=1
  else
    say "down: no fresh heartbeat and tcp :22 unreachable on $COMPANION_HOST"
  fi
fi

[ "$fresh" -eq 1 ] || exit 1

# 3. Optional: confirm SSH actually works from THIS shell (mDNS/keychain can
#    fail even when the box is up). Two failures → stop, fall back to Syncthing.
if [ "$check_ssh" -eq 1 ]; then
  if companion_ssh true 2>/dev/null; then
    say "ssh: ok"
  else
    say "ssh: UNREACHABLE from this shell — use Syncthing channels, do not retry"
    exit 1
  fi
fi
exit 0
