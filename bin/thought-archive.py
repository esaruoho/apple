#!/usr/bin/env python3
"""Thought Multiplier — Local Archive Manager

Manages the persistent JSONL archive of seed thoughts.
Works alongside the Ray Browser Studio apps and Agent Scripter pipeline.

Usage:
  thought-archive.py                   # Show stats
  thought-archive.py --tail [N]        # Show last N seeds (default 5)
  thought-archive.py --search QUERY    # Search seeds by keyword
  thought-archive.py --add "text"      # Add a seed from CLI (bypassing Studio)
  thought-archive.py --export FILE     # Export archive to a file
  thought-archive.py --daily           # Seeds per day summary
  thought-archive.py --words [N]       # Top N words across all seeds
"""

import argparse
import json
import os
import sys
from collections import Counter
from datetime import datetime, timezone
from pathlib import Path

ARCHIVE_PATH = Path.home() / "thought-archive.jsonl"

STOP_WORDS = {
    "the", "a", "an", "is", "it", "in", "on", "to", "of", "and", "or", "for",
    "with", "this", "that", "be", "as", "at", "by", "from", "not", "but", "are",
    "was", "were", "been", "have", "has", "had", "do", "does", "did", "will",
    "would", "could", "should", "may", "might", "can", "shall", "i", "you", "he",
    "she", "we", "they", "me", "my", "your", "his", "her", "our", "their", "its",
    "what", "which", "who", "whom", "how", "when", "where", "why", "if", "so",
    "no", "yes", "all", "some", "any", "each", "every", "much", "many", "more",
    "most", "very", "just", "only", "also", "then", "than", "too", "about", "up",
    "out", "into", "over", "after", "before", "between", "through", "during",
    "without", "within", "along", "across", "around", "above", "below", "been",
}


def load_seeds():
    """Load all seeds from the archive."""
    if not ARCHIVE_PATH.exists():
        return []
    seeds = []
    with open(ARCHIVE_PATH) as f:
        for line in f:
            line = line.strip()
            if line:
                try:
                    seeds.append(json.loads(line))
                except json.JSONDecodeError:
                    pass
    return seeds


def add_seed(text):
    """Add a seed to the archive."""
    seed = {
        "ts": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "seed": text,
        "branches": {"archive": True},
        "context_tabs": [],
    }
    with open(ARCHIVE_PATH, "a") as f:
        f.write(json.dumps(seed) + "\n")
    print(f"Seed archived: {seed['ts']}")
    return seed


def show_stats(seeds):
    """Show archive statistics."""
    if not seeds:
        print("Archive empty. Capture your first seed.")
        return

    total = len(seeds)
    first = seeds[0]["ts"][:10]
    last = seeds[-1]["ts"][:10]
    avg_len = sum(len(s["seed"]) for s in seeds) / total

    days = len(set(s["ts"][:10] for s in seeds))
    seeds_per_day = total / max(days, 1)

    print(f"Seeds:      {total}")
    print(f"First:      {first}")
    print(f"Last:       {last}")
    print(f"Days:       {days}")
    print(f"Seeds/day:  {seeds_per_day:.1f}")
    print(f"Avg length: {avg_len:.0f} chars")
    print(f"Archive:    {ARCHIVE_PATH}")


def show_tail(seeds, n=5):
    """Show last N seeds."""
    for s in seeds[-n:]:
        ts = s["ts"][:19].replace("T", " ")
        text = s["seed"][:100]
        if len(s["seed"]) > 100:
            text += "..."
        print(f"  {ts}  {text}")


def search_seeds(seeds, query):
    """Search seeds by keyword."""
    query_lower = query.lower()
    matches = [s for s in seeds if query_lower in s["seed"].lower()]
    if not matches:
        print(f"No seeds matching '{query}'")
        return
    print(f"{len(matches)} match{'es' if len(matches) != 1 else ''}:")
    for s in matches:
        ts = s["ts"][:19].replace("T", " ")
        text = s["seed"][:100]
        if len(s["seed"]) > 100:
            text += "..."
        print(f"  {ts}  {text}")


def show_daily(seeds):
    """Show seeds per day."""
    days = Counter(s["ts"][:10] for s in seeds)
    for day, count in sorted(days.items()):
        bar = "#" * count
        print(f"  {day}  {count:3d}  {bar}")


def show_words(seeds, n=20):
    """Show top N words across all seeds."""
    words = Counter()
    for s in seeds:
        for w in s["seed"].lower().split():
            w = "".join(c for c in w if c.isalpha())
            if len(w) > 2 and w not in STOP_WORDS:
                words[w] += 1
    for word, count in words.most_common(n):
        bar = "#" * min(count, 40)
        print(f"  {word:20s}  {count:3d}  {bar}")


def export_archive(seeds, filepath):
    """Export archive to a file."""
    with open(filepath, "w") as f:
        for s in seeds:
            f.write(json.dumps(s) + "\n")
    print(f"Exported {len(seeds)} seeds to {filepath}")


def main():
    parser = argparse.ArgumentParser(description="Thought Multiplier Archive Manager")
    parser.add_argument("--tail", nargs="?", const=5, type=int, metavar="N", help="Show last N seeds")
    parser.add_argument("--search", type=str, metavar="QUERY", help="Search seeds by keyword")
    parser.add_argument("--add", type=str, metavar="TEXT", help="Add a seed from CLI")
    parser.add_argument("--export", type=str, metavar="FILE", help="Export archive")
    parser.add_argument("--daily", action="store_true", help="Seeds per day")
    parser.add_argument("--words", nargs="?", const=20, type=int, metavar="N", help="Top N words")
    args = parser.parse_args()

    if args.add:
        add_seed(args.add)
        return

    seeds = load_seeds()

    if args.tail is not None:
        show_tail(seeds, args.tail)
    elif args.search:
        search_seeds(seeds, args.search)
    elif args.daily:
        show_daily(seeds)
    elif args.words is not None:
        show_words(seeds, args.words)
    elif args.export:
        export_archive(seeds, args.export)
    else:
        show_stats(seeds)


if __name__ == "__main__":
    main()
