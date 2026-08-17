#!/bin/bash
# Build DualCam, and install it to a connected iPhone if one is attached.
set -euo pipefail
cd "$(dirname "$0")"

# Read the team from Xcode's own preferences instead of hardcoding one. A team id baked into
# the project is wrong the moment it is built on another machine or another account — and the
# error it produces ("No Account for Team XXXX") points at the account rather than at the
# hardcoded value, which sends you looking in the wrong place.
TEAM=$(python3 -c "
import plistlib, os, re
p = os.path.expanduser('~/Library/Preferences/com.apple.dt.Xcode.plist')
try:
    d = plistlib.load(open(p, 'rb'))
except Exception:
    d = {}
t = d.get('IDEProvisioningTeamManagerLastSelectedTeamID')
if not t:
    m = re.search(r'teamID = ([A-Z0-9]{10})', str(d))
    t = m.group(1) if m else ''
print(t)
" 2>/dev/null)
if [ -z "${TEAM:-}" ]; then
  TEAM=$(defaults read com.apple.dt.Xcode IDEProvisioningTeamManagerLastSelectedTeamID 2>/dev/null || true)
fi
[ -n "${TEAM:-}" ] || { echo "no Xcode team found — sign in: Xcode ▸ Settings ▸ Accounts"; exit 1; }
echo "==> team: $TEAM"

echo "==> building…"
# -allowProvisioningUpdates: automatic signing must be allowed to CREATE the profile the
# first time a bundle id is seen, otherwise it fails with "No profiles for ... were found"
# even though automatic signing is on.
xcodebuild -project DualCam.xcodeproj -scheme DualCam -sdk iphoneos \
  -configuration Release -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates DEVELOPMENT_TEAM="$TEAM" \
  -derivedDataPath build build 2>&1 | grep -E "error:|BUILD" || true

APP="build/Build/Products/Release-iphoneos/DualCam.app"
[ -d "$APP" ] || { echo "no app at $APP"; exit 1; }
echo "==> built: $APP"

# Install only if a device is actually connected — a rig gets plugged and unplugged, and this
# script should be safe to run either way.
# Parse JSON, not columns. The table's last field is the MODEL ("iPhone 16 Pro (iPhone17,1)"),
# not the identifier, so a $NF grab installs to a device that does not exist.
DEV=$(xcrun devicectl list devices --json-output /tmp/devicectl.json >/dev/null 2>&1 && python3 -c "
import json
try:
    d = json.load(open('/tmp/devicectl.json'))
except Exception:
    raise SystemExit
for dev in d.get('result', {}).get('devices', []):
    state = dev.get('connectionProperties', {}).get('tunnelState', '')
    paired = dev.get('connectionProperties', {}).get('pairingState', '')
    if state != 'unavailable' and paired == 'paired':
        print(dev.get('identifier', ''))
        break
" 2>/dev/null)
if [ -n "${DEV:-}" ]; then
  echo "==> installing to $DEV"
  xcrun devicectl device install app --device "$DEV" "$APP"
  echo "✓ installed — open DualCam on the phone, then: iphonemirror --rig"
else
  echo "• no iPhone connected; plug one in and re-run to install"
fi
