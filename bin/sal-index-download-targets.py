#!/usr/bin/env python3

from __future__ import annotations

import html
import re
import unicodedata
from collections import defaultdict
from pathlib import Path
from urllib.parse import urljoin, urlparse

import yaml


ROOT = Path(__file__).resolve().parents[1]
INDEX_PATH = ROOT / "indexes" / "sal-download-targets.yaml"

SITE_ROOTS = {
    "macosxautomation.com": ROOT / "sources" / "sal" / "macosxautomation.com" / "mirror",
    "iworkautomation.com": ROOT / "sources" / "sal" / "iworkautomation.com" / "mirror",
    "configautomation.com": ROOT / "sources" / "sal" / "configautomation.com" / "mirror" / "wayback-20240422",
    "photosautomation.com": ROOT / "sources" / "sal" / "photosautomation.com" / "mirror" / "wayback-20240721",
    "dictationcommands.com": ROOT / "sources" / "sal" / "dictationcommands.com" / "mirror" / "wayback-20240424",
}

SITE_DIRS = {
    "macosxautomation.com": ROOT / "sources" / "sal" / "macosxautomation.com",
    "iworkautomation.com": ROOT / "sources" / "sal" / "iworkautomation.com",
    "configautomation.com": ROOT / "sources" / "sal" / "configautomation.com",
    "photosautomation.com": ROOT / "sources" / "sal" / "photosautomation.com",
    "dictationcommands.com": ROOT / "sources" / "sal" / "dictationcommands.com",
}

SAL_DOMAINS = set(SITE_ROOTS)
TARGET_RE = re.compile(
    r"""(?:href|src)=['"]([^'"]+\.(?:zip|pkg|scpt|workflow|m4v|mp4|mov|pdf|epub)(?:\?[^'"]*)?)""",
    re.IGNORECASE,
)
TITLE_RE = re.compile(r"<title>(.*?)</title>", re.IGNORECASE | re.DOTALL)
WAYBACK_RE = re.compile(r"^https?://web\.archive\.org/web/(\d+)/(https?:.+)$", re.IGNORECASE)


def yaml_dump(data: object) -> str:
    return yaml.safe_dump(data, sort_keys=False, allow_unicode=True)


def slugify(value: str, *, max_length: int = 120) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = value.encode("ascii", "ignore").decode("ascii")
    value = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    value = re.sub(r"-{2,}", "-", value)
    if not value:
        value = "item"
    return value[:max_length].rstrip("-")


def extract_title(text: str, fallback: str) -> str:
    match = TITLE_RE.search(text)
    if not match:
        return fallback
    title = html.unescape(re.sub(r"\s+", " ", match.group(1))).strip()
    return title or fallback


def infer_page_urls(site_slug: str, html_path: Path) -> tuple[str, str | None]:
    site_root = SITE_ROOTS[site_slug]
    rel = html_path.relative_to(site_root).as_posix()
    if rel.startswith("web.archive.org/web/"):
        parts = rel.split("/", 3)
        timestamp = parts[2]
        original = re.sub(r"^(https?):/", r"\1://", parts[3], count=1)
        return f"https://web.archive.org/web/{timestamp}/{original}", original
    original = f"https://{site_slug}/{rel}"
    return original, original


def classify_asset_type(path: str) -> str:
    suffix = Path(urlparse(path).path).suffix.lower()
    if suffix == ".zip":
        return "zip"
    if suffix == ".pkg":
        return "pkg"
    if suffix in {".scpt", ".workflow"}:
        return "workflow-artifact"
    if suffix in {".mp4", ".m4v", ".mov"}:
        return "video"
    if suffix == ".pdf":
        return "pdf"
    if suffix == ".epub":
        return "epub"
    return suffix.lstrip(".") or "file"


def classify_category(path: str) -> str:
    target = f"{urlparse(path).netloc}{urlparse(path).path}".lower()
    checks = (
        ("pixelmator-pro", "pixelmator-pro"),
        ("keynote/automator", "keynote-automator"),
        ("keynote", "keynote"),
        ("numbers", "numbers"),
        ("pages", "pages"),
        ("photos", "photos"),
        ("config", "configurator"),
        ("dictation", "dictation"),
        ("services", "services"),
        ("automator", "automator"),
        ("epub", "epub"),
        ("aperture", "aperture"),
        ("uiscripting", "ui-scripting"),
        ("toolbar", "toolbar"),
        ("imageevents", "image-events"),
        ("applescript", "applescript"),
    )
    for token, label in checks:
        if token in target:
            return label
    return "general"


def unwrap_wayback(url: str) -> tuple[str, str | None]:
    match = WAYBACK_RE.match(url)
    if not match:
        return url, None
    original = match.group(2)
    return original, url


def wayback_timestamp(url: str) -> str | None:
    match = WAYBACK_RE.match(url)
    if not match:
        return None
    return match.group(1)


def normalize_target_url(source_url: str, join_base_url: str, raw_url: str) -> tuple[str, str | None]:
    resolved = urljoin(join_base_url, raw_url)
    if resolved.startswith("https://web.archive.org") or resolved.startswith("http://web.archive.org"):
        original, archive_url = unwrap_wayback(resolved)
        return original, archive_url
    timestamp = wayback_timestamp(source_url)
    if timestamp:
        return resolved, f"https://web.archive.org/web/{timestamp}/{resolved}"
    return resolved, None


def build_site_file_indexes() -> dict[str, dict[str, object]]:
    indexes: dict[str, dict[str, object]] = {}
    for site, site_dir in SITE_DIRS.items():
        basename_map: dict[str, list[Path]] = defaultdict(list)
        for path in site_dir.rglob("*"):
            if not path.is_file():
                continue
            if path.stat().st_size == 0:
                continue
            basename_map[path.name].append(path)
        indexes[site] = {
            "site_dir": site_dir,
            "basename_map": basename_map,
            "downloads_root": site_dir / "downloads",
            "mirror_root": site_dir / "mirror",
            "assets_root": site_dir / "assets",
        }
    return indexes


def select_preferred_match(paths: list[Path]) -> Path:
    def sort_key(path: Path) -> tuple[int, int, str]:
        rel = path.as_posix()
        priority = 3
        if "/downloads/" in rel:
            priority = 0
        elif "/mirror/" in rel:
            priority = 1
        elif "/assets/" in rel:
            priority = 2
        return (priority, len(rel), rel)

    return sorted(paths, key=sort_key)[0]


def locate_local_artifact(target_host: str, normalized_url: str, site_indexes: dict[str, dict[str, object]]) -> tuple[str, str | None]:
    if target_host not in site_indexes:
        return "external-reference", None

    info = site_indexes[target_host]
    parsed = urlparse(normalized_url)
    rel_path = parsed.path.lstrip("/")
    if rel_path:
        candidates = [
            info["downloads_root"] / rel_path,
            info["mirror_root"] / rel_path,
            info["assets_root"] / rel_path,
        ]
        for candidate in candidates:
            if candidate.is_file() and candidate.stat().st_size > 0:
                rel = candidate.relative_to(ROOT).as_posix()
                if "/downloads/" in rel:
                    return "recovered", rel
                return "captured-in-mirror", rel

    basename = Path(parsed.path).name
    if not basename:
        return "missing", None

    matches = info["basename_map"].get(basename, [])
    if matches:
        chosen = select_preferred_match(matches)
        rel = chosen.relative_to(ROOT).as_posix()
        if "/downloads/" in rel:
            return "recovered", rel
        return "captured-in-mirror", rel

    return "missing", None


def infer_retrieval_strategy(normalized_url: str, archive_url: str | None, target_host: str) -> str:
    if archive_url:
        return "wayback-direct"
    if target_host in SAL_DOMAINS:
        return "live-direct"
    return "external-host"


def should_skip(raw_url: str, normalized_url: str) -> bool:
    lowered = raw_url.lower()
    if any(token in lowered for token in ("javascript:", "itunes.app", "itunes.apple", "applescript://")):
        return True
    parsed = urlparse(normalized_url)
    if not parsed.path:
        return True
    return False


def build_record(
    *,
    site_slug: str,
    html_path: Path,
    page_title: str,
    source_url: str,
    original_page_url: str | None,
    raw_url: str,
    normalized_url: str,
    archive_url: str | None,
    status: str,
    local_path: str | None,
) -> dict[str, object]:
    parsed = urlparse(normalized_url)
    filename = Path(parsed.path).name or parsed.netloc
    target_host = parsed.netloc.lower()
    record: dict[str, object] = {
        "id": slugify(f"sal-download-{site_slug}-{html_path.stem}-{filename}"),
        "site": site_slug,
        "filename": filename,
        "asset_type": classify_asset_type(normalized_url),
        "category": classify_category(normalized_url),
        "source_url": source_url,
        "source_title": page_title,
        "source_archive_path": html_path.relative_to(ROOT).as_posix(),
        "discovered_url": raw_url,
        "normalized_url": normalized_url,
        "target_host": target_host,
        "retrieval_strategy": infer_retrieval_strategy(normalized_url, archive_url, target_host),
        "status": status,
    }
    if original_page_url:
        record["original_page_url"] = original_page_url
    if archive_url:
        record["archive_url"] = archive_url
    if local_path:
        record["local_path"] = local_path
    return record


def main() -> None:
    site_indexes = build_site_file_indexes()
    records: list[dict[str, object]] = []
    seen_ids: dict[str, int] = {}

    for site_slug, site_root in SITE_ROOTS.items():
        for html_path in sorted(site_root.rglob("*.html")):
            text = html_path.read_text(encoding="utf-8", errors="ignore")
            matches = TARGET_RE.findall(text)
            if not matches:
                continue

            page_title = extract_title(text, html_path.stem)
            source_url, original_page_url = infer_page_urls(site_slug, html_path)
            for raw_url in matches:
                normalized_url, archive_url = normalize_target_url(
                    source_url,
                    original_page_url or source_url,
                    raw_url,
                )
                if should_skip(raw_url, normalized_url):
                    continue

                target_host = urlparse(normalized_url).netloc.lower()
                status, local_path = locate_local_artifact(target_host, normalized_url, site_indexes)
                record = build_record(
                    site_slug=site_slug,
                    html_path=html_path,
                    page_title=page_title,
                    source_url=source_url,
                    original_page_url=original_page_url,
                    raw_url=raw_url,
                    normalized_url=normalized_url,
                    archive_url=archive_url,
                    status=status,
                    local_path=local_path,
                )

                base_id = str(record["id"])
                seen_ids[base_id] = seen_ids.get(base_id, 0) + 1
                if seen_ids[base_id] > 1:
                    record["id"] = f"{base_id}-{seen_ids[base_id]:02d}"
                records.append(record)

    records.sort(
        key=lambda item: (
            str(item["site"]),
            str(item["category"]),
            str(item["filename"]).lower(),
            str(item["source_archive_path"]),
        )
    )

    index = {
        "version": 1,
        "updated": "2026-04-01",
        "schema": {
            "required": [
                "id",
                "site",
                "filename",
                "asset_type",
                "category",
                "source_url",
                "source_archive_path",
                "normalized_url",
                "target_host",
                "retrieval_strategy",
                "status",
            ],
            "optional": [
                "source_title",
                "original_page_url",
                "discovered_url",
                "archive_url",
                "local_path",
            ],
            "status_values": [
                "recovered",
                "captured-in-mirror",
                "missing",
                "external-reference",
            ],
            "retrieval_strategies": [
                "live-direct",
                "wayback-direct",
                "external-host",
            ],
        },
        "records": records,
    }
    INDEX_PATH.write_text(yaml_dump(index), encoding="utf-8")


if __name__ == "__main__":
    main()
