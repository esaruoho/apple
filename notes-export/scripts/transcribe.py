#!/usr/bin/env python3
"""Audio transcription for Apple Notes exports.

Uses OpenAI Whisper to transcribe m4a/audio files in the vault's
assets directories. Saves transcripts as .transcript.md files alongside
the audio, and updates the parent note's markdown with transcript embeds.

Usage:
    python3 transcribe.py                  # Transcribe all pending audio
    python3 transcribe.py --folder Notes   # Only process one folder
    python3 transcribe.py --force          # Re-transcribe everything
    python3 transcribe.py --model medium   # Use a larger model
"""

import argparse
import json
import sys
from datetime import datetime, timezone
from pathlib import Path

# Reuse the same .env+config loader as notes_export.py
from notes_export import load_config

SCRIPT_DIR = Path(__file__).resolve().parent
TRANSCRIPT_STATE_PATH = SCRIPT_DIR / ".transcribe-state.json"

AUDIO_EXTENSIONS = {".m4a", ".mp4", ".mp3", ".wav", ".ogg", ".flac", ".webm"}


def load_transcript_state():
    if TRANSCRIPT_STATE_PATH.exists():
        with open(TRANSCRIPT_STATE_PATH) as f:
            return json.load(f)
    return {"transcribed": {}, "last_run": None}


def save_transcript_state(state):
    state["last_run"] = datetime.now(timezone.utc).isoformat()
    with open(TRANSCRIPT_STATE_PATH, "w") as f:
        json.dump(state, f, indent=2)


def find_audio_files(vault_path, folder=None):
    """Find all audio files in vault assets directories."""
    vault = Path(vault_path)
    if folder:
        search_dirs = [vault / folder / "assets"]
    else:
        search_dirs = list(vault.glob("*/assets"))

    audio_files = []
    for assets_dir in search_dirs:
        if not assets_dir.exists():
            continue
        for ext in AUDIO_EXTENSIONS:
            audio_files.extend(assets_dir.rglob(f"*{ext}"))

    return sorted(audio_files)


_whisper_model = None
_whisper_model_name = None


def get_whisper_model(model_name="base"):
    """Get or cache the Whisper model."""
    global _whisper_model, _whisper_model_name
    if _whisper_model is None or _whisper_model_name != model_name:
        try:
            import whisper
        except ImportError:
            print("ERROR: whisper not installed. Run: pip3 install openai-whisper")
            sys.exit(1)
        print(f"  Loading Whisper model '{model_name}'...")
        _whisper_model = whisper.load_model(model_name)
        _whisper_model_name = model_name
    return _whisper_model


def transcribe_file_cached(audio_path, model_name="base"):
    """Transcribe using a cached model instance."""
    model = get_whisper_model(model_name)
    print(f"  Transcribing: {audio_path.name}")
    result = model.transcribe(str(audio_path))
    return result["text"].strip()


def write_transcript(audio_path, text):
    """Write transcript to a .transcript.md file alongside the audio."""
    transcript_path = audio_path.with_suffix("").with_suffix(".transcript.md")
    content = f"""---
source_audio: {audio_path.name}
transcribed: {datetime.now(timezone.utc).isoformat()}
---

{text}
"""
    transcript_path.write_text(content)
    return transcript_path


def update_parent_note(audio_path, transcript_text, vault_path):
    """Find and update the parent note's markdown to include transcript preview."""
    assets_dir = audio_path.parent
    note_slug = assets_dir.name
    folder_dir = assets_dir.parent.parent

    md_path = folder_dir / f"{note_slug}.md"
    if not md_path.exists():
        for candidate in folder_dir.glob("*.md"):
            content = candidate.read_text()
            if audio_path.name in content:
                md_path = candidate
                break
        else:
            return

    content = md_path.read_text()
    audio_ref = audio_path.name
    if "**Transcript:**" in content and audio_ref in content:
        lines = content.split("\n")
        for i, line in enumerate(lines):
            if audio_ref in line:
                if i + 1 < len(lines) and "Transcript:" in lines[i + 1]:
                    return

    preview = transcript_text[:200]
    if len(transcript_text) > 200:
        preview += "..."
    transcript_line = f'  > **Transcript:** "{preview}"'

    lines = content.split("\n")
    new_lines = []
    for line in lines:
        new_lines.append(line)
        if audio_ref in line and "Transcript:" not in line:
            new_lines.append(transcript_line)

    md_path.write_text("\n".join(new_lines))


def main():
    parser = argparse.ArgumentParser(description="Transcribe audio files in vault")
    parser.add_argument("--folder", type=str, help="Only process one folder")
    parser.add_argument("--force", action="store_true", help="Re-transcribe everything")
    parser.add_argument("--model", type=str, default=None, help="Whisper model (tiny/base/small/medium/large)")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be transcribed")
    args = parser.parse_args()

    cfg = load_config()
    model_name = args.model or cfg.get("whisper_model", "base")
    state = load_transcript_state()
    vault_path = cfg["vault_path"]

    audio_files = find_audio_files(vault_path, args.folder)
    print(f"Found {len(audio_files)} audio files")

    pending = []
    for af in audio_files:
        key = str(af.relative_to(vault_path))
        if not args.force and key in state["transcribed"]:
            continue
        transcript_path = af.with_suffix("").with_suffix(".transcript.md")
        if not args.force and transcript_path.exists():
            state["transcribed"][key] = {
                "transcribed_at": "pre-existing",
                "audio_file": af.name,
            }
            continue
        pending.append(af)

    print(f"Pending transcription: {len(pending)} files")

    if args.dry_run:
        for af in pending:
            print(f"  Would transcribe: {af.relative_to(vault_path)}")
        return

    if not pending:
        print("Nothing to transcribe.")
        save_transcript_state(state)
        return

    transcribed = 0
    errors = 0

    for i, af in enumerate(pending, 1):
        key = str(af.relative_to(vault_path))
        print(f"\n[{i}/{len(pending)}] {af.relative_to(vault_path)}")

        try:
            text = transcribe_file_cached(af, model_name)
            if text:
                transcript_path = write_transcript(af, text)
                update_parent_note(af, text, vault_path)
                state["transcribed"][key] = {
                    "transcribed_at": datetime.now(timezone.utc).isoformat(),
                    "audio_file": af.name,
                    "transcript_file": transcript_path.name,
                    "length_chars": len(text),
                }
                transcribed += 1
                print(f"  ✓ {len(text)} chars")
            else:
                print(f"  ⚠ Empty transcript")
        except Exception as e:
            print(f"  ✗ Error: {e}")
            errors += 1

    save_transcript_state(state)
    print(f"\nDone: {transcribed} transcribed, {errors} errors")


if __name__ == "__main__":
    main()
