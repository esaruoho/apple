#!/bin/bash
# cloudcity.sh — the RIGHT side of `cloudcity` (splitscreen 1 claude 2 cloudcity.sh).
#   1. starts the Cloudcity BBS (~/work/convey/projects/cloudcity) on 127.0.0.1:8765
#   2. once it answers, puts the Safari page on the right half of the screen
#      (iTerm keeps the left: claude)
#   3. watches the project: *.py change → restart server; web/ change → reload Safari.
#      So every edit claude makes shows up on the right.
# Mini (always-on) side is NOT this script: Boot pane "Cloudcity BBS" runs
# comms/cloudcity-boot/start-cloudcity-bbs.sh; deploy = push convey (puller restarts it).
CC=~/work/convey/projects/cloudcity; PORT=8765; URL="http://127.0.0.1:$PORT/"
cd "$CC" || exit 1
up() { curl -sf -o /dev/null "$URL"; }

tile() {  # iTerm fills the screen (claude left pane), Safari covers the right half
  osascript <<OSA >/dev/null 2>&1
tell application "Finder" to set b to bounds of window of desktop
set W to item 3 of b
set H to item 4 of b
set top to 25
tell application "iTerm2" to set bounds of front window to {0, top, W, H}
tell application "Safari"
  activate
  set found to false
  repeat with w in windows
    repeat with t in tabs of w
      if URL of t starts with "$URL" then
        set current tab of w to t
        set index of w to 1
        set found to true
        exit repeat
      end if
    end repeat
    if found then exit repeat
  end repeat
  if not found then make new document with properties {URL:"$URL"}
  set bounds of front window to {(W div 2), top, W, H}
end tell
tell application "iTerm2" to activate
OSA
}
reload() {
  osascript -e "tell application \"Safari\" to repeat with w in windows
repeat with t in tabs of w
if URL of t starts with \"$URL\" then set URL of t to (URL of t)
end repeat
end repeat" >/dev/null 2>&1
}
stamp() { find . \( -name '*.py' -o -path './web/*' \) -not -path './.data/*' -not -path '*/__pycache__/*' -type f -exec stat -f '%m %N' {} + 2>/dev/null | sort; }

PID=""
start() { python3 server.py --port $PORT & PID=$!; for i in $(seq 1 60); do up && return 0; sleep 0.25; done; echo "[cloudcity] server did not answer" >&2; }
stop() { [ -n "$PID" ] && kill "$PID" 2>/dev/null && wait "$PID" 2>/dev/null; PID=""; }
trap 'stop; exit 0' INT TERM

if up; then echo "[cloudcity] :$PORT already served elsewhere — watching + reloading only"; else start; fi
tile
echo "[cloudcity] $URL — edit away; py → restart, web → reload. Ctrl-C stops."
last=$(stamp)
while sleep 1; do
  [ -n "$PID" ] && ! kill -0 "$PID" 2>/dev/null && { echo "[cloudcity] server died → restart"; start; reload; }
  now=$(stamp); [ "$now" = "$last" ] && continue
  changed=$(diff <(echo "$last") <(echo "$now") | grep -F -e '.py' | head -1)
  last=$now
  if [ -n "$changed" ] && [ -n "$PID" ]; then echo "[cloudcity] python changed → restart"; stop; start; fi
  echo "[cloudcity] reload $(date +%T)"; reload
done
