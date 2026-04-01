#!/usr/bin/env python3

from __future__ import annotations

import argparse
import json
import ssl
import sys
import time
from collections import OrderedDict
from pathlib import Path
from typing import Iterable
from socket import timeout as SocketTimeout
from urllib.error import HTTPError, URLError
from urllib.parse import quote, urlparse
from urllib.request import Request, urlopen

import yaml


ROOT = Path(__file__).resolve().parents[1]
INDEX_PATH = ROOT / "indexes" / "sal-download-targets.yaml"
USER_AGENT = "Mozilla/5.0 (compatible; sal-recover-downloads/1.0; +https://macosxautomation.com/)"
SSL_CONTEXT = ssl.create_default_context()

PACKAGE_TYPES = {"zip", "pkg", "workflow-artifact", "pdf", "epub"}


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Recover archived Sal download targets.")
    parser.add_argument("--site", action="append", help="Limit to one or more sites.")
    parser.add_argument(
        "--asset-type",
        action="append",
        help="Limit to one or more asset types. Default: package-like assets only.",
    )
    parser.add_argument(
        "--strategy",
        action="append",
        help="Limit to retrieval strategies such as live-direct or wayback-direct.",
    )
    parser.add_argument("--limit", type=int, default=0, help="Stop after N successful recoveries.")
    parser.add_argument(
        "--mark-failures",
        action="store_true",
        help="Write .failed markers when no candidate fetch succeeds.",
    )
    parser.add_argument(
        "--sleep",
        type=float,
        default=0.0,
        help="Seconds to sleep between requests.",
    )
    return parser.parse_args()


def load_records() -> list[dict]:
    data = yaml.safe_load(INDEX_PATH.read_text())
    return data["records"]


def unique_records(records: Iterable[dict]) -> list[dict]:
    ordered: OrderedDict[str, dict] = OrderedDict()
    for record in records:
        ordered.setdefault(record["normalized_url"], record)
    return list(ordered.values())


def record_matches(record: dict, args: argparse.Namespace) -> bool:
    if record["status"] != "missing":
        return False
    if args.site and record["site"] not in set(args.site):
        return False
    allowed_types = set(args.asset_type or PACKAGE_TYPES)
    if record["asset_type"] not in allowed_types:
        return False
    if args.strategy and record["retrieval_strategy"] not in set(args.strategy):
        return False
    return True


def relative_download_path(record: dict) -> Path:
    parsed = urlparse(record["normalized_url"])
    rel = Path(parsed.path.lstrip("/"))
    return Path("sources") / "sal" / record["site"] / "downloads" / rel


def cdx_lookup(url: str) -> list[str]:
    cdx_url = (
        "https://web.archive.org/cdx/search/cdx?url="
        + quote(url, safe="")
        + "&output=json&fl=timestamp,original,statuscode,mimetype&filter=statuscode:200"
        + "&limit=10&from=2000"
    )
    payload = fetch_bytes(cdx_url)
    if payload is None:
        return []
    try:
        rows = json.loads(payload.decode("utf-8"))
    except json.JSONDecodeError:
        return []
    results: list[str] = []
    for row in rows[1:]:
        timestamp, original, *_ = row
        results.append(f"https://web.archive.org/web/{timestamp}/{original}")
    return results


def fetch_bytes(url: str) -> bytes | None:
    request = Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urlopen(request, timeout=45, context=SSL_CONTEXT) as response:
            return response.read()
    except (HTTPError, URLError, TimeoutError, SocketTimeout):
        return None


def fetch_to_path(url: str, dest: Path) -> tuple[bool, str]:
    tmp = dest.with_suffix(dest.suffix + ".part")
    request = Request(url, headers={"User-Agent": USER_AGENT})
    try:
        with urlopen(request, timeout=90, context=SSL_CONTEXT) as response:
            dest.parent.mkdir(parents=True, exist_ok=True)
            with tmp.open("wb") as fh:
                while True:
                    chunk = response.read(65536)
                    if not chunk:
                        break
                    fh.write(chunk)
    except HTTPError as exc:
        if tmp.exists():
            tmp.unlink()
        return False, f"HTTP {exc.code}"
    except URLError as exc:
        if tmp.exists():
            tmp.unlink()
        return False, f"URL error: {exc.reason}"
    except Exception as exc:  # noqa: BLE001
        if tmp.exists():
            tmp.unlink()
        return False, f"{type(exc).__name__}: {exc}"

    if not tmp.exists() or tmp.stat().st_size == 0:
        if tmp.exists():
            tmp.unlink()
        return False, "empty body"
    tmp.replace(dest)
    return True, "ok"


def write_failed_marker(dest: Path, attempts: list[str]) -> None:
    marker = dest.with_suffix(dest.suffix + ".failed")
    marker.parent.mkdir(parents=True, exist_ok=True)
    marker.write_text("\n".join(attempts) + "\n")


def candidate_urls(record: dict) -> list[str]:
    candidates = [record["normalized_url"]]
    archive_url = record.get("archive_url")
    if archive_url:
        candidates.append(archive_url)
    if record["retrieval_strategy"] == "live-direct":
        candidates.extend(cdx_lookup(record["normalized_url"]))
    deduped: list[str] = []
    seen: set[str] = set()
    for candidate in candidates:
        if candidate and candidate not in seen:
            seen.add(candidate)
            deduped.append(candidate)
    return deduped


def main() -> int:
    args = parse_args()
    records = unique_records(load_records())
    targets = [record for record in records if record_matches(record, args)]
    print(f"targets={len(targets)}", file=sys.stderr)

    successes = 0
    failures = 0
    for record in targets:
        dest = relative_download_path(record)
        if dest.exists() and dest.stat().st_size > 0:
            print(f"skip-existing {record['normalized_url']}")
            continue

        attempts: list[str] = []
        for candidate in candidate_urls(record):
            ok, detail = fetch_to_path(candidate, dest)
            attempts.append(f"{candidate} -> {detail}")
            if ok:
                rel_dest = dest if not dest.is_absolute() else dest.relative_to(ROOT)
                print(f"recovered {record['normalized_url']} -> {rel_dest} via {candidate}")
                successes += 1
                break
        else:
            failures += 1
            print(f"failed {record['normalized_url']}", file=sys.stderr)
            for attempt in attempts:
                print(f"  {attempt}", file=sys.stderr)
            if args.mark_failures:
                write_failed_marker(dest, attempts)

        if args.limit and successes >= args.limit:
            break
        if args.sleep:
            time.sleep(args.sleep)

    print(f"successes={successes} failures={failures}", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
