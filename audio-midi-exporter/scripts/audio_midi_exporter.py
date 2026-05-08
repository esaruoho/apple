#!/usr/bin/env python3
"""audio-midi-exporter — Audio MIDI Setup data via system_profiler back-door.

Audio MIDI Setup has no AppleScript dictionary, no App Intents, no URL
scheme. The back-door is `system_profiler SPAudioDataType` and
`SPMIDIDataType` (both ship with macOS) plus the saved-config plists at
`~/Library/Audio/MIDI Configurations/`.

Subcommands (all read-only):
  status           summary line: device counts
  audio            list audio devices (input/output, sample rate, channels)
  midi             list MIDI devices, ports, virtual sources
  configurations   list saved MIDI Studio configurations (.mcfg files)
  export           write the lot as markdown sidecars

No third-party dependencies.
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
from pathlib import Path
from datetime import datetime

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
MIDI_CONFIG_DIR = Path(os.path.expanduser("~/Library/Audio/MIDI Configurations"))


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/audio-midi"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def system_profiler(data_type: str) -> list[dict]:
    """Return parsed system_profiler XML as a Python list of dicts."""
    proc = subprocess.run(
        ["system_profiler", data_type, "-xml"],
        capture_output=True, check=False, timeout=30,
    )
    if proc.returncode != 0:
        sys.stderr.write(proc.stderr.decode("utf-8", errors="replace"))
        return []
    try:
        d = plistlib.loads(proc.stdout)
    except Exception as e:
        sys.stderr.write(f"plist parse error: {e}\n")
        return []
    if isinstance(d, list) and d and isinstance(d[0], dict):
        return d[0].get("_items") or []
    return []


# =====================================================================
# Audio
# =====================================================================

@dataclass
class AudioDevice:
    name: str
    raw: dict
    input_channels: int = 0
    output_channels: int = 0
    sample_rate_in: float = 0.0
    sample_rate_out: float = 0.0
    is_default_in: bool = False
    is_default_out: bool = False
    is_default_system: bool = False
    transport: str = ""
    manufacturer: str = ""


def parse_audio() -> list[AudioDevice]:
    items = system_profiler("SPAudioDataType")
    out: list[AudioDevice] = []
    # SPAudio reports a tree: top-level entries are AudioBuses; per-bus a list of devices.
    for top in items:
        for d in top.get("_items") or []:
            ad = AudioDevice(name=d.get("_name", "(unnamed)"), raw=d)
            ad.input_channels = int(d.get("coreaudio_device_input", 0) or 0)
            ad.output_channels = int(d.get("coreaudio_device_output", 0) or 0)
            ad.sample_rate_in = float(d.get("coreaudio_device_srate", 0.0) or 0.0)
            ad.sample_rate_out = ad.sample_rate_in
            ad.is_default_in = bool(d.get("coreaudio_default_audio_input_device"))
            ad.is_default_out = bool(d.get("coreaudio_default_audio_output_device"))
            ad.is_default_system = bool(d.get("coreaudio_default_audio_system_device"))
            ad.transport = d.get("coreaudio_device_transport", "") or ""
            ad.manufacturer = d.get("coreaudio_device_manufacturer", "") or ""
            out.append(ad)
    return out


# =====================================================================
# MIDI
# =====================================================================

@dataclass
class MidiDevice:
    name: str
    raw: dict
    is_online: bool = False
    is_offline: bool = False
    manufacturer: str = ""
    model: str = ""
    embedded: list[str] = field(default_factory=list)


def parse_midi() -> list[MidiDevice]:
    items = system_profiler("SPMIDIDataType")
    out: list[MidiDevice] = []
    for d in items:
        md = MidiDevice(name=d.get("_name", "(unnamed)"), raw=d)
        md.manufacturer = d.get("midi_manufacturer", "") or ""
        md.model = d.get("midi_model", "") or ""
        md.is_online = bool(d.get("midi_is_online")) or "online" in str(d.get("midi_status", "")).lower()
        # nested entities (cables, ports)
        for child_key in ("_items", "midi_entities"):
            for c in d.get(child_key) or []:
                if isinstance(c, dict):
                    md.embedded.append(c.get("_name", "") or "(entity)")
        out.append(md)
    return out


# =====================================================================
# MIDI Configurations
# =====================================================================

def list_configurations() -> list[Path]:
    if not MIDI_CONFIG_DIR.exists():
        return []
    return sorted(MIDI_CONFIG_DIR.glob("*.mcfg"))


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    audio = parse_audio()
    midi = parse_midi()
    cfgs = list_configurations()
    print("Audio MIDI overview")
    print(f"  Audio devices: {len(audio)}")
    print(f"  MIDI devices:  {len(midi)}")
    print(f"  Saved MIDI configs: {len(cfgs)}")
    for d in audio:
        flags = []
        if d.is_default_system: flags.append("system")
        if d.is_default_in: flags.append("def-in")
        if d.is_default_out: flags.append("def-out")
        flag_s = f" [{','.join(flags)}]" if flags else ""
        print(f"    audio: {d.name}{flag_s}  {d.transport}  "
              f"in:{d.input_channels} out:{d.output_channels} @ {d.sample_rate_in:g} Hz")
    for d in midi:
        status = "online" if d.is_online else "?"
        print(f"    midi:  {d.name}  {d.manufacturer}/{d.model}  ({status})")
    return 0


def cmd_audio(args) -> int:
    audio = parse_audio()
    if args.json:
        out = [{
            "name": d.name, "transport": d.transport, "manufacturer": d.manufacturer,
            "input_channels": d.input_channels, "output_channels": d.output_channels,
            "sample_rate_hz": d.sample_rate_in,
            "is_default_input": d.is_default_in,
            "is_default_output": d.is_default_out,
            "is_default_system": d.is_default_system,
        } for d in audio]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for d in audio:
        flags = []
        if d.is_default_system: flags.append("SYS")
        if d.is_default_in: flags.append("IN")
        if d.is_default_out: flags.append("OUT")
        flag_s = f" [{'/'.join(flags)}]" if flags else ""
        print(f"  {d.name}{flag_s}")
        print(f"    transport={d.transport}  manufacturer={d.manufacturer or '?'}")
        print(f"    inputs={d.input_channels}  outputs={d.output_channels}  "
              f"sample_rate={d.sample_rate_in:g} Hz")
    print(f"\n{len(audio)} audio device(s)")
    return 0


def cmd_midi(args) -> int:
    midi = parse_midi()
    if args.json:
        out = [{
            "name": d.name, "manufacturer": d.manufacturer, "model": d.model,
            "is_online": d.is_online, "embedded": d.embedded,
        } for d in midi]
        print(json.dumps(out, indent=2, ensure_ascii=False))
        return 0
    for d in midi:
        status = "online" if d.is_online else "offline/unknown"
        print(f"  {d.name}  ({status})")
        if d.manufacturer or d.model:
            print(f"    {d.manufacturer or '?'} / {d.model or '?'}")
        for e in d.embedded:
            print(f"    - {e}")
    print(f"\n{len(midi)} MIDI device(s)")
    return 0


def cmd_configurations(args) -> int:
    cfgs = list_configurations()
    for c in cfgs:
        size = c.stat().st_size
        mtime = datetime.fromtimestamp(c.stat().st_mtime).strftime("%Y-%m-%d %H:%M")
        print(f"  {mtime}  {size:>8}b  {c.name}")
    print(f"\n{len(cfgs)} configuration(s) at {MIDI_CONFIG_DIR}")
    return 0


def write_md(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content)


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    vault.mkdir(parents=True, exist_ok=True)

    audio = parse_audio()
    midi = parse_midi()
    cfgs = list_configurations()
    stamp = datetime.now().isoformat(timespec="seconds")

    # audio.md
    lines = ["---",
             f'kind: "audio-devices"',
             f'generated: "{stamp}"',
             f'count: {len(audio)}',
             "---", "",
             "# Audio Devices",
             ""]
    for d in audio:
        flags = []
        if d.is_default_system: flags.append("system default")
        if d.is_default_in: flags.append("default input")
        if d.is_default_out: flags.append("default output")
        lines.append(f"## {d.name}{(' — ' + ', '.join(flags)) if flags else ''}")
        lines.append("")
        lines.append(f"- **Transport**: {d.transport or '?'}")
        lines.append(f"- **Manufacturer**: {d.manufacturer or '?'}")
        lines.append(f"- **Inputs**: {d.input_channels} channels")
        lines.append(f"- **Outputs**: {d.output_channels} channels")
        lines.append(f"- **Sample rate**: {d.sample_rate_in:g} Hz")
        lines.append("")
    write_md(vault / "audio.md", "\n".join(lines))

    # midi.md
    lines = ["---",
             f'kind: "midi-devices"',
             f'generated: "{stamp}"',
             f'count: {len(midi)}',
             "---", "",
             "# MIDI Devices",
             ""]
    for d in midi:
        status = "online" if d.is_online else "offline/unknown"
        lines.append(f"## {d.name} — {status}")
        lines.append("")
        if d.manufacturer or d.model:
            lines.append(f"- **Manufacturer / model**: {d.manufacturer or '?'} / {d.model or '?'}")
        if d.embedded:
            lines.append("- **Embedded entities/ports**:")
            for e in d.embedded:
                lines.append(f"  - {e}")
        lines.append("")
    write_md(vault / "midi.md", "\n".join(lines))

    # configurations: copy/symlink + index
    cfg_dir = vault / "configurations"
    cfg_dir.mkdir(parents=True, exist_ok=True)
    cfg_lines = ["# MIDI Studio Configurations", ""]
    for c in cfgs:
        target = cfg_dir / c.name
        if target.exists() or target.is_symlink():
            target.unlink()
        target.symlink_to(c)
        cfg_lines.append(f"- [{c.name}](./{c.name}) "
                         f"({c.stat().st_size}b, "
                         f"{datetime.fromtimestamp(c.stat().st_mtime).strftime('%Y-%m-%d')})")
    write_md(cfg_dir / "_index.md", "\n".join(cfg_lines))

    # INDEX
    index = ["# Audio MIDI Vault", "",
             f"Generated {stamp}.", "",
             f"- [Audio devices](./audio.md) ({len(audio)})",
             f"- [MIDI devices](./midi.md) ({len(midi)})",
             f"- [MIDI Studio configurations](./configurations/_index.md) "
             f"({len(cfgs)} .mcfg files)", ""]
    write_md(vault / "INDEX.md", "\n".join(index))

    print(f"Wrote vault to {vault}")
    print(f"  audio devices: {len(audio)}")
    print(f"  MIDI devices:  {len(midi)}")
    print(f"  configurations: {len(cfgs)} (symlinked)")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="audio-midi-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)

    sp = sub.add_parser("status", help="Counts overview")
    sp.set_defaults(func=cmd_status)

    sp = sub.add_parser("audio", help="List audio devices")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_audio)

    sp = sub.add_parser("midi", help="List MIDI devices")
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_midi)

    sp = sub.add_parser("configurations", help="List saved MIDI Studio configs")
    sp.set_defaults(func=cmd_configurations)

    sp = sub.add_parser("export", help="Write everything to markdown vault")
    sp.set_defaults(func=cmd_export)

    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
