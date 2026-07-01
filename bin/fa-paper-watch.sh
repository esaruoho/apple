#!/usr/bin/env bash
# fa-paper-watch — keep the living papers folded into the wiki, zero-token, on every edit.
#
# Runs the fa-paper manifest watcher under a machine-wide single-instance lock so it is
# safe to run as a laptop background process NOW and as a Cloudcity-Boot iTerm pane LATER
# (same script, same lock, same manifest — the manifest paths live under /Users/esaruoho/work
# so they resolve identically on both machines once merlib-dump is synced to the Mini).
#
#   Laptop (now):   bash ~/work/apple/bin/fa-paper-watch.sh
#   Mini (later):   add as a systems.yaml pane running exactly this script.
set -u
MANIFEST="${FA_PAPER_MANIFEST:-/Users/esaruoho/work/apple/bin/fa-paper-watch-manifest.tsv}"
SI="/Users/esaruoho/work/comms/scripts/single-instance.sh"
if [ -f "$SI" ]; then
  # shellcheck disable=SC1090
  source "$SI" && single_instance fa-paper-watch
fi
exec python3 -u /Users/esaruoho/work/apple/bin/fa-paper --manifest "$MANIFEST"
