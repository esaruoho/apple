"""arm_apple — load the Apple skill's knowledge into a chat brain (FM or MLX).

This is the "What would Bearden say" move, applied to the Apple skill. A small
on-device model (Qwen3-4B / FoundationModels) does NOT know the Apple skill from
its weights. So we hand it the knowledge at turn time, exactly the way Convey's
roundtable grounds a persona:

  • IDENTITY (set once, the system prompt)  — who the skill is, the default tool
    order, the hard rules, plus the folder you launched from (cwd context).
  • RETRIEVAL (per turn)                     — the few wiki/ passages most relevant
    to THIS question, pulled by convey.knows.retrieve (lexical overlap, cached).

DRY: the retrieval engine is convey.knows.retrieve — the same function that
grounds the roundtable personas. We do not re-roll it. If convey isn't importable
the chat still works; it just loses per-turn retrieval and leans on the identity
block + the model's own reasoning.

FEATURE-CARD >> features/arm-apple-skill.feature
"""
from __future__ import annotations

import os
import sys
from pathlib import Path

APPLE = Path(__file__).resolve().parent.parent      # ~/work/apple
WIKI = APPLE / "wiki"
SKILL_MD = APPLE / "skill.md"

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
    """The identity block — set ONCE as the chat's system instruction."""
    cwd = cwd or os.getcwd()
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
# we retrieve from the content dirs directly. (k, cap) tuned to weight the
# "how X works" concepts highest while still surfacing entity/lesson pages.
_CORPORA = [
    ("concepts", 4),
    ("entities", 2),
    ("lessons", 1),
    ("devices", 1),
    ("operations", 1),
]


def retrieve_context(query: str, cap: int = 2400) -> str:
    """Per-turn: the wiki passages most relevant to `query`, drawn from the
    content subdirs (not the auto-generated INDEX/compiled catalogs). '' if
    retrieval is unavailable or nothing matched. Reuses convey.knows.retrieve."""
    if _retrieve is None or not query:
        return ""
    blocks, total = [], 0
    for sub, k in _CORPORA:
        d = WIKI / sub
        if not d.is_dir():
            continue
        try:
            b = _retrieve(str(d), query, k=k, cap=cap)
        except Exception:
            b = ""
        if not b:
            continue
        for line in b.splitlines():
            if total + len(line) > cap:
                break
            blocks.append(line)
            total += len(line)
    return "\n".join(blocks)


def augment_prompt(prompt: str, query: str) -> str:
    """Prepend LIVE DATA (real sensor/state readings) and retrieved wiki knowledge
    to a turn's prompt. The query is the raw user line; the prompt is the replayed
    dialogue fm-chat already built. Live data goes first — it's the answer to
    'how hot is the Mini' / 'room temperature' questions a stateless model can't
    otherwise know."""
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
        head.append("RELEVANT KNOWLEDGE (from the Apple wiki — ground your answer "
                    "in this, cite the page paths):\n" + ctx)
    if not head:
        return prompt
    return "\n\n".join(head) + "\n\n" + prompt


def available() -> bool:
    """True if per-turn retrieval is wired (convey.knows importable)."""
    return _retrieve is not None
