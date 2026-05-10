#!/usr/bin/env python3
"""
sdef-to-jxa.py — Render each app's parsed sdef as a JXA (JavaScript for Automation) cheat-sheet.

Consumes the YAML emitted by sdef-extract.py (`dictionaries/<slug>/<slug>.yaml`) and
emits `dictionaries/<slug>/<slug>.jxa.md` — the same dictionary in JavaScript dialect.

Rooted in WWDC 2014 #306 (Sal + David Steinberg). The translation rules from that
session, applied verbatim:

    AppleScript                       JavaScript for Automation
    ─────────────────────────────────────────────────────────────────
    tell application "Mail"           var Mail = Application('Mail')
    every message of inbox            Mail.inbox.messages
    message 1 of inbox                Mail.inbox.messages[0]
    every X whose name is "Y"         X.whose({name: 'Y'})
    make new document                 app.documents.push(app.Document())
    set name of doc to "foo"          doc.name = 'foo'
    name of doc                       doc.name()        # getter takes parens
    open theFile                      app.open(Path('/path'))
    reply with replyAll               msg.reply({replyAll: true})

Usage:
    python3 sdef-to-jxa.py                # render every dictionaries/*/<slug>.yaml
    python3 sdef-to-jxa.py mail safari    # render specific apps
    python3 sdef-to-jxa.py --check        # report which dicts have/lack jxa.md
"""

import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
DICTS = REPO / "dictionaries"


def parse_sdef(xml_path: Path) -> dict:
    """Parse <slug>.sdef.xml into the same dict shape sdef-to-jxa expects.
    Resilient to the xi:include directives sdef files often carry — we ignore
    them and only process inline <suite>/<command>/<class> nodes."""
    try:
        # Strip DOCTYPE to avoid external DTD fetching
        text = xml_path.read_text(encoding="utf-8", errors="replace")
        # Remove DOCTYPE and xi:include nodes (we only render what's inline)
        import re
        # DOCTYPE may have an inline DTD subset: <!DOCTYPE ... [ ... ]>
        text = re.sub(r"<!DOCTYPE\b.*?(?:\[.*?\])?\s*>", "", text, flags=re.DOTALL)
        # Drop xi:include nodes entirely (we render only inline content)
        text = re.sub(r"<xi:include\b[^>]*?/>", "", text, flags=re.DOTALL)
        text = re.sub(r"<xi:include\b.*?</xi:include>", "", text, flags=re.DOTALL)
        # Strip xmlns declarations and xi: prefix uses
        text = re.sub(r'\s+xmlns(:[a-zA-Z0-9]+)?="[^"]*"', "", text)
        text = re.sub(r"\bxi:", "", text)
        root = ET.fromstring(text)
    except ET.ParseError as e:
        return {"_error": str(e)}

    app_name = (root.get("title") or "").replace(" Terminology", "").strip()
    suites_out = []
    cmd_total = cls_total = 0
    for suite in root.findall("suite"):
        s = {"name": suite.get("name", ""), "description": suite.get("description", ""), "commands": [], "classes": []}
        for cmd in suite.findall("command"):
            dp = cmd.find("direct-parameter")
            params = []
            for p in cmd.findall("parameter"):
                params.append({
                    "name": p.get("name", ""),
                    "type": p.get("type", ""),
                    "optional": p.get("optional") == "yes",
                })
            s["commands"].append({
                "name": cmd.get("name", ""),
                "description": cmd.get("description", ""),
                "direct_parameter": ({"type": dp.get("type", "specifier")} if dp is not None else None),
                "parameters": params,
            })
            cmd_total += 1
        for cls in suite.findall("class"):
            props = []
            for pr in cls.findall("property"):
                props.append({
                    "name": pr.get("name", ""),
                    "type": pr.get("type", ""),
                    "access": pr.get("access", "rw") or "rw",
                })
            elems = [e.get("type", "") for e in cls.findall("element") if e.get("type")]
            s["classes"].append({
                "name": cls.get("name", ""),
                "description": cls.get("description", ""),
                "properties": props,
                "elements": elems,
            })
            cls_total += 1
        suites_out.append(s)
    return {
        "app": app_name,
        "commands_count": cmd_total,
        "classes_count": cls_total,
        "suites_count": len(suites_out),
        "suites": suites_out,
    }


def selector_camel(name: str) -> str:
    """AE command name → JXA method name. 'reply' stays 'reply'. 'duplicate' stays 'duplicate'.
    Multi-word AE command names are rare; leave them lowercase-joined."""
    parts = name.replace("-", " ").split()
    if not parts:
        return name
    return parts[0].lower() + "".join(p.capitalize() for p in parts[1:])


def param_key(name: str) -> str:
    """AE parameter label → JXA record key. 'with properties' → 'withProperties'.
    'to' stays 'to'."""
    return selector_camel(name)


def render_command(app_var: str, cmd: dict) -> str:
    """One JXA call site for an AE command."""
    name = cmd.get("name", "?")
    method = selector_camel(name)
    dp = cmd.get("direct_parameter")
    params = cmd.get("parameters") or []
    args = []
    if dp:
        t = dp.get("type", "specifier")
        # heuristic placeholder
        if t == "file":
            args.append("Path('/path/to/file')")
        elif t == "specifier":
            args.append("target")
        elif t == "text":
            args.append("'...'")
        elif t == "boolean":
            args.append("true")
        else:
            args.append(f"/* {t} */")
    if params:
        record_items = []
        for p in params:
            key = param_key(p.get("name", ""))
            t = p.get("type", "?")
            if t == "boolean":
                v = "true"
            elif t == "text":
                v = "'...'"
            elif t == "file" or t == "location specifier":
                v = "Path('/path')"
            elif t == "record":
                v = "{}"
            else:
                v = f"/* {t} */"
            record_items.append(f"{key}: {v}")
        args.append("{" + ", ".join(record_items) + "}")
    desc = cmd.get("description", "").strip()
    line = f"{app_var}.{method}({', '.join(args)})"
    return f"// {desc}\n{line}" if desc else line


def render_class(app_var: str, cls: dict) -> list[str]:
    """Two snippets per class: property access + element collection + whose-filter example."""
    name = cls.get("name", "?")
    slug = name.replace(" ", "")
    var = slug[:1].lower() + slug[1:]
    out = [f"// class: {name}"]
    if desc := cls.get("description"):
        out.append(f"// {desc.strip()}")
    props = cls.get("properties") or []
    if props:
        # show one rw and one ro property as exemplar
        rw = [p for p in props if p.get("access") == "rw"]
        ro = [p for p in props if p.get("access") in ("r", None) and p not in rw]
        if rw:
            p = rw[0]
            out.append(f"{var}.{param_key(p['name'])}        // getter ({p.get('type','?')})")
            v = "'...'" if p.get("type") == "text" else "/* value */"
            out.append(f"{var}.{param_key(p['name'])} = {v}  // setter")
        if ro:
            p = ro[0]
            out.append(f"{var}.{param_key(p['name'])}        // read-only getter ({p.get('type','?')})")
    elems = cls.get("elements") or []
    if elems:
        e = elems[0]
        coll = selector_camel(e) + "s" if not e.endswith("s") else selector_camel(e)
        # heuristic plural
        if not coll.endswith("s"):
            coll = coll + "s"
        out.append(f"{var}.{coll}[0]                   // first {e}")
        out.append(f"{var}.{coll}.whose({{name: 'x'}})  // filter")
    return out


def render(slug: str, data: dict) -> str:
    app = data.get("app", slug)
    app_var = "".join(c for c in app if c.isalnum()) or "App"
    out = []
    out.append(f"# {app} — JavaScript for Automation (JXA) Reference")
    out.append("")
    out.append(f"> Rendered from `{slug}.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `{slug}.md`.")
    out.append(f"> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).")
    out.append("")
    out.append("## Get the application")
    out.append("")
    out.append("```javascript")
    out.append(f"var {app_var} = Application('{app}')")
    out.append(f"{app_var}.includeStandardAdditions = true   // if calling beep/say/displayDialog")
    out.append("```")
    out.append("")
    out.append(f"**Commands:** {data.get('commands_count', 0)}  ·  **Classes:** {data.get('classes_count', 0)}  ·  **Suites:** {data.get('suites_count', 0)}")
    out.append("")
    for suite in data.get("suites", []):
        sname = suite.get("name", "?")
        out.append(f"## Suite — {sname}")
        if d := suite.get("description"):
            out.append("")
            out.append(f"_{d}_")
        cmds = suite.get("commands") or []
        if cmds:
            out.append("")
            out.append("### Commands")
            out.append("")
            out.append("```javascript")
            for cmd in cmds:
                out.append(render_command(app_var, cmd))
                out.append("")
            out.append("```")
        classes = suite.get("classes") or []
        if classes:
            out.append("")
            out.append("### Classes")
            out.append("")
            out.append("```javascript")
            for cls in classes:
                for line in render_class(app_var, cls):
                    out.append(line)
                out.append("")
            out.append("```")
        out.append("")
    out.append("## JXA gotchas (apply to every app)")
    out.append("")
    out.append("- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.")
    out.append("- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.")
    out.append("- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.")
    out.append("- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.")
    out.append("- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.")
    out.append("- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).")
    out.append("")
    return "\n".join(out)


def process(slug: str) -> tuple[str, str]:
    xml = DICTS / slug / f"{slug}.sdef.xml"
    if not xml.exists():
        return slug, f"SKIP: no {xml.relative_to(REPO)}"
    data = parse_sdef(xml)
    if "_error" in data:
        return slug, f"SKIP: parse error — {data['_error']}"
    if not data.get("app"):
        data["app"] = slug.replace("-", " ").title()
    out_path = DICTS / slug / f"{slug}.jxa.md"
    out_path.write_text(render(slug, data))
    return slug, f"wrote {out_path.relative_to(REPO)} ({data['commands_count']} cmds, {data['classes_count']} classes)"


def main():
    args = sys.argv[1:]
    if args and args[0] == "--check":
        missing = []
        present = []
        for d in sorted(DICTS.iterdir()):
            if not d.is_dir():
                continue
            slug = d.name
            if (d / f"{slug}.sdef.xml").exists():
                if (d / f"{slug}.jxa.md").exists():
                    present.append(slug)
                else:
                    missing.append(slug)
        print(f"have jxa.md: {len(present)}")
        print(f"missing:     {len(missing)}")
        for m in missing:
            print(f"  - {m}")
        return
    if args:
        slugs = args
    else:
        slugs = [d.name for d in sorted(DICTS.iterdir()) if d.is_dir() and (d / f"{d.name}.sdef.xml").exists()]
    for slug in slugs:
        s, msg = process(slug)
        print(f"{s}: {msg}")


if __name__ == "__main__":
    main()
