#!/usr/bin/env bash
# setup.sh — stand up the companion-mac fabric on THIS machine.
# Idempotent: safe to run repeatedly. Does the local-side wiring; the
# companion-side pieces (repo-puller, boot-app, workers) you deploy via
# Syncthing/git per the README.
#
# Usage:  setup.sh

set -uo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
. "$here/lib/common.sh"

echo "── companion-mac setup ───────────────────────────────"

# 1. Config must exist.
if [ ! -f "$here/companion.conf" ]; then
  cp "$here/companion.conf.example" "$here/companion.conf"
  echo "created companion.conf from the example."
  echo "→ edit $here/companion.conf (host, paths, SERVICES), then re-run setup.sh"
  exit 0
fi
load_config || exit 1
echo "config: host=$COMPANION_HOST  queue=$QUEUE_DIR"

# 2. Queue folders.
bash "$here/lib/queues.sh"

# 3. Sanity: is the companion reachable right now? (non-fatal)
if bash "$here/lib/preflight.sh" --quiet; then
  echo "preflight: companion is reachable."
else
  echo "preflight: companion not reachable yet (that's fine — set up Syncthing first)."
fi

cat <<EOF

next steps:
  • make sure $COMMS_DIR is a Syncthing folder shared with the companion.
  • deploy the puller on the companion:
      cp lib/repo-puller.sh repos.conf  →  companion  →  nohup bash repo-puller.sh &
  • build a service:  cp -R services/_template services/<name>  (see that README)
  • build the boot-app:  cd lib/boot-app && cp panes.conf.example panes.conf && ./build.sh
  • check status anytime:  bash lib/preflight.sh
EOF
