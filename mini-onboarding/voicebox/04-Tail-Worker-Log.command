#!/usr/bin/env bash
# Live tail of the worker stdout. Ctrl-C to exit.
echo "tail -F ~/work/comms/queue/voicebox-worker.stdout"
echo "(Ctrl-C to stop)"
echo
exec tail -F "$HOME/work/comms/queue/voicebox-worker.stdout"
