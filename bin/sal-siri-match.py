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
STOPWORDS = {"the","a","an","of","to","in","on","at","my","your","this","that","please","hey","sal"}
MIN_COVERAGE = 0.5  # at least half the intent's content words must be in the utterance

# Sal handlers that target deprecated bundle IDs (Apple changed these post-2016).
# Skip them entirely — they always error -1728 on current macOS.
DEAD_BUNDLES = {"com.apple.iWork.Keynote", "com.apple.iWork.Pages", "com.apple.iWork.Numbers"}
DEAD_LIBRARIES = {"DC-Keynote", "DC-Pages", "DC-Numbers", "DC-Assistive-Keynote", "DC-Keynote-Objects"}

def tokens(s):
    return [w for w in re.findall(r"[a-z0-9]+", s.lower()) if w not in STOPWORDS]

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

    u_set = set(tokens(utterance))
    if not u_set:
        sys.exit(1)

    best = None  # (kind, score, payload, matched_phrase)
    best_score = 0.0

    # Score 1: Sal catalog (DC-XXX commands)
    # Skip handlers that depend on deprecated bundle IDs (they always error -1728)
    if SAL_CATALOG.exists():
        sal = json.load(open(SAL_CATALOG))
        for intent in sal:
            applescript = intent.get("applescript", "")
            # filter out dead-bundle and dead-library references
            if any(b in applescript for b in DEAD_BUNDLES):
                continue
            if any(f'"{lib}"' in applescript for lib in DEAD_LIBRARIES):
                continue
            for ph in intent.get("phrases", []) + [intent.get("primary_phrase","")]:
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

    # Score 2: user's own Shortcuts — prefer over Sal catalog when both match.
    # User-installed Shortcuts often replace broken/legacy Sal handlers (e.g. the
    # Swift-native Take My Picture replaces Sal's broken IKPictureTaker chain).
    # Boost factor 1.5 ensures a user Shortcut wins on equal-token overlap.
    USER_BOOST = 1.5
    user = load_user_catalog()
    for sc in user:
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

    if not best:
        sys.exit(1)

    kind, score, payload, matched = best
    if kind == "sal":
        print(payload["applescript"])
    elif kind == "user":
        # Run the user's Shortcut by UUID via the shortcuts CLI
        uuid = payload["uuid"]
        name = payload["name"].replace('"','\\"')
        print(f'do shell script "/usr/bin/shortcuts run \\"{name}\\""')

if __name__ == "__main__":
    main()

