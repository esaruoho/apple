"""paketti_faq — the Paketti Feature-Answer Vault core (shared by gen / rate / ask).

The bot DRAFTS grounded answers (mlx-here armed with paketti + renoise-api); Esa
CERTIFIES them (rate); certified answers serve instantly (ask, via on-device
NLEmbedding match). Theory: wiki/concepts/paketti-feature-answer-vault.md.

Apple-native + DRY: generation reuses arm_apple + fm-mlx; matching reuses
bin/apple-embed (NLEmbedding). No new model, no network.
"""
from __future__ import annotations

import json
import math
import os
import re
import subprocess
import sys
import time
import uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent
sys.path.insert(0, str(HERE))
FM_MLX = HERE / "fm-mlx"
APPLE_EMBED = HERE / "apple-embed"
PAKETTI = "/Users/esaruoho/work/paketti"

VAULT_DIR = Path.home() / ".paketti-faq"
VAULT = VAULT_DIR / "vault.jsonl"

# Seed feature-questions — real Paketti topics. gen() answers the next unanswered ones.
SEED_QUESTIONS = [
    "Does Paketti have a system for changing pattern length?",
    "How do I load a sample and turn it into an instrument in Paketti?",
    "What does Paketti's HyperEdit do and how do I use it?",
    "How does Paketti handle external MIDI input and recording?",
    "Can Paketti render the song or a pattern to a WAV file?",
    "What are the rules for naming a Paketti keybinding?",
    "Does Paketti have sample slicing or beat detection?",
    "How do I set or configure the default pattern in Paketti?",
    "What is the Beat Structure Editor in Paketti?",
    "How do I quickly load all samples from a module in Paketti?",
    "Does Paketti have a Groovebox, and what does it do?",
    "What automation-related tools does Paketti provide?",
]


# ── vault io ─────────────────────────────────────────────────────────────────
def load() -> list:
    if not VAULT.exists():
        return []
    out = []
    for line in VAULT.read_text(encoding="utf-8", errors="replace").splitlines():
        line = line.strip()
        if line:
            try:
                out.append(json.loads(line))
            except Exception:
                pass
    return out


def save(entries: list):
    VAULT_DIR.mkdir(parents=True, exist_ok=True)
    tmp = VAULT.with_suffix(".tmp")
    tmp.write_text("\n".join(json.dumps(e, ensure_ascii=False) for e in entries) + "\n")
    tmp.replace(VAULT)


def add(entry: dict):
    entries = load()
    entries.append(entry)
    save(entries)


def update(entry_id: str, **fields):
    entries = load()
    for e in entries:
        if e.get("id") == entry_id:
            e.update(fields)
    save(entries)


# ── generation (the bot drafts) ──────────────────────────────────────────────
def _citations(answer: str) -> list:
    return sorted(set(re.findall(r"[A-Za-z0-9_/.\-]+\.lua", answer)))


SPINE = Path.home() / ".paketti-spine" / "spine.json"


def spine_context(query: str) -> str:
    """If the question names a documented Paketti ENTITY (HyperEdit, Groovebox, …),
    return its AUTHORITATIVE spine record (foundation + parts + regions, all in
    Esa's words) so the model presents real facts instead of inventing them."""
    try:
        s = json.loads(SPINE.read_text())
    except Exception:
        return ""
    ql = query.lower()
    blocks = []
    for name, rec in s.get("entities", {}).items():
        if len(name) > 3 and name.lower() in ql:
            b = [f'AUTHORITATIVE SPINE — Paketti "{name}" (ground EVERY claim in this; '
                 f'do NOT invent modes or features):']
            if rec.get("code_file"):
                b.append(f"CODE: {rec['code_file']}")
            if rec.get("foundation"):
                b.append(f"FOUNDATION ({rec['foundation']['date']}): {rec['foundation']['title']}")
            if rec.get("regions"):
                b.append("LIVES IN REGIONS: " + ", ".join(rec["regions"]))
            parts = [p for p in rec.get("parts", [])
                     if not p["title"].lower().startswith(("nineteen", "seven", "all playmode",
                                                           "dialog of dialogs", "more tools"))]
            if parts:
                b.append("PARTS ADDED OVER TIME:\n"
                         + "\n".join(f"- {p['date']} {p['title']}" for p in parts[:14]))
            blocks.append("\n".join(b))
    return "\n\n".join(blocks[:2])


def generate_answer(question: str, timeout: int = 180) -> "str | None":
    """Draft a grounded answer with the paketti+renoise-armed MLX brain. If the
    question names a spine entity, that authoritative record leads the prompt."""
    import arm_apple
    system = arm_apple.build_system(PAKETTI)            # arms paketti (+renoise companion)
    prompt = arm_apple.augment_prompt(question, question)  # + per-turn retrieval
    spine = spine_context(question)
    if spine:
        prompt = spine + "\n\n" + prompt
    try:
        p = subprocess.run([str(FM_MLX), "--raw", "--system", system, prompt],
                           capture_output=True, text=True, timeout=timeout,
                           stdin=subprocess.DEVNULL)
    except Exception:
        return None
    a = (p.stdout or "").strip()
    if a.lower().startswith("assistant:"):
        a = a.split(":", 1)[1].strip()
    return a or None


def new_entry(question: str, answer: str) -> dict:
    return {"id": uuid.uuid4().hex[:10], "q": question, "a": answer,
            "citations": _citations(answer), "status": "unvetted",
            "ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())}


def unanswered_seeds(entries: list) -> list:
    have = {e["q"] for e in entries}
    return [q for q in SEED_QUESTIONS if q not in have]


# ── semantic match (NLEmbedding, on-device) ──────────────────────────────────
def embed(texts: list) -> list:
    """512-dim NLEmbedding vectors for each text (via bin/apple-embed)."""
    if not texts:
        return []
    try:
        p = subprocess.run([str(APPLE_EMBED)], input="\n".join(t.replace("\n", " ") for t in texts),
                           capture_output=True, text=True, timeout=60)
    except Exception:
        return [None] * len(texts)
    vecs = []
    for line in p.stdout.splitlines():
        try:
            vecs.append(json.loads(line).get("v"))
        except Exception:
            vecs.append(None)
    while len(vecs) < len(texts):
        vecs.append(None)
    return vecs


def cosine(a, b) -> float:
    if not a or not b:
        return 0.0
    dot = sum(x * y for x, y in zip(a, b))
    na = math.sqrt(sum(x * x for x in a))
    nb = math.sqrt(sum(y * y for y in b))
    return dot / (na * nb) if na and nb else 0.0


def best_match(question: str, entries: list, vetted_only: bool = True):
    """Return (entry, score) of the closest VETTED vault question, or (None, 0)."""
    pool = [e for e in entries if (e.get("status") == "vetted" or not vetted_only)]
    if not pool:
        return None, 0.0
    vecs = embed([question] + [e["q"] for e in pool])
    qv = vecs[0]
    best, score = None, -1.0
    for e, v in zip(pool, vecs[1:]):
        s = cosine(qv, v)
        if s > score:
            best, score = e, s
    return best, score
