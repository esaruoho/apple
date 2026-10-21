"""The execution loop — Think -> Act -> Observe -> Stop, per asset.

Crash-only and idempotent: the ledger row's `status` is the recovery point.
Each asset walks the state machine; any organ failure lands the row in `error`
(recoverable — a later run re-picks it up), never crashes the whole run.

    needs_analysis -> extracting -> extracted -> structured -> analyzed

Zero tokens through `structured`. The LLM is touched only at the final step,
and only with entities + a tiny snippet.
"""
from __future__ import annotations

import json
from pathlib import Path

from . import capabilities, organs, reasoning


def _write_asset_note(cfg, row: dict, text: str) -> str:
    """Write the Obsidian-shaped Asset Note; return its path (string)."""
    vault_assets = cfg.vault / "System" / "Assets"
    vault_assets.mkdir(parents=True, exist_ok=True)
    note = vault_assets / f"{row['id']}.md"

    tags = row.get("tags") or []
    fm_lines = [
        "---",
        f"id: {row['id']}",
        f"type: {row['modality']}",
        f'source_path: "{row["path"]}"',
        f"status: {row['status']}",
        "tags:",
    ]
    for t in tags:
        fm_lines.append(f"  - {t}")
    fm_lines.append("entities:")
    for e in row.get("entities", []):
        fm_lines.append(f'  - "{e["text"]}" ({e["type"]})')
    fm_lines.append("---")
    header = "\n".join(fm_lines)

    body = f"\n## Extract\n\n{text.strip()}\n"
    note.write_text(header + "\n" + body, encoding="utf-8")
    return str(note)


def _store_vector(cfg, row: dict, vector: list[float]) -> None:
    if vector is None:
        return
    rec = {"id": row["id"], "path": row["path"], "v": vector}
    with open(cfg.embeds, "a", encoding="utf-8") as f:
        f.write(json.dumps(rec) + "\n")


def run_asset(cfg, ledger, row: dict, *, verbose=lambda *_: None) -> None:
    if row["status"] == "analyzed":
        return
    row["errors"] = []  # clear on re-run

    try:
        # --- Act: zero-token extraction -----------------------------------
        row["status"] = "extracting"
        ledger.commit(row)
        verbose(f"  extract  {row['modality']:5}  {Path(row['path']).name}")
        text = organs.extract(cfg, row)  # resolves provider; never downloads

        row["status"] = "extracted"
        ledger.commit(row)
        verbose(f"           via {row.get('extract_provider','?')}")

        # --- Observe: zero-token structuring ------------------------------
        row["entities"] = organs.tag_entities(cfg, text)
        vector = organs.embed(cfg, text)
        row["vector_row"] = None  # the embeds file is append-order; index is implicit
        _store_vector(cfg, row, vector)
        row["status"] = "structured"
        row["extract_path"] = _write_asset_note(cfg, row, text)
        ledger.commit(row)
        verbose(f"           entities={len(row['entities'])} vector={'yes' if vector else 'no'}")

        # --- Think: the ONLY token spend ----------------------------------
        rp = cfg.reasoning
        if rp.get("enabled", True):
            rr = capabilities.resolve("reason", cfg.capability("reason"))  # local fm or fleet fmremote
            res = reasoning.judge(rr.cmd, rp, row["entities"], text)
            row["reason_provider"] = f"reason:{rr.provider}"
            row["tags"] = res["tags"]
            row["vote"] = res["vote"]
            if res["flip_flop"]:
                row["errors"].append(f"reasoning flip-flop at {res['vote']}")
            verbose(f"           reason via {rr.provider}: tags={row['tags']} vote={row['vote']}")

        # --- Stop: rewrite the note with the final status + tags ----------
        row["status"] = "analyzed"
        row["extract_path"] = _write_asset_note(cfg, row, text)
        ledger.commit(row)

    except Exception as e:  # recoverable: mark error, keep going
        row["status"] = "error"
        row["errors"].append(str(e))
        ledger.commit(row)
        verbose(f"  ERROR    {Path(row['path']).name}: {e}")
