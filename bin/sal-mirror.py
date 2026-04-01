#!/usr/bin/env python3
"""Mirror Sal Soghoian source sites into the Apple repo archive layout.

This is a thin repo-local wrapper around the existing MERLib mirror engine.
It keeps the Apple repo's manifests as the source of truth while storing
captures under:

  sources/sal/<domain>/mirror/
  sources/sal/<domain>/assets/
"""

from __future__ import annotations

import argparse
import os
import shutil
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
from pathlib import Path

import yaml


REPO_ROOT = Path(__file__).resolve().parent.parent
SITES_INDEX = REPO_ROOT / "indexes" / "sal-sites.yaml"
DEFAULT_MIRROR_TOOL = Path("/Users/esaruoho/work/merlib-mirror/mirror.py")
DEFAULT_USER_AGENT_NOTE = "merlib-mirror wrapper"

WAYBACK_ONLY_SLUGS = {"dictationcommands"}
ASSET_SUFFIXES = {
    ".pdf",
    ".zip",
    ".sit",
    ".sitx",
    ".dmg",
    ".pkg",
    ".scpt",
    ".applescript",
    ".txt",
    ".rtf",
    ".jpg",
    ".jpeg",
    ".png",
    ".gif",
    ".tif",
    ".tiff",
    ".mp3",
    ".m4a",
    ".mov",
    ".mp4",
}


def load_yaml(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        data = yaml.safe_load(handle) or {}
    if not isinstance(data, dict):
        raise ValueError(f"Expected mapping in {path}")
    return data


def save_yaml(path: Path, data: dict) -> None:
    with path.open("w", encoding="utf-8") as handle:
        yaml.safe_dump(data, handle, sort_keys=False, allow_unicode=False)


def load_site_registry() -> list[dict]:
    data = load_yaml(SITES_INDEX)
    return data.get("sites", [])


def slug_to_manifest(slug: str) -> Path:
    for site in load_site_registry():
        if site.get("slug") == slug:
            return REPO_ROOT / site["manifest"]
    raise KeyError(f"Unknown site slug: {slug}")


def selected_manifests(slugs: list[str]) -> list[Path]:
    sites = load_site_registry()
    all_slugs = [site["slug"] for site in sites]
    chosen = slugs or all_slugs
    return [slug_to_manifest(slug) for slug in chosen]


def capture_mode(slug: str, manifest: dict, force_wayback: bool) -> str:
    if force_wayback:
        return "wayback"
    if slug in WAYBACK_ONLY_SLUGS:
        return "wayback"
    capture = manifest.get("capture", {})
    preferred = capture.get("preferred_mode")
    if preferred in {"live", "wayback"}:
        return preferred
    return "live"


def manifest_paths(manifest_path: Path, manifest: dict) -> tuple[Path, Path, Path]:
    site_dir = manifest_path.parent
    mirror_rel = manifest["capture"]["mirror_root"]
    asset_rel = manifest["capture"]["asset_root"]
    mirror_root = REPO_ROOT / mirror_rel
    asset_root = REPO_ROOT / asset_rel
    return site_dir, mirror_root, asset_root


def site_seed_urls(manifest: dict) -> list[str]:
    origin = manifest.get("origin", {})
    seeds: list[str] = []
    home = origin.get("home")
    if home:
        seeds.append(home)
    for url in origin.get("known_urls", []):
        if url not in seeds:
            seeds.append(url)
    return seeds


def sync_tree(src: Path, dst: Path) -> None:
    dst.mkdir(parents=True, exist_ok=True)
    for item in src.rglob("*"):
        rel = item.relative_to(src)
        target = dst / rel
        if item.is_dir():
            target.mkdir(parents=True, exist_ok=True)
            continue
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)


def extract_assets(mirror_root: Path, asset_root: Path) -> int:
    count = 0
    asset_root.mkdir(parents=True, exist_ok=True)
    for item in mirror_root.rglob("*"):
        if not item.is_file():
            continue
        if item.suffix.lower() not in ASSET_SUFFIXES:
            continue
        rel = item.relative_to(mirror_root)
        target = asset_root / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(item, target)
        count += 1
    return count


def count_content_files(root: Path) -> int:
    count = 0
    for item in root.rglob("*"):
        if not item.is_file():
            continue
        name = item.name
        if name.startswith("_"):
            continue
        if name in {"ALLFILES.txt", "error.log"}:
            continue
        count += 1
    return count


def run_engine(
    mirror_tool: Path,
    mode: str,
    target: str,
    output_base: Path,
    seeds: list[str] | None = None,
    max_pages: int | None = None,
    delay: float | None = None,
    wayback_from: str | None = None,
    wayback_to: str | None = None,
) -> None:
    cmd = ["python3", str(mirror_tool), mode, target, "--output-dir", str(output_base)]

    if mode == "live":
        if seeds:
            with tempfile.NamedTemporaryFile("w", encoding="utf-8", delete=False) as handle:
                for seed in seeds:
                    handle.write(seed + "\n")
                seeds_path = handle.name
            cmd.extend(["--seeds", seeds_path])
        else:
            seeds_path = None
        if max_pages is not None:
            cmd.extend(["--max-pages", str(max_pages)])
    else:
        seeds_path = None
        if wayback_from is not None:
            cmd.extend(["--from", wayback_from])
        if wayback_to is not None:
            cmd.extend(["--to", wayback_to])

    if delay is not None:
        cmd.extend(["--delay", str(delay)])

    try:
        subprocess.run(cmd, check=True)
    finally:
        if seeds_path and os.path.exists(seeds_path):
            os.unlink(seeds_path)


def update_manifest(manifest_path: Path, manifest: dict, mode: str, asset_count: int) -> None:
    now = datetime.now(timezone.utc).replace(microsecond=0).isoformat().replace("+00:00", "Z")
    manifest.setdefault("site", {})["status"] = "captured"

    capture = manifest.setdefault("capture", {})
    capture["captured_at"] = now
    capture["method"] = f"{DEFAULT_USER_AGENT_NOTE}:{mode}"

    extraction = manifest.setdefault("extraction", {})
    extraction["status"] = "mirrored"
    extraction["asset_count"] = asset_count

    if manifest["site"].get("slug") == "dictationcommands":
        origin = manifest.setdefault("origin", {})
        origin["live_domain_status"] = "compromised"
        origin["archived_via"] = "web.archive.org"

    save_yaml(manifest_path, manifest)


def run_site(
    manifest_path: Path,
    mirror_tool: Path,
    force_wayback: bool,
    max_pages: int | None,
    delay: float | None,
    wayback_from: str | None,
    wayback_to: str | None,
) -> None:
    manifest = load_yaml(manifest_path)
    slug = manifest["site"]["slug"]
    domain = manifest["site"]["domain"]
    mode = capture_mode(slug, manifest, force_wayback)
    site_dir, mirror_root, asset_root = manifest_paths(manifest_path, manifest)

    with tempfile.TemporaryDirectory(prefix=f"sal-mirror-{slug}-") as tmpdir:
        output_base = Path(tmpdir)
        target = domain if mode == "wayback" else site_seed_urls(manifest)[0]
        seeds = None if mode == "wayback" else site_seed_urls(manifest)

        print(f"[sal-mirror] {slug}: {mode} -> {mirror_root}")
        run_engine(
            mirror_tool=mirror_tool,
            mode=mode,
            target=target,
            output_base=output_base,
            seeds=seeds,
            max_pages=max_pages,
            delay=delay,
            wayback_from=wayback_from,
            wayback_to=wayback_to,
        )

        engine_output = output_base / domain
        if not engine_output.exists():
            raise FileNotFoundError(f"Expected mirror output at {engine_output}")

        if count_content_files(engine_output) == 0:
            raise RuntimeError(f"No site content captured for {slug}")

        mirror_root.mkdir(parents=True, exist_ok=True)
        asset_root.mkdir(parents=True, exist_ok=True)
        sync_tree(engine_output, mirror_root)
        asset_count = extract_assets(mirror_root, asset_root)
        update_manifest(manifest_path, manifest, mode, asset_count)

        print(f"[sal-mirror] {slug}: mirrored, assets copied={asset_count}")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "sites",
        nargs="*",
        help="Site slugs from indexes/sal-sites.yaml. Defaults to all sites.",
    )
    parser.add_argument(
        "--mirror-tool",
        default=str(DEFAULT_MIRROR_TOOL),
        help="Path to MERLib mirror.py",
    )
    parser.add_argument(
        "--force-wayback",
        action="store_true",
        help="Force Wayback mode for all selected sites.",
    )
    parser.add_argument(
        "--max-pages",
        type=int,
        default=500,
        help="Maximum live pages per site.",
    )
    parser.add_argument(
        "--delay",
        type=float,
        default=None,
        help="Per-request delay to pass through to mirror.py.",
    )
    parser.add_argument(
        "--wayback-from",
        help="Inclusive YYYYMMDD lower bound for Wayback captures.",
    )
    parser.add_argument(
        "--wayback-to",
        help="Inclusive YYYYMMDD upper bound for Wayback captures.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    mirror_tool = Path(args.mirror_tool)
    if not mirror_tool.exists():
        print(f"mirror tool not found: {mirror_tool}", file=sys.stderr)
        return 1

    manifests = selected_manifests(args.sites)
    for manifest_path in manifests:
        run_site(
            manifest_path=manifest_path,
            mirror_tool=mirror_tool,
            force_wayback=args.force_wayback,
            max_pages=args.max_pages,
            delay=args.delay,
            wayback_from=args.wayback_from,
            wayback_to=args.wayback_to,
        )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
