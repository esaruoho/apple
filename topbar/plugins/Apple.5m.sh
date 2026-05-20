#!/bin/bash
# SwiftBar plugin: Apple Toolbox — unified bar item.
# One icon in the menu bar combining:
#   - 🧰 click-to-run actions (Stop Voicebox, Empty Trash, etc.)
#   - 🌡 HomePod climate (temp + humidity)
#   - 🗂 Sal Soghoian archive recovery progress
#   - 🔋/⚡ Battery + power state
#
# Refresh every 5 min. Sub-sections that need finer cadence (Sal hourly) can be
# split back out later by dropping a new <Name>.<interval>.sh into this folder.

TB="$HOME/work/apple/topbar/scripts"
APPLE_DIR="$HOME/work/apple"

# ─────────────────────────────────────────────────────────────
# Climate — read last line of newest HomePod JSONL log
# ─────────────────────────────────────────────────────────────
LOG_DIR="$HOME/work/homepod-watcher/climate-logs"
LATEST=$(ls -1t "$LOG_DIR"/*.jsonl 2>/dev/null | head -1)
CLIMATE_LABEL=""
CLIMATE_BODY=""
if [ -n "$LATEST" ]; then
  LAST=$(tail -1 "$LATEST")
  TEMP=$(echo "$LAST" | /usr/bin/sed -n 's/.*"temperature_cal":[ ]*\([0-9.]*\).*/\1/p')
  HUM=$(echo "$LAST" | /usr/bin/sed -n 's/.*"humidity_cal":[ ]*\([0-9.]*\).*/\1/p')
  [ -z "$TEMP" ] && TEMP=$(echo "$LAST" | /usr/bin/sed -n 's/.*"temperature_c":[ ]*\([0-9.]*\).*/\1/p')
  [ -z "$HUM" ]  && HUM=$(echo "$LAST"  | /usr/bin/sed -n 's/.*"humidity_pct":[ ]*\([0-9.]*\).*/\1/p')
  TS=$(echo "$LAST" | /usr/bin/sed -n 's/.*"timestamp":[ ]*"\([^"]*\)".*/\1/p')
  if [ -n "$TEMP" ]; then
    TEMP_R=$(printf "%.1f" "$TEMP")
    HUM_R=$(printf "%.0f" "$HUM")
    CLIMATE_LABEL="${TEMP_R}° ${HUM_R}%"
    CLIMATE_BODY="${TS}|Temp ${TEMP_R}°C|Humidity ${HUM_R}%"
  fi
fi

# ─────────────────────────────────────────────────────────────
# Battery — pmset
# ─────────────────────────────────────────────────────────────
PMSET=$(/usr/bin/pmset -g batt)
PCT=$(echo "$PMSET" | /usr/bin/grep -o "[0-9]*%" | head -1)
STATE=$(echo "$PMSET" | /usr/bin/grep -oE "discharging|charging|charged|AC attached" | head -1)
TIMELEFT=$(echo "$PMSET" | /usr/bin/grep -oE "[0-9]+:[0-9]+ remaining" | head -1)
case "$STATE" in
  charging|charged|"AC attached") BATT_ICON="⚡" ;;
  *) BATT_ICON="🔋" ;;
esac
BATT_LABEL="${BATT_ICON}${PCT}"

# ─────────────────────────────────────────────────────────────
# Sal archive — refresh + parse current-status.md
# ─────────────────────────────────────────────────────────────
STATUS="$APPLE_DIR/analysis/sal/current-status.md"
/usr/bin/python3 "$APPLE_DIR/bin/sal-archive-status.py" --write "$STATUS" >/dev/null 2>&1
SAL_LABEL=""
SAL_REC=""; SAL_TOTAL=""; SAL_MISS=""
if [ -f "$STATUS" ]; then
  SAL_REC=$(/usr/bin/grep -m1 "recovered" "$STATUS" | /usr/bin/sed -n 's/.*`\([0-9]*\)`.*/\1/p')
  SAL_MISS=$(/usr/bin/grep -m1 "missing" "$STATUS" | /usr/bin/sed -n 's/.*`\([0-9]*\)`.*/\1/p')
  SAL_TOTAL=$(/usr/bin/grep "Download/media targets indexed" "$STATUS" | /usr/bin/sed -n 's/.*`\([0-9]*\)`.*/\1/p')
  [ -n "$SAL_REC" ] && SAL_LABEL="Sal ${SAL_REC}/${SAL_TOTAL}"
fi

# ─────────────────────────────────────────────────────────────
# Bar label — compact composite
# ─────────────────────────────────────────────────────────────
BAR="🧰"
[ -n "$CLIMATE_LABEL" ] && BAR="$BAR $CLIMATE_LABEL"
BAR="$BAR $BATT_LABEL"
[ -n "$SAL_LABEL" ]     && BAR="$BAR · $SAL_LABEL"

echo "$BAR"
echo "---"

# ─────────────────────────────────────────────────────────────
# Dropdown — status sections first, then action toolbox
# ─────────────────────────────────────────────────────────────

# Climate section
if [ -n "$CLIMATE_BODY" ]; then
  echo "🌡 HomePod Climate | font=Menlo size=11"
  IFS='|' read -r C_TS C_T C_H <<< "$CLIMATE_BODY"
  echo "-- ${C_T}"
  echo "-- ${C_H}"
  echo "-- Last reading: ${C_TS}"
  echo "-- 📊 Open climate graph | shell=\"/usr/bin/open\" param1=\"$HOME/work/apple/homepod/climate-graph.html\" terminal=false"
fi

# Battery section
echo "${BATT_ICON} Battery"
echo "-- ${PCT} · ${STATE}"
[ -n "$TIMELEFT" ] && echo "-- ${TIMELEFT}"
echo "-- 📊 apple-report (full Mac dump) | shell=\"$HOME/work/apple/bin/apple-report\" terminal=true"

# Sal archive section
if [ -n "$SAL_REC" ]; then
  echo "🗂 Sal Archive"
  echo "-- Recovered: ${SAL_REC} / ${SAL_TOTAL}"
  echo "-- Missing: ${SAL_MISS}"
  echo "-- 📄 Open status report | shell=\"/usr/bin/open\" param1=\"$STATUS\" terminal=false"
fi

echo "---"

# Toolbox quick actions
echo "🔇 Stop Voicebox | shell=\"/Users/esaruoho/bin/voicebox-stop\" terminal=false"
echo "🗑 Empty Trash | shell=\"/usr/bin/osascript\" param1=\"-e\" param2='tell application \"Finder\" to empty trash' terminal=false"
echo "👁 Hide Desktop Icons | shell=\"$TB/hide-desktop.sh\" terminal=false"
echo "👀 Show Desktop Icons | shell=\"$TB/show-desktop.sh\" terminal=false"

# Audio submenu
echo "Audio"
echo "-- 🔇 Mute | shell=\"/usr/bin/osascript\" param1=\"-e\" param2='set volume with output muted' terminal=false"
echo "-- 🔊 Unmute | shell=\"/usr/bin/osascript\" param1=\"-e\" param2='set volume without output muted' terminal=false"
echo "-- 🔉 Volume 25% | shell=\"/usr/bin/osascript\" param1=\"-e\" param2='set volume output volume 25' terminal=false"
echo "-- 🔉 Volume 50% | shell=\"/usr/bin/osascript\" param1=\"-e\" param2='set volume output volume 50' terminal=false"
echo "-- 🔊 Volume 75% | shell=\"/usr/bin/osascript\" param1=\"-e\" param2='set volume output volume 75' terminal=false"

# Finder submenu
echo "Finder"
echo "-- 💀 Kill Finder | shell=\"/usr/bin/killall\" param1=\"Finder\" terminal=false"
echo "-- 🫥 Show Hidden Files | shell=\"$TB/show-hidden.sh\" terminal=false"
echo "-- 🙈 Hide Hidden Files | shell=\"$TB/hide-hidden.sh\" terminal=false"
echo "-- 📋 Restart Menu Bar | shell=\"/usr/bin/killall\" param1=\"SystemUIServer\" terminal=false"

echo "---"
echo "Edit Toolbox… | shell=\"/usr/bin/open\" param1=\"-a\" param2=\"TextEdit\" param3=\"$HOME/work/apple/topbar/plugins/Apple.5m.sh\" terminal=false"
echo "🔄 Refresh now | refresh=true"
