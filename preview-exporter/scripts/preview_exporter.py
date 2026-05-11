#!/usr/bin/env python3
"""
preview-exporter — Apple Preview recent docs + per-PDF metadata to markdown.

Preview's recent-documents list lives in
~/Library/Application Support/com.apple.sharedfilelist/
  com.apple.LSSharedFileList.ApplicationRecentDocuments/com.apple.preview.sfl3

We resolve that .sfl3 with the shared `sfl3_resolver` from bin/lib/ — the
same NSKeyedArchiver decoder that powers finder-exporter and iwork-exporter.

PDF annotations are stored INSIDE each PDF file (Preview writes them as
standard /Annot dictionaries, not as Apple sidecars). Extracting annotation
text would require a PDF parser (PyMuPDF, pdfplumber) — out of scope for
this Apple-native package. For each PDF recent we surface the file metadata
via `mdls` (page count, author, subject, encryption status) which is
read-only and free.

Subcommands:
  status                recent count + per-extension breakdown
  recents [--limit N]   resolved name + path
  export                vault under VAULT_PATH with metadata sidecars
"""
from __future__ import annotations

import argparse
import json
import os
import re
import subprocess
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ENV = ROOT / ".env"
SFL = (Path.home() /
       "Library/Application Support/com.apple.sharedfilelist/"
       "com.apple.LSSharedFileList.ApplicationRecentDocuments/com.apple.preview.sfl3")

sys.path.insert(0, str(ROOT.parent / "bin" / "lib"))
from sfl3_resolver import load_sfl3_items  # noqa: E402


def load_env() -> dict[str, str]:
    env: dict[str, str] = {}
    if DEFAULT_ENV.exists():
        for line in DEFAULT_ENV.read_text().splitlines():
            line = line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            k, v = line.split("=", 1)
            env[k.strip()] = os.path.expanduser(v.strip().strip('"').strip("'"))
    env.setdefault("VAULT_PATH", os.path.expanduser("~/work/apple/exported/preview"))
    env["VAULT_PATH"] = os.path.expanduser(env["VAULT_PATH"])
    return env


def slugify(s: str) -> str:
    s = re.sub(r"[^a-zA-Z0-9._-]+", "-", s).strip("-").lower()
    return (s or "untitled")[:80]


_MDLS_KEYS = [
    "kMDItemContentType",
    "kMDItemKind",
    "kMDItemNumberOfPages",
    "kMDItemAuthors",
    "kMDItemTitle",
    "kMDItemSubject",
    "kMDItemPixelWidth",
    "kMDItemPixelHeight",
    "kMDItemFSSize",
    "kMDItemFSCreationDate",
    "kMDItemFSContentChangeDate",
    "kMDItemSecurityMethod",
]


def file_metadata(path: str) -> dict:
    """Pull Spotlight metadata for a file. Returns {} on failure / missing file."""
    if not path or not Path(path).exists():
        return {}
    try:
        proc = subprocess.run(
            ["/usr/bin/mdls"] + [f"-name" if False else f"-name" for _ in []] +
            sum([["-name", k] for k in _MDLS_KEYS], []) + [path],
            capture_output=True, text=True, timeout=5,
        )
    except (subprocess.TimeoutExpired, FileNotFoundError):
        return {}
    if proc.returncode != 0:
        return {}
    out: dict = {}
    # mdls output format: `kMDItemKey = value`. Multi-line values get an
    # opening paren on the value line and closing paren on a subsequent line.
    current_key = None
    buf: list[str] = []
    for line in proc.stdout.splitlines():
        if "=" in line and not line.startswith(" "):
            if current_key is not None:
                out[current_key] = " ".join(buf).strip()
            k, v = line.split("=", 1)
            current_key = k.strip()
            buf = [v.strip()]
        else:
            buf.append(line.strip())
    if current_key is not None:
        out[current_key] = " ".join(buf).strip()
    # strip mdls noise — "(null)" → "", quoted strings → unquoted
    for k, v in list(out.items()):
        v = v.strip()
        if v == "(null)" or not v:
            del out[k]
            continue
        if v.startswith('"') and v.endswith('"'):
            v = v[1:-1]
        out[k] = v
    return out


# =====================================================================
# Subcommands
# =====================================================================

def cmd_status(args) -> int:
    items = load_sfl3_items(SFL)
    by_ext: Counter = Counter()
    resolved = 0
    for it in items:
        p = it.get("path") or ""
        if p:
            resolved += 1
            by_ext[Path(p).suffix.lower() or "(no-ext)"] += 1
    print("Preview overview")
    print(f"  Recent docs entries: {len(items)}")
    print(f"  Resolved file paths: {resolved}/{len(items)}")
    print(f"  Sfl3 path:           {SFL}")
    if by_ext:
        print(f"  By extension:")
        for ext, n in by_ext.most_common():
            print(f"    {n:>4}  {ext}")
    return 0


def cmd_recents(args) -> int:
    items = load_sfl3_items(SFL)
    if args.limit:
        items = items[: args.limit]
    if args.json:
        print(json.dumps(items, indent=2, ensure_ascii=False))
        return 0
    for it in items:
        name = it.get("name") or "(unnamed)"
        path = it.get("path") or ""
        print(f"  {name}")
        if path:
            print(f"      {path}")
    print(f"\n{len(items)} recent doc(s)")
    return 0


def render_doc_md(it: dict, meta: dict) -> str:
    name = it.get("name") or "(unnamed)"
    path = it.get("path") or ""
    yaml = ["---", f"name: {json.dumps(name, ensure_ascii=False)}"]
    if path:
        yaml.append(f"path: {json.dumps(path, ensure_ascii=False)}")
    for key, frontmatter_key in [
        ("kMDItemContentType", "content_type"),
        ("kMDItemKind", "kind"),
        ("kMDItemNumberOfPages", "pages"),
        ("kMDItemPixelWidth", "width"),
        ("kMDItemPixelHeight", "height"),
        ("kMDItemFSSize", "bytes"),
        ("kMDItemFSCreationDate", "fs_created"),
        ("kMDItemFSContentChangeDate", "fs_modified"),
        ("kMDItemTitle", "title"),
        ("kMDItemSubject", "subject"),
        ("kMDItemSecurityMethod", "security"),
    ]:
        if key in meta:
            yaml.append(f"{frontmatter_key}: {json.dumps(meta[key], ensure_ascii=False)}")
    yaml.append("---")
    body = [f"# {name}", ""]
    if path:
        body.append(f"`{path}`")
        body.append("")
    if meta.get("kMDItemTitle") and meta["kMDItemTitle"] != name:
        body.append(f"**PDF Title** {meta['kMDItemTitle']}  ")
    if meta.get("kMDItemSubject"):
        body.append(f"**Subject** {meta['kMDItemSubject']}  ")
    if meta.get("kMDItemAuthors"):
        body.append(f"**Authors** {meta['kMDItemAuthors']}  ")
    if meta.get("kMDItemNumberOfPages"):
        body.append(f"**Pages** {meta['kMDItemNumberOfPages']}  ")
    if meta.get("kMDItemSecurityMethod"):
        body.append(f"**Security** {meta['kMDItemSecurityMethod']}  ")
    if path and Path(path).exists():
        body.append("")
        body.append(f"> PDF annotations (highlights / notes / drawings) are stored inside")
        body.append(f"> the file itself as standard PDF /Annot dictionaries. Extracting")
        body.append(f"> annotation contents requires a PDF parser (e.g. PyMuPDF) and is")
        body.append(f"> out of scope for the Apple-native preview-exporter.")
    return "\n".join(yaml) + "\n\n" + "\n".join(body) + "\n"


def cmd_export(args) -> int:
    env = load_env()
    vault = Path(env["VAULT_PATH"])
    (vault / "recents").mkdir(parents=True, exist_ok=True)
    items = load_sfl3_items(SFL)

    written = 0
    for it in items:
        name = it.get("name") or "(unnamed)"
        path = it.get("path") or ""
        meta = file_metadata(path) if path else {}
        slug = slugify(Path(path).stem if path else name) or f"item-{written}"
        target = vault / "recents" / f"{slug}.md"
        i = 0
        while target.exists():
            i += 1
            target = vault / "recents" / f"{slug}-{i}.md"
        target.write_text(render_doc_md(it, meta))
        written += 1

    # master index
    master = [
        "# Preview recents",
        "",
        f"- **Total:** {written}",
        "",
        "## Recent documents",
        "",
    ]
    for it in items:
        name = it.get("name") or "(unnamed)"
        path = it.get("path") or ""
        slug = slugify(Path(path).stem if path else name)
        master.append(f"- [{name}](./recents/{slug}.md)")
    (vault / "_index.md").write_text("\n".join(master) + "\n")
    print(f"wrote {written} recent doc sidecar(s) to {vault}")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(prog="preview-exporter")
    sub = p.add_subparsers(dest="cmd", required=True)
    sub.add_parser("status").set_defaults(func=cmd_status)
    sp = sub.add_parser("recents")
    sp.add_argument("--limit", type=int)
    sp.add_argument("--json", action="store_true")
    sp.set_defaults(func=cmd_recents)
    sub.add_parser("export").set_defaults(func=cmd_export)
    args = p.parse_args()
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
