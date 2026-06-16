"""arm_apple — load the GOVERNING skill's knowledge into a chat brain (FM or MLX).

This is the "What would Bearden say" move, applied to whichever skill governs the
folder you launched from. A small on-device model (Qwen3-4B / FoundationModels)
does NOT know a skill from its weights. So we hand it the knowledge at turn time,
exactly the way Convey's roundtable grounds a persona:

  • IDENTITY (set once, the system prompt)  — who the skill is, plus the folder you
    launched from (cwd context). Apple is only the FALLBACK; standing in another
    project arms THAT project's skill.
  • RETRIEVAL (per turn)                     — the few passages most relevant to THIS
    question, pulled by convey.knows.retrieve (lexical overlap, cached).

DRY: the retrieval engine is convey.knows.retrieve — the same function that
grounds the roundtable personas. We do not re-roll it. If convey isn't importable
the chat still works; it just loses per-turn retrieval.

FEATURE-CARD >> features/arm-apple-skill.feature
"""
from __future__ import annotations

import os
import re
import sys
from pathlib import Path

APPLE = Path(__file__).resolve().parent.parent      # ~/work/apple
WIKI = APPLE / "wiki"
SKILL_MD = APPLE / "skill.md"
SKILLS_DIR = Path.home() / ".claude" / "skills"     # installed Claude skills

# Reuse convey.knows.retrieve — the engine that grounds the roundtable personas.
_retrieve = None
for _cand in (Path.home() / "work" / "convey", APPLE.parent / "convey"):
    if (_cand / "convey" / "knows.py").exists():
        sys.path.insert(0, str(_cand))
        try:
            from convey.knows import retrieve as _retrieve  # noqa: E402
        except Exception:
            _retrieve = None
        break


# ── which skill governs the folder you launched from ────────────────────────
_ACTIVE: dict | None = None   # set by build_system(); read by retrieve_context()

# Skills whose knowledge is armed ALONGSIDE a project skill (its foundation layer).
# Paketti is a Renoise Lua tool, so the Renoise API reference rides with it — a
# question like "can Paketti change pattern length?" needs both the Paketti feature
# AND the underlying Renoise API it's built on.
_COMPANIONS = {"paketti": ["renoise-api"]}


def _name_tokens(name: str):
    """Candidate skill names from a folder name, longest first. Handles symlink
    targets like 'org.lackluster.Paketti.xrnx' → 'paketti' (strip .xrnx, split on
    dots/dashes/spaces/underscores), so a repo symlinked to a bundle still maps to
    its skill."""
    toks = {name}
    base = name
    for ext in (".xrnx", ".app", ".bundle", ".git"):
        if base.lower().endswith(ext):
            base = base[: -len(ext)]
    toks.add(base)
    for sep in (".", " ", "-", "_"):
        for part in base.split(sep):
            if len(part) > 2:
                toks.add(part)
    return sorted({t for t in toks if t}, key=len, reverse=True)


def _installed_skill(name: str) -> "Path | None":
    """~/.claude/skills/<name>/SKILL.md if that skill is installed, else None.
    Tries the name as-is and lowercased (skills use lowercase-kebab)."""
    for n in (name, name.lower()):
        sp = SKILLS_DIR / n / "SKILL.md"
        if sp.exists():
            return sp
    return None


def detect_skill(cwd: str) -> dict:
    """Find the governing skill of `cwd`. Returns {root, skill_md, name, is_apple,
    corpus}. Resolution order:
      1. an in-repo SKILL.md / skill.md (walk up)            — e.g. impulse-tracker
      2. the folder name matching an installed Claude skill  — e.g. ~/work/paketti
         → ~/.claude/skills/paketti/SKILL.md (skill lives OUTSIDE the repo). Checks
         the symlink name AND the resolved target's tokens (.xrnx bundle → paketti).
      3. Apple (the fallback).
    `corpus` is the list of dirs to retrieve from per turn."""
    raw = Path(cwd)
    real = Path(cwd).resolve()
    home = Path.home()
    # 1. in-repo SKILL.md / skill.md — check raw (symlink) and resolved ancestors.
    seen: set = set()
    for base in (raw, real):
        for d in [base, *base.parents]:
            if d in seen:
                continue
            seen.add(d)
            for fname in ("SKILL.md", "skill.md"):
                sp = d / fname
                if sp.exists():
                    return {"root": d, "skill_md": sp, "name": d.name,
                            "is_apple": d == APPLE, "corpus": [d]}
            if d == home:
                break
    # 2. folder name → an installed Claude skill (paketti repo → paketti skill).
    for base in (raw, real):
        for d in [base, *base.parents]:
            if d == home:
                break
            for tok in _name_tokens(d.name):
                sp = _installed_skill(tok)
                if sp:
                    name = tok.lower()
                    corpus = [d, sp.parent]
                    companions = []
                    for comp in _COMPANIONS.get(name, []):
                        csp = _installed_skill(comp)
                        if csp:
                            companions.append({"name": comp, "skill_md": csp})
                            corpus.append(csp.parent)       # its docs join retrieval
                    return {"root": d, "skill_md": sp, "name": name,
                            "is_apple": False, "corpus": corpus,
                            "companions": companions}
    # 3. Apple fallback
    return {"root": APPLE, "skill_md": SKILL_MD, "name": "apple",
            "is_apple": True, "corpus": None}


def active_label() -> str:
    """Human label for the currently-armed skill (for the chat banner)."""
    s = _ACTIVE or {}
    if s.get("is_apple", True):
        return "Apple skill"
    comps = [c["name"] for c in (s.get("companions") or [])]
    extra = f" +{'+'.join(comps)}" if comps else ""
    return f"{s.get('name', 'project')}{extra} skill"


def _first_chars(path: Path, n: int) -> str:
    try:
        return path.read_text(encoding="utf-8", errors="replace")[:n].strip()
    except Exception:
        return ""


def _folder_context(cwd: str, max_entries: int = 40) -> str:
    """A compact snapshot of the folder the user launched from: a listing plus
    the first lines of any CLAUDE.md / README.md / skill.md that governs it."""
    p = Path(cwd)
    lines = [f"CURRENT FOLDER: {cwd}"]
    try:
        entries = sorted(
            e.name + ("/" if e.is_dir() else "")
            for e in p.iterdir() if not e.name.startswith(".")
        )
        shown = entries[:max_entries]
        more = f"  (+{len(entries) - len(shown)} more)" if len(entries) > len(shown) else ""
        lines.append("Contents: " + ", ".join(shown) + more)
    except Exception:
        pass
    for governing in ("CLAUDE.md", "README.md", "skill.md"):
        gp = p / governing
        if gp.exists():
            snippet = _first_chars(gp, 1400)
            if snippet:
                lines.append(f"\n--- {governing} (governs this folder) ---\n{snippet}")
            break
    return "\n".join(lines)


def build_system(cwd: str | None = None, extra: str = "") -> str:
    """The identity block — set ONCE as the chat's system instruction. Detects
    which skill governs `cwd` and arms THAT one (Apple is the fallback)."""
    global _ACTIVE
    cwd = cwd or os.getcwd()
    _ACTIVE = detect_skill(cwd)
    if _ACTIVE["is_apple"]:
        return _build_apple_system(cwd, extra)
    return _build_generic_system(cwd, _ACTIVE, extra)


def _build_generic_system(cwd: str, skill: dict, extra: str = "") -> str:
    """Identity for any non-Apple project skill: the project's own SKILL.md is
    the identity, its tree is the per-turn retrieval corpus."""
    name = skill["name"]
    skill_core = _first_chars(skill["skill_md"], 6000)
    companions = skill.get("companions") or []
    comp_names = ", ".join(c["name"] for c in companions)
    comp_clause = (f" You ALSO have the {comp_names} reference — the foundation "
                   f"this project is built on — so answer feature questions using "
                   f"both this project's own conventions AND that underlying API."
                   if companions else "")
    parts = [
        f"You are the {name} skill — the development assistant for the \"{name}\" "
        f"project. You help Esa Ruoho work on THIS specific repository. Ground "
        f"every answer in this project's own conventions, build pipeline, source "
        f"files and docs — do NOT give generic advice, and do NOT talk about Apple "
        f"or macOS automation unless this project is actually about that." + comp_clause,
        "",
        "HARD RULES: Never invent file names, functions, build steps, flags or "
        "APIs. Cite only ones that appear in THE SKILL (or COMPANION) below or in "
        "the RELEVANT KNOWLEDGE retrieved each turn, or that you are certain of. If "
        "you don't know, say so plainly. Be concise and concrete; prefer a real "
        "file path or command over prose.",
        "",
        f"--- THE SKILL ({skill['skill_md'].name}, abridged) ---",
        skill_core,
    ]
    for c in companions:
        parts += ["", f"--- COMPANION: the {c['name']} reference (abridged) ---",
                  _first_chars(c["skill_md"], 3000)]
    parts += [
        "",
        "--- WHERE YOU ARE ---",
        _folder_context(cwd),
    ]
    if extra:
        parts += ["", extra.strip()]
    parts += [
        "",
        "Each turn you may be given RELEVANT KNOWLEDGE retrieved from this "
        "project's docs. Ground your answer in it and cite the file path when you "
        "use one.",
    ]
    return "\n".join(parts)


def _build_apple_system(cwd: str, extra: str = "") -> str:
    """The Apple skill identity — the original hand-crafted block (with live data)."""
    skill_core = _first_chars(SKILL_MD, 6000)
    parts = [
        "You are the Apple skill — \"Product Manager of Automation Technologies\", "
        "the role Apple eliminated in 2016, continued as open-source. You help Esa "
        "Ruoho automate his macOS (Sequoia) workday: AppleScript, Shortcuts, "
        "Automator, hardware triggers (Loupedeck/Stream Deck), and the bin/ tools "
        "in this repo.",
        "",
        "DEFAULT TOOL ORDER when a task needs code: (1) AppleScript + ASObjC "
        "(`use framework \"Foundation\"`), (2) Python stdlib, (3) Swift compile, "
        "(4) shell for Apple-shipped CLIs only.",
        "",
        "HARD RULES: Never claim a Cocoa class exists unless it appears in the "
        "knowledge you are given (the skill probes with `bin/cocoa-class-probe` "
        "first). Never invent bin/ tool names or wiki page paths — only cite ones "
        "that appear in the RELEVANT KNOWLEDGE below or that you are certain of. If "
        "you don't know, say so plainly. Be concise and concrete; prefer a command "
        "or a file path over prose.",
        "",
        "--- THE SKILL (skill.md, abridged) ---",
        skill_core,
        "",
        "--- WHERE YOU ARE ---",
        _folder_context(cwd),
    ]
    if extra:
        parts += ["", extra.strip()]
    parts += [
        "",
        "For each question you may be given LIVE DATA (real sensor/state readings — "
        "room climate from the HomePod, and per-machine CPU/GPU die temps, load, "
        "memory, uptime, battery from the fleet's machine cards) and RELEVANT "
        "KNOWLEDGE retrieved from the Apple wiki. When LIVE DATA is present, answer "
        "live-state questions with those exact numbers — do NOT claim you have no "
        "sensor access. Ground other answers in the knowledge and cite the wiki/ "
        "page path when you use one.",
    ]
    return "\n".join(parts)


# Content lives in these subdirs (real prose). INDEX.md and compiled/ are
# auto-generated catalogs — they over-match lexically and crowd out content, so
# we retrieve from the content dirs directly.
_CORPORA = [
    ("concepts", 4),
    ("entities", 2),
    ("lessons", 1),
    ("devices", 1),
    ("operations", 1),
]


# Plain-text feature/keybinding manifests a project ships — the GROUND TRUTH that
# .md retrieval (convey.knows reads only *.md) never sees. For Paketti this is the
# authoritative "what features exist" list, e.g.
#   Paketti:Set Pattern Length to 016 (010)|||CTRL + 3
_FEATURE_MANIFESTS = ("autocomplete_shortcuts.txt", "action_selector_settings.txt")


def _feature_lines(query: str, roots, cap: int = 2200) -> str:
    """Ground-truth feature/keybinding lines from the project's shortcut manifests,
    ranked by how many query terms they contain. This is what makes "does Paketti
    have pattern length?" answer correctly — the keybindings live in .txt/.lua, not
    the .md docs the lexical retriever reads."""
    terms = _expand(_query_terms(query))
    if not terms:
        return ""
    scored, seen = [], set()
    for root in roots:
        for name in _FEATURE_MANIFESTS:
            fp = Path(root) / name
            if not fp.is_file():
                continue
            try:
                lines = fp.read_text(encoding="utf-8", errors="replace").splitlines()
            except Exception:
                continue
            for s in (ln.strip() for ln in lines):
                if not s or s in seen:
                    continue
                low = s.lower()
                score = sum(1 for t in terms if t in low)
                if score:
                    seen.add(s)
                    scored.append((score, s))
    scored.sort(key=lambda x: -x[0])
    out, total = [], 0
    for _score, line in scored:
        if total + len(line) + 2 > cap:
            break
        out.append("- " + line)
        total += len(line) + 2
    return "\n".join(out)


# Domain synonyms so the user's word reaches the code's word (Renoise/tracker
# vocab): "resize" never appears in code that says "length". Bridges the gap.
_SYNONYMS = {
    "resize": ["length", "lines", "size", "rows", "expand", "shrink", "longer", "shorter"],
    "length": ["lines", "size", "rows"], "size": ["length", "lines", "rows"],
    "tempo": ["bpm"], "speed": ["bpm", "lpb", "tempo"], "bpm": ["bpm", "tempo"],
    "sample": ["instrument", "slice", "wav"], "render": ["wav", "bounce", "export"],
    "midi": ["mapping", "cc", "controller"], "shortcut": ["keybinding"],
    "fill": ["interpolate", "write"], "double": ["doubler"], "halve": ["halver"],
}


# Stopwords + the project name (matches everything) — excluded from ranking.
_STOP = {"can", "the", "and", "for", "with", "you", "your", "how", "does", "did",
         "has", "have", "what", "where", "when", "why", "which", "this", "that",
         "there", "are", "any", "use", "using", "make", "made", "paketti", "renoise",
         "able", "want", "need", "way", "system", "feature", "features", "tool"}


def _query_terms(query: str) -> set:
    return {t for t in re.split(r"[^a-z0-9]+", (query or "").lower())
            if len(t) > 2 and t not in _STOP}


def _expand(terms: set) -> set:
    out = set(terms)
    for t in list(terms):
        out.update(_SYNONYMS.get(t, []))
    return out


def _source_grep(query: str, roots, cap: int = 2400, top: int = 5, max_funcs: int = 24) -> str:
    """The CODEBASE view. Ranks source files by query (+ domain synonyms) over the
    FILENAME and the CONTENT, then lists each winner's functions and keybinding/menu
    registrations — so the bot sees the dialog / relative-adjust / arbitrary-length
    code (the real implementation), not just the fixed shortcuts in the manifest."""
    base = _query_terms(query)
    if not base:
        return ""
    terms = _expand(base)
    func_re = re.compile(r"^\s*(?:local\s+)?function\s+[\w:.]+|add_keybinding|add_menu_entry|add_midi_mapping")
    scored = []
    for root in roots:
        for fp in Path(root).rglob("*.lua"):
            try:
                txt = fp.read_text(encoding="utf-8", errors="replace")
            except Exception:
                continue
            low = txt.lower()
            name_low = fp.name.lower()
            # Filename match DOMINATES (PakettiPatternLength.lua is literally about
            # pattern length); content frequency is only a tiebreak, so a big general
            # file can't bury the focused one.
            name_hits = sum(1 for t in terms if t in name_low)
            content = sum(min(low.count(t), 6) for t in terms)
            score = name_hits * 100 + min(content, 30)
            if score:
                scored.append((score, fp, txt))
    scored.sort(key=lambda x: -x[0])
    out, total = [], 0
    for _s, fp, txt in scored[:top]:
        defs = [ln.strip()[:150] for ln in txt.splitlines() if func_re.match(ln)]
        if not defs:
            continue
        block = (f"{fp.name} — functions & registrations (the actual code):\n"
                 + "\n".join("  · " + d for d in defs[:max_funcs]))
        if total + len(block) > cap:
            break
        out.append(block)
        total += len(block)
    return "\n\n".join(out)


def retrieve_context(query: str, cap: int = 2400) -> str:
    """Per-turn: the passages most relevant to `query`. For Apple, the wiki content
    subdirs; for any project skill, the keybinding MANIFESTS + the actual CODEBASE
    (matching .lua functions) first (ground truth), then the project's .md docs."""
    skill = _ACTIVE or detect_skill(os.getcwd())
    blocks, total = [], 0

    # Project skills: lead with authoritative keybindings AND the real code.
    if not skill.get("is_apple", True):
        roots = skill.get("corpus") or [skill["root"]]
        feat = _feature_lines(query, roots)
        if feat:
            blocks.append("EXACT FEATURES / KEYBINDINGS (authoritative — answer FROM "
                          "these; a feature's absence from the prose below does NOT "
                          "mean it doesn't exist):")
            blocks.append(feat)
            total += len(feat)
        src = _source_grep(query, roots)
        if src:
            blocks.append("\nSOURCE CODE (the actual implementation — these functions "
                          "exist; describe what they do, e.g. a dialog or relative "
                          "adjust is MORE than the fixed shortcuts):")
            blocks.append(src)
            total += len(src)
        corpora = [(d, 6) for d in roots]
    else:
        corpora = [(WIKI / sub, k) for sub, k in _CORPORA]

    # Then the lexical .md retrieval (convey.knows), if available.
    if _retrieve is not None and query:
        for d, k in corpora:
            if not Path(d).is_dir():
                continue
            try:
                b = _retrieve(str(d), query, k=k, cap=cap)
            except Exception:
                b = ""
            if not b:
                continue
            for line in b.splitlines():
                if total + len(line) > cap + 2200:   # extra room for the manifest lines
                    break
                blocks.append(line)
                total += len(line)
    return "\n".join(blocks)


def augment_prompt(prompt: str, query: str) -> str:
    """Prepend LIVE DATA (real sensor/state readings) and retrieved knowledge to a
    turn's prompt. Live data goes first — it's the answer to 'how hot is the Mini'
    questions a stateless model can't otherwise know."""
    head = []
    try:
        import live_data                      # bin/live_data.py (sys.path has HERE)
        live = live_data.lookup(query)
        if live:
            head.append(live)
    except Exception:
        pass
    ctx = retrieve_context(query)
    if ctx:
        src = "the Apple wiki" if (_ACTIVE or {}).get("is_apple", True) else "this project's docs"
        head.append(f"RELEVANT KNOWLEDGE (from {src} — ground your answer "
                    "in this, cite the file paths):\n" + ctx)
    if not head:
        return prompt
    return "\n\n".join(head) + "\n\n" + prompt


def available() -> bool:
    """True if per-turn retrieval is wired (convey.knows importable)."""
    return _retrieve is not None
