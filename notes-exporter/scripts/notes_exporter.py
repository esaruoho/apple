#!/usr/bin/env python3
"""Apple Notes → Markdown vault exporter.

Hybrid approach:
- SQLite for metadata, folder/note relationships, and attachment→media file mapping
- AppleScript for HTML body extraction (notes are stored as protobuf blobs in
  SQLite which is complex to parse; AppleScript gives clean HTML)

Configuration is split into two files:
  - .env           Personal paths and identity (vault dir, account ID, etc.)
  - config.json    Folder selection and tool settings

Both are gitignored. .env.example and config.example.json are committed templates.

Usage:
    python3 notes_export.py export --folders Notes,Work
    python3 notes_export.py export --all
    python3 notes_export.py status
    python3 notes_export.py folders
"""

import argparse
import base64
import hashlib
import json
import os
import re
import shutil
import sqlite3
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

try:
    from markdownify import markdownify as md, MarkdownConverter
except ImportError:
    print("ERROR: markdownify not installed. Run: pip3 install -r ../requirements.txt")
    sys.exit(1)


# --- Constants ---

SCRIPT_DIR = Path(__file__).resolve().parent
TOOL_DIR = SCRIPT_DIR.parent
ENV_PATH = TOOL_DIR / ".env"
CONFIG_PATH = TOOL_DIR / "config.json"
STATE_PATH = SCRIPT_DIR / ".export-state.json"

DEFAULT_NOTES_DB = "~/Library/Group Containers/group.com.apple.notes/NoteStore.sqlite"
DEFAULT_MEDIA_BASE_TEMPLATE = "~/Library/Group Containers/group.com.apple.notes/Accounts/{ACCOUNT_ID}/Media"
DEFAULT_VAULT_PATH = "~/notes-vault"
DEFAULT_EXPORT_PATH = "~/notes-export"
DEFAULT_WHISPER_MODEL = "base"
DEFAULT_WATCH_INTERVAL = 300

# Apple Notes epoch is 2001-01-01 (Core Data / NSDate reference)
APPLE_EPOCH_OFFSET = 978307200


# --- .env + config loading ---

def load_env(path):
    """Minimal .env parser — KEY=VALUE per line, # comments, optional quotes."""
    env = {}
    if not path.exists():
        return env
    for line in path.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip()
        if len(val) >= 2 and val[0] == val[-1] and val[0] in ('"', "'"):
            val = val[1:-1]
        env[key] = val
    return env


def load_config():
    """Merge .env (paths + identity) and config.json (data)."""
    env = load_env(ENV_PATH)
    for k in ("VAULT_PATH", "EXPORT_PATH", "NOTES_DB", "NOTES_ACCOUNT_ID",
              "WHISPER_MODEL", "WATCH_INTERVAL"):
        if k in os.environ:
            env[k] = os.environ[k]

    if not CONFIG_PATH.exists():
        print(f"ERROR: config.json not found at {CONFIG_PATH}", file=sys.stderr)
        print("Copy config.example.json to config.json and configure your folders.",
              file=sys.stderr)
        sys.exit(1)

    with open(CONFIG_PATH) as f:
        data = json.load(f)

    account_id = env.get("NOTES_ACCOUNT_ID", "").strip()
    if not account_id:
        print("ERROR: NOTES_ACCOUNT_ID not set in .env", file=sys.stderr)
        print("Find your account ID:", file=sys.stderr)
        print("  ls ~/Library/Group\\ Containers/group.com.apple.notes/Accounts/",
              file=sys.stderr)
        sys.exit(1)

    media_base = DEFAULT_MEDIA_BASE_TEMPLATE.replace("{ACCOUNT_ID}", account_id)

    cfg = {
        "notes_db": os.path.expanduser(env.get("NOTES_DB", DEFAULT_NOTES_DB)),
        "media_base": os.path.expanduser(media_base),
        "vault_path": os.path.expanduser(env.get("VAULT_PATH", DEFAULT_VAULT_PATH)),
        "export_path": os.path.expanduser(env.get("EXPORT_PATH", DEFAULT_EXPORT_PATH)),
        "whisper_model": env.get("WHISPER_MODEL", DEFAULT_WHISPER_MODEL),
        "watch_interval_seconds": int(env.get("WATCH_INTERVAL", DEFAULT_WATCH_INTERVAL)),
        "folders": data.get("folders", []),
    }
    return cfg


def load_state():
    """Load export state."""
    if STATE_PATH.exists():
        with open(STATE_PATH) as f:
            return json.load(f)
    return {"notes": {}, "last_run": None}


def save_state(state):
    """Persist export state."""
    state["last_run"] = datetime.now(timezone.utc).isoformat()
    with open(STATE_PATH, "w") as f:
        json.dump(state, f, indent=2)


def apple_ts_to_iso(ts):
    """Convert Apple Core Data timestamp to ISO 8601 string."""
    if ts is None:
        return None
    return datetime.fromtimestamp(ts + APPLE_EPOCH_OFFSET, tz=timezone.utc).isoformat()


def apple_ts_to_float(ts):
    """Convert Apple Core Data timestamp to Unix timestamp float."""
    if ts is None:
        return 0.0
    return ts + APPLE_EPOCH_OFFSET


def slugify(text):
    """Create a filesystem-safe slug from text."""
    if not text:
        return "untitled"
    slug = re.sub(r'[^\w\s-]', '', text.lower())
    slug = re.sub(r'[\s_]+', '-', slug).strip('-')
    return slug[:80] or "untitled"


# --- SQLite queries ---

def get_db_connection(db_path):
    """Open read-only connection to Apple Notes database."""
    uri = f"file:{db_path}?mode=ro"
    conn = sqlite3.connect(uri, uri=True)
    conn.row_factory = sqlite3.Row
    return conn


def get_folders(conn):
    """Get all non-deleted regular folders with note counts."""
    rows = conn.execute("""
        SELECT f.Z_PK, f.ZTITLE2 as name, f.ZFOLDERTYPE as folder_type,
               COUNT(n.Z_PK) as note_count
        FROM ZICCLOUDSYNCINGOBJECT f
        LEFT JOIN ZICCLOUDSYNCINGOBJECT n
            ON n.ZFOLDER = f.Z_PK AND n.Z_ENT = 11 AND n.ZMARKEDFORDELETION != 1
        WHERE f.Z_ENT = 14
        AND f.ZMARKEDFORDELETION != 1
        AND f.ZFOLDERTYPE != 1
        GROUP BY f.Z_PK
        ORDER BY note_count DESC
    """).fetchall()
    return [dict(r) for r in rows]


def get_smart_folder_tag(conn, folder_name):
    """Get the tag used by a smart folder to filter notes."""
    row = conn.execute("""
        SELECT ZSMARTFOLDERQUERYJSON
        FROM ZICCLOUDSYNCINGOBJECT
        WHERE Z_ENT = 14 AND ZTITLE2 = ? AND ZFOLDERTYPE = 2
    """, (folder_name,)).fetchone()
    if row and row[0]:
        try:
            query = json.loads(row[0])
            return _extract_tag_from_query(query)
        except (json.JSONDecodeError, KeyError):
            pass
    return None


def _extract_tag_from_query(query):
    """Recursively extract tag from smart folder query JSON."""
    if isinstance(query, dict):
        if "tag" in query:
            return query["tag"]
        for v in query.values():
            result = _extract_tag_from_query(v)
            if result:
                return result
    elif isinstance(query, list):
        for item in query:
            result = _extract_tag_from_query(item)
            if result:
                return result
    return None


def get_notes_in_folder(conn, folder_name):
    """Get all notes in a regular folder."""
    rows = conn.execute("""
        SELECT n.Z_PK, n.ZTITLE1 as title,
               n.ZCREATIONDATE3 as created,
               n.ZMODIFICATIONDATE1 as modified,
               n.ZFOLDER as folder_pk,
               n.ZNOTEDATA as notedata_pk,
               n.ZIDENTIFIER as identifier,
               f.ZTITLE2 as folder_name
        FROM ZICCLOUDSYNCINGOBJECT n
        JOIN ZICCLOUDSYNCINGOBJECT f ON n.ZFOLDER = f.Z_PK
        WHERE n.Z_ENT = 11
        AND f.ZTITLE2 = ?
        AND n.ZMARKEDFORDELETION != 1
        ORDER BY n.ZMODIFICATIONDATE1 DESC
    """, (folder_name,)).fetchall()
    return [dict(r) for r in rows]


def enrich_notes_from_sqlite(conn, notes):
    """Enrich AppleScript-sourced notes with SQLite metadata (dates, PKs)."""
    for note in notes:
        pk = note.get("Z_PK")
        if pk:
            row = conn.execute("""
                SELECT ZCREATIONDATE3 as created, ZMODIFICATIONDATE1 as modified,
                       ZNOTEDATA as notedata_pk
                FROM ZICCLOUDSYNCINGOBJECT
                WHERE Z_PK = ? AND Z_ENT = 11
            """, (pk,)).fetchone()
            if row:
                note["created"] = row["created"]
                note["modified"] = row["modified"]
                note["notedata_pk"] = row["notedata_pk"]
    return notes


def get_attachments_for_note(conn, note_pk):
    """Get all attachments for a note, with media file paths."""
    rows = conn.execute("""
        SELECT a.Z_PK, a.ZIDENTIFIER as att_id, a.ZTYPEUTI as uti,
               a.ZFILENAME as att_filename,
               m.Z_PK as media_pk, m.ZIDENTIFIER as media_id,
               m.ZFILENAME as media_filename
        FROM ZICCLOUDSYNCINGOBJECT a
        LEFT JOIN ZICCLOUDSYNCINGOBJECT m ON a.ZMEDIA = m.Z_PK
        WHERE a.Z_ENT = 4
        AND a.ZNOTE = ?
        AND a.ZMARKEDFORDELETION != 1
        AND a.ZTYPEUTI IS NOT NULL
    """, (note_pk,)).fetchall()
    return [dict(r) for r in rows]


def find_media_file(media_base, media_id, filename):
    """Locate a media file on disk given its identifier and filename."""
    media_dir = Path(media_base) / media_id
    if not media_dir.exists():
        return None
    for subdir in media_dir.iterdir():
        if subdir.is_dir():
            candidate = subdir / filename
            if candidate.exists():
                return candidate
    return None


# --- AppleScript interface ---

def get_notes_via_applescript(folder_name):
    """Get note list from a folder via AppleScript (works on smart folders)."""
    script = f'''
    tell application "Notes"
        set theFolder to folder "{folder_name}"
        set theNotes to notes of theFolder
        set output to ""
        repeat with theNote in theNotes
            set noteName to name of theNote
            set noteId to id of theNote
            set noteCreation to creation date of theNote
            set noteMod to modification date of theNote
            set output to output & "ID:" & noteId & "{{SEP}}" & ¬
                "NAME:" & noteName & "{{SEP}}" & ¬
                "CREATED:" & (noteCreation as string) & "{{SEP}}" & ¬
                "MODIFIED:" & (noteMod as string) & "{{RECORD_END}}"
        end repeat
        return output
    end tell
    '''
    result = run_applescript(script)
    if not result:
        return []

    notes = []
    for record in result.split("{RECORD_END}"):
        record = record.strip()
        if not record:
            continue
        fields = {}
        for field in record.split("{SEP}"):
            field = field.strip()
            if ":" in field:
                key, _, val = field.partition(":")
                fields[key] = val
        if "ID" in fields:
            pk_match = re.search(r'/p(\d+)$', fields.get("ID", ""))
            pk = int(pk_match.group(1)) if pk_match else None
            notes.append({
                "Z_PK": pk,
                "title": fields.get("NAME", "Untitled"),
                "identifier": fields.get("ID", ""),
                "folder_name": folder_name,
            })
    return notes


def get_note_html(folder_name, note_name):
    """Get the HTML body of a specific note via AppleScript."""
    safe_name = note_name.replace('\\', '\\\\').replace('"', '\\"')
    script = f'''
    tell application "Notes"
        set theFolder to folder "{folder_name}"
        set theNotes to notes of theFolder
        repeat with theNote in theNotes
            if name of theNote is "{safe_name}" then
                return body of theNote
            end if
        end repeat
        return ""
    end tell
    '''
    return run_applescript(script)


def run_applescript(script, timeout=30):
    """Execute AppleScript and return output."""
    try:
        result = subprocess.run(
            ["osascript", "-e", script],
            capture_output=True, text=True, timeout=timeout
        )
        if result.returncode != 0:
            if result.stderr.strip():
                print(f"  AppleScript error: {result.stderr.strip()}", file=sys.stderr)
            return ""
        return result.stdout.strip()
    except subprocess.TimeoutExpired:
        print(f"  AppleScript timed out after {timeout}s", file=sys.stderr)
        return ""
    except Exception as e:
        print(f"  AppleScript failed: {e}", file=sys.stderr)
        return ""


# --- HTML → Markdown conversion ---

class NotesConverter(MarkdownConverter):
    """Custom markdownify converter for Apple Notes HTML."""

    def convert_img(self, el, text, convert_as_inline=False, parent_tags=None):
        """Handle images - extract base64 inline images to files."""
        src = el.get("src", "")
        alt = el.get("alt", "")

        if src.startswith("data:"):
            match = re.match(r'data:image/(\w+);base64,(.+)', src)
            if match:
                ext = match.group(1)
                if ext == "jpeg":
                    ext = "jpg"
                data = base64.b64decode(match.group(2))
                img_hash = hashlib.md5(data).hexdigest()[:10]
                placeholder = f"{{{{IMG:{ext}:{img_hash}}}}}"
                if not hasattr(self, '_images'):
                    self._images = {}
                self._images[placeholder] = (ext, data)
                return f"\n![{alt}]({placeholder})\n"
        elif src:
            return f"\n![{alt}]({src})\n"
        return ""


def html_to_markdown(html, note_slug, assets_dir):
    """Convert Apple Notes HTML to clean Markdown, extracting inline images."""
    if not html:
        return "", []

    converter = NotesConverter(
        heading_style="atx",
        bullets="-",
        strip=["style", "script"],
    )
    markdown = converter.convert(html)

    extracted_images = []
    if hasattr(converter, '_images'):
        for placeholder, (ext, data) in converter._images.items():
            img_hash = placeholder.split(":")[2].rstrip("}")
            filename = f"image-{img_hash}.{ext}"
            img_path = assets_dir / filename
            os.makedirs(assets_dir, exist_ok=True)
            with open(img_path, "wb") as f:
                f.write(data)
            rel_path = f"assets/{note_slug}/{filename}"
            markdown = markdown.replace(placeholder, rel_path)
            extracted_images.append(filename)

    markdown = re.sub(r'\n{3,}', '\n\n', markdown)
    markdown = markdown.strip()

    return markdown, extracted_images


# --- Core export logic ---

def export_folder(folder_name, cfg, state, conn, force=False):
    """Export all notes from a folder to the vault."""
    vault_path = Path(cfg["vault_path"])
    media_base = cfg["media_base"]

    folders = get_folders(conn)
    folder_info = next((f for f in folders if f["name"] == folder_name), None)

    is_smart = False
    if folder_info and folder_info["folder_type"] == 2:
        is_smart = True
    elif not folder_info:
        tag = get_smart_folder_tag(conn, folder_name)
        if tag:
            is_smart = True

    print(f"\n{'='*60}")
    print(f"Exporting folder: {folder_name}" + (" (smart folder)" if is_smart else ""))
    print(f"{'='*60}")

    if is_smart:
        notes = get_notes_via_applescript(folder_name)
        notes = enrich_notes_from_sqlite(conn, notes)
    else:
        notes = get_notes_in_folder(conn, folder_name)

    if not notes:
        print(f"  No notes found in '{folder_name}'")
        return 0

    print(f"  Found {len(notes)} notes")

    folder_dir = vault_path / folder_name
    os.makedirs(folder_dir, exist_ok=True)

    exported = 0
    skipped = 0

    for i, note in enumerate(notes, 1):
        title = note.get("title") or "Untitled"
        note_pk = note.get("Z_PK")
        note_slug = slugify(title)

        state_key = f"{folder_name}/{note_slug}"
        if note_pk:
            state_key = f"{folder_name}/pk-{note_pk}"

        if not force and state_key in state["notes"]:
            mod_date = note.get("modified")
            if mod_date is not None:
                last_exported = state["notes"][state_key].get("modified", 0)
                current_mod = apple_ts_to_float(mod_date)
                if current_mod <= last_exported:
                    skipped += 1
                    continue

        print(f"  [{i}/{len(notes)}] {title[:60]}...")

        html = get_note_html(folder_name, title)
        if not html:
            print(f"    WARNING: Could not get HTML body, skipping")
            continue

        assets_dir = folder_dir / "assets" / note_slug
        markdown_body, extracted_images = html_to_markdown(html, note_slug, assets_dir)

        attachment_info = []
        audio_files = []
        if note_pk:
            attachments = get_attachments_for_note(conn, note_pk)
            for att in attachments:
                uti = att.get("uti") or ""
                media_id = att.get("media_id")
                media_filename = att.get("media_filename")

                if uti in ("public.url", "com.apple.notes.table",
                           "com.apple.notes.gallery", "com.apple.drawing.2",
                           "com.apple.paper"):
                    continue

                if media_id and media_filename:
                    src_file = find_media_file(media_base, media_id, media_filename)
                    if src_file:
                        os.makedirs(assets_dir, exist_ok=True)
                        dest_name = media_filename
                        if dest_name == "recording.m4a":
                            att_id_short = (att.get("att_id") or "unknown")[:8]
                            dest_name = f"recording-{att_id_short}.m4a"
                        dest_file = assets_dir / dest_name
                        if not dest_file.exists():
                            shutil.copy2(str(src_file), str(dest_file))
                        attachment_info.append({
                            "filename": dest_name,
                            "uti": uti,
                            "path": f"assets/{note_slug}/{dest_name}",
                        })
                        if "audio" in uti or "m4a" in uti:
                            audio_files.append(dest_name)

        created_iso = apple_ts_to_iso(note.get("created"))
        modified_iso = apple_ts_to_iso(note.get("modified"))

        tags = ["apple-notes", slugify(folder_name)]

        frontmatter = {
            "title": title,
            "created": created_iso,
            "modified": modified_iso,
            "source": "apple-notes",
            "folder": folder_name,
            "attachments": len(attachment_info) + len(extracted_images),
            "tags": tags,
        }

        fm_lines = ["---"]
        fm_lines.append(f'title: "{title.replace(chr(34), chr(39))}"')
        fm_lines.append(f"created: {created_iso or 'unknown'}")
        fm_lines.append(f"modified: {modified_iso or 'unknown'}")
        fm_lines.append(f"source: apple-notes")
        fm_lines.append(f"folder: {folder_name}")
        fm_lines.append(f"attachments: {frontmatter['attachments']}")
        fm_lines.append(f"tags: [{', '.join(tags)}]")
        fm_lines.append("---")

        content_parts = ["\n".join(fm_lines), ""]
        content_parts.append(markdown_body)

        if audio_files:
            content_parts.append("")
            content_parts.append("## Audio Recordings")
            content_parts.append("")
            for af in audio_files:
                rel_path = f"assets/{note_slug}/{af}"
                content_parts.append(f"- [{af}]({rel_path})")
                transcript_path = assets_dir / f"{Path(af).stem}.transcript.md"
                if transcript_path.exists():
                    transcript_text = transcript_path.read_text().strip()
                    preview = transcript_text[:200]
                    if len(transcript_text) > 200:
                        preview += "..."
                    content_parts.append(f'  > **Transcript:** "{preview}"')
            content_parts.append("")

        other_attachments = [a for a in attachment_info if a["filename"] not in audio_files]
        if other_attachments:
            content_parts.append("")
            content_parts.append("## Attachments")
            content_parts.append("")
            for att in other_attachments:
                uti = att["uti"]
                fname = att["filename"]
                rel_path = att["path"]
                if "image" in uti or "png" in uti or "jpeg" in uti or "tiff" in uti or "heic" in uti or "webp" in uti:
                    content_parts.append(f"![{fname}]({rel_path})")
                else:
                    content_parts.append(f"- [{fname}]({rel_path})")
            content_parts.append("")

        final_content = "\n".join(content_parts)

        md_filename = f"{note_slug}.md"
        md_path = folder_dir / md_filename

        if md_path.exists():
            existing_content = md_path.read_text()
            if f'title: "{title.replace(chr(34), chr(39))}"' not in existing_content:
                if note_pk:
                    md_filename = f"{note_slug}-{note_pk}.md"
                    md_path = folder_dir / md_filename

        md_path.write_text(final_content)
        exported += 1

        state["notes"][state_key] = {
            "title": title,
            "slug": note_slug,
            "file": str(md_path.relative_to(Path(cfg["vault_path"]))),
            "modified": apple_ts_to_float(note.get("modified")),
            "exported_at": datetime.now(timezone.utc).isoformat(),
            "attachment_count": frontmatter["attachments"],
        }

    print(f"\n  Exported: {exported}, Skipped (unchanged): {skipped}")
    return exported


def build_manifest(cfg, state):
    """Write a flat JSON manifest of all exported notes."""
    manifest_path = Path(cfg["export_path"]) / "manifest.json"
    os.makedirs(os.path.dirname(manifest_path), exist_ok=True)

    manifest = {
        "generated": datetime.now(timezone.utc).isoformat(),
        "vault_path": cfg["vault_path"],
        "total_notes": len(state["notes"]),
        "notes": state["notes"],
    }

    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    print(f"\nManifest written: {manifest_path}")


def cmd_export(args, cfg):
    """Export selected folders."""
    state = load_state()
    conn = get_db_connection(cfg["notes_db"])

    if args.all:
        folders = cfg["folders"]
        if not folders:
            print("No folders configured in config.json. Edit config.json to add folders, "
                  "or use --folders.")
            return
    elif args.folders:
        folders = [f.strip() for f in args.folders.split(",")]
    else:
        print("Specify --folders or --all")
        return

    total = 0
    for folder in folders:
        try:
            count = export_folder(folder, cfg, state, conn, force=args.force)
            total += count
        except Exception as e:
            print(f"  ERROR exporting '{folder}': {e}", file=sys.stderr)
            import traceback
            traceback.print_exc()

    conn.close()
    save_state(state)
    build_manifest(cfg, state)
    print(f"\n{'='*60}")
    print(f"Total exported: {total} notes")
    print(f"State saved to: {STATE_PATH}")


def cmd_status(args, cfg):
    """Show export status."""
    state = load_state()
    print(f"Last run: {state.get('last_run', 'never')}")
    print(f"Total notes tracked: {len(state.get('notes', {}))}")

    by_folder = {}
    for key, info in state.get("notes", {}).items():
        folder = key.split("/")[0]
        by_folder.setdefault(folder, []).append(info)

    for folder, notes in sorted(by_folder.items()):
        print(f"\n  {folder}: {len(notes)} notes")


def cmd_list_folders(args, cfg):
    """List all available Apple Notes folders."""
    conn = get_db_connection(cfg["notes_db"])
    folders = get_folders(conn)
    conn.close()

    configured = set(cfg.get("folders", []))

    print(f"\n{'Folder':<25} {'Notes':>6}  {'Type':<8}")
    print("-" * 45)
    for f in folders:
        ftype = "smart" if f["folder_type"] == 2 else "regular"
        marker = " *" if f["name"] in configured else ""
        print(f"  {f['name']:<23} {f['note_count']:>6}  {ftype:<8}{marker}")
    print(f"\n* = configured in config.json (used by --all)")


def main():
    parser = argparse.ArgumentParser(description="Apple Notes → Markdown vault exporter")
    sub = parser.add_subparsers(dest="command")

    p_export = sub.add_parser("export", help="Export notes to vault")
    p_export.add_argument("--folders", type=str, help="Comma-separated folder names")
    p_export.add_argument("--all", action="store_true", help="Export all configured folders")
    p_export.add_argument("--force", action="store_true", help="Re-export even unchanged notes")

    sub.add_parser("status", help="Show export status")
    sub.add_parser("folders", help="List all Apple Notes folders")

    args = parser.parse_args()
    cfg = load_config()

    if args.command is None:
        if "--folders" in sys.argv or "--all" in sys.argv:
            args.command = "export"
            args = p_export.parse_args(sys.argv[1:])
            args.command = "export"
        elif "--status" in sys.argv:
            args.command = "status"
        elif "--list-folders" in sys.argv:
            args.command = "folders"
        else:
            parser.print_help()
            return

    if args.command == "export":
        cmd_export(args, cfg)
    elif args.command == "status":
        cmd_status(args, cfg)
    elif args.command == "folders":
        cmd_list_folders(args, cfg)


if __name__ == "__main__":
    main()
