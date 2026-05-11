"""
WAL-safe read-only snapshot for Apple SQLite stores.

Apple's first-party apps (Shortcuts, Photos, Notes, Mail, Safari, Messages,
Voice Memos, Calendar, …) use WAL journaling and keep their database files
open while they're running. Two ways to read them safely from the side:

1. ?immutable=1   Fast, no copy. SQLite assumes the file won't change AND
                  ignores the -wal sibling entirely. Misses anything the host
                  app has written but not yet checkpointed. Good for
                  "user closed the app first" workflows.

2. snapshot       Copy the .sqlite + -wal + -shm trio to a temp dir, then
                  open with ?mode=ro. Sees the live WAL state. Slower (one
                  extra disk write per export), strictly more correct,
                  immune to "database is locked" contention.

This module provides the snapshot path. Use it when the host app is likely
to be running and you want the freshest data.

Usage:

    from apple_sqlite_snapshot import snapshot_open

    # Context-managed: temp files cleaned up on exit
    with snapshot_open("~/Library/Shortcuts/Shortcuts.sqlite") as con:
        rows = con.execute("SELECT ZNAME FROM ZSHORTCUT").fetchall()

    # Or get the snapshot path itself (e.g. for tooling that takes a path):
    with snapshot_path("~/Library/Shortcuts/Shortcuts.sqlite") as snap:
        subprocess.run(["sqlite3", snap, ".schema"])

No external dependencies. Pure stdlib.
"""
from __future__ import annotations

import contextlib
import shutil
import sqlite3
import tempfile
from pathlib import Path
from typing import Iterator


SIBLING_SUFFIXES = ("-wal", "-shm")


def _resolve(db_path: str | Path) -> Path:
    p = Path(db_path).expanduser()
    if not p.exists():
        raise FileNotFoundError(f"SQLite store not found: {p}")
    return p


def _snapshot_to_dir(src: Path, dest_dir: Path) -> Path:
    """Copy src + -wal + -shm into dest_dir. Returns the snapshot DB path."""
    snap = dest_dir / src.name
    shutil.copy2(src, snap)
    for suffix in SIBLING_SUFFIXES:
        sib = src.with_name(src.name + suffix)
        if sib.exists():
            shutil.copy2(sib, dest_dir / sib.name)
    return snap


@contextlib.contextmanager
def snapshot_path(db_path: str | Path) -> Iterator[Path]:
    """
    Snapshot the SQLite store and yield the path to the copy. Cleans up on exit.

    Use this when you need to hand a file path to an external tool (sqlite3 CLI,
    etc.) rather than a connection.
    """
    src = _resolve(db_path)
    with tempfile.TemporaryDirectory(prefix="apple-sqlite-snap-") as tmp:
        snap = _snapshot_to_dir(src, Path(tmp))
        yield snap


@contextlib.contextmanager
def snapshot_open(db_path: str | Path, row_factory=None) -> Iterator[sqlite3.Connection]:
    """
    Snapshot the SQLite store and yield a read-only sqlite3.Connection to the copy.
    Closes the connection and cleans up the snapshot on exit.

    `row_factory` (optional) — pass `sqlite3.Row` for name-keyed rows.
    """
    src = _resolve(db_path)
    with tempfile.TemporaryDirectory(prefix="apple-sqlite-snap-") as tmp:
        snap = _snapshot_to_dir(src, Path(tmp))
        con = sqlite3.connect(f"file:{snap}?mode=ro", uri=True)
        if row_factory is not None:
            con.row_factory = row_factory
        try:
            yield con
        finally:
            con.close()


def snapshot_open_persistent(db_path: str | Path, row_factory=None) -> sqlite3.Connection:
    """
    Drop-in replacement for `sqlite3.connect(..., uri=True)` against a live
    Apple store. Snapshots the file to a temp dir, opens read-only, and
    registers an `atexit` hook to clean up the temp dir when the process exits.

    Use this in scripts (one-shot exporters) where switching to the
    context-managed `snapshot_open(...)` would require restructuring the
    surrounding code. The connection is returned bare; caller may close it
    explicitly or let the process exit.
    """
    import atexit
    src = _resolve(db_path)
    tmp_dir = Path(tempfile.mkdtemp(prefix="apple-sqlite-snap-"))
    atexit.register(shutil.rmtree, tmp_dir, ignore_errors=True)
    snap = _snapshot_to_dir(src, tmp_dir)
    con = sqlite3.connect(f"file:{snap}?mode=ro", uri=True)
    if row_factory is not None:
        con.row_factory = row_factory
    return con


def open_immutable(db_path: str | Path, row_factory=None) -> sqlite3.Connection:
    """
    Open the live SQLite store read-only with ?immutable=1. No copy.

    Fast, but ignores anything in the -wal file. Use this when the host app
    is known-quiescent (user closed it, or the data store is checkpoint-only).
    Returns a regular sqlite3.Connection — caller closes.
    """
    src = _resolve(db_path)
    con = sqlite3.connect(f"file:{src}?mode=ro&immutable=1", uri=True)
    if row_factory is not None:
        con.row_factory = row_factory
    return con
