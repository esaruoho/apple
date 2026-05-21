#!/usr/bin/env bash
# Four-checkpoint smoke test.

set +e
LABEL="com.esa.voicebox-worker"
echo
echo "=== Voicebox pipeline verification ==="
echo

# 1
printf "  [1] Voicebox listening on :17493     ... "
if curl -m 2 -fsS http://127.0.0.1:17493/health >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗  (launch Voicebox.app and wait for models to finish)"
fi

# 2
printf "  [2] LaunchAgent bootstrapped         ... "
if launchctl print "gui/$(id -u)/$LABEL" >/dev/null 2>&1; then
  echo "✓"
else
  echo "✗  (run 02-Install-LaunchAgent.command first)"
fi

# 3
HB="$HOME/work/comms/queue/voicebox-heartbeat.json"
printf "  [3] Worker heartbeat fresh           ... "
if [[ -f "$HB" ]]; then
  age=$(( $(date +%s) - $(stat -f %m "$HB") ))
  if [[ $age -lt 30 ]]; then
    echo "✓  (${age}s ago)"
  else
    echo "✗  (${age}s old — worker may be stuck)"
  fi
else
  echo "✗  (no heartbeat yet)"
fi

# 4
WAV="$HOME/work/comms/queue/voicebox-results/smoke-test-001.wav"
printf "  [4] Smoke-test WAV produced          ... "
if [[ -f "$WAV" ]]; then
  size=$(stat -f %z "$WAV")
  echo "✓  (${size} bytes)"
  echo
  echo "Playing smoke-test WAV ..."
  afplay "$WAV"
else
  echo "✗  (not yet — wait 10s and re-run if Voicebox just came up)"
fi

echo
echo "(close this Terminal window when done)"
