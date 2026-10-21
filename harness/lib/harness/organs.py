"""Organ dispatch — zero-token extraction + structuring, via capability resolution.

Every extraction goes through `capabilities.resolve`, so the provider (local vs
a fleet belt) is chosen by preflight/heartbeat, never by a silent download. A
fleet provider may deliver its result in a file beside the source (`collect`,
e.g. `convey transcript` writing `<stem>.txt`) rather than on stdout; local
organs return text on stdout.
"""
from __future__ import annotations

import json
import os
import shlex
import subprocess

from . import capabilities


class OrganError(RuntimeError):
    pass


def _run(cmd: list[str], stdin: str | None = None, timeout: int = 600) -> str:
    try:
        res = subprocess.run(cmd, input=stdin, capture_output=True, text=True, timeout=timeout)
    except FileNotFoundError:
        raise OrganError(f"organ not found: {cmd[0]}")
    except subprocess.TimeoutExpired:
        raise OrganError(f"organ timed out ({timeout}s): {cmd[0]}")
    if res.returncode != 0:
        raise OrganError(f"{cmd[0]} exited {res.returncode}: {res.stderr.strip()[:300]}")
    return res.stdout


def _fill(template: str, path: str) -> list[str]:
    stem = os.path.splitext(path)[0]
    return [p.format(path=path, stem=stem) for p in shlex.split(template)]


def extract(cfg, row: dict) -> str:
    """Dispatch an asset to its modality's capability. Resolves provider first."""
    modality = row["modality"]
    cap_name = cfg.capability_for_modality(modality)

    if not cap_name:  # text modality: read bytes directly, no organ, no tokens
        row["extract_provider"] = "local:read"
        with open(row["path"], "r", encoding="utf-8", errors="ignore") as f:
            return f.read()

    spec = cfg.capability(cap_name)
    r = capabilities.resolve(cap_name, spec)  # raises CapabilityUnavailable, never downloads
    row["extract_provider"] = f"{cap_name}:{r.provider}"

    path = row["path"]
    cmd = _fill(r.cmd, path)
    if r.collect:
        # belt does the work and writes the result beside the source
        _run(cmd, timeout=1800)
        collect_path = r.collect.format(path=path, stem=os.path.splitext(path)[0])
        if not os.path.exists(collect_path):
            raise OrganError(f"{cap_name} belt produced no result at {collect_path}")
        with open(collect_path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()
    return _run(cmd, timeout=1800)


def tag_entities(cfg, text: str) -> list[dict]:
    """NER via the 'ner' capability. Zero tokens."""
    if not text.strip():
        return []
    r = capabilities.resolve("ner", cfg.capability("ner"))
    out = _run(shlex.split(r.cmd), stdin=text)
    entities, seen = [], set()
    for line in out.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        key = (e.get("text", ""), e.get("type", ""))
        if key not in seen:
            seen.add(key)
            entities.append({"text": key[0], "type": key[1]})
    return entities


def embed(cfg, text: str) -> list[float] | None:
    """One 512-dim vector via the 'embed' capability. Zero tokens."""
    snippet = " ".join(text.split())[:2000]
    if not snippet:
        return None
    r = capabilities.resolve("embed", cfg.capability("embed"))
    out = _run(shlex.split(r.cmd), stdin=snippet)
    for line in out.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        if isinstance(rec.get("v"), list):
            return rec["v"]
    return None
