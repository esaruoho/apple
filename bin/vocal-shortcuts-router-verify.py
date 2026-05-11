#!/usr/bin/env python3
"""
Verify the Hey Sal router resolves audit-matched suggestions to the right
Shortcut. For each unbound-but-audit-matched candidate from
vocal-shortcuts-suggest.py, run several natural phrasings through
sal-siri-match.py and report which resolve.

Why this exists: the router pattern claims to cover N targets with one
trained phrase. That only holds if the matcher actually maps "Hey Sal,
<thing>" to the correct Shortcut. This tool measures that empirically
without anyone speaking.

Usage:
  bin/vocal-shortcuts-router-verify.py            # text report
  bin/vocal-shortcuts-router-verify.py --json
  bin/vocal-shortcuts-router-verify.py --write    # markdown to analysis/

Each row reports the candidate Shortcut, the test phrasings tried, and the
matcher's response per phrasing (resolves to expected / wrong / no-match).
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from datetime import date
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SUGGEST = REPO / "bin/vocal-shortcuts-suggest.py"
MATCHER = REPO / "bin/sal-siri-match.py"
DEFAULT_OUT = REPO / "analysis/sal/vocal-shortcuts-router-verify.md"

# Words that hint at a Shortcut's natural verbalization. The matcher is
# stop-word-aware; we still vary phrasings to test robustness.
PHRASE_TEMPLATES = [
    "{words}",
    "show me {words}",
    "do {words}",
    "run {words}",
]


def get_audit_matched_suggestions() -> list[dict]:
    out = subprocess.run(
        [sys.executable, str(SUGGEST), "--json", "--audit-only"],
        capture_output=True, text=True, check=True,
    ).stdout
    return json.loads(out)["suggestions"]


def humanize(name: str) -> str:
    """'mail-unread-count' or 'MailUnreadCount' → 'mail unread count'."""
    s = re.sub(r"[-_]+", " ", name)
    s = re.sub(r"([a-z])([A-Z])", r"\1 \2", s)
    return s.lower().strip()


def ask_matcher(utterance: str) -> tuple[bool, str]:
    """Run utterance through sal-siri-match.py. Returns (matched, response)."""
    r = subprocess.run(
        [sys.executable, str(MATCHER), utterance],
        capture_output=True, text=True,
    )
    body = r.stdout.strip()
    return (r.returncode == 0 and bool(body)), body


def extract_run_target(matcher_output: str) -> str:
    """
    Pull the Shortcut name out of the matcher's AppleScript body.

    The matcher emits e.g.
        do shell script "/usr/bin/shortcuts run \\"mail-unread-count\\""
    so we have to handle both bare and backslash-escaped quote delimiters.
    """
    m = re.search(r'shortcuts run\s+\\?"([^"\\]+)\\?"', matcher_output)
    return m.group(1) if m else matcher_output


def evaluate_one(shortcut: dict) -> dict:
    name = shortcut["name"]
    human = humanize(name)
    phrasings = [t.format(words=human) for t in PHRASE_TEMPLATES]
    results = []
    correct = 0
    for utt in phrasings:
        matched, body = ask_matcher(utt)
        target = extract_run_target(body) if matched else ""
        ok = matched and target.lower() == name.lower()
        if ok:
            correct += 1
        results.append({
            "phrasing": utt,
            "matched": matched,
            "target": target,
            "correct": ok,
        })
    return {
        "name": name,
        "uuid": shortcut["uuid"],
        "audit_matches": shortcut.get("audit_matches", []),
        "phrasings": results,
        "score": correct,
        "score_max": len(phrasings),
    }


def render_text(rows: list[dict]) -> str:
    out = [f"Router-verification: {len(rows)} audit-matched candidates\n"]
    full = sum(1 for r in rows if r["score"] == r["score_max"])
    partial = sum(1 for r in rows if 0 < r["score"] < r["score_max"])
    none = sum(1 for r in rows if r["score"] == 0)
    out.append(f"Coverage: {full} full-match, {partial} partial, {none} no-match\n")
    for r in sorted(rows, key=lambda x: (-x["score"], x["name"].lower())):
        marker = "✓" if r["score"] == r["score_max"] else ("~" if r["score"] else "✗")
        out.append(f"{marker} {r['name']}  [{r['score']}/{r['score_max']}]")
        for p in r["phrasings"]:
            tag = "ok " if p["correct"] else ("WRONG→" + p["target"] if p["matched"] else "NO-MATCH")
            out.append(f"    \"{p['phrasing']}\"  → {tag}")
    return "\n".join(out)


def render_markdown(rows: list[dict]) -> str:
    full = sum(1 for r in rows if r["score"] == r["score_max"])
    partial = sum(1 for r in rows if 0 < r["score"] < r["score_max"])
    none = sum(1 for r in rows if r["score"] == 0)
    lines = [
        "---",
        "title: Vocal Shortcuts router verification",
        f"date: {date.today().isoformat()}",
        "generator: bin/vocal-shortcuts-router-verify.py",
        "what: simulates Hey Sal voice routing for each audit-matched candidate",
        "---",
        "",
        "# Summary",
        "",
        f"- Candidates tested: **{len(rows)}**",
        f"- Full-match (all phrasings resolve correctly): **{full}**",
        f"- Partial: **{partial}**",
        f"- No-match: **{none}**",
        "",
        "# Detail",
        "",
        "| Shortcut | Score | Notes |",
        "|---|---|---|",
    ]
    for r in sorted(rows, key=lambda x: (-x["score"], x["name"].lower())):
        wrong = [p for p in r["phrasings"] if p["matched"] and not p["correct"]]
        miss = [p for p in r["phrasings"] if not p["matched"]]
        notes = []
        if wrong:
            notes.append(f"wrong: {', '.join(set(p['target'] for p in wrong))}")
        if miss:
            notes.append(f"no-match: {len(miss)}")
        lines.append(f"| `{r['name']}` | {r['score']}/{r['score_max']} | {'; '.join(notes) or '—'} |")
    return "\n".join(lines)


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--json", action="store_true")
    p.add_argument("--write", nargs="?", const=str(DEFAULT_OUT))
    args = p.parse_args()

    suggestions = get_audit_matched_suggestions()
    rows = [evaluate_one(s) for s in suggestions]

    if args.json:
        print(json.dumps({"results": rows}, indent=2))
    else:
        print(render_text(rows))

    if args.write:
        out = Path(args.write)
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_text(render_markdown(rows))
        print(f"\nWrote {out}", file=sys.stderr)

    return 0


if __name__ == "__main__":
    sys.exit(main())
