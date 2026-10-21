"""Oracle spaces — an entity-first projection of the ledger.

A post-pass (not part of the per-asset loop): read every `analyzed` row, group
its NER entities, and write one human-readable space per entity under the
vault's `oracle_spaces/<slug>/`:

  namespace.yaml  — the entity's identity, focus areas (aggregated tags), and
                    connections (co-occurring entities, with co-occurrence count)
  index.md        — an Obsidian-navigable view linking that entity's Asset Notes

Idempotent: re-running rebuilds the spaces from the current ledger. Dependency-
free: the YAML is hand-emitted (we only write it; nothing here parses YAML).
"""
from __future__ import annotations

import re
from collections import Counter
from pathlib import Path


def slug(text: str) -> str:
    s = re.sub(r"[^a-z0-9]+", "_", text.lower()).strip("_")
    return s or "unnamed"


def _yq(s: str) -> str:
    """A safely double-quoted YAML scalar."""
    return '"' + str(s).replace("\\", "\\\\").replace('"', '\\"') + '"'


def build(cfg, ledger, *, verbose=lambda *_: None) -> int:
    """Project the ledger into oracle spaces. Returns the number of spaces written."""
    spaces: dict[str, dict] = {}

    for row in ledger.rows.values():
        if row.get("status") != "analyzed":
            continue
        ents = [(e.get("text", ""), e.get("type", "")) for e in row.get("entities", []) if e.get("text")]
        note = row.get("extract_path") or ""
        note_name = Path(note).stem if note else row.get("id", "")
        for name, typ in ents:
            sp = spaces.setdefault(slug(name), {
                "name": name, "type": typ,
                "docs": [], "tags": set(), "connections": Counter(),
            })
            sp["docs"].append({"id": row.get("id", ""), "source": row.get("path", ""), "note": note_name})
            sp["tags"].update(row.get("tags") or [])
            for other, _ot in ents:
                if other != name:
                    sp["connections"][other] += 1

    base = cfg.vault / "oracle_spaces"
    base.mkdir(parents=True, exist_ok=True)

    for sl, sp in spaces.items():
        d = base / sl
        d.mkdir(parents=True, exist_ok=True)

        # --- namespace.yaml ---
        y = ["entity:",
             f"  name: {_yq(sp['name'])}",
             f"  type: {sp['type']}",
             f"  slug: {sl}",
             "focus_areas:"]
        y += [f"  - {t}" for t in sorted(sp["tags"])] or ["  []"]
        y.append("connections:")
        if sp["connections"]:
            for other, n in sp["connections"].most_common():
                y.append(f"  - name: {_yq(other)}")
                y.append(f"    slug: {slug(other)}")
                y.append(f"    co_occurrences: {n}")
        else:
            y.append("  []")
        y.append("documents:")
        for doc in sp["docs"]:
            y.append(f"  - id: {doc['id']}")
            y.append(f"    source: {_yq(doc['source'])}")
            y.append(f"    note: {_yq(doc['note'])}")
        (d / "namespace.yaml").write_text("\n".join(y) + "\n", encoding="utf-8")

        # --- index.md (Obsidian) ---
        m = [f"# {sp['name']}", "", f"type:: {sp['type']}", ""]
        if sp["tags"]:
            m += ["## Focus areas", "", ", ".join(sorted(sp["tags"])), ""]
        m += ["## Documents", ""]
        m += [f"- [[{doc['note']}]] — `{Path(doc['source']).name}`" for doc in sp["docs"]]
        if sp["connections"]:
            m += ["", "## Connected entities", ""]
            m += [f"- [[../{slug(o)}/index|{o}]] ({n})" for o, n in sp["connections"].most_common()]
        (d / "index.md").write_text("\n".join(m) + "\n", encoding="utf-8")

        verbose(f"  {sl:28} {sp['type']:16} docs={len(sp['docs'])} links={len(sp['connections'])}")

    return len(spaces)
