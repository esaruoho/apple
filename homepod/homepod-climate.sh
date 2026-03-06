#!/bin/bash
# homepod-climate.sh — Read HomePod temperature & humidity via Shortcuts CLI
# Appends timestamped JSON to a daily JSONL log file
# Updates current reading in environment/home-climate.md
# Regenerates climate-data.js for the graph to auto-load
#
# Requires: A Shortcut called "HomePod Sensors" in Shortcuts.app
#
# Usage:
#   homepod                               # single reading, log + update status + open graph
#   homepod --stdout                      # print to stdout only, don't log
#   homepod --dump                        # dump today's full log to stdout
#   homepod --nograph                     # log but don't open graph

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ENV_DIR="${SCRIPT_DIR}"
LOG_DIR="${ENV_DIR}/climate-logs"
STATUS_FILE="${ENV_DIR}/home-climate.md"
DATA_JS="${LOG_DIR}/climate-data.js"
TODAY=$(date +%Y-%m-%d)
LOG_FILE="${LOG_DIR}/${TODAY}.jsonl"

# Calibration offsets (measured Feb 13, 2026 against professional olosuhdemittaus sensor)
# HomePod reads 0.4-0.5°C low on temperature, 4-5% low on humidity
TEMP_OFFSET=0.45
HUMID_OFFSET=4.5

mkdir -p "$LOG_DIR"

# --- Git pull before reading (if autocommit enabled) ---
if [[ "${GIT_AUTOCOMMIT:-0}" == "1" ]] && [[ -d "${ENV_DIR}/.git" ]]; then
    git -C "$ENV_DIR" pull --rebase --autostash --quiet 2>/dev/null || true
fi

# --- Mode: dump today's log ---
if [[ "$1" == "--dump" ]]; then
    if [[ -f "$LOG_FILE" ]]; then
        cat "$LOG_FILE"
    else
        echo "No log for $TODAY yet."
    fi
    exit 0
fi

# --- Read from HomePod via Shortcut ---
RAW=$(shortcuts run "HomePod Sensors" | tee 2>/dev/null)

if [[ -z "$RAW" ]]; then
    echo "Error: No output from Shortcut 'HomePod Sensors'." >&2
    exit 1
fi

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
LOCAL_TIME=$(date +%H:%M)

# Parse "16, 23,2°C" format
HUMIDITY=$(echo "$RAW" | sed 's/,.*//')
TEMPERATURE=$(echo "$RAW" | sed 's/^[^,]*, //' | tr -d '°C' | tr ',' '.')

# Calculate calibrated values
TEMP_CAL=$(awk "BEGIN { printf \"%.2f\", $TEMPERATURE + $TEMP_OFFSET }")
HUMID_CAL=$(awk "BEGIN { printf \"%.1f\", $HUMIDITY + $HUMID_OFFSET }")

ENTRY="{\"timestamp\":\"${TIMESTAMP}\",\"temperature_c\":${TEMPERATURE},\"humidity_pct\":${HUMIDITY},\"temperature_cal\":${TEMP_CAL},\"humidity_cal\":${HUMID_CAL}}"

# --- Mode: stdout only ---
if [[ "$1" == "--stdout" ]]; then
    echo "$ENTRY"
    exit 0
fi

# --- Append to daily log ---
echo "$ENTRY" >> "$LOG_FILE"

# --- Generate JS data file for the graph ---
echo -n "window._climateData = [" > "$DATA_JS"
FIRST=true
while IFS= read -r line; do
    if [ "$FIRST" = true ]; then
        FIRST=false
    else
        echo -n "," >> "$DATA_JS"
    fi
    echo -n "$line" >> "$DATA_JS"
done < "$LOG_FILE"
echo "];" >> "$DATA_JS"

# --- Update current status file ---
cat > "$STATUS_FILE" << EOF
# Home Climate (Inkiväärikuja)

**Last reading:** ${TODAY} ${LOCAL_TIME}

| Metric | Raw (HomePod) | Calibrated | Offset |
|--------|---------------|------------|--------|
| Temperature | ${TEMPERATURE}°C | ${TEMP_CAL}°C | +${TEMP_OFFSET}°C |
| Humidity | ${HUMIDITY}% | ${HUMID_CAL}% | +${HUMID_OFFSET}% |

*Calibration: measured Feb 13, 2026 against professional olosuhdemittaus sensor*

Source: HomePod sensor via Shortcuts CLI

## Today's Log

\`climate-logs/${TODAY}.jsonl\`
EOF

echo "${LOCAL_TIME} — ${TEMPERATURE}°C → ${TEMP_CAL}°C (cal +${TEMP_OFFSET}) | ${HUMIDITY}% → ${HUMID_CAL}% (cal +${HUMID_OFFSET})"

# --- Git autocommit (if enabled) ---
if [[ "${GIT_AUTOCOMMIT:-0}" == "1" ]] && [[ -d "${ENV_DIR}/.git" ]]; then
    git -C "$ENV_DIR" add "climate-logs/${TODAY}.jsonl" 2>/dev/null
    git -C "$ENV_DIR" commit -m "climate: ${TODAY} ${LOCAL_TIME} — ${TEMP_CAL}°C ${HUMID_CAL}%" --quiet 2>/dev/null || true
    git -C "$ENV_DIR" push --quiet 2>/dev/null &
fi

# --- Ensure server is running, then open graph ---
if [[ "$1" != "--nograph" ]]; then
    if ! lsof -i :3007 &>/dev/null; then
        nohup python3 "${ENV_DIR}/climate-server.py" &>/dev/null &
        sleep 0.5
    fi
    open "http://localhost:3007/climate-graph.html"
fi
