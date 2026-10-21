r"""The durable status ledger — the Apple Harness's single source of truth.

One JSONL file at the root of the target pool (`.harness-ledger.jsonl`). It is
append-only; the latest row per `path` wins on load. The ledger IS the episodic
memory: on crash, re-read it, skip `analyzed`, continue. Idempotent.

State machine:
    needs_analysis -> extracting -> extracted -> structured -> analyzed
                                 \-> error (recoverable: re-run picks it up)
"""
from __future__ import annotations

import json
import os
from datetime import datetime, timezone
from pathlib import Path

LEDGER_NAME = ".harness-ledger.jsonl"

# Terminal + re-runnable states.
DONE = "analyzed"
RERUN = {"needs_analysis", "error"}
ALL_STATES = ["needs_analysis", "extracting", "extracted", "structured", "analyzed", "error"]


def _now() -> str:
    return datetime.now(timezone.utc).isoformat()


def _asset_id(path: str, size: int, mtime: float) -> str:
    import hashlib
    h = hashlib.sha256(f"{path}|{size}|{mtime}".encode()).hexdigest()[:12]
    stamp = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
    return f"asset_{stamp}_{h}"


class Ledger:
    def __init__(self, pool_path: str):
        self.pool = Path(os.path.abspath(os.path.expanduser(pool_path)))
        self.path = self.pool / LEDGER_NAME
        self.rows: dict[str, dict] = {}  # keyed by absolute asset path
        self._load()

    def _load(self) -> None:
        if not self.path.exists():
            return
        with open(self.path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    row = json.loads(line)
                except json.JSONDecodeError:
                    continue  # tolerate a torn final line from a crash
                self.rows[row["path"]] = row

    def seed(self, file_path: str, modality: str) -> dict:
        """Create a needs_analysis row for a new asset. No-op if already known."""
        ap = os.path.abspath(file_path)
        if ap in self.rows:
            return self.rows[ap]
        st = os.stat(ap)
        row = {
            "id": _asset_id(ap, st.st_size, st.st_mtime),
            "path": ap,
            "size": st.st_size,
            "mtime": int(st.st_mtime),
            "modality": modality,
            "status": "needs_analysis",
            "extract_path": None,
            "entities": [],
            "tags": [],
            "vote": None,
            "errors": [],
            "touched": _now(),
        }
        self.commit(row)
        return row

    def commit(self, row: dict) -> None:
        """Atomically append the row and update the in-memory view."""
        row["touched"] = _now()
        self.rows[row["path"]] = row
        # Append-only; one fsync'd write. A crash can only tear the last line,
        # which _load tolerates.
        with open(self.path, "a", encoding="utf-8") as f:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")
            f.flush()
            os.fsync(f.fileno())

    def pending(self) -> list[dict]:
        return [r for r in self.rows.values() if r["status"] != DONE]

    def rerunnable(self) -> list[dict]:
        return [r for r in self.rows.values() if r["status"] in RERUN]

    def counts(self) -> dict:
        c = {s: 0 for s in ALL_STATES}
        for r in self.rows.values():
            c[r["status"]] = c.get(r["status"], 0) + 1
        return c

    def compact(self) -> None:
        """Rewrite the ledger keeping only the latest row per path (optional)."""
        tmp = self.path.with_suffix(".jsonl.tmp")
        with open(tmp, "w", encoding="utf-8") as f:
            for row in self.rows.values():
                f.write(json.dumps(row, ensure_ascii=False) + "\n")
        os.replace(tmp, self.path)  # atomic
