#!/bin/bash
# climate-summary.sh — Summarize a day's climate readings
# Usage:
#   ./climate-summary.sh              # today
#   ./climate-summary.sh 2026-02-07   # specific date

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/climate-logs"
DATE="${1:-$(date +%Y-%m-%d)}"
LOG_FILE="${LOG_DIR}/${DATE}.jsonl"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "No climate data for $DATE"
    exit 1
fi

python3 -c "
import json, sys

readings = []
with open('$LOG_FILE') as f:
    for line in f:
        line = line.strip()
        if line:
            readings.append(json.loads(line))

if not readings:
    print('No readings found.')
    sys.exit(0)

temps = [r.get('temperature_c', r.get('temperature')) for r in readings if r.get('temperature_c') is not None or r.get('temperature') is not None]
humids = [r.get('humidity_pct', r.get('humidity')) for r in readings if r.get('humidity_pct') is not None or r.get('humidity') is not None]

print(f'Date: $DATE')
print(f'Readings: {len(readings)}')
print()
if temps:
    print(f'Temperature:')
    print(f'  Min:  {min(temps):.1f}°C')
    print(f'  Max:  {max(temps):.1f}°C')
    print(f'  Avg:  {sum(temps)/len(temps):.1f}°C')
print()
if humids:
    print(f'Humidity:')
    print(f'  Min:  {min(humids):.1f}%')
    print(f'  Max:  {max(humids):.1f}%')
    print(f'  Avg:  {sum(humids)/len(humids):.1f}%')
print()
print('All readings:')
for r in readings:
    ts = r.get('timestamp','?')
    t = r.get('temperature_c', r.get('temperature','?'))
    h = r.get('humidity_pct', r.get('humidity','?'))
    print(f'  {ts}  {t}°C  {h}%')
"
