#!/usr/bin/env python3
"""Generate a standalone, double-clickable wiki-view.html from a wiki/ folder.

Companion to wiki-index.py. Where wiki-index.py emits a markdown INDEX, this emits
a self-contained interactive HTML browser of the same pages: a sidebar index, each
page rendered from its markdown, and a connections graph.

Everything is derived from the filesystem on every run — nothing is hand-authored:
- pages         : every .md under wiki/ (INDEX.md / README.md / log.md excluded)
- title/one_liner: frontmatter (title, one_liner|description) or H1 / first paragraph
- graph_label   : frontmatter `graph_label:` or a short label derived from the title
- edges         : links in the body + `see_also:` frontmatter pointing at other pages
- components    : connected components (union-find)
- bridges       : edges whose removal disconnects the graph (Tarjan) — drawn dashed
- layout        : a deterministic (seeded) force-directed layout, baked into the HTML

The output is fully offline (inline CSS/JS, no external requests) so it opens from
file:// with a double-click.

Usage:
    python3 bin/wiki-view.py                 # ./wiki/wiki-view.html (default: apple wiki)
    python3 bin/wiki-view.py <wiki-dir>      # target another wiki/ (e.g. merlib-dump/wiki)
    python3 bin/wiki-view.py <wiki-dir> --stdout
"""
import re, sys, json, math, random, pathlib

ROOT = pathlib.Path(__file__).resolve().parent.parent
DEFAULT_WIKI = ROOT / "wiki"

CATEGORY_ORDER = ["devices", "entities", "people", "concepts", "lessons", "operations", "compiled"]
CATEGORY_LABEL = {c: c + "/" for c in CATEGORY_ORDER}
CATEGORY_KIND = {  # css colour bucket: "concept" (amber) or "person" (cyan)
    "people": "person", "entities": "person",
    "concepts": "concept", "devices": "concept",
    "lessons": "concept", "operations": "concept", "compiled": "concept",
}

FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.S)
H1 = re.compile(r"(?m)^# (.+)$")
LINK = re.compile(r"\]\(([^)]+?\.md)[^)]*\)")


def resolve_wiki() -> pathlib.Path:
    for arg in sys.argv[1:]:
        if arg.startswith("-"):
            continue
        p = pathlib.Path(arg).expanduser().resolve()
        return p if p.name == "wiki" else (p / "wiki" if (p / "wiki").is_dir() else p)
    return DEFAULT_WIKI


def parse_frontmatter(text):
    m = FRONTMATTER.match(text)
    if not m:
        return {}, [], text
    block = m.group(1)
    meta, see_also = {}, []
    lines = block.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        km = re.match(r"^([a-zA-Z_][a-zA-Z0-9_-]*):\s*(.*)$", line)
        if km and km.group(1) == "see_also":
            i += 1
            while i < len(lines) and re.match(r"^\s+-\s+", lines[i]):
                val = re.sub(r"^\s+-\s+", "", lines[i]).strip().strip('"').strip("'")
                see_also.append(val)
                i += 1
            continue
        if km:
            v = km.group(2).strip()
            if (v[:1] == '"' and v[-1:] == '"') or (v[:1] == "'" and v[-1:] == "'"):
                v = v[1:-1]
            meta[km.group(1)] = v
        i += 1
    return meta, see_also, text[m.end():]


def first_paragraph(body):
    for p in re.split(r"\n\s*\n", body.strip()):
        p = p.strip()
        if p.startswith(">"):
            p = re.sub(r"(?m)^>\s?", "", p)
        elif p.startswith(("#", "|", "-")) or not p:
            continue
        p = re.sub(r"\s+", " ", p)
        p = re.sub(r"\*\*([^*]+)\*\*", r"\1", p)
        p = re.sub(r"`([^`]+)`", r"\1", p)
        p = re.sub(r"\[([^\]]+)\]\([^)]+\)", r"\1", p)
        return p[:220].rstrip() + ("…" if len(p) > 220 else "")
    return ""


def short_label(title, slug):
    t = re.sub(r"\s*\(.*?\)", "", title).strip()
    t = re.sub(r"^The\s+", "", t)
    for d in (" — ", " / ", ": "):
        if d in t:
            t = t.split(d)[0]
    t = t.strip()
    if len(t) > 18:
        t = t[:17].rstrip() + "…"
    return t or slug


def basename_slug(url):
    return url.split("#")[0].split("/").pop().replace(".md", "")


def force_layout(nodes, edges, seed=7, iters=600):
    """Small deterministic force-directed layout, normalised to 0..1."""
    if not nodes:
        return {}
    rnd = random.Random(seed)
    n = len(nodes)
    pos = {}
    for idx, nm in enumerate(nodes):  # start on a circle for stability
        ang = 2 * math.pi * idx / n
        pos[nm] = [math.cos(ang) + rnd.uniform(-0.1, 0.1),
                   math.sin(ang) + rnd.uniform(-0.1, 0.1)]
    k = 1.0
    eset = edges
    for it in range(iters):
        disp = {nm: [0.0, 0.0] for nm in nodes}
        for i in range(n):
            for j in range(i + 1, n):
                a, b = nodes[i], nodes[j]
                dx = pos[a][0] - pos[b][0]; dy = pos[a][1] - pos[b][1]
                d2 = dx * dx + dy * dy + 1e-4; d = math.sqrt(d2)
                f = (k * k) / d2 * 0.06
                disp[a][0] += dx / d * f; disp[a][1] += dy / d * f
                disp[b][0] -= dx / d * f; disp[b][1] -= dy / d * f
        for a, b in eset:
            dx = pos[a][0] - pos[b][0]; dy = pos[a][1] - pos[b][1]
            d = math.sqrt(dx * dx + dy * dy) + 1e-4
            f = (d * d) / k * 0.02
            disp[a][0] -= dx / d * f; disp[a][1] -= dy / d * f
            disp[b][0] += dx / d * f; disp[b][1] += dy / d * f
        t = 0.10 * (1 - it / iters) + 0.004
        for nm in nodes:
            disp[nm][0] -= pos[nm][0] * 0.012; disp[nm][1] -= pos[nm][1] * 0.012
            dl = math.hypot(disp[nm][0], disp[nm][1]) + 1e-9
            pos[nm][0] += disp[nm][0] / dl * min(dl, t)
            pos[nm][1] += disp[nm][1] / dl * min(dl, t)
    xs = [p[0] for p in pos.values()]; ys = [p[1] for p in pos.values()]
    mnx, mxx, mny, mxy = min(xs), max(xs), min(ys), max(ys)
    def nz(v, mn, mx):
        return 0.5 if mx - mn < 1e-6 else 0.06 + 0.88 * (v - mn) / (mx - mn)
    return {nm: [round(nz(pos[nm][0], mnx, mxx), 4), round(nz(pos[nm][1], mny, mxy), 4)] for nm in nodes}


def components(nodes, edges):
    parent = {nm: nm for nm in nodes}
    def find(x):
        while parent[x] != x:
            parent[x] = parent[parent[x]]; x = parent[x]
        return x
    for a, b in edges:
        parent[find(a)] = find(b)
    return len({find(nm) for nm in nodes})


def bridges(nodes, edges):
    adj = {nm: [] for nm in nodes}
    for idx, (a, b) in enumerate(edges):
        adj[a].append((b, idx)); adj[b].append((a, idx))
    disc = {}; low = {}; timer = [0]; res = []
    import sys as _s
    _s.setrecursionlimit(10000)
    def dfs(u, pe):
        disc[u] = low[u] = timer[0]; timer[0] += 1
        for v, ei in adj[u]:
            if ei == pe:
                continue
            if v not in disc:
                dfs(v, ei)
                low[u] = min(low[u], low[v])
                if low[v] > disc[u]:
                    res.append(tuple(sorted((u, v))))
            else:
                low[u] = min(low[u], disc[v])
    for nm in nodes:
        if nm not in disc:
            dfs(nm, -1)
    return res


def build():
    WIKI = resolve_wiki()
    pages = {}
    for path in sorted(WIKI.rglob("*.md")):
        rel = path.relative_to(WIKI)
        if rel.name in {"INDEX.md", "README.md", "log.md"} or rel.name.endswith(".lesser.md") or len(rel.parts) < 2:
            continue
        cat = rel.parts[0]
        slug = path.stem
        meta, see_also, body = parse_frontmatter(path.read_text())
        h1 = H1.search(body)
        title = meta.get("title") or (h1.group(1).strip() if h1 else meta.get("name", slug))
        one = meta.get("one_liner") or meta.get("description") or first_paragraph(body)
        label = meta.get("graph_label") or short_label(title, slug)
        pages[slug] = {"cat": cat, "title": title, "one": one, "label": label,
                       "body": body, "see_also": see_also,
                       "generated": str(meta.get("generated", "")).strip().lower() == "true"}

    slugs = list(pages)
    # edges from body links + see_also (undirected, deduped)
    eset = set()
    for slug, pg in pages.items():
        targets = set()
        for url in LINK.findall(pg["body"]):
            targets.add(basename_slug(url))
        for ref in pg["see_also"]:
            if ref.endswith(".md"):
                targets.add(basename_slug(ref))
        for t in targets:
            if t in pages and t != slug:
                eset.add(tuple(sorted((slug, t))))
    edges = sorted(eset)

    # ---- scale guard: embed/draw at most CAP pages (curated + most-connected hubs).
    # The full set always lives in INDEX.md and in Obsidian (built for thousands of nodes);
    # this browser view is the small, fast, curated lens.
    CAP = 60
    full_pages, full_links = len(slugs), len(edges)
    truncated = None
    if full_pages > CAP:
        deg = {}
        for a, b in edges:
            deg[a] = deg.get(a, 0) + 1; deg[b] = deg.get(b, 0) + 1
        keep = [s for s in slugs if not pages[s].get("generated")]          # curated first
        seen = set(keep)
        for s in sorted((s for s in slugs if s not in seen), key=lambda s: (-deg.get(s, 0), pages[s]["title"])):
            if len(keep) >= CAP:
                break
            keep.append(s)
        keepset = set(keep)
        slugs = [s for s in slugs if s in keepset]
        pages = {s: pages[s] for s in slugs}
        edges = [e for e in edges if e[0] in keepset and e[1] in keepset]
        truncated = {"shown": len(slugs), "total": full_pages, "curated": len(seen)}

    pos = force_layout(slugs, edges)
    ncomp = components(slugs, edges)
    brs = bridges(slugs, edges)

    order = {}
    cats_present = []
    for cat in CATEGORY_ORDER + sorted({p["cat"] for p in pages.values()} - set(CATEGORY_ORDER)):
        members = sorted([s for s in slugs if pages[s]["cat"] == cat], key=lambda s: pages[s]["title"])
        if members:
            order[cat] = members
            if cat not in cats_present:
                cats_present.append(cat)

    W = {
        "meta": {s: {"cat": pages[s]["cat"], "title": pages[s]["title"],
                     "one": pages[s]["one"], "label": pages[s]["label"],
                     "kind": CATEGORY_KIND.get(pages[s]["cat"], "concept")} for s in slugs},
        "order": order,
        "cats": cats_present,
        "catLabel": {c: CATEGORY_LABEL.get(c, c + "/") for c in cats_present},
        "edges": edges,
        "bridges": brs,
        "pos": pos,
        "components": ncomp,
        "counts": {"pages": full_pages, "cats": len(cats_present), "links": full_links},
        "truncated": truncated,
    }
    md_blocks = "\n".join(
        '<script type="text/markdown" id="md-%s">\n%s\n</script>' % (s, pages[s]["body"].strip())
        for s in slugs
    )
    return W, md_blocks, str(WIKI)


# ---------------------------------------------------------------- HTML assembly
STYLE = r"""<style>
  :root{
    --bg:#e9ebe6;--surface:#f6f7f3;--surface-2:#eff1eb;--ink:#1a1e1b;--muted:#5b625b;--faint:#828a82;
    --line:#d3d7cd;--line-strong:#c2c7bb;--amber:#9c6410;--amber-soft:#b8791f;--amber-wash:#f0e5cf;
    --cyan:#256a70;--cyan-wash:#d9e6e5;
    --serif:"Charter","Iowan Old Style","Palatino",Georgia,serif;
    --sans:"Avenir Next","Segoe UI",system-ui,-apple-system,sans-serif;
    --mono:"SF Mono","Menlo","Consolas",ui-monospace,monospace;--maxw:1180px;}
  @media (prefers-color-scheme:dark){:root{
    --bg:#13161a;--surface:#1b1f24;--surface-2:#20252b;--ink:#e6e8e2;--muted:#9aa39a;--faint:#6f776f;
    --line:#2a3037;--line-strong:#39414a;--amber:#e3a441;--amber-soft:#d0902f;--amber-wash:#2c2416;
    --cyan:#5fb4b8;--cyan-wash:#132a2b;}}
  :root[data-theme="light"]{--bg:#e9ebe6;--surface:#f6f7f3;--surface-2:#eff1eb;--ink:#1a1e1b;--muted:#5b625b;
    --faint:#828a82;--line:#d3d7cd;--line-strong:#c2c7bb;--amber:#9c6410;--amber-soft:#b8791f;
    --amber-wash:#f0e5cf;--cyan:#256a70;--cyan-wash:#d9e6e5;}
  :root[data-theme="dark"]{--bg:#13161a;--surface:#1b1f24;--surface-2:#20252b;--ink:#e6e8e2;--muted:#9aa39a;
    --faint:#6f776f;--line:#2a3037;--line-strong:#39414a;--amber:#e3a441;--amber-soft:#d0902f;
    --amber-wash:#2c2416;--cyan:#5fb4b8;--cyan-wash:#132a2b;}
  *{box-sizing:border-box}html,body{margin:0;padding:0}
  .wrap{background:var(--bg);color:var(--ink);font-family:var(--serif);line-height:1.6;min-height:100vh;-webkit-font-smoothing:antialiased}
  .masthead{border-bottom:1px solid var(--line-strong);background:var(--surface)}
  .masthead-in{max-width:var(--maxw);margin:0 auto;padding:22px 28px 18px;display:flex;justify-content:space-between;align-items:flex-start;gap:24px;flex-wrap:wrap}
  .brand h1{font-family:var(--sans);font-weight:700;font-size:1.5rem;margin:0;letter-spacing:-.01em;text-wrap:balance}
  .brand .sub{color:var(--muted);font-size:.92rem;margin-top:5px;max-width:54ch}
  .glyphs{font-family:var(--mono);font-size:1.05rem;color:var(--amber);letter-spacing:.35em;margin-top:12px}
  .glyphs span{opacity:.55}.glyphs span.kept{opacity:1}
  .meta-col{text-align:right;font-family:var(--sans);font-size:.74rem;color:var(--muted);display:flex;flex-direction:column;align-items:flex-end;gap:9px}
  .stat{font-variant-numeric:tabular-nums}.stat b{color:var(--ink);font-size:1.05rem}
  .themebtn{font-family:var(--sans);font-size:.72rem;letter-spacing:.06em;text-transform:uppercase;background:var(--surface-2);color:var(--muted);border:1px solid var(--line);border-radius:999px;padding:5px 12px;cursor:pointer}
  .themebtn:hover{border-color:var(--amber);color:var(--ink)}
  .grid{max-width:var(--maxw);margin:0 auto;padding:26px 28px 60px;display:grid;grid-template-columns:248px 1fr;gap:34px;align-items:start}
  @media (max-width:820px){.grid{grid-template-columns:1fr;gap:22px}}
  .side{position:sticky;top:18px}@media (max-width:820px){.side{position:static}}
  .side .home{font-family:var(--sans);font-weight:600;font-size:.9rem;color:var(--ink);background:none;border:0;padding:0 0 4px;cursor:pointer;display:flex;align-items:center;gap:8px}
  .side .home:hover{color:var(--amber)}.side .home::before{content:"◈";color:var(--amber);font-size:.8em}
  .cat{margin-top:22px}
  .cat h3{font-family:var(--sans);text-transform:uppercase;letter-spacing:.11em;font-size:.68rem;color:var(--faint);margin:0 0 9px;font-weight:700}
  .cat ul{list-style:none;margin:0;padding:0;display:flex;flex-direction:column;gap:1px}
  .navitem{font-family:var(--sans);font-size:.86rem;text-align:left;width:100%;background:none;border:0;border-left:2px solid transparent;color:var(--muted);padding:6px 10px;cursor:pointer;line-height:1.35;border-radius:0 4px 4px 0}
  .navitem:hover{background:var(--surface-2);color:var(--ink)}
  .navitem.active{border-left-color:var(--amber);color:var(--ink);background:var(--surface-2);font-weight:600}
  .navitem .dot{display:inline-block;width:6px;height:6px;border-radius:50%;margin-right:7px;vertical-align:middle}
  .dot.concept{background:var(--amber-soft)}.dot.person{background:var(--cyan)}
  .panel{background:var(--surface);border:1px solid var(--line);border-radius:10px;padding:34px 40px 40px;min-height:60vh;min-width:0}
  @media (max-width:520px){.panel{padding:24px 22px 30px}}
  .fade{animation:fade .28s ease}@keyframes fade{from{opacity:0;transform:translateY(4px)}to{opacity:1;transform:none}}
  @media (prefers-reduced-motion:reduce){.fade{animation:none}}
  .chip{display:inline-block;font-family:var(--sans);font-size:.66rem;text-transform:uppercase;letter-spacing:.09em;font-weight:700;padding:3px 9px;border-radius:999px;margin-bottom:14px}
  .chip.concept{background:var(--amber-wash);color:var(--amber)}.chip.person{background:var(--cyan-wash);color:var(--cyan)}
  .ptitle{font-family:var(--sans);font-weight:700;font-size:1.9rem;line-height:1.15;margin:0;letter-spacing:-.015em;text-wrap:balance}
  .oneliner{font-size:1.06rem;color:var(--muted);font-style:italic;margin:12px 0 4px;max-width:64ch;border-left:3px solid var(--amber);padding-left:14px}
  .rule{height:1px;background:var(--line);margin:26px 0}
  .md{max-width:70ch}.md h1{display:none}
  .md h2{font-family:var(--sans);font-size:1.18rem;font-weight:700;margin:30px 0 10px;letter-spacing:-.01em;color:var(--ink);text-wrap:balance}
  .md h3{font-family:var(--sans);font-size:.98rem;font-weight:700;margin:22px 0 6px;color:var(--ink)}
  .md h4{font-family:var(--sans);font-size:.9rem;font-weight:700;margin:18px 0 4px;color:var(--muted)}
  .md p{margin:11px 0}.md ul,.md ol{margin:11px 0;padding-left:22px}.md li{margin:6px 0}
  .md blockquote{margin:18px 0;padding:14px 20px;background:var(--surface-2);border-left:3px solid var(--amber);border-radius:0 6px 6px 0;color:var(--ink);font-size:.98rem}
  .md blockquote strong{color:var(--amber)}
  .md code{font-family:var(--mono);font-size:.82em;background:var(--surface-2);padding:1px 5px;border-radius:4px;border:1px solid var(--line);color:var(--amber-soft);overflow-wrap:anywhere}
  .md a.wl{color:var(--amber);text-decoration:none;border-bottom:1px solid color-mix(in srgb,var(--amber) 40%,transparent);cursor:pointer;font-weight:500}
  .md a.wl:hover{border-bottom-color:var(--amber);background:var(--amber-wash)}
  .md .ref{color:var(--muted);border-bottom:1px dotted var(--faint);cursor:help}
  .md .ref::after{content:" ↗";font-size:.7em;color:var(--faint);vertical-align:super}
  .md strong{font-weight:700}.md em{font-style:italic}
  .tablewrap{overflow-x:auto;margin:16px 0;border:1px solid var(--line);border-radius:8px}
  .md table{border-collapse:collapse;width:100%;font-size:.9rem;font-family:var(--sans)}
  .md th,.md td{text-align:left;padding:8px 12px;border-bottom:1px solid var(--line);vertical-align:top}
  .md th{background:var(--surface-2);font-weight:700;font-size:.8rem;text-transform:uppercase;letter-spacing:.04em;color:var(--muted)}
  .md tr:last-child td{border-bottom:0}.md td strong{color:var(--ink)}
  .lede{font-size:1.12rem;color:var(--ink);margin:0 0 6px;max-width:66ch}.lede .amber{color:var(--amber);font-weight:600;font-style:italic}
  .graphcard{margin:24px 0 8px;border:1px solid var(--line);border-radius:10px;background:var(--surface-2);overflow:hidden}
  .graphcard .ghead{padding:13px 18px;border-bottom:1px solid var(--line);display:flex;justify-content:space-between;align-items:center;gap:12px;flex-wrap:wrap}
  .graphcard .ghead h2{font-family:var(--sans);font-size:.95rem;margin:0;font-weight:700}
  .legend{display:flex;gap:16px;font-family:var(--sans);font-size:.74rem;color:var(--muted)}
  .legend i{display:inline-block;width:9px;height:9px;border-radius:50%;margin-right:5px;vertical-align:middle}
  canvas#graph{display:block;width:100%;height:400px;cursor:default}@media (max-width:520px){canvas#graph{height:330px}}
  .gnote{font-family:var(--sans);font-size:.78rem;color:var(--muted);padding:10px 18px;border-top:1px solid var(--line);background:var(--surface)}
  .gnote b{color:var(--amber)}
  .obsidian{margin-top:22px;border:1px dashed var(--line-strong);border-radius:10px;padding:16px 20px;background:var(--surface);display:flex;gap:14px;align-items:flex-start}
  .obsidian .ic{font-size:1.3rem;line-height:1;color:var(--cyan)}
  .obsidian h3{font-family:var(--sans);font-size:.9rem;margin:0 0 5px}.obsidian p{margin:4px 0;font-size:.9rem;color:var(--muted)}
  .obsidian code{font-family:var(--mono);font-size:.8em;background:var(--surface-2);padding:2px 6px;border-radius:4px;border:1px solid var(--line);color:var(--ink);overflow-wrap:anywhere}
  .footer{max-width:var(--maxw);margin:0 auto;padding:0 28px 40px;font-family:var(--sans);font-size:.76rem;color:var(--faint);text-align:center}
  .footer code{font-family:var(--mono);color:var(--muted)}
</style>"""

APP_JS = r"""<script>
(function(){"use strict";
  var W=window.__WIKI__;var META=W.meta,ORDER=W.order,POS=W.pos,EDGES=W.edges,BRIDGES=W.bridges;
  var SLUGS=Object.keys(META);
  var BRK={};BRIDGES.forEach(function(e){BRK[e[0]+"|"+e[1]]=1;BRK[e[1]+"|"+e[0]]=1;});
  var DEG={};EDGES.forEach(function(e){DEG[e[0]]=(DEG[e[0]]||0)+1;DEG[e[1]]=(DEG[e[1]]||0)+1;});
  function esc(s){return s.replace(/&(?!(amp|lt|gt|#\d+);)/g,"&amp;").replace(/</g,"&lt;").replace(/>/g,"&gt;");}
  function inline(t){t=esc(t);
    t=t.replace(/`([^`]+)`/g,function(_,c){return "<code>"+c+"</code>";});
    t=t.replace(/\[([^\]]+)\]\(([^)]+)\)/g,function(_,txt,url){
      var base=url.split("#")[0].split("/").pop().replace(/\.md$/,"");
      if(/^https?:/.test(url))return '<a class="wl" href="'+url+'" target="_blank" rel="noopener">'+txt+'</a>';
      if(META[base])return '<a class="wl" data-slug="'+base+'">'+txt+'</a>';
      return '<span class="ref" title="'+esc(url)+'">'+txt+'</span>';});
    t=t.replace(/\*\*([^*]+?)\*\*/g,"<strong>$1</strong>");
    t=t.replace(/\*([^*\n]+?)\*/g,"<em>$1</em>");return t;}
  function renderMD(md){md=md.replace(/\r/g,"").replace(/^\s*\n/,"");
    if(md.indexOf("---\n")===0){var e=md.indexOf("\n---\n");if(e>-1)md=md.slice(e+5);}
    var lines=md.split("\n"),out=[],i=0,firstH1=false;
    function isRow(l){return /^\s*\|.*\|\s*$/.test(l);}
    function cells(l){return l.trim().replace(/^\|/,"").replace(/\|$/,"").split("|").map(function(c){return c.trim();});}
    while(i<lines.length){var line=lines[i];
      if(line.trim()===""){i++;continue;}
      var h=/^(#{1,6})\s+(.*)$/.exec(line);
      if(h){var lvl=h[1].length;if(lvl===1&&!firstH1){firstH1=true;i++;continue;}
        out.push("<h"+lvl+">"+inline(h[2])+"</h"+lvl+">");i++;continue;}
      if(isRow(line)&&i+1<lines.length&&/^\s*\|?[\s:|-]+\|?\s*$/.test(lines[i+1])&&lines[i+1].indexOf("-")>-1){
        var hd=cells(line);i+=2;var rows=[];while(i<lines.length&&isRow(lines[i])){rows.push(cells(lines[i]));i++;}
        var th="<tr>"+hd.map(function(c){return "<th>"+inline(c)+"</th>";}).join("")+"</tr>";
        var tb=rows.map(function(r){return "<tr>"+r.map(function(c){return "<td>"+inline(c)+"</td>";}).join("")+"</tr>";}).join("");
        out.push('<div class="tablewrap"><table><thead>'+th+'</thead><tbody>'+tb+'</tbody></table></div>');continue;}
      if(/^\s*>/.test(line)){var bq=[];while(i<lines.length&&/^\s*>/.test(lines[i])){bq.push(lines[i].replace(/^\s*>\s?/,""));i++;}
        out.push("<blockquote>"+inline(bq.join(" ").trim())+"</blockquote>");continue;}
      if(/^\s*-\s+/.test(line)){var it=[];while(i<lines.length){
        if(/^\s*-\s+/.test(lines[i])){it.push(lines[i].replace(/^\s*-\s+/,""));i++;}
        else if(lines[i].trim()!==""&&/^\s+/.test(lines[i])&&it.length){it[it.length-1]+=" "+lines[i].trim();i++;}
        else break;}
        out.push("<ul>"+it.map(function(x){return "<li>"+inline(x)+"</li>";}).join("")+"</ul>");continue;}
      if(/^\s*\d+\.\s+/.test(line)){var oi=[];while(i<lines.length){
        if(/^\s*\d+\.\s+/.test(lines[i])){oi.push(lines[i].replace(/^\s*\d+\.\s+/,""));i++;}
        else if(lines[i].trim()!==""&&/^\s+/.test(lines[i])&&oi.length){oi[oi.length-1]+=" "+lines[i].trim();i++;}
        else break;}
        out.push("<ol>"+oi.map(function(x){return "<li>"+inline(x)+"</li>";}).join("")+"</ol>");continue;}
      var para=[line];i++;
      while(i<lines.length&&lines[i].trim()!==""&&!/^(#{1,6}\s|\s*>|\s*-\s|\s*\d+\.\s)/.test(lines[i])&&!isRow(lines[i])){para.push(lines[i]);i++;}
      out.push("<p>"+inline(para.join(" "))+"</p>");}
    return out.join("\n");}
  var panel=document.getElementById("panel"),mdCache={};
  function getMD(slug){if(mdCache[slug])return mdCache[slug];var el=document.getElementById("md-"+slug);mdCache[slug]=renderMD(el.textContent);return mdCache[slug];}
  function buildNav(){var host=document.getElementById("navcats");host.innerHTML="";
    W.cats.forEach(function(cat){var d=document.createElement("div");d.className="cat";
      var h=document.createElement("h3");h.textContent=W.catLabel[cat];d.appendChild(h);
      var ul=document.createElement("ul");
      ORDER[cat].forEach(function(slug){var li=document.createElement("li");var b=document.createElement("button");
        b.className="navitem";b.dataset.slug=slug;
        b.innerHTML='<span class="dot '+META[slug].kind+'"></span>'+META[slug].title;
        b.addEventListener("click",function(){go(slug);});li.appendChild(b);ul.appendChild(li);});
      d.appendChild(ul);host.appendChild(d);});}
  function markActive(slug){document.querySelectorAll(".navitem").forEach(function(b){b.classList.toggle("active",b.dataset.slug===slug);});}
  function renderPage(slug){var m=META[slug];
    var conn=EDGES.filter(function(e){return e[0]===slug||e[1]===slug;}).map(function(e){return e[0]===slug?e[1]:e[0];});
    var connHTML=conn.map(function(s){return '<a class="wl" data-slug="'+s+'">'+META[s].label+'</a>';}).join(" · ")||"—";
    panel.className="panel fade";
    panel.innerHTML='<span class="chip '+m.kind+'">'+W.catLabel[m.cat]+' · '+m.cat.replace(/s$/,"")+'</span>'+
      '<h2 class="ptitle">'+esc(m.title)+'</h2>'+
      '<p class="oneliner">'+esc(m.one)+'</p><div class="rule"></div>'+
      '<div class="md">'+getMD(slug)+'</div><div class="rule"></div>'+
      '<p style="font-family:var(--sans);font-size:.82rem;color:var(--muted)"><strong style="color:var(--ink)">Connections:</strong> '+connHTML+'</p>';
    wire();void panel.offsetWidth;}
  function wire(){panel.querySelectorAll("a.wl[data-slug]").forEach(function(a){a.addEventListener("click",function(ev){ev.preventDefault();go(a.dataset.slug);});});}
  function overview(){markActive(null);panel.className="panel fade";
    var comp=W.components,br=BRIDGES.length;
    var lede;
    if(W.truncated){lede='The map and list below show the <span class="amber">'+W.truncated.shown+' most-connected pages</span> ('+W.truncated.curated+' curated + top hubs). All <strong>'+W.counts.pages+'</strong> are browsable in <code>INDEX.md</code> and in the Obsidian vault (built for graphs this size).';}
    else if(comp===1)lede='The cross-links form <span class="amber">one connected graph</span>'+(br?' held together by '+br+' bridge link'+(br>1?"s":"")+'':'')+'.';
    else lede='The cross-links form <span class="amber">'+comp+' separate clusters</span> (not yet all connected).';
    var bnote="";
    if(br){bnote=BRIDGES.map(function(e){return META[e[0]].label+" → "+META[e[1]].label;}).join(", ");
      bnote='<div class="gnote">Dashed amber = <b>bridge link</b> (removing it splits the graph): <b>'+esc(bnote)+'</b>. Click any node to open its page.</div>';}
    else bnote='<div class="gnote">Click any node to open its page.</div>';
    panel.innerHTML='<span class="chip concept">overview</span>'+
      '<h2 class="ptitle">'+W.counts.pages+' pages · '+W.counts.links+' links</h2>'+
      '<p class="lede">This wiki holds <strong>'+W.counts.pages+' pages</strong> across <strong>'+W.counts.cats+'</strong> categories. '+lede+'</p>'+
      '<div class="graphcard"><div class="ghead"><h2>Connections map</h2>'+
        '<div class="legend"><span><i style="background:var(--amber-soft)"></i>concept</span><span><i style="background:var(--cyan)"></i>person</span></div></div>'+
        '<canvas id="graph" width="900" height="400" role="img" aria-label="Graph of wiki pages and their links"></canvas>'+bnote+'</div>'+
      '<div class="obsidian"><div class="ic">◆</div><div><h3>Open the live version in Obsidian</h3>'+
        '<p>The <code>wiki/</code> folder is a valid Obsidian vault — the pages use standard markdown links and <code>see_also:</code> frontmatter, so Obsidian&rsquo;s graph view renders these same connections and updates as pages change.</p>'+
        '<p>In Obsidian: <em>Open folder as vault</em> → the <code>wiki/</code> folder.</p></div></div>';
    drawGraph();panel.querySelectorAll("a.wl[data-slug]").forEach(function(a){a.addEventListener("click",function(e){e.preventDefault();go(a.dataset.slug);});});void panel.offsetWidth;}
  var hit=[];function css(v){return getComputedStyle(document.documentElement).getPropertyValue(v).trim();}
  function drawGraph(){var cv=document.getElementById("graph");if(!cv)return;var ctx=cv.getContext("2d");
    var dpr=window.devicePixelRatio||1,rect=cv.getBoundingClientRect(),Wd=rect.width||900,Hd=rect.height||400;
    cv.width=Wd*dpr;cv.height=Hd*dpr;ctx.setTransform(dpr,0,0,dpr,0,0);ctx.clearRect(0,0,Wd,Hd);
    var padX=64,padY=42;function X(n){return padX+n*(Wd-2*padX);}function Y(n){return padY+n*(Hd-2*padY);}
    var amber=css("--amber-soft")||"#b8791f",cyan=css("--cyan")||"#256a70",line=css("--line-strong")||"#c2c7bb",
        ink=css("--ink")||"#1a1e1b",surf=css("--surface")||"#f6f7f3";
    EDGES.forEach(function(e){var a=POS[e[0]],b=POS[e[1]];var isB=BRK[e[0]+"|"+e[1]];
      ctx.beginPath();ctx.moveTo(X(a[0]),Y(a[1]));ctx.lineTo(X(b[0]),Y(b[1]));
      if(isB){ctx.strokeStyle=amber;ctx.lineWidth=2.2;ctx.setLineDash([6,4]);}else{ctx.strokeStyle=line;ctx.lineWidth=1.1;ctx.setLineDash([]);}ctx.stroke();});
    ctx.setLineDash([]);hit=[];
    SLUGS.forEach(function(slug){var p=POS[slug];var x=X(p[0]),y=Y(p[1]);var isC=META[slug].kind==="concept";
      var r=8+(DEG[slug]||1)*1.4;ctx.beginPath();ctx.arc(x,y,r,0,7);ctx.fillStyle=isC?amber:cyan;ctx.fill();
      ctx.lineWidth=2;ctx.strokeStyle=surf;ctx.stroke();
      ctx.font="600 12px "+((css("--sans")||"sans-serif").split(",")[0].replace(/"/g,""));
      ctx.textAlign="center";ctx.textBaseline="top";ctx.fillStyle=ink;ctx.fillText(META[slug].label,x,y+r+4);
      hit.push({slug:slug,x:x,y:y,r:r+6});});
    cv.onmousemove=function(ev){var rc=cv.getBoundingClientRect(),mx=ev.clientX-rc.left,my=ev.clientY-rc.top;
      cv.style.cursor=hit.some(function(h){return (mx-h.x)*(mx-h.x)+(my-h.y)*(my-h.y)<=h.r*h.r;})?"pointer":"default";};
    cv.onclick=function(ev){var rc=cv.getBoundingClientRect(),mx=ev.clientX-rc.left,my=ev.clientY-rc.top;
      for(var k=0;k<hit.length;k++){var h=hit[k];if((mx-h.x)*(mx-h.x)+(my-h.y)*(my-h.y)<=h.r*h.r){go(h.slug);return;}}};}
  function go(slug){if(slug&&META[slug]){if(location.hash!=="#"+slug)history.replaceState(null,"","#"+slug);
      markActive(slug);renderPage(slug);window.scrollTo({top:0,behavior:(matchMedia("(prefers-reduced-motion:reduce)").matches?"auto":"smooth")});}
    else{history.replaceState(null,"","#");overview();window.scrollTo({top:0});}}
  document.getElementById("homebtn").addEventListener("click",function(){go(null);});
  document.getElementById("themebtn").addEventListener("click",function(){var cur=document.documentElement.getAttribute("data-theme");
    var next=cur==="dark"?"light":cur==="light"?"dark":(matchMedia("(prefers-color-scheme:dark)").matches?"light":"dark");
    document.documentElement.setAttribute("data-theme",next);if(panel.querySelector("#graph"))drawGraph();});
  window.addEventListener("resize",function(){if(panel.querySelector("#graph"))drawGraph();});
  buildNav();var start=location.hash.replace("#","");if(start&&META[start])go(start);else overview();
})();
</script>"""


def html(W, md_blocks, wiki_path):
    body = (
        '<div class="wrap"><header class="masthead"><div class="masthead-in">'
        '<div class="brand"><h1>MERLib Wiki</h1>'
        '<div class="sub">The archive&rsquo;s concept &amp; person layer — one page per idea or figure, re-derived from the filesystem on every run.</div>'
        '<div class="glyphs" title="The four universal glyphs: CEM/EE kept the lemniscate and the spiral, dropped the dot-in-circle and the vortex pair">'
        '<span class="kept">&#8734;</span><span class="kept">@</span><span>&#9737;</span><span>&gt;|&lt;</span></div></div>'
        '<div class="meta-col"><button class="themebtn" id="themebtn" type="button">Theme</button>'
        '<div class="stat"><b>' + str(W["counts"]["pages"]) + '</b> pages</div>'
        '<div class="stat"><b>' + str(W["counts"]["cats"]) + '</b> categories &middot; <b>' + str(W["counts"]["links"]) + '</b> links</div>'
        '</div></div></header>'
        '<div class="grid"><nav class="side" aria-label="Wiki index">'
        '<button class="home" id="homebtn" type="button">Overview</button><div id="navcats"></div></nav>'
        '<main class="panel" id="panel"></main></div>'
        '<div class="footer">Auto-generated by <code>apple/bin/wiki-view.py</code> &middot; source of truth is <code>' + wiki_path + '</code></div></div>'
    )
    data = '<script>window.__WIKI__=' + json.dumps(W, ensure_ascii=False) + ';</script>'
    return ("<!doctype html>\n<html lang=\"en\">\n<head>\n<meta charset=\"utf-8\">\n"
            "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">\n"
            "<title>MERLib Wiki</title>\n" + STYLE + "\n</head>\n<body>\n"
            + body + "\n" + md_blocks + "\n" + data + "\n" + APP_JS + "\n</body>\n</html>\n")


def main():
    W, md_blocks, wiki_path = build()
    out = html(W, md_blocks, wiki_path)
    if "--stdout" in sys.argv:
        sys.stdout.write(out)
    else:
        out_path = resolve_wiki() / "wiki-view.html"
        out_path.write_text(out)
        print("wrote %s (%d pages, %d links, %d bridge(s), %d component(s), %d bytes)" % (
            out_path, W["counts"]["pages"], W["counts"]["links"],
            len(W["bridges"]), W["components"], len(out)))


if __name__ == "__main__":
    main()
