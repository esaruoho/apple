"""Capability-aware provider resolution — the no-download safety layer.

A *capability* (ocr, transcribe, ner, embed, reason) is a typed need, not a
command. It resolves to a *provider*:

  - local  — a native organ that is ALREADY present (OS-shipped framework, or a
             model already in cache). Gated by `local_preflight`: a cheap,
             read-only check that returns exit 0 ONLY if the thing can run
             locally WITHOUT downloading. If proving availability would trigger
             a download, the preflight fails and local is skipped.
  - fleet  — a belt on another machine (e.g. the Mini's whisp / fm workers),
             reached by `fleet_cmd`. Gated by `fleet_heartbeat`: is the belt alive?

Resolution order follows `prefer` (local-first or fleet-first). If no provider
is available, the policy in `on_unavailable` applies — default `error`, NEVER
a silent local download.

This is the mechanism that stops "just run it locally" from pulling a 1.2 GB
model onto a workstation that was never meant to host it.
"""
from __future__ import annotations

import shlex
import subprocess
from dataclasses import dataclass


class CapabilityUnavailable(RuntimeError):
    pass


@dataclass
class Resolved:
    capability: str
    provider: str          # "local" | "fleet"
    cmd: str               # command template (may contain {path})
    collect: str = ""      # fleet-only: where the result lands (e.g. "{stem}.txt")


def _check(cmd: str, timeout: int = 20) -> bool:
    """Run a preflight/heartbeat shell check; True iff it exits 0. Read-only."""
    if not cmd:
        return True  # empty check = always available (OS-shipped, no model)
    try:
        r = subprocess.run(cmd, shell=True, capture_output=True, timeout=timeout)
        return r.returncode == 0
    except subprocess.TimeoutExpired:
        return False


def resolve(capability: str, spec: dict, *, probe=_check) -> Resolved:
    """Pick a provider for one capability. Never downloads; errors if none."""
    prefer = spec.get("prefer", "local")
    order = ["local", "fleet"] if prefer == "local" else ["fleet", "local"]

    for provider in order:
        cmd = spec.get(f"{provider}_cmd", "")
        if not cmd:
            continue
        gate = spec.get("local_preflight", "") if provider == "local" else spec.get("fleet_heartbeat", "")
        if not probe(gate):
            continue  # not installed locally (no download!), or belt is down
        return Resolved(
            capability=capability,
            provider=provider,
            cmd=cmd,
            collect=spec.get("fleet_collect", "") if provider == "fleet" else "",
        )

    policy = spec.get("on_unavailable", "error")
    if policy == "error":
        raise CapabilityUnavailable(
            f"capability '{capability}' is unavailable: no local provider is "
            f"installed (and installing is NOT automatic) and no fleet belt is "
            f"reachable. Install it explicitly, or point at a live belt."
        )
    raise CapabilityUnavailable(f"capability '{capability}': unknown policy {policy!r}")


def describe(capabilities: dict, *, probe=_check) -> list[dict]:
    """Resolution table for `apple-harness capabilities` — what runs where, now."""
    rows = []
    for cap, spec in capabilities.items():
        try:
            r = resolve(cap, spec, probe=probe)
            rows.append({"capability": cap, "provider": r.provider, "cmd": r.cmd.split()[0]})
        except CapabilityUnavailable as e:
            rows.append({"capability": cap, "provider": "UNAVAILABLE", "cmd": str(e)})
    return rows
