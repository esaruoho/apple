#!/usr/bin/env python3

from __future__ import annotations

import argparse
from collections import Counter, defaultdict
from datetime import UTC, datetime
from pathlib import Path

import yaml


ROOT = Path(__file__).resolve().parents[1]


def load_yaml(path: str) -> dict:
    return yaml.safe_load((ROOT / path).read_text())


def unique_download_records(records: list[dict]) -> list[dict]:
    unique: dict[str, dict] = {}
    for record in records:
        unique[record["normalized_url"]] = record
    return list(unique.values())


def build_report() -> str:
    scripts = load_yaml("indexes/sal-scripts.yaml")
    lessons = load_yaml("indexes/sal-lessons.yaml")
    downloads = load_yaml("indexes/sal-download-targets.yaml")

    script_count = len(scripts["records"])
    lesson_count = len(lessons["lessons"])
    track_count = len(lessons["tracks"])

    unique_records = unique_download_records(downloads["records"])
    status_counts = Counter(record["status"] for record in unique_records)

    by_site: dict[str, Counter] = defaultdict(Counter)
    missing_by_type = Counter()
    missing_packages: list[str] = []
    missing_videos: list[str] = []

    for record in unique_records:
        by_site[record["site"]][record["status"]] += 1
        if record["status"] != "missing":
            continue
        missing_by_type[record["asset_type"]] += 1
        if record["asset_type"] == "zip":
            missing_packages.append(record["normalized_url"])
        if record["asset_type"] == "video":
            missing_videos.append(record["normalized_url"])

    macos_video_focus = [
        item for item in missing_videos if "macosxautomation.com" in item
    ]
    iwork_video_count = sum(1 for item in missing_videos if "iworkautomation.com" in item)
    photos_video_count = sum(1 for item in missing_videos if "photosautomation.com" in item)

    lines = [
        "# Sal Archive Status",
        "",
        f"Updated: {datetime.now(UTC).strftime('%Y-%m-%dT%H:%M:%SZ')}",
        "",
        "## Current State",
        "",
        f"- Extracted inline AppleScript examples: `{script_count}`",
        f"- Curriculum lesson modules indexed: `{lesson_count}` across `{track_count}` tracks",
        f"- Download/media targets indexed: `{len(downloads['records'])}`",
        "- Unique target status counts:",
        f"  - `recovered`: `{status_counts['recovered']}`",
        f"  - `captured-in-mirror`: `{status_counts['captured-in-mirror']}`",
        f"  - `external-reference`: `{status_counts['external-reference']}`",
        f"  - `missing`: `{status_counts['missing']}`",
        "",
        "## By Site",
        "",
    ]

    for site in sorted(by_site):
        counts = by_site[site]
        parts = [f"`{key}`: `{counts[key]}`" for key in ("recovered", "captured-in-mirror", "external-reference", "missing") if counts[key]]
        lines.append(f"- `{site}` -> " + ", ".join(parts))

    lines.extend(
        [
            "",
            "## Remaining Work",
            "",
            f"- Missing packages: `{missing_by_type['zip']}`",
            f"- Missing videos: `{missing_by_type['video']}`",
            f"- `macosxautomation.com` missing packages are down to `{len([item for item in missing_packages if 'macosxautomation.com' in item])}` dead URLs.",
            f"- `iworkautomation.com` is down to `{iwork_video_count}` missing videos plus `PresidentsSQLiteDB.zip`.",
            f"- `photosautomation.com` is down to `{photos_video_count}` missing video plus `installer.zip`.",
            "",
            "### Missing Packages",
            "",
        ]
    )

    for item in missing_packages:
        lines.append(f"- `{item}`")

    lines.extend(
        [
            "",
            "### Priority Video Queue",
            "",
        ]
    )

    if macos_video_focus:
        for item in macos_video_focus:
            lines.append(f"- `{item}`")
    if iwork_video_count:
        lines.append(f"- `iworkautomation.com`: `{iwork_video_count}` remaining lesson/demo videos")
    if photos_video_count:
        lines.append(f"- `photosautomation.com`: `{photos_video_count}` remaining video")

    lines.extend(
        [
            "",
            "## Next Recommended Actions",
            "",
            "- Transcribe retained local media and attach transcript paths to lessons and indexes.",
            "- Extract recovered ZIP contents into curated script/example folders under `scripts/sal/`.",
            "- Cross-link every recovered bundle, script, video, and transcript back into `indexes/sal-lessons.yaml`.",
            "- Keep failure markers for dead URLs so the archive does not regress into false positives.",
        ]
    )

    return "\n".join(lines) + "\n"


def main() -> int:
    parser = argparse.ArgumentParser(description="Summarize the current Sal archive state.")
    parser.add_argument("--write", help="Optional path to write the generated markdown report.")
    args = parser.parse_args()

    report = build_report()
    if args.write:
        target = Path(args.write)
        if not target.is_absolute():
            target = ROOT / target
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(report)
    print(report, end="")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
