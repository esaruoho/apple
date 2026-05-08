#!/usr/bin/env python3
"""image-capture-exporter — Image Capture surface via AVFoundation + system_profiler.

Image Capture has no AppleScript dictionary, no App Intents, no URL
scheme — Tier 5 dark. Two back-doors:
  - AVFoundation `AVCaptureDevice.DiscoverySession` for cameras (via Swift)
  - `system_profiler SPCameraDataType / SPUSBDataType` for connected
    iOS devices, scanners, USB cameras

Subcommands (all read-only by default):
  status        cameras + connected iOS devices + USB cameras counts
  cameras       list AVFoundation video devices (name, model, formats)
  ios-devices   list connected iOS/iPadOS devices via SPUSBDataType
  scanners      list connected scanners via SPSCSIDataType + USB filter
  prefs         read ~/Library/Preferences/com.apple.imagecapture.plist
  snap          ⚠ WRITE: capture one photo from a camera (--camera SELECTOR)
  export        full markdown vault dump

`snap` is the explicit write action (creates a new file). Other
subcommands are pure read-only.
"""

from __future__ import annotations

import argparse
import json
import os
import plistlib
import re
import subprocess
import sys
from dataclasses import dataclass, field
from datetime import datetime
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
SCRIPT_DIR = Path(__file__).resolve().parent
LIST_CAMERAS_SWIFT = SCRIPT_DIR / "list_cameras.swift"
TAKE_PHOTO_SWIFT = SCRIPT_DIR / "take_photo.swift"

IC_PLIST = Path(os.path.expanduser("~/Library/Preferences/com.apple.imagecapture.plist"))


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/image-capture"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


# =====================================================================
# Cameras via AVFoundation (Swift)
# =====================================================================

def list_cameras() -> list[dict]:
    proc = subprocess.run(
        ["/usr/bin/swift", str(LIST_CAMERAS_SWIFT)],
        capture_output=True, text=True, check=False, timeout=30,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr)
        return []
    try:
        return json.loads(proc.stdout)
    except json.JSONDecodeError:
        sys.stderr.write(f"could not parse swift output:\n{proc.stdout[:500]}\n")
        return []


# =====================================================================
# iOS / scanner / USB peripherals via system_profiler
# =====================================================================

def system_profiler(data_type: str) -> list[dict]:
    proc = subprocess.run(
        ["system_profiler", data_type, "-xml"],
        capture_output=True, check=False, timeout=30,
    )
    if proc.returncode != 0:
        return []
    try:
        d = plistlib.loads(proc.stdout)
    except Exception:
        return []
    if isinstance(d, list) and d and isinstance(d[0], dict):
        return d[0].get("_items") or []
    return []


def walk_usb(items: list[dict]) -> list[dict]:
    """Flatten the recursive USB tree into a single list."""
    out: list[dict] = []
    def visit(node: dict) -> None:
        for k in ("_items", "_children", "_subitems"):
            for c in node.get(k) or []:
                visit(c)
        out.append(node)
    for item in items:
        visit(item)
    return out


def list_ios_devices() -> list[dict]:
    items = walk_usb(system_profiler("SPUSBDataType"))
    out = []
    for d in items:
        manufacturer = d.get("manufacturer", "") or ""
        name = d.get("_name", "") or ""
        if "Apple Inc." in manufacturer and any(
            x in name.lower() for x in ("iphone", "ipad", "ipod", "apple watch")
        ):
            out.append({
                "name": name,
                "manufacturer": manufacturer,
                "serial_num": d.get("serial_num", ""),
                "vendor_id": d.get("vendor_id", ""),
                "product_id": d.get("product_id", ""),
                "speed": d.get("device_speed", ""),
            })
    return out


def list_scanners() -> list[dict]:
    """Scanners are tricky on macOS — try SPSCSIDataType + USB filter."""
    items = walk_usb(system_profiler("SPUSBDataType"))
    out = []
    for d in items:
        name = (d.get("_name") or "").lower()
        if "scan" in name or "scanner" in name:
            out.append({
                "name": d.get("_name", ""),
                "manufacturer": d.get("manufacturer", ""),
                "vendor_id": d.get("vendor_id", ""),
                "product_id": d.get("product_id", ""),
            })
    return out


# =====================================================================
# Image Capture preferences
# =====================================================================

def read_ic_prefs() -> dict:
    if not IC_PLIST.exists():
        return {}
    try:
        with open(IC_PLIST, "rb") as f:
            return plistlib.load(f) or {}
    except Exception as e:
        return {"_error": str(e)}


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    cams = list_cameras()
    ios = list_ios_devices()
    scanners = list_scanners()
    print("Image Capture overview")
    print(f"  Cameras (AVFoundation):  {len(cams)}")
    for c in cams:
        flags = ""
        if c.get("is_in_use_by_another_app"):
            flags = " [IN USE]"
        print(f"    - {c['name']}  ({c.get('model_id', '?')}){flags}")
    print(f"  iOS devices:             {len(ios)}")
    for d in ios:
        print(f"    - {d['name']}  ({d.get('serial_num', '?')[:8]})")
    print(f"  Scanners:                {len(scanners)}")
    for s in scanners:
        print(f"    - {s['name']}")
    return 0


def cmd_cameras(args) -> int:
    cams = list_cameras()
    if args.json:
        print(json.dumps(cams, indent=2, ensure_ascii=False))
        return 0
    for c in cams:
        flags = []
        if not c.get("is_connected", True): flags.append("disconnected")
        if c.get("is_in_use_by_another_app"): flags.append("in-use")
        flag_s = f" [{','.join(flags)}]" if flags else ""
        print(f"  {c['name']}{flag_s}")
        print(f"    unique_id     = {c.get('unique_id', '?')}")
        print(f"    model_id      = {c.get('model_id', '?')}")
        print(f"    device_type   = {c.get('device_type', '?')}")
        print(f"    manufacturer  = {c.get('manufacturer', '?')}")
        print(f"    formats       = {c.get('format_count', 0)}")
        for f in (c.get("formats_sample") or [])[:3]:
            print(f"      {f.get('width', 0)}×{f.get('height', 0)} "
                  f"@ {f.get('frame_rates', [{}])[0].get('max', 0)} fps max")
    print(f"\n{len(cams)} camera(s)")
    return 0


def cmd_ios_devices(args) -> int:
    devs = list_ios_devices()
    if args.json:
        print(json.dumps(devs, indent=2, ensure_ascii=False))
        return 0
    for d in devs:
        print(f"  {d['name']}")
        for k in ("manufacturer", "serial_num", "vendor_id", "product_id", "speed"):
            v = d.get(k, "")
            if v:
                print(f"    {k} = {v}")
    print(f"\n{len(devs)} iOS / iPadOS / Watch device(s)")
    return 0


def cmd_scanners(args) -> int:
    scs = list_scanners()
    if args.json:
        print(json.dumps(scs, indent=2, ensure_ascii=False))
        return 0
    for s in scs:
        print(f"  {s['name']}")
        for k in ("manufacturer", "vendor_id", "product_id"):
            v = s.get(k, "")
            if v:
                print(f"    {k} = {v}")
    print(f"\n{len(scs)} scanner(s)")
    return 0


def cmd_prefs(args) -> int:
    prefs = read_ic_prefs()
    if args.json:
        print(json.dumps(prefs, indent=2, ensure_ascii=False, default=str))
        return 0
    if not prefs:
        print(f"(no preferences found at {IC_PLIST})")
        return 0
    for k, v in sorted(prefs.items()):
        if isinstance(v, (bytes, bytearray)):
            print(f"  {k} = <{len(v)} bytes>")
        elif isinstance(v, (dict, list)):
            print(f"  {k} = {json.dumps(v, default=str)[:200]}")
        else:
            print(f"  {k} = {v}")
    return 0


def cmd_snap(args) -> int:
    cams = list_cameras()
    if not cams:
        print("No cameras found.", file=sys.stderr)
        return 1
    sel = args.camera
    out_path = args.out or os.path.expanduser(
        f"~/work/apple/exported/image-capture/snaps/"
        f"{datetime.now().strftime('%Y-%m-%d__%H%M%S')}.jpg"
    )
    Path(out_path).parent.mkdir(parents=True, exist_ok=True)
    swift_args = ["/usr/bin/swift", str(TAKE_PHOTO_SWIFT), out_path]
    if sel:
        swift_args.append(sel)
    proc = subprocess.run(swift_args, capture_output=True, text=True, timeout=15)
    print(proc.stdout, end="")
    if proc.returncode != 0:
        print(proc.stderr, file=sys.stderr, end="")
    return proc.returncode


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)
    cams = list_cameras()
    ios = list_ios_devices()
    scanners = list_scanners()
    prefs = read_ic_prefs()
    stamp = datetime.now().isoformat(timespec="seconds")

    cam_lines = ["---", f'kind: "cameras"', f'generated: "{stamp}"',
                 f'count: {len(cams)}', "---", "", "# Cameras", ""]
    for c in cams:
        cam_lines.append(f"## {c['name']}")
        cam_lines.append("")
        cam_lines.append(f"- model_id: `{c.get('model_id', '?')}`")
        cam_lines.append(f"- unique_id: `{c.get('unique_id', '?')}`")
        cam_lines.append(f"- device_type: `{c.get('device_type', '?')}`")
        cam_lines.append(f"- manufacturer: `{c.get('manufacturer', '?')}`")
        cam_lines.append(f"- format count: {c.get('format_count', 0)}")
        cam_lines.append("")
    write_md(vault / "cameras.md", "\n".join(cam_lines))

    ios_lines = ["---", f'kind: "ios-devices"', f'generated: "{stamp}"',
                 f'count: {len(ios)}', "---", "", "# iOS / iPadOS / Watch Devices", ""]
    for d in ios:
        ios_lines.append(f"## {d['name']}")
        for k in ("manufacturer", "serial_num", "vendor_id", "product_id", "speed"):
            v = d.get(k, "")
            if v:
                ios_lines.append(f"- {k}: `{v}`")
        ios_lines.append("")
    write_md(vault / "ios-devices.md", "\n".join(ios_lines))

    sc_lines = ["---", f'kind: "scanners"', f'generated: "{stamp}"',
                f'count: {len(scanners)}', "---", "", "# Scanners", ""]
    for s in scanners:
        sc_lines.append(f"## {s['name']}")
        for k in ("manufacturer", "vendor_id", "product_id"):
            v = s.get(k, "")
            if v:
                sc_lines.append(f"- {k}: `{v}`")
        sc_lines.append("")
    write_md(vault / "scanners.md", "\n".join(sc_lines))

    pref_lines = ["---", f'kind: "preferences"', f'generated: "{stamp}"',
                  "---", "", "# Image Capture Preferences", "",
                  f"Source: `{IC_PLIST}`", ""]
    for k, v in sorted(prefs.items()):
        if isinstance(v, (bytes, bytearray)):
            pref_lines.append(f"- **{k}**: `<{len(v)} bytes>`")
        else:
            pref_lines.append(f"- **{k}**: `{v}`")
    write_md(vault / "preferences.md", "\n".join(pref_lines))

    index = ["# Image Capture Vault", "", f"Generated {stamp}.", "",
             f"- [Cameras](./cameras.md) ({len(cams)})",
             f"- [iOS devices](./ios-devices.md) ({len(ios)})",
             f"- [Scanners](./scanners.md) ({len(scanners)})",
             f"- [Preferences](./preferences.md) "
             f"({len(prefs)} keys from {IC_PLIST.name})", ""]
    write_md(vault / "INDEX.md", "\n".join(index))
    print(f"Wrote vault to {vault}")
    print(f"  cameras: {len(cams)}  iOS: {len(ios)}  scanners: {len(scanners)}  "
          f"prefs keys: {len(prefs)}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="image-capture-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("status", help="Counts overview")
    sp.set_defaults(func=cmd_status)

    sp = sub.add_parser("cameras", help="List AVFoundation video devices")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_cameras)

    sp = sub.add_parser("ios-devices", help="List connected iOS/iPad/Watch via USB")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_ios_devices)

    sp = sub.add_parser("scanners", help="List connected scanners")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_scanners)

    sp = sub.add_parser("prefs", help="Image Capture preferences plist")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_prefs)

    sp = sub.add_parser("snap", help="WRITE: capture a photo from a camera")
    sp.add_argument("--camera", help="Camera name substring (default: first available)")
    sp.add_argument("--out", help="Output JPG path "
                                  "(default: ~/work/apple/exported/image-capture/snaps/<timestamp>.jpg)")
    sp.set_defaults(func=cmd_snap)

    sp = sub.add_parser("export", help="Write all read-only data to markdown vault")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
