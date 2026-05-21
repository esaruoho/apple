#!/usr/bin/env python3
"""
apps-exporter — Clock, Weather, Stocks, Maps in one package.

These four Apple consumer apps each have a thin slice of personal data on
disk (the rest lives in CloudKit). Each on its own is too small to justify
a full exporter directory, so they're bundled here under one umbrella.

Subcommands (all read-only):
  status                summary line per app — what's there, what's empty
  clock                 World Clock cities + timers + alarms + stopwatches
  weather               saved locations + home/work + notification subs
  stocks                tracked tickers (mined from CloudKit bplist)
  maps                  navigation prefs + report-a-problem submissions
  export                run all four; write markdown into the vault
  --vault <path>        override destination (default: cc/vault/sources/)
  --json                emit JSON instead of markdown (status/per-app only)

Default vault target is ~/work/cc/vault/sources/<app>/<app>.md, joining the
existing 25 per-app vault sources (books, mail, photos, safari, …).
"""
from __future__ import annotations

import argparse
import base64
import json
import os
import plistlib
import re
import sys
from datetime import datetime
from pathlib import Path

HOME = Path.home()
DEFAULT_VAULT = HOME / "work/cc/vault/sources"

APPS = ("clock", "weather", "stocks", "maps")


# ── helpers ───────────────────────────────────────────────────────────────
def load_plist(path: Path):
    try:
        return plistlib.loads(path.read_bytes())
    except FileNotFoundError:
        return None
    except Exception as e:
        return {"_err": str(e)}


def frontmatter(source: str) -> str:
    return (
        f"---\nsource: {source}\nexporter: apps-exporter\n"
        f"extracted_at: {datetime.now().isoformat(timespec='seconds')}\n---\n\n"
    )


# ── CLOCK ─────────────────────────────────────────────────────────────────
def collect_clock() -> dict:
    mt = load_plist(HOME / "Library/Containers/com.apple.clock/Data/Library/Preferences/com.apple.mobiletimer.plist") or {}
    mtd = load_plist(HOME / "Library/Preferences/com.apple.mobiletimerd.plist") or {}

    cities = []
    for c in mt.get("cities", []):
        city = c.get("city", {})
        cities.append({
            "name": city.get("name"),
            "country": city.get("countryName"),
            "timezone": city.get("timeZone"),
            "latitude": city.get("latitude"),
            "longitude": city.get("longitude"),
        })

    def safe_iter(v):
        return v if isinstance(v, list) else []

    return {
        "cities": cities,
        "timers": safe_iter(mtd.get("MTTimers")),
        "alarms": safe_iter(mtd.get("MTAlarms")),
        "stopwatches": safe_iter(mtd.get("MTStopwatches")),
    }


def render_clock(d: dict) -> str:
    lines = ["# Clock\n"]
    cities = d["cities"]
    lines.append(f"## World Clock — {len(cities)} cities\n")
    if cities:
        lines.append("| City | Country | Time zone | Lat | Lon |")
        lines.append("|---|---|---|---|---|")
        for c in cities:
            lat = c["latitude"]
            lon = c["longitude"]
            lat_s = f"{lat:.4f}" if isinstance(lat, (int, float)) else str(lat)
            lon_s = f"{lon:.4f}" if isinstance(lon, (int, float)) else str(lon)
            lines.append(f"| {c['name']} | {c['country']} | `{c['timezone']}` | {lat_s} | {lon_s} |")
    lines.append(f"\n## Timers — {len(d['timers'])} ({'opaque NSKeyedArchiver' if d['timers'] else 'none'})")
    lines.append(f"## Alarms — {len(d['alarms'])}")
    lines.append(f"## Stopwatches — {len(d['stopwatches'])}")
    return "\n".join(lines) + "\n"


# ── WEATHER ───────────────────────────────────────────────────────────────
def collect_weather() -> dict:
    wp = load_plist(HOME / "Library/Group Containers/group.com.apple.weather/Library/Preferences/group.com.apple.weather.plist") or {}
    locations = []
    for c in wp.get("Cities", []):
        locations.append({
            "name": c.get("Name"),
            "title": c.get("CitySearchTitle", ""),
            "precise_name": c.get("PreciseName"),
            "latitude": c.get("Lat"),
            "longitude": c.get("Lon"),
            "timezone": c.get("TimeZone"),
        })
    loi_raw = wp.get("LocationsOfInterest")
    me_card = []
    if isinstance(loi_raw, bytes):
        try:
            j = json.loads(loi_raw)
            for x in j.get("locations", []):
                tkey = list(x.get("type", {}).keys() or ["unknown"])[0]
                me_card.append({
                    "type": tkey,
                    "address": x.get("fullAddress", "").replace("\n", " · "),
                    "name": x.get("location", {}).get("name"),
                    "latitude": x.get("location", {}).get("coordinate", {}).get("latitude"),
                    "longitude": x.get("location", {}).get("coordinate", {}).get("longitude"),
                })
        except Exception:
            pass
    return {
        "locations": locations,
        "me_card": me_card,
        "prefs_version": wp.get("PrefsVersion"),
        "last_updated": wp.get("LastUpdated"),
    }


def render_weather(d: dict) -> str:
    lines = ["# Weather\n"]
    lines.append(f"## Saved locations — {len(d['locations'])}\n")
    if d["locations"]:
        lines.append("| Name | Title | Lat | Lon | Time zone |")
        lines.append("|---|---|---|---|---|")
        for c in d["locations"]:
            lines.append(f"| {c['name']} | {c['title']} | {c['latitude']} | {c['longitude']} | `{c['timezone']}` |")
    lines.append(f"\n## Me-card locations — {len(d['me_card'])}")
    for m in d["me_card"]:
        lines.append(f"- **{m['type']}** — {m['address']}  ({m['latitude']}, {m['longitude']})")
    if d.get("last_updated"):
        lines.append(f"\n_last updated: {d['last_updated']}, prefs v{d.get('prefs_version')}_")
    return "\n".join(lines) + "\n"


# ── STOCKS ────────────────────────────────────────────────────────────────
def collect_stocks() -> dict:
    """Symbols are stored in CloudKit-encrypted bplist blobs inside a JSON
    dbstore. The wrapper is opaque, but each ticker is a length-prefixed
    ASCII string inside the blob — base64-decode each serverRecord and
    regex-mine the matches."""
    p = HOME / "Library/Group Containers/group.com.apple.stocks/Library/Documents/PrivateData/com.apple.stocks.private-production-dbstore.json"
    if not p.exists():
        return {"tickers": [], "zones": [], "last_sync": None}

    d = json.loads(p.read_text())
    zones = d.get("database", {}).get("zones", [])
    syms = set()
    last_sync = None
    for z in zones:
        if z.get("lastSyncDate"):
            last_sync = z["lastSyncDate"]
        for rec_b64 in z.get("serverRecords", []):
            try:
                raw = base64.b64decode(rec_b64)
            except Exception:
                continue
            for m in re.finditer(rb"\x6a[\x03-\x10]([A-Z0-9]{1,8}(?:-[A-Z]{3})?)", raw):
                sym = m.group(1).decode("ascii", errors="ignore")
                if sym.startswith("NS") or len(sym) < 2:
                    continue
                syms.add(sym)

    tickers = sorted(syms)
    return {
        "tickers": [{"symbol": s, "kind": "crypto" if "-" in s else "equity"} for s in tickers],
        "zones": [z["name"] for z in zones],
        "last_sync": last_sync,
    }


def render_stocks(d: dict) -> str:
    lines = ["# Stocks\n"]
    lines.append(f"## Tickers tracked — {len(d['tickers'])}\n")
    for t in d["tickers"]:
        lines.append(f"- `{t['symbol']}` ({t['kind']})")
    lines.append(f"\n## CloudKit\n")
    lines.append(f"- zones: {d['zones']}")
    lines.append(f"- last sync: {d['last_sync']}")
    return "\n".join(lines) + "\n"


# ── MAPS ──────────────────────────────────────────────────────────────────
def collect_maps() -> dict:
    cd = load_plist(HOME / "Library/Containers/com.apple.Maps/Data/Library/Preferences/com.apple.Maps.plist") or {}
    gd = load_plist(HOME / "Library/Group Containers/group.com.apple.Maps/Library/Preferences/group.com.apple.Maps.plist") or {}

    KEYS_CONTAINER = [
        "DistanceUnits", "HikingWelcomeScreenDisplayed",
        "NavigationVoiceGuidanceLevelCycling",
        "NavigationVoiceGuidanceLevelDriving",
        "NavigationVoiceGuidanceLevelWalking",
        "MapsNotificationAuthLastPromptedDate",
        "MapsNotificationAuthPromptCount",
        "MigratedNavigoAppPreferences",
        "DesiresTrafficKey",
        "NSWindow Frame MapMainWindow",
        "LastSuspendTime",
    ]

    settings = {k: cd.get(k) for k in KEYS_CONTAINER if cd.get(k) is not None}
    rap_ids = cd.get("RAPPreviouslySubmittedProblemIDs", []) or []
    rap_urls = cd.get("RAPPreviouslySubmittedProblemURLs", []) or []
    rap = [{"id": i, "url": u} for i, u in zip(rap_ids, rap_urls)]

    group_settings = {k: v for k, v in gd.items() if not k.startswith("_") and not isinstance(v, bytes)}
    last_camera_bytes = len(gd["MapsLastActivityCamera"]) if isinstance(gd.get("MapsLastActivityCamera"), bytes) else 0

    return {
        "settings": settings,
        "rap_submissions": rap,
        "group_settings": group_settings,
        "last_camera_blob_bytes": last_camera_bytes,
    }


def render_maps(d: dict) -> str:
    lines = ["# Maps\n", "## Settings (container)\n"]
    for k, v in d["settings"].items():
        lines.append(f"- **{k}**: `{v}`")
    lines.append(f"\n## Report-a-Problem — {len(d['rap_submissions'])} submission(s)\n")
    for r in d["rap_submissions"]:
        lines.append(f"- `{r['id']}` → {r['url']}")
    lines.append(f"\n## Settings (group container)\n")
    for k, v in sorted(d["group_settings"].items()):
        lines.append(f"- **{k}**: `{v}`")
    if d["last_camera_blob_bytes"]:
        lines.append(f"- **MapsLastActivityCamera**: {d['last_camera_blob_bytes']} bytes binary (last viewed map position)")
    return "\n".join(lines) + "\n"


# ── dispatch ──────────────────────────────────────────────────────────────
COLLECTORS = {"clock": collect_clock, "weather": collect_weather, "stocks": collect_stocks, "maps": collect_maps}
RENDERERS  = {"clock": render_clock,  "weather": render_weather,  "stocks": render_stocks,  "maps": render_maps}


def write_to_vault(app: str, body: str, vault: Path) -> Path:
    d = vault / app
    d.mkdir(parents=True, exist_ok=True)
    p = d / f"{app}.md"
    p.write_text(frontmatter(app) + body)
    return p


def cmd_app(args, app: str):
    data = COLLECTORS[app]()
    if args.json:
        print(json.dumps(data, indent=2, default=str))
        return 0
    print(RENDERERS[app](data))
    return 0


def cmd_status(args):
    rows = []
    for app in APPS:
        d = COLLECTORS[app]()
        if app == "clock":
            n, label = len(d["cities"]), "cities"
        elif app == "weather":
            n, label = len(d["locations"]) + len(d["me_card"]), "locations+homework"
        elif app == "stocks":
            n, label = len(d["tickers"]), "tickers"
        elif app == "maps":
            n, label = len(d["rap_submissions"]), "RAP submissions"
        rows.append((app, n, label))
    if args.json:
        print(json.dumps([{"app": a, "count": n, "label": l} for a, n, l in rows], indent=2))
        return 0
    for app, n, label in rows:
        print(f"  {app:<10} {n:>3} {label}")
    return 0


def cmd_export(args):
    vault = Path(os.path.expanduser(args.vault)) if args.vault else DEFAULT_VAULT
    print(f"vault: {vault}")
    for app in APPS:
        data = COLLECTORS[app]()
        body = RENDERERS[app](data)
        p = write_to_vault(app, body, vault)
        print(f"  wrote {p}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="apps-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)

    for app in APPS:
        sp = sub.add_parser(app, help=f"Dump {app} data")
        sp.add_argument("--json", action="store_true")
        sp.set_defaults(func=lambda a, _app=app: cmd_app(a, _app))

    sp = sub.add_parser("status", help="One-line summary per app")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_status)

    sp = sub.add_parser("export", help="Write all four into the vault")
    sp.add_argument("--vault", help="Override vault root (default: ~/work/cc/vault/sources)")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
