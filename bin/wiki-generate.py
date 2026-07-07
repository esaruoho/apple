#!/usr/bin/env python3
"""Project the ontology (ontology/*.yaml) into wiki pages — zero model tokens, zero round-trips.

The ontology already holds one structured entry per person / device / concept. A wiki page is a
"summary-with-pointers" of exactly that. So the whole wiki layer can be *generated* deterministically
from the YAML: load the dict, emit one markdown page per key, turn related_people / related_devices /
key_concepts into cross-links (which become the graph edges for free).

Companion to wiki-index.py (emits the INDEX) and wiki-view.py (renders the browser view). This is the
populator that gives them something to index and draw.

Rules of engagement:
- Curated pages win. Any existing page that does NOT carry `generated: true` in its frontmatter is
  hand-written and is NEVER overwritten. Generated pages carry `generated: true` and `status: auto`
  and are freely overwritten on re-run.
- Kortela name-restriction: no standalone kortela page is emitted and the name is dropped from
  cross-link lists (belt-and-suspenders; generated .md stay archive-internal / local either way).
- Nothing is interpreted or invented — the `description` prose is the archivist's own, rendered as-is.
  This is projection, not authorship (so it cannot flatten).

Usage:
    python3 bin/wiki-generate.py <repo-dir>            # writes into <repo>/wiki
    python3 bin/wiki-generate.py <repo-dir> --dry-run  # report counts, write nothing
    python3 bin/wiki-generate.py                        # defaults to CWD
"""
import sys, re, pathlib, yaml

SCRUB = re.compile(r"kortela", re.I)   # name-restriction

SPEC = [
    ("people.yaml",   "people",   "person"),
    ("devices.yaml",  "devices",  "device"),
    ("concepts.yaml", "concepts", "concept"),
]


def base_dir():
    for a in sys.argv[1:]:
        if a.startswith("-"):
            continue
        return pathlib.Path(a).expanduser().resolve()
    return pathlib.Path.cwd()


def slugify(k):
    return re.sub(r"[^a-z0-9._-]+", "-", str(k).strip().lower()).strip("-")


def short_label(title, slug):
    t = re.sub(r"\s*\(.*?\)", "", str(title)).strip()
    t = re.sub(r"^The\s+", "", t)
    for d in (" — ", " / ", ": ", ","):
        if d in t:
            t = t.split(d)[0]
    t = t.strip()
    if len(t) > 20:
        t = t[:19].rstrip() + "…"
    return t or slug


def first_sentence(text, cap=220):
    s = re.sub(r"\s+", " ", str(text)).strip()
    m = re.search(r"(.+?[.!?])(\s|$)", s)
    out = m.group(1) if m else s
    return (out[:cap].rstrip() + "…") if len(out) > cap else out


def as_list(v):
    if v is None:
        return []
    return v if isinstance(v, list) else [v]


def is_generated(path):
    try:
        head = path.read_text()[:400]
    except Exception:
        return False
    return bool(re.search(r"(?m)^generated:\s*true\s*$", head))


def title_of(entry, slug):
    if isinstance(entry, dict):
        for k in ("full_name", "name", "title"):
            if entry.get(k):
                return str(entry[k])
    return slug.replace("-", " ").title()


def desc_of(entry):
    if isinstance(entry, dict):
        for k in ("description", "summary", "one_liner", "notes"):
            if entry.get(k):
                return str(entry[k])
    return ""


def render(cat, kind, slug, entry, titles, present):
    """Build one page's markdown. `titles` maps slug->display title per category;
    `present` maps category->set(slugs) so links only point at pages that exist."""
    if not isinstance(entry, dict):
        entry = {"description": str(entry)}
    title = title_of(entry, slug)
    desc = desc_of(entry)
    one = first_sentence(desc) if desc else title

    def link(tcat, tslug):
        ts = slugify(tslug)
        if SCRUB.search(ts):
            return None
        disp = titles.get(tcat, {}).get(ts, ts.replace("-", " "))
        if ts in present.get(tcat, set()):
            rel = "" if tcat == cat else "../" + tcat + "/"
            return "[%s](%s%s.md)" % (disp, rel, ts)
        return disp  # no page for it (yet) — plain text

    def linklist(vals, tcat):
        out = []
        for v in as_list(vals):
            vs = v if isinstance(v, str) else (v.get("name") if isinstance(v, dict) else str(v))
            if vs is None or SCRUB.search(str(vs)):
                continue
            lk = link(tcat, vs)
            if lk:
                out.append(lk)
        return out

    fm = {
        "title": title,
        "wiki_page": kind,
        "slug": slug,
        "graph_label": short_label(title, slug),
        "status": "auto",
        "generated": True,
        "ontology_source": "ontology/%s.yaml" % cat.replace("people", "people").replace("devices", "devices").replace("concepts", "concepts"),
        "one_liner": one,
    }
    # gather see_also links (to other wiki pages) for the graph
    see = []
    for v in as_list(entry.get("related_people")):
        s = slugify(v if isinstance(v, str) else "")
        if s and s in present.get("people", set()) and not SCRUB.search(s):
            see.append("wiki/people/%s.md" % s)
    for key in ("related_devices", "devices"):
        for v in as_list(entry.get(key)):
            s = slugify(v if isinstance(v, str) else "")
            if s and s in present.get("devices", set()):
                see.append("wiki/devices/%s.md" % s)
    for key in ("key_concepts", "concepts", "related_concepts"):
        for v in as_list(entry.get(key)):
            s = slugify(v if isinstance(v, str) else "")
            if s and s in present.get("concepts", set()):
                see.append("wiki/concepts/%s.md" % s)
    if see:
        fm["see_also"] = sorted(set(see))

    front = yaml.safe_dump(fm, allow_unicode=True, default_flow_style=False, sort_keys=False).strip()
    L = ["---", front, "---", "", "# " + title, ""]
    if one:
        L += ["> " + one, ""]

    # metadata line
    bits = []
    if entry.get("role"):
        bits.append("**Role:** " + str(entry["role"]))
    if entry.get("inventor"):
        bits.append("**Inventor:** " + str(entry["inventor"]))
    if entry.get("born") or entry.get("died"):
        bits.append("**Lived:** %s–%s" % (entry.get("born", "?"), entry.get("died", "")))
    if entry.get("year"):
        bits.append("**Year:** " + str(entry["year"]))
    if entry.get("nationality"):
        bits.append("**Nationality:** " + str(entry["nationality"]))
    if entry.get("active_period"):
        bits.append("**Active:** " + str(entry["active_period"]))
    for dom in ("domain",):
        if entry.get(dom):
            bits.append("**Domain:** " + ", ".join(as_list(entry[dom])))
    if bits:
        L += [" · ".join(bits), ""]
    aka = as_list(entry.get("also_known_as"))
    if aka:
        L += ["**Also known as:** " + ", ".join(str(a) for a in aka), ""]
    if entry.get("formula"):
        L += ["**Formula:** `" + str(entry["formula"]).strip() + "`", ""]

    # full description prose (verbatim from ontology)
    if desc and desc.strip() != one.strip():
        L += [re.sub(r"\s+\n", "\n", desc.strip()), ""]

    def section(heading, items):
        if items:
            L.append("## " + heading)
            L.extend("- " + it for it in items)
            L.append("")

    section("Related people", linklist(entry.get("related_people"), "people"))
    section("Devices", linklist(entry.get("devices") or entry.get("related_devices"), "devices"))
    section("Key concepts", linklist(entry.get("key_concepts") or entry.get("concepts") or entry.get("related_concepts"), "concepts"))

    pubs = as_list(entry.get("publications"))
    if pubs:
        L.append("## Publications")
        for p in pubs:
            if isinstance(p, dict):
                t = p.get("title", "?"); y = p.get("year", ""); d = p.get("description", "")
                line = "- *%s*%s%s" % (t, (" (%s)" % y if y else ""), (" — " + d if d else ""))
            else:
                line = "- " + str(p)
            L.append(line)
        L.append("")

    srcs = as_list(entry.get("key_sources")) + as_list(entry.get("source"))
    if entry.get("primary_source"):
        srcs.append(str(entry["primary_source"]))
    srcs = [s for s in srcs if s and not SCRUB.search(str(s))]
    if srcs:
        L.append("## Sources")
        L += ["- " + str(s) for s in srcs[:12]]
        L.append("")

    L.append("---")
    L.append("*Auto-generated from `ontology/%s.yaml` by `bin/wiki-generate.py`. A hand-curated page at this slug overrides it.*" % cat)
    return "\n".join(L) + "\n"


def main():
    base = base_dir()
    ont = base / "ontology"
    wiki = base / "wiki"
    dry = "--dry-run" in sys.argv
    if not ont.is_dir():
        sys.exit("no ontology/ under %s" % base)

    data, titles, present = {}, {}, {}
    for fn, cat, kind in SPEC:
        p = ont / fn
        if not p.is_file():
            print("skip (missing): %s" % fn); continue
        d = yaml.safe_load(p.read_text()) or {}
        d = {slugify(k): v for k, v in d.items()}
        data[cat] = (d, kind)
        titles[cat] = {s: title_of(v, s) for s, v in d.items()}
        present[cat] = set(d.keys())

    created = updated = unchanged = skipped = scrubbed = 0
    for fn, cat, kind in SPEC:
        if cat not in data:
            continue
        d, _kind = data[cat]
        outdir = wiki / cat
        for slug, entry in d.items():
            if SCRUB.search(slug):
                scrubbed += 1; continue
            dest = outdir / (slug + ".md")
            if dest.exists() and not is_generated(dest):
                skipped += 1; continue           # curated → never touch
            content = render(cat, kind, slug, entry, titles, present)
            if dest.exists():
                if dest.read_text() == content:  # idempotent: no churn, no Syncthing storm
                    unchanged += 1; continue
                if dry:
                    updated += 1; continue
                dest.write_text(content); updated += 1
            else:
                if dry:
                    created += 1; continue
                outdir.mkdir(parents=True, exist_ok=True)
                dest.write_text(content); created += 1

    print("%s: people=%d devices=%d concepts=%d | created=%d updated=%d unchanged=%d curated-preserved=%d kortela-skipped=%d" % (
        "DRY-RUN" if dry else "WROTE",
        len(present.get("people", [])), len(present.get("devices", [])), len(present.get("concepts", [])),
        created, updated, unchanged, skipped, scrubbed))


if __name__ == "__main__":
    main()
