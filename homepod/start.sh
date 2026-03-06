#!/bin/bash
# start.sh — Start climate server + logger with git sync
# Usage: ./start.sh
# For Mac Mini: runs with GIT_AUTOCOMMIT=1 to auto-commit readings

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

export GIT_AUTOCOMMIT=1

# Pull latest changes on startup
if [[ -d "${SCRIPT_DIR}/.git" ]]; then
    echo "Pulling latest changes..."
    git -C "$SCRIPT_DIR" pull --rebase --autostash || true
fi

# Start climate server in background
echo "Starting climate server on port 3007..."
python3 "$SCRIPT_DIR/climate-server.py" &
SERVER_PID=$!

# Start climate logger (foreground — Ctrl+C stops everything)
echo "Starting climate logger (every 15 min, git autocommit enabled)..."
echo "---"

cleanup() {
    echo "Stopping..."
    kill $SERVER_PID 2>/dev/null
    exit 0
}
trap cleanup INT TERM

INTERVAL=900
while true; do
    bash "$SCRIPT_DIR/homepod-climate.sh" --nograph
    sleep $INTERVAL
done
