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
FM_SUBMIT = HERE / "fm-submit"          # the fleet brain: queues to the Mini's fm-service
APPLE_EMBED = HERE / "apple-embed"
PAKETTI = "/Users/esaruoho/work/paketti"
FEATURE_MAP = Path(PAKETTI) / "docs" / "FEATURE-MAP.md"   # auto-pulled, always fresh on the Mini

# Brain: fm-submit (Mini's on-device FoundationModels, works from any fleet machine)
# unless overridden. The laptop-only fm-mlx remains the fallback.
BRAIN = os.environ.get("PAKETTI_FAQ_BRAIN", "fm-submit")

# Vault lives in the Syncthing comms queue so the Mini's bot serves the SAME certified
# answers you vet on the laptop. Override with PAKETTI_FAQ_VAULT.
_COMMS_VAULT = Path.home() / "work" / "comms" / "queue" / "paketti-faq" / "vault.jsonl"
_LEGACY_VAULT = Path.home() / ".paketti-faq" / "vault.jsonl"
VAULT = Path(os.environ.get("PAKETTI_FAQ_VAULT", str(_COMMS_VAULT)))
VAULT_DIR = VAULT.parent

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
    # One-time migration: seed the shared comms vault from the legacy laptop vault.
    if not VAULT.exists() and VAULT != _LEGACY_VAULT and _LEGACY_VAULT.exists():
        try:
            VAULT_DIR.mkdir(parents=True, exist_ok=True)
            VAULT.write_text(_LEGACY_VAULT.read_text(encoding="utf-8"), encoding="utf-8")
        except Exception:
            pass
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


_FEAT_STOP = {"does", "have", "what", "with", "this", "that", "from", "your", "paketti",
              "renoise", "they", "them", "when", "where", "which", "would", "could", "into",
              "about", "there", "their", "make", "made", "system", "feature", "thing"}


def feature_context(query: str, limit: int = 18) -> str:
    """Grep the live FEATURE-MAP (every registered Paketti feature, auto-pulled fresh on
    the Mini) for lines matching the question's keywords — so the model grounds in
    features that ACTUALLY EXIST rather than inventing them."""
    try:
        lines = FEATURE_MAP.read_text(encoding="utf-8").splitlines()
    except Exception:
        return ""
    words = {w for w in re.findall(r"[a-z]{4,}", query.lower()) if w not in _FEAT_STOP}
    if not words:
        return ""
    hits = []
    for ln in lines:
        s = ln.strip()
        if not (s.startswith("-") or s.startswith("|")):
            continue
        low = s.lower()
        if any(w in low for w in words):
            hits.append(s.lstrip("-| ").strip())
        if len(hits) >= limit:
            break
    if not hits:
        return ""
    return ("RELEVANT PAKETTI FEATURES (from the live feature map — these EXIST; ground "
            "claims in these, do NOT invent features):\n" + "\n".join(f"- {h}" for h in hits))


_LEAN_SYSTEM = (
    "You are a concise expert on Paketti, a Lua quality-of-life tool for the Renoise "
    "tracker. Answer the user's question using ONLY the Paketti features and facts listed "
    "below. Do NOT invent features; if the list doesn't cover it, say you're not sure. Keep "
    "it to 2-6 sentences and name the exact feature(s) the user should use.")


def generate_answer(question: str, timeout: int = 180) -> "str | None":
    """Draft a grounded answer. Grounding = any named spine entity + the matching live
    FEATURE-MAP lines (real registered features). Brain is fm-submit (the Mini's small
    on-device FoundationModels) by default — fed a LEAN system + grounding, because the
    full 12KB skill-arm overwhelms it (slow + refuses). fm-mlx (laptop, capable) keeps the
    full armed system."""
    import arm_apple
    grounding = "\n\n".join(c for c in (feature_context(question), spine_context(question)) if c)
    try:
        if BRAIN == "fm-submit" and FM_SUBMIT.exists():
            system = _LEAN_SYSTEM + (("\n\n" + grounding) if grounding else "")
            cmd = [str(FM_SUBMIT), "--system", system,
                   "--timeout", str(max(60, timeout - 20)), question]
        else:
            system = arm_apple.build_system(PAKETTI)            # full paketti(+renoise) arm
            prompt = arm_apple.augment_prompt(question, question)
            if grounding:
                prompt = grounding + "\n\n" + prompt
            cmd = [str(FM_MLX), "--raw", "--system", system, prompt]
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
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
