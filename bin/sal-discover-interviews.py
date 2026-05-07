#!/usr/bin/env python3
"""
Sal Soghoian interview / article / podcast discovery.

Probes a curated list of likely sources (Mac journalism, podcast indexes,
Internet Archive, Wayback CDX, YouTube) for any mention of Sal Soghoian
and writes the consolidated hit list to:

  - analysis/sal/interviews-discovered.md     (human-readable report)
  - indexes/sal-interviews-discovered.yaml    (machine-readable index)

Network is the only requirement. No API keys, no paid services. Sites
that aggressively block scrapers may return zero hits — that is recorded
honestly (not faked into noise).

Usage:
  python3 bin/sal-discover-interviews.py
  python3 bin/sal-discover-interviews.py --query Soghoian   # default
  python3 bin/sal-discover-interviews.py --skip youtube,wayback
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import time
import urllib.parse
import urllib.request
from datetime import datetime, timezone
from html import unescape
from pathlib import Path

UA = (
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_0) "
    "AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
)
TIMEOUT = 20

# Disambiguation: "Soghoian" matches both Sal (Apple automation) and
# Christopher (privacy researcher, ACLU, Defcon/TED talks). Keep Sal hits
# only when surrounding text matches an Apple/automation keyword OR does
# NOT match a Christopher-context keyword.
SAL_POSITIVE = (
    "applescript", "automator", "automation", "apple ", "macos", "mac os",
    "macintosh", "iwork", "keynote", "numbers", "pages", "shortcuts",
    "sal soghoian", "macautomation", "cmd-d", "cmdd", "iphoto", "photos automation",
    "siri", "dictation commands", "wwdc", "user automation",
    "quark", "xtensions", "publishing", "filemaker", "cocoa", "pro applications",
)
CHRIS_NEGATIVE = (
    "christopher soghoian", "chris soghoian", "surveillance", "wiretap",
    "encryption", "aclu", "defcon", "def con", "fbi", "nsa", "privacy",
    "civil rights", "smartphone", "crypto wars", "stingray", "ted.com",
    "ted talk", "lawfare", "pirate tv", "weisberg", "bin laden",
    "florence m", "richard j", "dr. richard",
)


def is_likely_sal(haystack: str) -> bool:
    """Return True if haystack looks like a Sal Soghoian (Apple) hit, not
    Christopher Soghoian (privacy)."""
    h = haystack.lower()
    if any(k in h for k in CHRIS_NEGATIVE):
        return False
    if any(k in h for k in SAL_POSITIVE):
        return True
    # No positive and no negative: keep as "uncertain" — caller may filter
    return False

REPO = Path(__file__).resolve().parent.parent
OUT_MD = REPO / "analysis" / "sal" / "interviews-discovered.md"
OUT_YAML = REPO / "indexes" / "sal-interviews-discovered.yaml"


def fetch(url: str) -> tuple[int, str]:
    req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "*/*"})
    try:
        with urllib.request.urlopen(req, timeout=TIMEOUT) as resp:
            data = resp.read()
            try:
                return resp.status, data.decode("utf-8")
            except UnicodeDecodeError:
                return resp.status, data.decode("utf-8", errors="replace")
    except urllib.error.HTTPError as e:
        return e.code, ""
    except Exception as e:  # noqa: BLE001
        return 0, f"__ERR__:{e!r}"


# ---------------------------------------------------------------------------
# Site search probes
# ---------------------------------------------------------------------------


def probe_site_search(name: str, search_url: str, link_pattern: str, query: str) -> list[dict]:
    """Hit a site search URL, return [{title, url}, ...] for links whose anchor
    text or surrounding HTML mentions the query.
    """
    status, html = fetch(search_url)
    if status != 200 or not html:
        return [{"title": f"[probe failed: HTTP {status}]", "url": search_url}]
    # Find every <a> matching the pattern
    hits = []
    for m in re.finditer(link_pattern, html, re.I | re.S):
        url = unescape(m.group("url"))
        title = re.sub(r"<[^>]+>", "", m.group("title")).strip()
        title = unescape(re.sub(r"\s+", " ", title))
        if not url or not title:
            continue
        if query.lower() in (title.lower() + " " + url.lower()):
            if url.startswith("/"):
                base = re.match(r"https?://[^/]+", search_url).group(0)
                url = base + url
            hits.append({"title": title, "url": url})
    # Dedupe by URL
    seen = set()
    deduped = []
    for h in hits:
        if h["url"] in seen:
            continue
        seen.add(h["url"])
        deduped.append(h)
    return deduped


SITE_SOURCES = [
    {
        "name": "TidBITS",
        "search": "https://tidbits.com/?s={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://tidbits\.com/[^"]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "MacStories",
        "search": "https://www.macstories.net/?s={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.macstories\.net/[^"]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "Six Colors",
        "search": "https://sixcolors.com/?s={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://sixcolors\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "Cult of Mac",
        "search": "https://www.cultofmac.com/?s={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.cultofmac\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "9to5Mac",
        "search": "https://9to5mac.com/?s={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://9to5mac\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "Daring Fireball (Gruber)",
        "search": "https://daringfireball.net/search/?q={q}",
        "pattern": r'<a[^>]+href="(?P<url>https?://daringfireball\.net/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "MacRumors",
        "search": "https://www.macrumors.com/search/?q={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.macrumors\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "iMore",
        "search": "https://www.imore.com/search?searchTerm={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.imore\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "Macworld",
        "search": "https://www.macworld.com/search?q={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.macworld\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "Ars Technica",
        "search": "https://arstechnica.com/search/?ie=UTF-8&q={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://arstechnica\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "The Verge",
        "search": "https://www.theverge.com/search?q={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.theverge\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "Relay FM",
        "search": "https://www.relay.fm/search?query={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.relay\.fm/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
    {
        "name": "MacSparky (David Sparks)",
        "search": "https://www.macsparky.com/search?q={q}",
        "pattern": r'<a[^>]+href="(?P<url>https://www\.macsparky\.com/[^"#?]+)"[^>]*>(?P<title>[^<]+)</a>',
    },
]


# ---------------------------------------------------------------------------
# Internet Archive
# ---------------------------------------------------------------------------


def probe_internet_archive(query: str) -> list[dict]:
    url = (
        "https://archive.org/advancedsearch.php?"
        f"q={urllib.parse.quote(query)}"
        "&fl%5B%5D=identifier&fl%5B%5D=title&fl%5B%5D=mediatype"
        "&fl%5B%5D=date&fl%5B%5D=creator"
        "&output=json&rows=100"
    )
    status, body = fetch(url)
    if status != 200:
        return [{"title": f"[probe failed: HTTP {status}]", "url": url}]
    try:
        docs = json.loads(body).get("response", {}).get("docs", [])
    except Exception:  # noqa: BLE001
        return []
    hits = []
    for d in docs:
        ident = d.get("identifier", "")
        title = d.get("title", "")
        if isinstance(title, list):
            title = title[0] if title else ""
        creator = d.get("creator", "")
        if isinstance(creator, list):
            creator = "; ".join(creator)
        date = d.get("date", "")
        if isinstance(date, list):
            date = date[0] if date else ""
        mediatype = d.get("mediatype", "")
        haystack = f"{title} {creator} {ident}".lower()
        if "soghoian" not in haystack and "macautomation" not in haystack:
            continue
        if not is_likely_sal(haystack):
            continue
        hits.append(
            {
                "title": f"{title} ({mediatype}, {date}, by {creator})" if creator else title,
                "url": f"https://archive.org/details/{ident}",
            }
        )
    return hits


# ---------------------------------------------------------------------------
# Wayback CDX
# ---------------------------------------------------------------------------


def probe_wayback_cdx(target_url: str, label: str) -> list[dict]:
    cdx = (
        "https://web.archive.org/cdx/search/cdx?"
        f"url={urllib.parse.quote(target_url, safe='')}"
        "&output=json&limit=2000&filter=statuscode:200&collapse=urlkey"
    )
    # Wayback CDX rate-limits aggressively; retry with backoff on 503/429/0
    for attempt in range(4):
        status, body = fetch(cdx)
        if status == 200 and body.strip().startswith("["):
            break
        time.sleep(2 ** attempt * 1.5)
    if status != 200 or not body.strip().startswith("["):
        return [{"title": f"[CDX failed for {label}: HTTP {status} after retries]", "url": cdx}]
    try:
        rows = json.loads(body)
    except Exception:  # noqa: BLE001
        return []
    if not rows or len(rows) < 2:
        return []
    hits = []
    for row in rows[1:]:  # skip header
        ts, original = row[1], row[2]
        snapshot = f"https://web.archive.org/web/{ts}/{original}"
        hits.append({"title": f"{label} snapshot {ts}", "url": snapshot})
    return hits


# ---------------------------------------------------------------------------
# Hacker News (Algolia)
# ---------------------------------------------------------------------------


def probe_hn_algolia(query: str) -> list[dict]:
    """HN search via Algolia API — no auth, returns JSON."""
    url = (
        "https://hn.algolia.com/api/v1/search?"
        f"query={urllib.parse.quote_plus(query)}&tags=story&hitsPerPage=100"
    )
    status, body = fetch(url)
    if status != 200:
        return [{"title": f"[HN failed: HTTP {status}]", "url": url}]
    try:
        data = json.loads(body)
    except Exception:  # noqa: BLE001
        return []
    hits = []
    for h in data.get("hits", []):
        title = h.get("title") or h.get("story_title") or ""
        href = h.get("url") or f"https://news.ycombinator.com/item?id={h.get('objectID', '')}"
        hn_link = f"https://news.ycombinator.com/item?id={h.get('objectID', '')}"
        haystack = f"{title} {href}".lower()
        if not is_likely_sal(haystack):
            continue
        hits.append({"title": f"{title} (HN: {hn_link})", "url": href})
    return hits


# ---------------------------------------------------------------------------
# Apple Podcasts (iTunes Search API)
# ---------------------------------------------------------------------------


def probe_apple_podcasts(query: str) -> list[dict]:
    """Apple Podcasts via iTunes Search API — no auth, JSON."""
    hits = []
    for entity in ("podcast", "podcastEpisode"):
        url = (
            "https://itunes.apple.com/search?"
            f"term={urllib.parse.quote_plus(query)}&entity={entity}&limit=50"
        )
        status, body = fetch(url)
        if status != 200:
            continue
        try:
            data = json.loads(body)
        except Exception:  # noqa: BLE001
            continue
        for r in data.get("results", []):
            title = (
                r.get("trackName")
                or r.get("collectionName")
                or r.get("artistName")
                or ""
            )
            artist = r.get("artistName") or r.get("collectionName") or ""
            href = (
                r.get("trackViewUrl")
                or r.get("collectionViewUrl")
                or r.get("artistViewUrl")
                or ""
            )
            haystack = f"{title} {artist} {r.get('description', '')}".lower()
            if not is_likely_sal(haystack):
                continue
            label = f"{title} — {artist}" if artist and artist != title else title
            hits.append({"title": f"[{entity}] {label}", "url": href})
        time.sleep(0.5)
    return hits


# ---------------------------------------------------------------------------
# Reddit (public JSON)
# ---------------------------------------------------------------------------


def probe_reddit(query: str) -> list[dict]:
    """Reddit search via public .json endpoint — rate-limited but no auth."""
    url = (
        "https://www.reddit.com/search.json?"
        f"q={urllib.parse.quote_plus(query)}&limit=100&sort=relevance"
    )
    status, body = fetch(url)
    if status != 200:
        return [{"title": f"[Reddit failed: HTTP {status}]", "url": url}]
    try:
        data = json.loads(body)
    except Exception:  # noqa: BLE001
        return []
    hits = []
    for child in data.get("data", {}).get("children", []):
        d = child.get("data", {})
        title = d.get("title", "")
        permalink = d.get("permalink", "")
        subreddit = d.get("subreddit", "")
        selftext = d.get("selftext", "") or ""
        haystack = f"{title} {selftext} r/{subreddit}".lower()
        if not is_likely_sal(haystack):
            continue
        full_url = f"https://www.reddit.com{permalink}" if permalink else ""
        hits.append({"title": f"r/{subreddit}: {title}", "url": full_url})
    return hits


# ---------------------------------------------------------------------------
# DuckDuckGo HTML search (covers JS-rendered Mac journalism sites)
# ---------------------------------------------------------------------------


JS_RENDERED_SITES = [
    "tidbits.com",
    "macstories.net",
    "sixcolors.com",
    "daringfireball.net",
    "macrumors.com",
    "macworld.com",
    "imore.com",
    "arstechnica.com",
    "theverge.com",
    "relay.fm",
    "macsparky.com",
    "cultofmac.com",
    "9to5mac.com",
    "appleinsider.com",
    "macobserver.com",
    "podfeet.com",
    "automators.fm",
    "atp.fm",
    "macvoices.com",
    "mactech.com",
    "applescriptpro.com",
]


def probe_ddg_for_site(query: str, site: str) -> list[dict]:
    q = f'"{query}" site:{site}'
    url = f"https://html.duckduckgo.com/html/?q={urllib.parse.quote_plus(q)}"
    status, html = fetch(url)
    if status != 200 or not html:
        return [{"title": f"[DDG failed for {site}: HTTP {status}]", "url": url}]
    # DDG result links wrap the real URL in /l/?uddg=<encoded>
    pattern = re.compile(
        r'<a[^>]+class="[^"]*result__a[^"]*"[^>]+href="(?P<href>[^"]+)"[^>]*>(?P<title>.*?)</a>',
        re.I | re.S,
    )
    hits = []
    for m in pattern.finditer(html):
        href = m.group("href")
        # Unwrap DDG redirect
        if "uddg=" in href:
            try:
                qs = urllib.parse.urlparse(href).query
                u = urllib.parse.parse_qs(qs).get("uddg", [""])[0]
                href = urllib.parse.unquote(u)
            except Exception:  # noqa: BLE001
                pass
        title = unescape(re.sub(r"<[^>]+>", "", m.group("title"))).strip()
        title = re.sub(r"\s+", " ", title)
        if not href.startswith("http"):
            continue
        if site not in href:
            continue
        if query.lower() not in (title.lower() + " " + href.lower()):
            continue
        if not is_likely_sal(title + " " + href):
            continue
        hits.append({"title": title, "url": href})
    # Dedupe
    seen = set()
    deduped = []
    for h in hits:
        if h["url"] in seen:
            continue
        seen.add(h["url"])
        deduped.append(h)
    return deduped


# ---------------------------------------------------------------------------
# YouTube via yt-dlp
# ---------------------------------------------------------------------------


def probe_youtube(query: str, max_results: int = 30) -> list[dict]:
    """Use yt-dlp to search YouTube without API keys."""
    try:
        out = subprocess.run(
            [
                "yt-dlp",
                f"ytsearch{max_results}:{query}",
                "--flat-playlist",
                "--dump-json",
                "--quiet",
                "--no-warnings",
            ],
            capture_output=True,
            text=True,
            timeout=120,
        )
    except FileNotFoundError:
        return [{"title": "[yt-dlp not installed]", "url": "https://github.com/yt-dlp/yt-dlp"}]
    except subprocess.TimeoutExpired:
        return [{"title": "[yt-dlp timed out]", "url": ""}]
    hits = []
    for line in out.stdout.splitlines():
        line = line.strip()
        if not line:
            continue
        try:
            obj = json.loads(line)
        except Exception:  # noqa: BLE001
            continue
        title = obj.get("title", "")
        vid = obj.get("id", "")
        uploader = obj.get("uploader") or obj.get("channel") or ""
        if not vid:
            continue
        haystack = f"{title} {uploader}".lower()
        if "soghoian" not in haystack and "macautomation" not in haystack:
            continue
        if not is_likely_sal(haystack):
            continue
        hits.append({"title": f"{title} — {uploader}", "url": f"https://www.youtube.com/watch?v={vid}"})
    return hits


# ---------------------------------------------------------------------------
# Aggregation
# ---------------------------------------------------------------------------


def render_markdown(query: str, results: dict) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    lines = [
        f"# Sal Soghoian Interview / Article / Podcast Discovery",
        "",
        f"Query: `{query}`",
        f"Generated: {now}",
        "",
        "Sources probed (no API keys, no paid services). Empty sections mean either the",
        "site has no hits for the query or its search returned a blocked / non-200 response.",
        "",
        "## Summary",
        "",
    ]
    total = sum(len(v) for v in results.values())
    lines.append(f"- Total hits across all sources: **{total}**")
    for source, hits in sorted(results.items()):
        lines.append(f"- {source}: **{len(hits)}**")
    lines.extend(["", "## Hits by source", ""])
    for source in sorted(results):
        lines.append(f"### {source}")
        lines.append("")
        if not results[source]:
            lines.append("_No hits._")
            lines.append("")
            continue
        for h in results[source]:
            t = h["title"].replace("\n", " ").strip()
            lines.append(f"- [{t}]({h['url']})")
        lines.append("")
    return "\n".join(lines) + "\n"


def render_yaml(query: str, results: dict) -> str:
    now = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    lines = [
        f"query: {query}",
        f"generated: {now}",
        "sources:",
    ]
    for source in sorted(results):
        lines.append(f"  - name: {source!r}")
        lines.append(f"    hit_count: {len(results[source])}")
        lines.append("    hits:")
        for h in results[source]:
            t = h["title"].replace("'", "''")
            lines.append(f"      - title: '{t}'")
            lines.append(f"        url: {h['url']}")
    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--query", default="Soghoian", help="search term (default: Soghoian)")
    parser.add_argument(
        "--skip",
        default="",
        help="comma-separated source categories to skip: sites,wayback,archive,youtube",
    )
    args = parser.parse_args()
    query = args.query
    skip = {s.strip().lower() for s in args.skip.split(",") if s.strip()}

    results: dict[str, list[dict]] = {}

    if "sites" not in skip:
        for src in SITE_SOURCES:
            url = src["search"].format(q=urllib.parse.quote_plus(query))
            print(f"[sites] {src['name']}: {url}", file=sys.stderr)
            hits = probe_site_search(src["name"], url, src["pattern"], query)
            # Drop the synthetic "probe failed" placeholders for clean reports
            real_hits = [h for h in hits if not h["title"].startswith("[probe failed")]
            results[src["name"]] = real_hits
            time.sleep(0.6)

    if "archive" not in skip:
        print(f"[archive] Internet Archive search", file=sys.stderr)
        results["Internet Archive"] = probe_internet_archive(query)
        time.sleep(0.6)

    if "wayback" not in skip:
        print(f"[wayback] @macautomation Twitter CDX", file=sys.stderr)
        # Two URL shapes: x.com (current) and twitter.com (legacy). Probe both.
        wb_x = probe_wayback_cdx("x.com/macautomation", "@macautomation (x.com)")
        time.sleep(1.5)
        wb_legacy = probe_wayback_cdx("twitter.com/macautomation", "@macautomation (twitter.com)")
        results["Wayback @macautomation"] = (wb_x + wb_legacy)[:200]
        time.sleep(0.6)
        print(f"[wayback] CMD-D conference CDX", file=sys.stderr)
        wb_cmdd = probe_wayback_cdx("cmddconf.com/*", "cmddconf.com")
        results["Wayback cmddconf.com"] = wb_cmdd[:200]
        time.sleep(0.6)

    if "ddg" not in skip:
        for site in JS_RENDERED_SITES:
            print(f"[ddg] site:{site}", file=sys.stderr)
            label = f"DDG site:{site}"
            hits = probe_ddg_for_site(query, site)
            real_hits = [h for h in hits if not h["title"].startswith("[DDG failed")]
            if real_hits:
                results[label] = real_hits
            time.sleep(1.0)  # DDG throttles

    if "hn" not in skip:
        print(f"[hn] HN Algolia search", file=sys.stderr)
        hn_hits = probe_hn_algolia(query)
        real = [h for h in hn_hits if not h["title"].startswith("[HN failed")]
        if real:
            results["Hacker News"] = real
        time.sleep(0.5)

    if "podcasts" not in skip:
        print(f"[podcasts] Apple Podcasts (iTunes Search API)", file=sys.stderr)
        ap = probe_apple_podcasts(query)
        if ap:
            results["Apple Podcasts"] = ap
        time.sleep(0.5)

    if "reddit" not in skip:
        print(f"[reddit] Reddit public JSON", file=sys.stderr)
        rd = probe_reddit(query)
        real = [h for h in rd if not h["title"].startswith("[Reddit failed")]
        if real:
            results["Reddit"] = real
        time.sleep(0.5)

    if "youtube" not in skip:
        print(f"[youtube] yt-dlp search: {query}", file=sys.stderr)
        results["YouTube"] = probe_youtube(query)

    OUT_MD.parent.mkdir(parents=True, exist_ok=True)
    OUT_YAML.parent.mkdir(parents=True, exist_ok=True)
    OUT_MD.write_text(render_markdown(query, results), encoding="utf-8")
    OUT_YAML.write_text(render_yaml(query, results), encoding="utf-8")

    total = sum(len(v) for v in results.values())
    print(f"\nDone. Total hits: {total}", file=sys.stderr)
    print(f"Wrote: {OUT_MD.relative_to(REPO)}", file=sys.stderr)
    print(f"Wrote: {OUT_YAML.relative_to(REPO)}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    sys.exit(main())
