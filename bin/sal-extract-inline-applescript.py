#!/usr/bin/env python3

from __future__ import annotations

import hashlib
import html
import re
import unicodedata
from pathlib import Path
from typing import Iterable
from urllib.parse import unquote_plus, urlparse

import yaml


ROOT = Path(__file__).resolve().parents[1]
OUT_ROOT = ROOT / "scripts" / "sal"
INDEX_PATH = ROOT / "indexes" / "sal-scripts.yaml"

SITE_ROOTS = {
    "macosxautomation.com": ROOT / "sources" / "sal" / "macosxautomation.com" / "mirror",
    "iworkautomation.com": ROOT / "sources" / "sal" / "iworkautomation.com" / "mirror",
    "configautomation.com": ROOT / "sources" / "sal" / "configautomation.com" / "mirror" / "wayback-20240422",
    "photosautomation.com": ROOT / "sources" / "sal" / "photosautomation.com" / "mirror" / "wayback-20240721",
    "dictationcommands.com": ROOT / "sources" / "sal" / "dictationcommands.com" / "mirror" / "wayback-20240424",
}

INLINE_SCRIPT_RE = re.compile(
    r'applescript://com\.apple\.scripteditor\?action=new(?:&name=([^&"]+))?&script=([^"#]+)',
    re.IGNORECASE,
)
TITLE_RE = re.compile(r"<title>(.*?)</title>", re.IGNORECASE | re.DOTALL)
APP_RE = re.compile(r'tell application "([^"]+)"', re.IGNORECASE)
USE_FRAMEWORK_RE = re.compile(r'^use framework "([^"]+)"', re.IGNORECASE | re.MULTILINE)
DO_SHELL_RE = re.compile(r"\bdo shell script\b", re.IGNORECASE)


def slugify(value: str, *, max_length: int = 80) -> str:
    value = unicodedata.normalize("NFKD", value)
    value = value.encode("ascii", "ignore").decode("ascii")
    value = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    value = re.sub(r"-{2,}", "-", value)
    if not value:
        value = "script"
    return value[:max_length].rstrip("-")


def yaml_dump(data: object) -> str:
    return yaml.safe_dump(data, sort_keys=False, allow_unicode=True)


def extract_title(text: str, fallback: str) -> str:
    match = TITLE_RE.search(text)
    if not match:
        return fallback
    title = html.unescape(re.sub(r"\s+", " ", match.group(1))).strip()
    return title or fallback


def normalize_script(encoded_script: str) -> str:
    script = unquote_plus(encoded_script)
    script = script.replace("\r\n", "\n").replace("\r", "\n")
    return script.rstrip() + "\n"


def infer_source_urls(site_slug: str, html_path: Path) -> tuple[str, str | None]:
    site_root = SITE_ROOTS[site_slug]
    rel = html_path.relative_to(site_root).as_posix()
    if rel.startswith("web.archive.org/web/"):
        parts = rel.split("/", 3)
        timestamp = parts[2]
        original = parts[3]
        original = re.sub(r"^(https?):/", r"\1://", original, count=1)
        wayback = f"https://web.archive.org/web/{timestamp}/{original}"
        return wayback, original

    original = f"https://{site_slug}/{rel}"
    return original, original


def infer_output_dir(site_slug: str, source_url: str, original_url: str | None) -> Path:
    parsed = urlparse(original_url or source_url)
    parent = Path(parsed.path.lstrip("/")).parent
    if str(parent) == ".":
        return OUT_ROOT / site_slug / "root"
    return OUT_ROOT / site_slug / parent


def infer_apps(script_text: str) -> list[str]:
    apps = sorted({match.group(1) for match in APP_RE.finditer(script_text)})
    if "current application" in script_text and "current application" not in apps:
        apps.append("current application")
    return apps


def infer_layers(script_text: str, apps: Iterable[str]) -> list[str]:
    layers = ["applescript"]
    if list(apps):
        layers.append("app-dictionary")
    if USE_FRAMEWORK_RE.search(script_text):
        layers.append("applescriptobj-c")
    if DO_SHELL_RE.search(script_text):
        layers.append("shell-bridge")
    return layers


def infer_concepts(site_slug: str, html_path: Path) -> list[str]:
    rel = html_path.relative_to(SITE_ROOTS[site_slug]).as_posix().lower()
    concepts: list[str] = []
    for token, concept in (
        ("keynote", "keynote"),
        ("numbers", "numbers"),
        ("pages", "pages"),
        ("photos", "photos"),
        ("services", "services"),
        ("automator", "automator"),
        ("dictation", "dictation"),
        ("config", "deployment"),
        ("workflow", "workflow-design"),
        ("script-library", "script-library"),
        ("presenter-notes", "presenter-notes"),
        ("export", "export"),
        ("slideshow", "slideshow"),
    ):
        if token in rel:
            concepts.append(concept)
    return sorted(set(concepts))


def build_record(
    *,
    site_slug: str,
    html_path: Path,
    page_title: str,
    source_url: str,
    original_url: str | None,
    script_name: str | None,
    script_text: str,
    index_on_page: int,
    local_script_path: Path,
) -> dict[str, object]:
    title = script_name or f"{page_title} Script {index_on_page:02d}"
    apps = infer_apps(script_text)
    source_archive_path = html_path.relative_to(ROOT).as_posix()
    relative_script_path = local_script_path.relative_to(ROOT).as_posix()
    digest = hashlib.sha256(script_text.encode("utf-8")).hexdigest()

    return {
        "id": slugify(
            f"sal-{site_slug}-{html_path.stem}-{index_on_page:02d}-{title}",
            max_length=120,
        ),
        "title": title,
        "site": site_slug,
        "language": "applescript",
        "source_url": source_url,
        "local_path": relative_script_path,
        "source_title": page_title,
        "source_domain": site_slug,
        "retrieved_at": "2026-04-01",
        "apps": apps,
        "automation_layers": infer_layers(script_text, apps),
        "concepts": infer_concepts(site_slug, html_path),
        "original_format": "inline-applescript-url",
        "normalization_notes": [
            "Decoded from applescript:// Script Editor URL embedded in archived HTML.",
            "Normalized line endings to LF and preserved one source record per inline example.",
        ],
        "tags": ["sal", "archive", "inline-script"],
        "original_url": original_url,
        "source_archive_path": source_archive_path,
        "extractor": "bin/sal-extract-inline-applescript.py",
        "hash_sha256": digest,
    }


def write_script_and_metadata(record: dict[str, object], script_text: str) -> None:
    script_path = ROOT / str(record["local_path"])
    meta_path = script_path.with_suffix(".yaml")
    script_path.parent.mkdir(parents=True, exist_ok=True)
    script_path.write_text(script_text, encoding="utf-8")

    sidecar = dict(record)
    sidecar["script_path"] = sidecar.pop("local_path")
    meta_path.write_text(yaml_dump(sidecar), encoding="utf-8")


def main() -> None:
    records: list[dict[str, object]] = []

    for site_slug, site_root in SITE_ROOTS.items():
        html_paths = sorted(site_root.rglob("*.html"))
        for html_path in html_paths:
            text = html_path.read_text(encoding="utf-8", errors="ignore")
            matches = list(INLINE_SCRIPT_RE.finditer(text))
            if not matches:
                continue

            page_title = extract_title(text, html_path.stem)
            source_url, original_url = infer_source_urls(site_slug, html_path)
            output_dir = infer_output_dir(site_slug, source_url, original_url)

            used_names: dict[str, int] = {}
            for index_on_page, match in enumerate(matches, start=1):
                raw_name, raw_script = match.groups()
                script_name = unquote_plus(raw_name) if raw_name else None
                script_text = normalize_script(raw_script)

                if script_name:
                    base_name = slugify(f"{html_path.stem}-{script_name}")
                else:
                    base_name = slugify(f"{html_path.stem}-{index_on_page:02d}")

                used_names[base_name] = used_names.get(base_name, 0) + 1
                if used_names[base_name] > 1:
                    base_name = f"{base_name}-{used_names[base_name]:02d}"

                local_script_path = output_dir / f"{base_name}.applescript"

                record = build_record(
                    site_slug=site_slug,
                    html_path=html_path,
                    page_title=page_title,
                    source_url=source_url,
                    original_url=original_url,
                    script_name=script_name,
                    script_text=script_text,
                    index_on_page=index_on_page,
                    local_script_path=local_script_path,
                )
                write_script_and_metadata(record, script_text)
                records.append(record)

    index = {
        "version": 1,
        "updated": "2026-04-01",
        "schema": {
            "required": [
                "id",
                "title",
                "site",
                "language",
                "source_url",
                "local_path",
            ],
            "optional": [
                "source_title",
                "source_domain",
                "retrieved_at",
                "apps",
                "automation_layers",
                "concepts",
                "functions",
                "original_format",
                "normalization_notes",
                "tags",
                "original_url",
                "source_archive_path",
                "extractor",
                "hash_sha256",
            ],
        },
        "records": sorted(records, key=lambda item: str(item["id"])),
    }
    INDEX_PATH.write_text(yaml_dump(index), encoding="utf-8")


if __name__ == "__main__":
    main()
