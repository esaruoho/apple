"""live_data — answer live sensor/state questions for an armed fm-chat.

A stateless model can't read its weights for "how hot is the Mini right now" or
"what's the room temperature". This module runs the real Apple-native sources and
returns a compact LIVE DATA block to inject into the prompt:

  • Ambient climate  → bin/homepod-now (HomePod thermo-hygrometer, Syncthing-mirrored)
  • Per-machine state → ~/work/comms/queue/machine-card-<host>.json (the fleet's
    Syncthing-published cards: CPU/GPU die temps, thermal pressure, load, memory,
    uptime, battery, top processes, queues — for EVERY peer, the Mini included).

Routing is keyword-based and generous: a bare "temperature" returns BOTH the room
climate and the relevant machine's die temp, so the model can pick. The model is
told to use ONLY these numbers for live state (the arming system prompt frames it).

DRY: reuses the existing homepod-now tool and the machine-card publisher's output;
it does not re-measure anything. FEATURE-CARD >> features/arm-apple-skill.feature
"""
from __future__ import annotations

import json
import os
import socket
import subprocess
import time
from pathlib import Path

HERE = Path(__file__).resolve().parent
QUEUE = Path.home() / "work" / "comms" / "queue"

# Query aliases → the card hostname (case-insensitive match on the query).
_ALIASES = {
    "cloudcity": "CloudcityMacMini", "mini": "CloudcityMacMini",
    "mac mini": "CloudcityMacMini", "macmini": "CloudcityMacMini",
    "raymac": "RayMac", "macbook": "RayMac", "mbp": "RayMac",
    "esarmbp": "esarMBP", "macpro": "HertsiMacPro", "hertsi": "HertsiMacPro",
}
# Words that mean "the machine the model runs on" → the Mini.
_SELF_WORDS = ("you ", "your", "yourself", "running on", "this server",
               "the server", "host you", "machine you")

_AMBIENT = ("humidity", "humid", "room", "climate", "homepod", "weather", "indoor")
_TEMP = ("temperature", "temp", "hot", "warm", "cold", "degrees", "°c", "celsius", "fahrenheit")
_MACHINE = ("battery", "charge", "charging", "power source", "cpu", "gpu", "load",
            "busy", "memory", " ram", "fan", "thermal", "die temp", "uptime",
            "running", "process", "queue", "whisp", "performance", "how hot")


def _cards() -> dict:
    out = {}
    try:
        for p in QUEUE.glob("machine-card-*.json"):
            if p.name.endswith(("heartbeat.json",)) or "probe" in p.name or "publish" in p.name:
                continue
            try:
                c = json.loads(p.read_text())
                out[str(c.get("id", p.stem)).lower()] = c
            except Exception:
                continue
    except Exception:
        pass
    return out


def _pick_host(q: str, cards: dict):
    for alias, host in _ALIASES.items():
        if alias in q and host.lower() in cards:
            return host.lower()
    if any(w in q for w in _SELF_WORDS) and "cloudcitymacmini" in cards:
        return "cloudcitymacmini"            # the model runs on the Mini
    local = socket.gethostname().split(".")[0].lower()
    if local in cards:
        return local
    return next(iter(cards), None)


def _age(ts) -> str:
    try:
        secs = time.time() - float(ts)
    except Exception:
        return "age unknown"
    if secs < 90:
        return f"{int(secs)}s ago"
    if secs < 5400:
        return f"{int(secs/60)} min ago"
    if secs < 172800:
        return f"{secs/3600:.1f} h ago"
    return f"{int(secs/86400)} d ago"


def _machine_summary(card: dict) -> str:
    r = card.get("running", {}) or {}
    name = card.get("id", "?")
    age = _age(card.get("ts"))
    bits = []
    th = r.get("thermal") or {}
    if th.get("cpu_c") is not None:
        line = f"CPU die {th['cpu_c']:.1f}°C"
        if th.get("gpu_c") is not None:
            line += f", GPU {th['gpu_c']:.1f}°C"
        if th.get("max_c") is not None:
            line += f", hottest sensor {th['max_c']:.1f}°C"
        if th.get("pressure"):
            line += f", thermal pressure {th['pressure']}"
        bits.append(line)
    if r.get("load_pct") is not None:
        bits.append(f"load {r['load_pct']}%")
    if r.get("mem_used_gb") is not None:
        bits.append(f"memory {r['mem_used_gb']} GB used")
    if r.get("battery_pct") is not None:
        bits.append(f"battery {r['battery_pct']}% ({r.get('power_source','?')})")
    elif r.get("power_source"):
        bits.append(f"on {r['power_source']}")
    if r.get("uptime"):
        bits.append(f"uptime {r['uptime']}")
    top = [t.get("cmd") for t in (r.get("top") or [])[:3] if t.get("cmd")]
    if top:
        bits.append("top processes: " + ", ".join(top))
    if not bits:
        return ""
    return f"{name} (card {age}): " + "; ".join(bits) + "."


def _climate_line() -> str:
    try:
        out = subprocess.run([str(HERE / "homepod-now")], capture_output=True,
                             text=True, timeout=15).stdout.strip()
    except Exception:
        return ""
    return out


def lookup(query: str) -> str:
    """Return a LIVE DATA block relevant to `query`, or '' if it asks for nothing live."""
    q = (query or "").lower()
    want_ambient = any(w in q for w in _AMBIENT)
    want_temp = any(w in q for w in _TEMP)
    want_machine = any(w in q for w in _MACHINE)
    host_named = any(a in q for a in _ALIASES) or any(w in q for w in _SELF_WORDS)
    if not (want_ambient or want_temp or want_machine or host_named):
        return ""

    blocks = []
    # Ambient room climate: when humidity/room/climate asked, or a bare temperature
    # question with no machine context.
    if want_ambient or (want_temp and not (want_machine or host_named)):
        c = _climate_line()
        if c:
            blocks.append("Room climate (HomePod): " + c)

    # Per-machine state: machine words, a host name, or a temperature question that
    # is really about a device's die temperature.
    if want_machine or host_named or want_temp:
        cards = _cards()
        host = _pick_host(q, cards)
        if host and host in cards:
            s = _machine_summary(cards[host])
            if s:
                blocks.append(s)

    if not blocks:
        return ""
    return ("LIVE DATA (real readings, use these exact numbers for any live-state "
            "question — do NOT say you lack sensor access):\n- " + "\n- ".join(blocks))


if __name__ == "__main__":
    import sys
    print(lookup(" ".join(sys.argv[1:]) or "temperature of the mini"))
