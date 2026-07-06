#!/usr/bin/env python3
"""Fold the dated ontology/*additions*.yaml deltas into the canonical people/concepts/devices YAML.

The archive accumulates knowledge in dated `-additions.yaml` files (one per session) and periodically
merges them into the canonical `people.yaml` / `concepts.yaml` / `devices.yaml`. This does that merge
deterministically and CONSERVATIVELY:

- Section names vary across files — `people` / `people_additions` / `people_added` / `people_updates`
  (and the concept/device equivalents). Any top-level key starting with people/concept/device is a
  target section; everything else (session, papers, whiteboards, cross_references, institutions,
  timeline_events, …) is left untouched and REPORTED, never silently dropped.
- Section values come as a dict (`slug: {...}`) or a list of flat entries (each carrying its own
  `key:` / `slug:` / `id:` / `name:`). Both shapes are handled.
- Merge policy is ENRICH-ONLY: a new slug is added whole; an existing slug has only its *missing*
  fields filled and its *list* fields unioned — an existing scalar (e.g. a curated description) is
  NEVER overwritten. So the merge cannot destroy canonical data, and it is idempotent.

Canonical files are backed up (`<file>.bak-<n>`) before writing.

Usage:
    python3 bin/merge-ontology-additions.py <repo-dir> --dry-run   # report, write nothing
    python3 bin/merge-ontology-additions.py <repo-dir>             # merge + back up
"""
import sys, re, glob, time, shutil, pathlib, yaml

TARGETS = {"people": "people.yaml", "concepts": "concepts.yaml", "devices": "devices.yaml"}


def base_dir():
    for a in sys.argv[1:]:
        if not a.startswith("-"):
            return pathlib.Path(a).expanduser().resolve()
    return pathlib.Path.cwd()


def slugify(k):
    return re.sub(r"[^a-z0-9._-]+", "-", str(k).strip().lower()).strip("-")


def classify(section_key):
    k = section_key.lower()
    if k.startswith("people"):
        return "people"
    if k.startswith("concept"):
        return "concepts"
    if k.startswith("device"):
        return "devices"
    return None


def entries_from(secval):
    """Yield (slug, entry-dict) from a section that is either a dict or a list of flat entries."""
    out = []
    if isinstance(secval, dict):
        for k, v in secval.items():
            if isinstance(v, dict):
                out.append((slugify(k), v))
            elif v is None:
                out.append((slugify(k), {}))
    elif isinstance(secval, list):
        for item in secval:
            if not isinstance(item, dict):
                continue
            if len(item) == 1 and isinstance(next(iter(item.values())), dict):
                k = next(iter(item))
                out.append((slugify(k), item[k]))
            else:
                sid = item.get("key") or item.get("slug") or item.get("id") \
                    or item.get("full_name") or item.get("name")
                if not sid:
                    continue
                entry = {k: v for k, v in item.items() if k not in ("key", "id", "slug")}
                if "full_name" not in entry and entry.get("name"):
                    entry["full_name"] = entry["name"]
                out.append((slugify(sid), entry))
    return out


def enrich(canon, slug, entry):
    if slug not in canon or not isinstance(canon.get(slug), dict):
        if slug in canon and not isinstance(canon.get(slug), dict):
            return "conflict-skip"
        canon[slug] = entry
        return "added"
    cur = canon[slug]
    for k, v in (entry or {}).items():
        if k not in cur or cur[k] in (None, "", []):
            cur[k] = v
        elif isinstance(cur[k], list) and isinstance(v, list):
            for x in v:
                if x not in cur[k]:
                    cur[k].append(x)
    return "enriched"


def main():
    base = base_dir()
    ont = base / "ontology"
    dry = "--dry-run" in sys.argv
    if not ont.is_dir():
        sys.exit("no ontology/ under %s" % base)

    canon = {}
    for cat, fn in TARGETS.items():
        p = ont / fn
        canon[cat] = (yaml.safe_load(p.read_text()) or {}) if p.is_file() else {}

    before = {c: len(canon[c]) for c in TARGETS}
    stats = {c: {"added": 0, "enriched": 0, "conflict": 0} for c in TARGETS}
    skipped_sections = {}
    files = sorted(glob.glob(str(ont / "*additions*.yaml")))

    for f in files:
        try:
            d = yaml.safe_load(pathlib.Path(f).read_text()) or {}
        except Exception as e:
            print("!! parse fail, skipping %s: %s" % (pathlib.Path(f).name, e)); continue
        for sec, val in d.items():
            cat = classify(sec)
            if not cat:
                skipped_sections.setdefault(sec, 0)
                skipped_sections[sec] += 1
                continue
            for slug, entry in entries_from(val):
                if not slug:
                    continue
                r = enrich(canon[cat], slug, entry)
                if r == "added":
                    stats[cat]["added"] += 1
                elif r == "enriched":
                    stats[cat]["enriched"] += 1
                else:
                    stats[cat]["conflict"] += 1

    print("=== %s ===" % ("DRY-RUN" if dry else "MERGE"))
    for cat, fn in TARGETS.items():
        s = stats[cat]
        print("  %-9s %-14s %4d -> %4d   (+%d new, %d enriched%s)" % (
            cat, fn, before[cat], len(canon[cat]), s["added"], s["enriched"],
            (", %d conflict" % s["conflict"]) if s["conflict"] else ""))
    print("  skipped non-target sections (left untouched): " +
          ", ".join("%s(%d)" % (k, v) for k, v in sorted(skipped_sections.items())))

    if dry:
        print("\n(dry-run — nothing written)")
        return

    ts = int(time.time())
    for cat, fn in TARGETS.items():
        p = ont / fn
        if p.is_file():
            shutil.copy2(p, p.with_suffix(p.suffix + ".bak-%d" % ts))
        header = "# %s ontology — canonical (additions merged %s)\n" % (cat, time.strftime("%Y-%m-%d", time.localtime(ts)))
        body = yaml.safe_dump(canon[cat], allow_unicode=True, default_flow_style=False,
                              sort_keys=False, width=4096)
        p.write_text(header + body)
    print("\nwrote canonical files (backups: *.bak-%d). Re-run wiki-generate + wiki-index next." % ts)


if __name__ == "__main__":
    main()
