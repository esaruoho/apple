#!/usr/bin/env bash
# heartbeat.sh — write a liveness heartbeat into the shared queue.
# A heartbeat is a tiny JSON file whose freshness (mtime) says "I'm alive".
# Any service the companion runs should drop one every N seconds; the local
# side reads them via preflight.sh without ever opening an SSH connection.
#
# Usage:
#   heartbeat.sh <name> [status] [detail]
# Writes:  $QUEUE_DIR/<name>-heartbeat.json   (overwritten each call)

. "$(dirname "${BASH_SOURCE[0]}")/common.sh"
load_config || exit 1

name="${1:?usage: heartbeat.sh <name> [status] [detail]}"
status="${2:-ok}"
detail="${3:-}"
ts="$(now_epoch)"

mkdir -p "$QUEUE_DIR"
out="$QUEUE_DIR/${name}-heartbeat.json"

# Build JSON with python stdlib so detail is escaped correctly.
/usr/bin/python3 - "$out" "$name" "$status" "$detail" "$ts" "$COMPANION_HOST" <<'PY'
import json, sys
out, name, status, detail, ts, host = sys.argv[1:7]
with open(out, "w") as f:
    json.dump({"name": name, "status": status, "detail": detail,
               "ts": int(ts), "host": host}, f)
    f.write("\n")
PY
