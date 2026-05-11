#!/usr/bin/env python3
"""
Sal's Siri matcher — fuzzy keyword matcher against the 588-intent catalog.

Input:  utterance as $1 (or stdin)
Output: AppleScript body to run, on stdout. Empty stdout means no match.
Exit:   0 = match found, 1 = no match

Uses simple word-overlap scoring. Not as smart as Apple Intelligence
Foundation Models — but works today, no Use Model action needed.
"""
import json
import os
import re
import subprocess
import sys
from pathlib import Path

SAL_CATALOG = Path.home() / "Library/Application Support/Sal-Siri/intents.json"
USER_CATALOG = Path.home() / "Library/Application Support/Sal-Siri/user-shortcuts.json"
STOPWORDS = {"the","a","an","of","to","in","on","at","my","your","this","that","please","hey","sal","me","i"}
MIN_COVERAGE = 0.5  # at least half the intent's content words must be in the utterance

# Leading instruction prefixes that wrap a real target phrase. When present at
# the start of the utterance, the literal verb ("show", "tell") leaks into
# scoring and accidentally matches antonym Shortcuts ("show me hide dock"
# routed to system-events-show-dock instead of -hide-dock). We try both the
# raw and prefix-stripped utterance and take the higher-scoring match — so
# literal "Tell Me Joke" still works while "show me X" routes to X.
COMMAND_PREFIXES = (
    "show me", "tell me", "give me",
    "could you", "can you", "would you",
    "i want to", "i would like to", "i'd like to",
    "please run", "please do", "please",
    "run", "do", "open",
)

# Sal handlers that target deprecated bundle IDs (Apple changed these post-2016).
# Skip them entirely — they always error -1728 on current macOS.
DEAD_BUNDLES = {"com.apple.iWork.Keynote", "com.apple.iWork.Pages", "com.apple.iWork.Numbers"}
DEAD_LIBRARIES = {"DC-Keynote", "DC-Pages", "DC-Numbers", "DC-Assistive-Keynote", "DC-Keynote-Objects"}

def tokens(s):
    return [w for w in re.findall(r"[a-z0-9]+", s.lower()) if w not in STOPWORDS]


def strip_command_prefix(utterance):
    """
    Remove a leading instruction prefix. Returns the stripped utterance,
    or None if no prefix matched (caller can then skip the second pass).
    """
    s = utterance.lower().strip()
    for prefix in COMMAND_PREFIXES:
        if s.startswith(prefix + " "):
            return utterance.strip()[len(prefix):].lstrip()
    return None

def refresh_user_catalog():
    """Run `shortcuts list --show-identifiers` and cache as user-shortcuts.json."""
    try:
        out = subprocess.run(
            ["shortcuts", "list", "--show-identifiers"],
            capture_output=True, text=True, timeout=10,
        )
        if out.returncode != 0:
            return []
        rows = []
        for line in out.stdout.splitlines():
            m = re.match(r"^(.+) \(([0-9A-F-]+)\)$", line.strip())
            if m:
                rows.append({"name": m.group(1), "uuid": m.group(2)})
        USER_CATALOG.parent.mkdir(parents=True, exist_ok=True)
        USER_CATALOG.write_text(json.dumps(rows, indent=2))
        return rows
    except Exception as e:
        print(f"-- user catalog refresh failed: {e}", file=sys.stderr)
        return []

def load_user_catalog():
    # Always refresh if cache is stale (>5 min) or missing.
    # ~0.5s overhead per call, but ensures newly-installed Shortcuts route
    # correctly without the user remembering --refresh.
    import time
    fresh_seconds = 300
    if not USER_CATALOG.exists() or (time.time() - USER_CATALOG.stat().st_mtime) > fresh_seconds:
        return refresh_user_catalog()
    try:
        return json.load(open(USER_CATALOG))
    except Exception:
        return []

USER_BOOST = 1.5  # user Shortcuts win over Sal catalog on equal-token overlap


def best_match(utterance, sal_catalog, user_catalog):
    """
    Score every candidate phrase against `utterance`. Returns
    (kind, score, payload, matched_phrase) or None.

    Pulled out of main() so we can run it on both the raw utterance and the
    prefix-stripped form, then take whichever scores higher.
    """
    u_set = set(tokens(utterance))
    if not u_set:
        return None

    best = None
    best_score = 0.0

    # Sal catalog (DC-XXX commands) — skip handlers using deprecated bundle IDs.
    for intent in sal_catalog:
        applescript = intent.get("applescript", "")
        if any(b in applescript for b in DEAD_BUNDLES):
            continue
        if any(f'"{lib}"' in applescript for lib in DEAD_LIBRARIES):
            continue
        for ph in intent.get("phrases", []) + [intent.get("primary_phrase", "")]:
            t = set(tokens(ph))
            if not t:
                continue
            overlap = len(u_set & t)
            coverage = overlap / len(t)
            if coverage < MIN_COVERAGE:
                continue
            score = overlap + coverage
            if score > best_score:
                best_score = score
                best = ("sal", score, intent, ph)

    # User's own Shortcuts — boosted; replaces broken legacy handlers.
    for sc in user_catalog:
        t = set(tokens(sc["name"]))
        if not t:
            continue
        overlap = len(u_set & t)
        coverage = overlap / len(t)
        if coverage < MIN_COVERAGE:
            continue
        score = (overlap + coverage) * USER_BOOST
        if score > best_score:
            best_score = score
            best = ("user", score, sc, sc["name"])

    return best


def main():
    args = list(sys.argv[1:])
    if "--refresh" in args:
        n = len(refresh_user_catalog())
        print(f"-- refreshed user catalog: {n} entries", file=sys.stderr)
        args = [a for a in args if a != "--refresh"]
    if args:
        utterance = " ".join(args)
    else:
        utterance = sys.stdin.read().strip()
    if not utterance:
        sys.exit(1)

    sal_catalog = json.load(open(SAL_CATALOG)) if SAL_CATALOG.exists() else []
    user_catalog = load_user_catalog()

    # If the utterance opens with an instruction prefix ("show me", "run", …),
    # score the stripped form only — the prefix words are instructional, not
    # content, and leaving them in causes "show me hide dock" to tie-match
    # against system-events-show-dock. If there is no prefix, score the raw
    # utterance. Either way: single pass, no ambiguity.
    scoring_utterance = strip_command_prefix(utterance) or utterance
    best = best_match(scoring_utterance, sal_catalog, user_catalog)
    if best is None:
        sys.exit(1)

    kind, score, payload, matched = best
    if kind == "sal":
        print(payload["applescript"])
    elif kind == "user":
        name = payload["name"].replace('"', '\\"')
        print(f'do shell script "/usr/bin/shortcuts run \\"{name}\\""')

if __name__ == "__main__":
    main()

