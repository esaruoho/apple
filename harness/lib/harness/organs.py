"""Organ dispatch — the zero-token extraction + structuring layer.

Every organ is a leaf binary bound in config. The engine never knows what a
leaf actually is; it only knows the contract:

  - extraction organ:  (asset path) -> extracted text on stdout
  - ner organ:         stdin text   -> JSONL entity rows {"text","type",...}
  - embed organ:       stdin lines  -> JSONL {"t","v":[512]} per line

The scaffold's reference bindings are all LOCAL and Apple-native:
vision-ocr (VNRecognizeTextRequest), apple-ner (NaturalLanguage NLTagger),
apple-embed (NLEmbedding). None spends an LLM token; none needs a network.
"""
from __future__ import annotations

import json
import shlex
import subprocess


class OrganError(RuntimeError):
    pass


def _run(cmd: list[str], stdin: str | None = None, timeout: int = 600) -> str:
    try:
        res = subprocess.run(
            cmd,
            input=stdin,
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError:
        raise OrganError(f"organ not found: {cmd[0]}")
    except subprocess.TimeoutExpired:
        raise OrganError(f"organ timed out ({timeout}s): {cmd[0]}")
    if res.returncode != 0:
        raise OrganError(f"{cmd[0]} exited {res.returncode}: {res.stderr.strip()[:300]}")
    return res.stdout


def extract(cfg, row: dict) -> str:
    """Dispatch an asset to its modality's extraction organ. Zero tokens."""
    modality = row["modality"]
    path = row["path"]
    template = cfg.organ_resolved(modality)

    if not template:  # text modality: read the bytes directly, no subprocess
        with open(path, "r", encoding="utf-8", errors="ignore") as f:
            return f.read()

    cmd = [part.format(path=path) for part in shlex.split(template)]
    return _run(cmd, timeout=1800)


def tag_entities(cfg, text: str) -> list[dict]:
    """Named-entity recognition via the bound NER organ. Zero tokens."""
    if not text.strip():
        return []
    out = _run(shlex.split(cfg.ner_cmd()), stdin=text)
    entities = []
    for line in out.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue  # skip the human summary header line
        try:
            e = json.loads(line)
        except json.JSONDecodeError:
            continue
        entities.append({"text": e.get("text", ""), "type": e.get("type", "")})
    # De-dup, keep order.
    seen, uniq = set(), []
    for e in entities:
        key = (e["text"], e["type"])
        if key not in seen:
            seen.add(key)
            uniq.append(e)
    return uniq


def embed(cfg, text: str) -> list[float] | None:
    """One 512-dim NLEmbedding vector for the asset. Zero tokens.

    NLEmbedding is a LIGHT model — weak on very short strings — so we embed a
    bounded leading slice, not fragments. (Partition-then-cluster is a
    downstream concern, not the per-asset embed.)
    """
    snippet = " ".join(text.split())[:2000]
    if not snippet:
        return None
    out = _run(shlex.split(cfg.embed_cmd()), stdin=snippet)
    for line in out.splitlines():
        line = line.strip()
        if not line.startswith("{"):
            continue
        try:
            rec = json.loads(line)
        except json.JSONDecodeError:
            continue
        v = rec.get("v")
        if isinstance(v, list):
            return v
    return None
