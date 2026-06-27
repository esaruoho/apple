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
PROJECT_DOC = Path(PAKETTI) / "README.md"                 # support/donations/manual/license/where
FUNCTIONS_INDEX = Path(PAKETTI) / "docs" / "paketti-functions.json"   # the ground-truth function index
MANUAL_INDEX = Path.home() / "work" / "comms" / "queue" / "paketti-faq" / "manual-index.json"  # embedded manual sections
CHANGELOG = Path(PAKETTI) / "manual" / "CHANGESLOG.md"   # dated '### YYYY-MM-DD - …' entries, newest first

# Brain: fm-mlx (the Mini's Qwen3-4B-Instruct via mlx_lm.server, port 8080) by default —
# better instruction-following + no aggressive guardrails than Apple FoundationModels.
# Set PAKETTI_FAQ_BRAIN=fm-submit to use FoundationModels (fm-service) instead.
BRAIN = os.environ.get("PAKETTI_FAQ_BRAIN", "fm-mlx")

THRESHOLD = 0.80   # cosine above this = "we're sure it's the same question" (shared by ask + bench).
# Raised from 0.62: at 0.62, structurally-similar but unrelated questions matched (e.g. "how do
# i support paketti" ↔ "how do i slice a sample" = 0.662 → served the WRONG vetted answer). Only
# serve a certified answer on a STRONG (>0.8) match; weaker → draft fresh (grounded, re-vettable).

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
# generic feature-suffix words that must NOT drive a name match ("Slice Tools DIALOG" ≠ "Stem Slice
# Randomizer DIALOG"): a match has to be on the distinctive name words, not these.
_NAME_GENERIC = {"dialog", "dialogs", "tool", "tools", "mode", "modes", "paketti", "feature",
                 "features", "window", "panel", "button", "buttons", "menu", "option", "options",
                 # generic action/UI words — they must NOT drive a match ("Player Pro SCANNER
                 # (Start/Stop)" wrongly hit "Start/Stop Playback" on start+stop alone):
                 "start", "stop", "open", "close", "toggle", "show", "hide", "play", "playback",
                 "next", "previous", "selected", "selection"}


def feature_context(query: str, limit: int = 28) -> str:
    """Grep the live FEATURE-MAP (every registered Paketti feature, auto-pulled fresh on
    the Mini) for lines matching the question's keywords — so the model grounds in
    features that ACTUALLY EXIST rather than inventing them."""
    try:
        lines = FEATURE_MAP.read_text(encoding="utf-8").splitlines()
    except Exception:
        return ""
    words = {w for w in re.findall(r"[a-z]{4,}", query.lower()) if w not in _FEAT_STOP}
    # expand with synonyms so e.g. "quieter" reaches the Volume features
    _SYN = {"quiet": "volume", "quieter": "volume", "softer": "volume", "louder": "volume",
            "loud": "volume", "lull": "volume", "faster": "tempo", "slower": "tempo",
            "speed": "tempo", "pan": "panning", "timing": "delay", "groove": "delay",
            "chop": "slice", "kit": "drumkit", "arp": "arpeggio"}
    for w in list(words):
        if w in _SYN:
            words.add(_SYN[w])
    if not words:
        return ""
    # Score each FEATURE BULLET (skip "| group | counts |" summary rows) by how many
    # distinct query keywords it matches, so specific multi-word hits (e.g. "Selection
    # Volume Offset") rank above generic single-word ones ("Add Pattern …").
    scored = []
    for ln in lines:
        s = ln.strip()
        if not s.startswith("- "):
            continue
        low = s.lower()
        n = sum(1 for w in words if w in low)
        if n:
            scored.append((n, s.lstrip("- ").strip()))
    if not scored:
        return ""
    scored.sort(key=lambda x: -x[0])
    top = [t for _, t in scored[:limit]]
    return ("RELEVANT PAKETTI FEATURES (from the live feature map — these EXIST; ground "
            "claims in these, do NOT invent features):\n" + "\n".join(f"- {t}" for t in top))


_LEAN_SYSTEM = (
    "You are a PRECISE expert on Paketti, a Lua workflow tool for the Renoise tracker. The feature "
    "NAMES in the info below are VERIFIED — they exist. But the hard rule:\n"
    "• ONLY state what a feature DOES if the provided CHANGELOG, MANUAL, or SOURCE CODE describes "
    "its behaviour. The CHANGELOG is authoritative; the SOURCE CODE is ground truth — describe from "
    "the code's actual logic and status messages. If you only have a name (or just its "
    "keybindings/midi mappings), NAME the feature and add “(behaviour not yet documented)” — NEVER "
    "guess, infer, or invent what it does from its name. Inventing behaviour is a LIE and far worse "
    "than admitting it's undocumented.\n"
    "• When you describe behaviour, cite the source date/heading (“— changelog 2025-09-15” or "
    "“— from the manual: X”).\n"
    "• For support / donation / install questions, use the project info (give the real links).\n"
    "• NEVER output a URL you aren't certain of — do NOT link to GitHub repos, wikis, or pages. The "
    "ONLY links you may give are ones present verbatim in the project info above.\n"
    "• Paketti lives on GitHub at github.com/esaruoho/paketti, by @esaruoho. There is NO paketti.com "
    "and no other 'official site'. NEVER invent a website or domain; if unsure, say it's on GitHub.\n"
    "• You are a Paketti FAQ assistant in Discord. NEVER add AI-assistant disclaimers ('as an AI…', "
    "'I can't display images', 'in this chat interface') and never output screenshot/image markdown — "
    "just answer the question.\n"
    "Don't pedantically say something “isn't a feature”. Be concise.")

_PROJECT_TRIGGERS = (
    "support", "donat", "patreon", "gumroad", "ko-fi", "kofi", "buy", "coffee", "sponsor",
    "money", "pay", "price", "cost", "free", "install", "download", "where", "get ", "manual",
    "license", "gpl", "discord", "forum", "contribut", "link", "website", "author", "who made",
    "lackluster", "esa")


def project_context(query: str) -> str:
    """Pull the README (support/donations/manual/install/license/where-to-get) into grounding
    when the question is about the PROJECT rather than a workflow feature — so 'how do I support
    Paketti' gets the real donation links instead of 'that isn't a feature'."""
    low = query.lower()
    if not any(t in low for t in _PROJECT_TRIGGERS):
        return ""
    try:
        txt = PROJECT_DOC.read_text(encoding="utf-8").strip()
    except Exception:
        return ""
    return ("PAKETTI PROJECT INFO (use for support / donations / manual / install / where-to-get "
            "/ license / links):\n" + txt)


_DOOR_PAT = {
    "midi": re.compile(r"midi[\s-]?mapping|midimapping|\bmidi\b"),
    "keybinding": re.compile(r"key[\s-]?bind|keybind|short ?cut|hot ?key"),
    "menu": re.compile(r"menu[\s-]?entr|menu item|\bmenu\b"),
}
_DOOR_LABEL = {"midi": "midimappings", "keybinding": "keybindings", "menu": "menu entries"}
_DOOR_GLYPH = {"midi": "🎛", "keybinding": "⌨", "menu": "☰"}
_DOOR_KEY = {"midi": "midi", "keybinding": "kb", "menu": "menu"}   # json stores 'kb', not 'keybinding'
_TOPIC_STOP = {"paketti", "renoise", "it", "them", "all", "everything", "the tool", ""}


def function_query(question: str) -> "str | None":
    """If the question is a 'list/show all <door> [for <area/topic>]' request, answer it straight
    from the ground-truth function index — every item provably exists, no model, no bullshit.
    Returns the answer text, or None if this isn't a list-query (fall through to the normal flow)."""
    ql = question.lower()
    # don't fire on a SYNTHESIZED revise/redraft prompt (it incidentally contains 'feature list',
    # 'midimappings', etc.) — only on a genuine user list-query.
    if ("the user's instruction" in ql or "here is the current answer" in ql
            or "previous answer was rejected" in ql or len(question) > 240):
        return None
    if not re.search(r"\b(list|show|give|all|every|which|what)\b", ql):
        return None
    door = next((d for d, p in _DOOR_PAT.items() if p.search(ql)), None)
    if not door:
        return None
    try:
        idx = json.loads(FUNCTIONS_INDEX.read_text(encoding="utf-8"))
    except Exception:
        return None
    label, glyph, dkey = _DOOR_LABEL[door], _DOOR_GLYPH[door], _DOOR_KEY[door]
    allf = [(area, f) for area, fns in idx.items() for f in fns]

    def names(topic):
        out = set()
        nt = _normalize(topic) if topic else topic       # 'playerpro' must match 'Player Pro' (space)
        for area, f in allf:
            if topic and not (nt in _normalize(f["function"]) or nt in _normalize(area)
                              or any(nt in _normalize(n) for n in f.get(dkey, []))):
                continue
            out.update(f.get(dkey, []))
        return sorted(out)

    # topic/area after for/in/about/on/of, else any known area name mentioned
    topic = None
    m = re.search(r"\b(?:for|in|about|on|of|with)\s+(?:the\s+)?([a-z][a-z0-9 ]{1,26}?)"
                  r"(?:\s+in\s+paketti)?\s*\??$", ql)
    if m:
        topic = m.group(1).strip(" ?")
    if topic in _TOPIC_STOP:               # "in paketti" / "all" aren't real topics → disambiguate
        topic = None
    if not topic:
        for area in idx:
            a = area.lower().split(" (")[0]
            if a and a != "global" and a in ql:
                topic = a
                break

    # If the topic names a known AREA (Mixer, Sample Editor, …), match by the real Renoise SCOPE
    # — NOT a substring — so "mixer" returns the Mixer-frame functions, not device names that merely
    # contain "mixer" (e.g. "Hold Device 11 (Mixer EQ)").
    area_keys = {a.lower(): a for a in idx if a.lower() not in ("global", "(menu/midi only)")}
    matched_area = None
    if topic:
        for al, ak in area_keys.items():
            if topic == al or (len(topic) > 3 and (topic in al or al in topic)):
                matched_area = ak
                break

    def area_names(area):
        out = set()
        for a, f in allf:
            if a == area:
                out.update(f.get(dkey, []))
        return sorted(out)

    if matched_area:
        ns = area_names(matched_area)
        broad = names(topic)
        shown = ns[:120]
        head = (f"{glyph} **{len(ns)} {label}** in the **{matched_area}** area "
                f"(the Renoise {matched_area} scope — accurate, no device-name coincidences):\n\n")
        body = "\n".join(f"- `{n}`" for n in shown) if ns else "_(none registered in this scope)_"
        extra = len(broad) - len(ns)
        note = (f"\n\n_(+{extra} more merely mention “{topic}” elsewhere, incl. device names — "
                f"`!ask all {label} named {topic}` to include those.)_") if extra > 0 else ""
        return head + body + note

    if topic:
        ns = names(topic)
        if ns:
            shown = ns[:120]
            head = (f"{glyph} **{len(ns)} {label}** matching “{topic}” "
                    f"— from the live Paketti index, every one exists:\n\n")
            body = "\n".join(f"- `{n}`" for n in shown)
            more = f"\n\n…and **{len(ns) - 120}** more." if len(ns) > 120 else ""
            return head + body + more

    # broad / unmatched → disambiguate instead of flooding all 7,240
    total = len(names(None))
    rows = sorted(((area, sum(1 for f in fns if f.get(door))) for area, fns in idx.items()),
                  key=lambda r: -r[1])
    areas_line = " · ".join(f"**{a}** ({c})" for a, c in rows if c)
    return (f"Paketti has **{total} {label}** in all — too many to dump at once. Which slice?\n\n"
            f"**By area:** {areas_line}\n\n"
            f"Reply (or `!ask`) with an **area** (e.g. *Mixer*), a **topic** keyword "
            f"(e.g. *mixer*, *sample*, *phrase*, *slice*), or say **all** to flood the lot.")


_manual_cache = None


_Q_BOILER = re.compile(
    r"\b(what is|what are|what does|what'?s|how do i|how can i|how does|tell me about|explain|"
    r"describe|in paketti|and what does it do|does it do|please|the|a|an|do|it|of|for)\b")


def _has_prose(text: str) -> bool:
    """True if the section has explanatory sentences (not just keybinding/menu list lines) — a
    list-only section has NO behaviour to ground in and makes the model invent it."""
    for ln in text.splitlines():
        s = ln.strip()
        if s and not re.match(r"^[-*|#>`\d.]", s) and len(s) > 45 and " " in s:
            return True
    return False


def manual_context(question: str, k: int = 2) -> str:
    """Retrieve the most relevant manual section(s) so the 'why' is grounded in the docs, not the
    model's guess — and CITED by heading. HYBRID: match the subject against section HEADINGS first
    (NLEmbedding is too weak for 'what is X' — it ranked the right section 124th), semantic fallback."""
    global _manual_cache
    if _manual_cache is None:
        try:
            _manual_cache = json.loads(MANUAL_INDEX.read_text(encoding="utf-8"))
        except Exception:
            _manual_cache = []
    if not _manual_cache:
        return ""

    subj = _Q_BOILER.sub(" ", question.lower())
    subj_words = {w for w in re.findall(r"[a-z0-9]{3,}", subj) if w not in _NAME_GENERIC}
    top = []
    if subj_words:
        ranked = []
        for c in _manual_cache:
            hwords = {w for w in re.findall(r"[a-z0-9]{3,}", c["heading"].lower()) if w not in _NAME_GENERIC}
            ov = len(subj_words & hwords)
            if ov:
                ranked.append((ov, c))
        ranked.sort(key=lambda x: -x[0])
        if ranked:
            best_ov = ranked[0][0]
            # the feature's OWN section is the strongest heading match. Require it to cover most of
            # the subject (≥2 distinctive words, or all of a short subject). Only consider sections at
            # that top strength — do NOT fall to weaker ones (a list-only own-section means undocumented,
            # not "grab some other prose"). prose filter below then decides.
            # require ALL distinctive subject words in the heading — a partial match like "Open
            # Waveform Viewer" for "PlayerPro Waveform Viewer" is a DIFFERENT feature, not grounding.
            if best_ov == len(subj_words):
                top = [c for ov, c in ranked if ov == best_ov][:k]

    if not top:                                   # semantic fallback (tight — <0.6 is noise per skill)
        qv = embed([question])
        qv = qv[0] if qv else None
        if qv:
            scored = sorted(((cosine(qv, c["vec"]), c) for c in _manual_cache if c.get("vec")),
                            key=lambda x: -x[0])
            top = [c for s, c in scored[:k] if s >= 0.62]
    # keep only sections with actual PROSE — a section that's just a keybinding list has NO
    # behaviour to ground in, and handing it over makes the model invent the behaviour.
    top = [c for c in top if _has_prose(c["text"])]
    if not top:
        return ""
    out = ["PAKETTI MANUAL — the most relevant section(s). Ground your answer in these and CITE the "
           "heading you used (e.g. “— from the manual: <heading>”):"]
    for c in top:
        out.append(f"\n### {c['heading']}\n{c['text']}")
    return "\n".join(out)


_CL_RECENCY = ("new", "recent", "latest", "chang", "updat", "when", "added", "release",
               "version", "history", "since", "lately", "this week", "today")


_cl_entries = None


def _normalize(s: str) -> str:
    """Collapse the naming variants that broke matching: 'Player Pro' (space) ≡ 'PlayerPro',
    'Cheat Sheet' ≡ 'CheatSheet'. Without this, {player, pro} never matched {playerpro}."""
    s = s.lower()
    s = s.replace("player pro", "playerpro").replace("cheat sheet", "cheatsheet")
    return s


def _changelog_entries():
    """Parse CHANGESLOG.md into {head, body, kind} entries, cached."""
    global _cl_entries
    if _cl_entries is None:
        try:
            raw = CHANGELOG.read_text(encoding="utf-8").splitlines()
        except Exception:
            _cl_entries = []
            return _cl_entries
        entries, cur = [], None
        for ln in raw:
            if ln.startswith("### "):
                if cur:
                    entries.append(cur)
                m = re.match(r"###\s+(\d{4}-\d{2}-\d{2})\s*-\s*(Feature|Improvement|Fix|Change)?",
                             ln, re.I)
                kind = (m.group(2).title() if m and m.group(2) else "Note")
                date = (m.group(1) if m else "")
                cur = {"head": ln[4:].strip(), "body": [], "kind": kind, "date": date,
                       "feat": kind == "Feature"}
            elif cur and ln.strip():
                cur["body"].append(ln.strip())
        if cur:
            entries.append(cur)
        _cl_entries = entries
    return _cl_entries


_URL_LABELS = [
    ("github.com/esaruoho/paketti", "GitHub (source + releases)"),
    ("github.com/sponsors/esaruoho", "GitHub Sponsors"),
    ("esaruoho.github.io/paketti-manual", "Manual"),
    ("esaruoho.github.io/paketti", "GitHub Pages"),
    ("patreon.com/esaruoho", "Patreon"),
    ("discord.gg", "Discord"),
    ("gumroad", "Gumroad"),
    ("ko-fi", "Ko-fi"),
    ("buymeacoffee", "Buy Me a Coffee"),
    ("lackluster.org", "Lackluster (support)"),
    ("forum.renoise.com", "Renoise forum thread"),
]


def _readme_urls():
    """The real Paketti URLs from the README (allowlisted), in encounter order."""
    try:
        txt = Path(PROJECT_DOC).read_text(encoding="utf-8")
    except Exception:
        return []
    seen, urls = set(), []
    for m in re.finditer(r"https?://[^\s)\]>\"']+", txt):
        u = m.group(0).rstrip(".,);:")
        if u not in seen and _link_ok(u):
            seen.add(u)
            urls.append(u)
    return urls


def urls_answer(question: str):
    """Web-presence questions — where Paketti is, its links, where to support — answered
    DETERMINISTICALLY from the README, correctly FRAMED. Paketti lives on GitHub; support links are
    support, not 'where Paketti is'; and there is no paketti.com. No LLM = nothing fabricated."""
    ql = question.lower()
    is_web = re.search(r"\b(urls?|links?|websites?|web ?sites?|homepages?|home ?pages?|official|"
                       r"hosted|host|repo|repository|github|download|online|where)\b", ql)
    is_support = re.search(r"\b(support|donate|donation|fund|contribute|sponsor|patreon|ko-?fi|"
                           r"gumroad|tip|buy ?me)\b", ql)
    if not (is_web or is_support):
        return None
    urls = _readme_urls()
    if not urls:
        return None
    home = [u for u in urls if "github.com/esaruoho/paketti" in u or "esaruoho.github.io" in u
            or "forum.renoise.com" in u]
    support = [u for u in urls if any(t in u.lower() for t in
               ("patreon", "ko-fi", "buymeacoffee", "sponsors/esaruoho", "gumroad", "lackluster.org"))]
    community = [u for u in urls if "discord.gg" in u]

    def block(title, items):
        if not items:
            return ""
        out = [f"**{title}**"]
        for u in items:
            lab = next((l for tok, l in _URL_LABELS if tok in u.lower()), "")
            out.append(f"- {u}" + (f" — {lab}" if lab else ""))
        return "\n".join(out)

    parts = ["**Paketti lives on GitHub** — it's an open-source Renoise tool by **@esaruoho** "
             "(Esa Ruoho). There is no paketti.com.", ""]
    # show ALL sections, clearly labelled — so support links are *labelled* support, never omitted
    # and never mistaken for "where Paketti is".
    for title, items in (("Where it lives", home), ("Support the development", support),
                         ("Community", community)):
        b = block(title, items)
        if b:
            parts += [b, ""]
    return "\n".join(parts).strip()


def changelog_answer(question: str):
    """For 'what is X / what does X do', return Esa's CHANGELOG descriptions — verbatim, no LLM, no
    invention. AGGREGATES every Feature/Improvement entry where the feature is the SUBJECT (the name
    leads the heading), normalized so 'Player Pro'≡'PlayerPro'. Returns None if nothing clearly
    matches (→ undocumented / LLM path)."""
    ql = question.lower()
    if not re.search(r"\b(what is|what'?s|what does|what do|explain|describe|tell me about|how does)\b", ql):
        return None
    subj = _normalize(_Q_BOILER.sub(" ", ql))
    words = {w for w in re.findall(r"[a-z0-9]{3,}", subj) if w not in _FEAT_STOP and w not in _NAME_GENERIC}
    if not words:
        return None
    need = max(2, (len(words) + 1) // 2)
    hits = []
    for e in _changelog_entries():
        if e["kind"] not in ("Feature", "Improvement"):
            continue
        clean = re.sub(r"^(feature|improvement):\s*", "", e["head"], flags=re.I)
        subject = _normalize(clean[:60])                 # the feature must LEAD the heading
        hwords = set(re.findall(r"[a-z0-9]{3,}", subject))
        ov = len(words & hwords)
        if ov >= need:
            hits.append((-ov, 0 if e["kind"] == "Feature" else 1, e))     # best overlap FIRST
    if not hits:
        return None
    hits.sort(key=lambda h: (h[0], h[1], h[2]["date"]))
    seen, lines = set(), []
    for _, _, e in hits:
        date = e.get("date") or e["head"][:10]
        txt = re.sub(r"^\d{4}-\d{2}-\d{2}\s*-\s*(feature|improvement|fix|change):\s*", "",
                     e["head"], flags=re.I).strip()
        body = " ".join(l for l in e["body"]
                        if not l.lstrip().startswith("![") and l.strip() not in ("--", "---"))
        full = (txt + ((" — " + body) if body else "")).strip()[:380]
        key = full[:45].lower()
        if key in seen:
            continue
        seen.add(key)
        lines.append(f"- **{date}:** {full}")
        if len(lines) >= 5:
            break
    lead = ("Here's what the Paketti changelog records for this (Esa's own words — verbatim):\n\n"
            if len(lines) > 1 else "")
    tail = "\n\n*— from the Paketti changelog, Esa's own words.*"
    return lead + "\n".join(lines) + tail


_QUESTION_RE = re.compile(r"\b(what is|what'?s|what does|what do|explain|describe|tell me about|how does)\b")


def _best_index_feature(question: str):
    """The index function whose name best matches the question (canonical feature name + doors)."""
    subj = _Q_BOILER.sub(" ", question.lower())
    words = {w for w in re.findall(r"[a-z0-9]{3,}", subj) if w not in _FEAT_STOP and w not in _NAME_GENERIC}
    if not words:
        return None, ""
    try:
        idx = json.loads(FUNCTIONS_INDEX.read_text(encoding="utf-8"))
    except Exception:
        return None, ""
    best, best_key, best_doors = None, (0, 0), ""
    need = max(2, int(len(words) * 0.6 + 0.5))
    for f in (f for fns in idx.values() for f in fns):
        fwords = set(re.findall(r"[a-z0-9]{3,}", f["function"].lower()))
        ov = len(words & fwords)
        if ov < need:
            continue
        key = (ov, -len(f["function"]))
        if key > best_key:
            best_key, best = key, f["function"]
            best_doors = "".join(g for g, k in (("⌨", "kb"), ("🎛", "midi"), ("☰", "menu")) if f.get(k))
    return best, best_doors


_lua_cache = None


def _lua_files():
    """All Paketti .lua source as (path, text), cached (BSD grep -r was unreliable on the repo)."""
    global _lua_cache
    if _lua_cache is None:
        _lua_cache = []
        try:
            for p in sorted(Path(PAKETTI).rglob("*.lua")):
                if "/.git/" in str(p):
                    continue
                try:
                    _lua_cache.append((p, p.read_text(encoding="utf-8", errors="ignore")))
                except Exception:
                    pass
        except Exception:
            pass
    return _lua_cache


def code_context(question: str, max_lines: int = 70) -> str:
    """Read the ACTUAL Lua implementation of a feature so its behaviour comes from the CODE, not a
    guess: index name → registration (invoke=) → function body. The code is ground truth."""
    if not _QUESTION_RE.search(question.lower()):
        return ""
    canon, _ = _best_index_feature(question)
    if not canon:
        return ""
    phrase = re.sub(r"\s*[.…(].*$", "", canon).strip().lower()   # distinctive contiguous part
    if len(phrase) < 4:
        return ""
    files = _lua_files()
    func, reg_line = None, ""
    for _, content in files:                       # find the registration that names this feature
        low = content.lower()
        i = low.find(phrase)
        while i >= 0:
            ls = content.rfind("\n", 0, i) + 1
            window = content[ls:i + 400]
            if "invoke" in window:
                m = re.search(r"invoke\s*=\s*(?:function\s*\([^)]*\)\s*(?:return\s+)?)?"
                              r"([A-Za-z_][A-Za-z0-9_]+)", window)
                if m and m.group(1).lower() != "function":
                    func = m.group(1)
                    le = content.find("\n", i)
                    reg_line = content[ls:le if le > 0 else i + 120].strip()[:200]
                    break
            i = low.find(phrase, i + 1)
        if func:
            break
    if not func:
        return ""
    body = ""                                       # find that function's definition + body
    defre = re.compile(r"(?:^|\n)\s*(?:local\s+)?function\s+%s\b|(?:^|\n)\s*%s\s*=\s*function"
                       % (re.escape(func), re.escape(func)))
    for _, content in files:
        m = defre.search(content)
        if m:
            start = content.rfind("\n", 0, m.start() + 1) + 1
            body = "\n".join(content[start:].splitlines()[:max_lines])
            break
    if not body:
        return ""
    return ("PAKETTI SOURCE CODE for this feature — describe what it DOES strictly from this Lua (its "
            "status messages, conditions, logic). Do not invent beyond the code.\n\n"
            f"Feature: {canon}  (registered: {reg_line})\n```lua\n{body[:2600]}\n```")


def feature_undocumented_answer(question: str):
    """When a feature EXISTS (it's in the index) but has NO authoritative description — no changelog
    entry, no prose manual section, and no readable source — say so honestly and invite the teach
    loop. NEVER let the model invent behaviour from the name. This is the anti-bullshit guarantee."""
    ql = question.lower()
    if not re.search(r"\b(what is|what'?s|what does|what do|explain|describe|tell me about)\b", ql):
        return None
    if changelog_answer(question) is not None:     # we have Esa's real words
        return None
    if manual_context(question):                   # we have prose docs
        return None
    if code_context(question):                     # we can read the source → describe from it
        return None
    best, best_doors = _best_index_feature(question)
    if not best:
        return None
    return (f"**{best}** {best_doors} — this exists in Paketti, but it isn't described in the "
            f"changelog or manual yet (only its shortcuts are listed). Tell me what it does and I'll "
            f"learn it — or @esaruoho can confirm.")


def changelog_context(question: str, limit: int = 5) -> str:
    """The CHANGELOG is the AUTHORITATIVE description source — Esa writes what each feature DOES when
    he ships it. Return full entries (heading + body), preferring 'Feature:' entries, for the queried
    feature; or the latest entries for a 'what's new' question. This is what fixes the junk: the real
    behaviour lives here, not the auto-generated manual."""
    recency = any(w in question.lower() for w in _CL_RECENCY)
    words = {w for w in re.findall(r"[a-z]{4,}", question.lower()) if w not in _FEAT_STOP}
    entries = _changelog_entries()
    if not entries:
        return ""

    def blob(e):
        return (e["head"] + " " + " ".join(e["body"])).lower()

    if words:
        need = max(1, len(words) // 3)
        hits = [e for e in entries if sum(1 for w in words if w in blob(e)) >= need]
        # prefer the original 'Feature:' description over Fix:/Improvement: entries, then by overlap
        hits.sort(key=lambda e: (e["feat"], sum(1 for w in words if w in blob(e))), reverse=True)
        hits = hits[:limit]
    elif recency:
        hits = entries[:limit]          # newest-first → the latest changes
    else:
        return ""
    if not hits:
        return ""
    out = ["PAKETTI CHANGELOG — the AUTHORITATIVE description of what these features DO (prefer this "
           "over the manual; cite the date):"]
    for e in hits:
        body = " ".join(e["body"])[:600]
        out.append(f"\n### {e['head']}\n{body}".rstrip())
    return "\n".join(out)


def topic_functions_context(question: str, max_funcs: int = 50) -> str:
    """For a broad topic question ('tell me about PlayerPro workflows'), ground in the COMPLETE real
    function list for that topic from the index — so nothing gets cropped. Fixes the OpenMPT gap: a
    feature matching only one topic word ('PlayerPro OpenMPT Linear Keyboard Layer') was ranked out of
    feature_context's keyword sample; here it surfaces because the whole topic set is included."""
    try:
        idx = json.loads(FUNCTIONS_INDEX.read_text(encoding="utf-8"))
    except Exception:
        return ""
    allf = [f for fns in idx.values() for f in fns]
    words = {w for w in re.findall(r"[a-z]{4,}", question.lower()) if w not in _FEAT_STOP}
    if not words:
        return ""
    picked = {}   # function name -> door glyphs
    for w in words:
        matches = [f for f in allf if w in _normalize(f["function"])]
        if 1 <= len(matches) <= 80:        # distinctive topic word (skip generic 'sample'/'track')
            for f in matches:
                picked[f["function"]] = "".join(g for g, k in (("⌨", "kb"), ("🎛", "midi"), ("☰", "menu"))
                                                 if f.get(k))
    if not picked:
        return ""
    names = sorted(picked)[:max_funcs]
    more = f"\n…(+{len(picked) - max_funcs} more)" if len(picked) > max_funcs else ""
    return ("PAKETTI FEATURES for this topic — the COMPLETE real list from the function index. These "
            "are VERIFIED NAMES ONLY (no behaviour). Name ALL the relevant ones, but do NOT describe "
            "what any of them does unless a MANUAL section above describes it — otherwise just list "
            "the name:\n"
            + "\n".join(f"- {n} {picked[n]}" for n in names) + more)


# A URL is only kept if it points at a REAL Paketti resource — every genuine one contains the owner
# handle or a known support host. The model loves to fabricate links (github.com/renoise/paketti);
# anything not on this list is stripped, visible text preserved.
_URL_OK = ("esaruoho", "discord.gg/qex7k5j4wg", "lackluster", "gumroad.com/l/paketti",
           "forum.renoise.com", "gnu.org/licenses", "ko-fi.com/esaruoho", "buymeacoffee.com/esaruoho")


def _link_ok(url: str) -> bool:
    u = url.lower()
    return any(tok in u for tok in _URL_OK)


_AI_JUNK = re.compile(
    r"(as an ai\b|a language model|this chat interface|i (can'?t|cannot|am unable to|am not able to|"
    r"don'?t have the ability to)\s+(directly\s+)?(show|display|attach|render|embed|provide|view|see)"
    r"\s+(you\s+)?(images?|screenshots?|pictures?|photos?|the image)|i'?m (just\s+)?an ai)",
    re.I)


def _strip_ai_boilerplate(text: str) -> str:
    """Kill generic AI-assistant disclaimers ('as an AI I can't display images in this chat
    interface'). It's a Paketti FAQ bot in Discord — it never apologises for being an AI."""
    if not text:
        return text
    out = []
    for ln in text.split("\n"):
        if _AI_JUNK.search(ln):
            sents = re.split(r"(?<=[.!?])\s+", ln)
            ln = " ".join(s for s in sents if not _AI_JUNK.search(s)).strip()
        out.append(ln)
    res = "\n".join(out)
    # drop a leftover "However, I can describe … :" lead-in if it now starts the answer
    res = re.sub(r"^\s*however,?\s+i can (describe|tell|explain|help|guide)[^:.\n]*[:.]\s*", "",
                 res, flags=re.I).strip()
    return re.sub(r"\n{3,}", "\n\n", res).strip() or text


_REAL_HOSTS = ("github.com", "esaruoho.github.io", "patreon.com", "ko-fi.com", "buymeacoffee.com",
               "lackluster.org", "gumroad.com", "discord.gg", "renoise.com", "gnu.org")
_DOMAIN_RE = re.compile(r"\b[a-z0-9][a-z0-9-]*\.(?:com|org|net|io|app|dev|co)\b", re.I)


def _strip_fake_domains(text: str) -> str:
    """Drop any sentence that asserts a FABRICATED domain — the model loves to claim 'paketti.com has
    a page'. A sentence is removed only if it names a domain that isn't a real Paketti/Renoise host."""
    if not text or "." not in text:
        return text
    out = []
    for ln in text.split("\n"):
        kept = []
        for s in re.split(r"(?<=[.!?])\s+", ln):
            doms = _DOMAIN_RE.findall(s)
            if any(not any(h in d.lower() for h in _REAL_HOSTS) for d in doms):
                continue           # names a fabricated domain → drop the whole sentence
            kept.append(s)
        out.append(" ".join(kept))
    return re.sub(r"\n{3,}", "\n\n", "\n".join(out)).strip() or text


def _sanitize_links(text: str) -> str:
    """Remove any URL the model invented (keep allowlisted real Paketti links) and any leaked
    markdown image (changelog `![](Screenshots/…)` refs that Discord renders as broken images)."""
    if not text:
        return text
    text = re.sub(r"!\[[^\]]*\]\([^)]*\)", "", text)        # drop markdown images entirely
    if "http" not in text:
        return text
    # markdown [label](url) → drop the link (keep label) when the URL isn't allowlisted
    text = re.sub(r"\[([^\]]+)\]\((https?://[^)\s]+)\)",
                  lambda m: m.group(0) if _link_ok(m.group(2)) else m.group(1), text)
    # bare URLs → remove when not allowlisted
    text = re.sub(r"https?://[^\s)>\]]+",
                  lambda m: m.group(0) if _link_ok(m.group(0)) else "", text)
    # tidy dangling "For more details, visit:" / link-bullet leftovers + collapse blank lines
    text = re.sub(r"(?im)^[ \t]*(?:🔗|🌐|-|\*|•)?[ \t]*(for more details[^\n]*|visit:?)?[ \t]*$\n?",
                  lambda m: "" if m.group(0).strip().lower().rstrip(":") in
                  ("", "🔗", "🌐", "-", "*", "•", "for more details, visit", "visit") else m.group(0), text)
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def generate_answer(question: str, timeout: int = 180) -> "str | None":
    """Draft a grounded answer. Grounding = any named spine entity + the matching live
    FEATURE-MAP lines (real registered features). A LEAN system + grounding is fed to
    whichever brain: fm-mlx → the Mini's Qwen3-4B (default, capable, no guardrails), or
    fm-submit → the Mini's FoundationModels. The full 12KB skill-arm overwhelms small
    on-device models, so grounding leads instead."""
    grounding = "\n\n".join(c for c in (changelog_context(question), manual_context(question),
                                        code_context(question), topic_functions_context(question),
                                        project_context(question), feature_context(question),
                                        spine_context(question)) if c)
    system = _LEAN_SYSTEM + (("\n\n" + grounding) if grounding else "")
    try:
        if BRAIN == "fm-submit" and FM_SUBMIT.exists():
            cmd = [str(FM_SUBMIT), "--system", system,
                   "--timeout", str(max(60, timeout - 20)), question]
        else:  # fm-mlx → the Mini's Qwen3-4B MLX server (--raw = text only, no speech)
            cmd = [str(FM_MLX), "--raw", "--system", system, question]
        p = subprocess.run(cmd, capture_output=True, text=True, timeout=timeout,
                           stdin=subprocess.DEVNULL)
    except Exception:
        return None
    a = (p.stdout or "").strip()
    if a.lower().startswith("assistant:"):
        a = a.split(":", 1)[1].strip()
    a = _strip_fake_domains(_strip_ai_boilerplate(_sanitize_links(a)))   # kill fabricated URLs/domains/AI junk
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


_TEMPLATE_WORDS = ("how do i", "how can i", "how do you", "can paketti", "does paketti",
                   "what does", "what is", "what are", "is there", "in paketti", "with paketti",
                   "paketti", "the", " a ", " an ")


def _strip_template(q: str) -> str:
    """Drop the boilerplate 'how do I … in Paketti?' scaffolding so the embedding compares the
    CONTENT (schedule patterns vs slice a sample), not the shared template. Without this, NLEmbedding
    rated 'how do i schedule patterns' ↔ 'how do i slice a sample' at 0.837 → a wrong vetted answer."""
    s = " " + q.lower() + " "
    for w in _TEMPLATE_WORDS:
        s = s.replace(w, " ")
    s = re.sub(r"[^a-z ]", " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s or q.lower()       # fall back to the raw question if stripping emptied it


def best_match(question: str, entries: list, vetted_only: bool = True):
    """Return (entry, score) of the closest VETTED vault question, or (None, 0). Matches on the
    content-stripped question so structurally-similar but unrelated questions don't false-match."""
    pool = [e for e in entries if (e.get("status") == "vetted" or not vetted_only)]
    if not pool:
        return None, 0.0
    vecs = embed([_strip_template(question)] + [_strip_template(e["q"]) for e in pool])
    qv = vecs[0]
    best, score = None, -1.0
    for e, v in zip(pool, vecs[1:]):
        s = cosine(qv, v)
        if s > score:
            best, score = e, s
    return best, score
