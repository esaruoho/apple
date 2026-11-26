#!/bin/bash
# Pane 2 of `cloudcity [topic]`: the Cloudcity BBS server, then the topic's page.
t="${1:-}"; CC=~/work/convey/projects/cloudcity
url=$(cloudcity-topic "$t" url)
if curl -sf -o /dev/null http://127.0.0.1:8765/; then
  echo "Cloudcity BBS already running on :8765"; open "$url"; exec bash -l
fi
( for i in $(seq 1 40); do curl -sf -o /dev/null http://127.0.0.1:8765/ && break; sleep 0.25; done; open "$url" ) &
cd "$CC" && exec ./start.command
