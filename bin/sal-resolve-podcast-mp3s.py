#!/usr/bin/env python3
"""
Resolve Apple Podcasts URLs to direct MP3 enclosure URLs.

Reads:  analysis/sal/apple-podcast-episodes.txt   (Apple Podcasts page URLs)
Writes: analysis/sal/apple-podcast-mp3-urls.yaml  (resolved MP3 URLs)
        analysis/sal/apple-podcast-mp3-urls.txt   (flat list, one MP3 URL per line)

For each Apple Podcasts URL of the form
  https://podcasts.apple.com/.../id<podcastId>?i=<episodeTrackId>
we:
  1. Call iTunes Lookup API (id=<podcastId>) to get feedUrl + trackName
  2. Call iTunes Lookup again with id=<episodeTrackId> to get the canonical
     episode trackName (and sometimes a direct previewUrl)
  3. Fetch the RSS feed and find the <item> whose <title> matches the
     episode trackName best
  4. Read its <enclosure url="..." /> as the MP3 URL

If the title match is ambiguous, picks the highest-similarity match.
If the feed cannot be fetched or no match found, records the failure
in the YAML so the orchestrator can skip it cleanly.

No API keys, no auth.
"""

from __future__ import annotations

import json
import re
import sys
import time
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from difflib import SequenceMatcher
from pathlib import Path

UA = "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
TIMEOUT = 25

REPO = Path(__file__).resolve().parent.parent
INPUT = REPO / "analysis" / "sal" / "apple-podcast-episodes.txt"
OUT_YAML = REPO / "analysis" / "sal" / "apple-podcast-mp3-urls.yaml"
OUT_TXT = REPO / "analysis" / "sal" / "apple-podcast-mp3-urls.txt"


def fetch(url: str) -> tuple[int, bytes]:
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            return resp.status, resp.read()
    except urllib.error.HTTPError as e:
        return e.code, b""
    except Exception:  # noqa: BLE001
        return 0, b""


def parse_apple_url(url: str) -> tuple[str, str] | None:
    m = re.search(r"/id(\d+)\?(?:.*&)?i=(\d+)", url)
    if not m:
        return None
    return m.group(1), m.group(2)


def itunes_lookup(ids: list[str]) -> dict:
    if not ids:
        return {}
    url = f"https://itunes.apple.com/lookup?id={','.join(ids)}&limit=200"
    status, body = fetch(url)
    if status != 200:
        return {}
    try:
        data = json.loads(body.decode("utf-8"))
    except Exception:  # noqa: BLE001
        return {}
    return {str(r.get("collectionId") or r.get("trackId")): r for r in data.get("results", [])}


def best_match(target: str, candidates: list[tuple[str, dict]]) -> dict | None:
    """candidates is [(title, item_dict), ...]. Returns the highest-similarity item."""
    if not candidates:
        return None
    target_lo = target.lower().strip()
    best = None
    best_score = 0.0
    for title, item in candidates:
        score = SequenceMatcher(None, target_lo, title.lower().strip()).ratio()
        # Boost score if target substring appears in title (common case)
        if target_lo in title.lower():
            score = max(score, 0.85)
        if score > best_score:
            best_score = score
            best = item
    if best_score < 0.45:
        return None
    return best


def parse_rss_for_episodes(feed_xml: bytes) -> list[tuple[str, dict]]:
    """Return [(title, {url, length, type, pub_date}), ...] from an RSS feed."""
    try:
        root = ET.fromstring(feed_xml)
    except ET.ParseError:
        return []
    items = []
    # Find all <item> regardless of namespace
    for item in root.iter():
        if item.tag.split("}")[-1] != "item":
            continue
        title = ""
        enclosure = None
        pub_date = ""
        for child in item:
            tag = child.tag.split("}")[-1]
            if tag == "title" and child.text:
                title = child.text.strip()
            elif tag == "enclosure":
                enclosure = {
                    "url": child.attrib.get("url", ""),
                    "length": child.attrib.get("length", ""),
                    "type": child.attrib.get("type", ""),
                }
            elif tag == "pubDate" and child.text:
                pub_date = child.text.strip()
        if title and enclosure and enclosure["url"]:
            enclosure["pub_date"] = pub_date
            items.append((title, enclosure))
    return items


def slugify(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9]+", "-", s.lower()).strip("-")
    return s[:80] or "untitled"


def main() -> int:
    if not INPUT.exists():
        print(f"input not found: {INPUT}", file=sys.stderr)
        return 1

    apple_urls: list[str] = []
    for line in INPUT.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if line.startswith("http"):
            apple_urls.append(line)

    print(f"Resolving {len(apple_urls)} Apple Podcasts URLs", file=sys.stderr)

    # First pass: collect unique podcast IDs and episode track IDs
    podcast_ids = set()
    pairs: list[tuple[str, str, str]] = []  # (apple_url, podcast_id, episode_id)
    for u in apple_urls:
        parsed = parse_apple_url(u)
        if not parsed:
            print(f"  skip (no id/i): {u}", file=sys.stderr)
            continue
        pid, eid = parsed
        podcast_ids.add(pid)
        pairs.append((u, pid, eid))

    # Bulk lookup the podcasts (gets feedUrl + collectionName per show)
    podcasts = itunes_lookup(sorted(podcast_ids))

    # Cache: feed_url -> [(title, enclosure)]
    feeds: dict[str, list[tuple[str, dict]]] = {}

    # Bulk lookup episodes by trackId for canonical titles (in batches of ~50)
    eids = sorted({eid for _, _, eid in pairs})
    episodes: dict[str, dict] = {}
    BATCH = 50
    for i in range(0, len(eids), BATCH):
        chunk = eids[i : i + BATCH]
        episodes.update(itunes_lookup(chunk))
        time.sleep(0.4)

    resolved = []
    for apple_url, pid, eid in pairs:
        show = podcasts.get(pid, {})
        ep = episodes.get(eid, {})
        feed_url = show.get("feedUrl", "")
        show_name = show.get("collectionName", "")
        episode_title = ep.get("trackName", "")

        record = {
            "apple_url": apple_url,
            "podcast_id": pid,
            "episode_id": eid,
            "show": show_name,
            "feed_url": feed_url,
            "episode_title": episode_title,
            "mp3_url": "",
            "pub_date": "",
            "slug": "",
            "status": "pending",
            "error": "",
        }

        if not feed_url:
            record["status"] = "no-feed"
            record["error"] = "no feedUrl from iTunes Lookup"
            resolved.append(record)
            continue

        if feed_url not in feeds:
            print(f"  fetching feed: {show_name} ({feed_url})", file=sys.stderr)
            status, body = fetch(feed_url)
            if status != 200:
                feeds[feed_url] = []
                record["status"] = "feed-fetch-failed"
                record["error"] = f"HTTP {status}"
                resolved.append(record)
                continue
            feeds[feed_url] = parse_rss_for_episodes(body)
            time.sleep(0.5)

        candidates = feeds[feed_url]
        if not candidates:
            record["status"] = "feed-empty"
            record["error"] = "RSS parse returned 0 items"
            resolved.append(record)
            continue

        target = episode_title or apple_url
        match = best_match(target, candidates)
        if not match:
            record["status"] = "no-match"
            record["error"] = f"no title match for '{target}' among {len(candidates)} items"
            resolved.append(record)
            continue

        record["mp3_url"] = match["url"]
        record["pub_date"] = match.get("pub_date", "")
        record["slug"] = slugify(f"{show_name}-{episode_title}" if episode_title else show_name)
        record["status"] = "resolved"
        resolved.append(record)

    # Write YAML
    yaml_lines = [
        f"# Resolved Apple Podcasts MP3 URLs",
        f"# Total: {len(resolved)}, resolved: {sum(1 for r in resolved if r['status'] == 'resolved')}",
        f"# Generated by bin/sal-resolve-podcast-mp3s.py",
        "",
        "episodes:",
    ]
    for r in resolved:
        yaml_lines.append(f"  - apple_url: {r['apple_url']}")
        yaml_lines.append(f"    podcast_id: '{r['podcast_id']}'")
        yaml_lines.append(f"    episode_id: '{r['episode_id']}'")
        yaml_lines.append(f"    show: {json.dumps(r['show'])}")
        yaml_lines.append(f"    feed_url: {r['feed_url']}")
        yaml_lines.append(f"    episode_title: {json.dumps(r['episode_title'])}")
        yaml_lines.append(f"    mp3_url: {r['mp3_url']}")
        yaml_lines.append(f"    pub_date: {json.dumps(r['pub_date'])}")
        yaml_lines.append(f"    slug: {r['slug']}")
        yaml_lines.append(f"    status: {r['status']}")
        if r["error"]:
            yaml_lines.append(f"    error: {json.dumps(r['error'])}")
    OUT_YAML.write_text("\n".join(yaml_lines) + "\n", encoding="utf-8")

    # Write flat MP3 URL list (only resolved ones)
    txt_lines = ["# Resolved MP3 URLs for Sal Soghoian Apple Podcasts episodes"]
    for r in resolved:
        if r["status"] == "resolved":
            txt_lines.append(f"# {r['show']} — {r['episode_title']}")
            txt_lines.append(r["mp3_url"])
    OUT_TXT.write_text("\n".join(txt_lines) + "\n", encoding="utf-8")

    ok = sum(1 for r in resolved if r["status"] == "resolved")
    print(
        f"\nResolved: {ok}/{len(resolved)}. "
        f"Wrote {OUT_YAML.relative_to(REPO)} and {OUT_TXT.relative_to(REPO)}.",
        file=sys.stderr,
    )
    return 0 if ok > 0 else 2


if __name__ == "__main__":
    sys.exit(main())
