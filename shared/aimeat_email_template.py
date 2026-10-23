"""Canonical Free Energy dossier content builder and source cleanup.

Rich text/Markdown/math rendering remains exclusively in ``format_email.py``.
"""
from __future__ import annotations
import re

ROLES = (
    ("Aria", "The Synthesizer", ("aria",)),
    ("Rigel", "The Electrical Engineer", ("rigel",)),
    ("Ilya Prigogine", "The Thermodynamicist", ("ilya prigogine", "ilya")),
    ("Lyra", "The Pragmatist", ("lyra",)),
    ("Tom Bearden", "The Scalar Electrodynamicist", ("tom bearden", "tom")),
    ("Vega", "The Experimental Auditor", ("vega",)),
    ("Walter Russell", "The Cosmic Ontologist", ("walter russell", "walter")),
    ("Orion", "The Resonance & Memory Field Theorist", ("orion",)),
    ("Hilarion", "The Aether & Longitudinal Wave Channel", ("hilarion",)),
)

# Text that belongs to the scanned-file masthead, never to an analysis email.
_BOILERPLATE = (
    "word processor parameters", "taken from keelynet bbs", "sponsored by vangard sciences",
    "po box 1031", "mesquite, tx 75150", "there are absolutely no restrictions",
    "on duplicating, publishing or distributing the", "files on keelynet",
    "we can be of service", "contact jerry at", "or ron at",
    "214) 324-8741", "214) 242-9346", "214-324-8741", "214-242-9346",
    "tom operates the thc online system", "604-361-4549",
)

def clean_source(text: str, *, strip_frontmatter: bool = True,
                 strip_duplicate_title: bool = True) -> str:
    """Remove YAML metadata, duplicate title and the KeelyNet distribution masthead."""
    text = text.lstrip("\ufeff")
    if strip_frontmatter and text.startswith("---\n"):
        close = text.find("\n---", 4)
        if close >= 0:
            text = text[close + 4:]
    lines = text.splitlines()
    # Strip only the leading masthead; keep all primary-source body content.
    cleaned=[]; masthead=True; masthead_notice=False; contact_continuation=False; drop_separator=False
    def is_rule(value):
        return bool(value.strip()) and set(value.strip()) <= {"-", "=", "_"}
    def adjacent_to_banner(index):
        for step in (-1, 1):
            neighbor = index + step
            while 0 <= neighbor < len(lines) and not lines[neighbor].strip():
                neighbor += step
            if 0 <= neighbor < len(lines):
                candidate = lines[neighbor].casefold()
                if any(marker in candidate for marker in _BOILERPLATE) or re.search(r"\b\d{3}[\s.-]*\d{4}\b", candidate):
                    return True
        return False
    for index, line in enumerate(lines):
        low=line.casefold().strip()
        if is_rule(low) and (masthead or adjacent_to_banner(index)):
            continue
        if contact_continuation:
            if re.search(r"\b\d{3}[\s.-]*\d{4}\b", low):
                drop_separator=True
                contact_continuation=False
                continue
            if not low:
                contact_continuation=False
            else:
                continue
        if drop_separator and low and set(low) <= {"-", "=", "_"}:
            drop_separator=False
            continue
        drop_separator=False
        if masthead:
            if strip_duplicate_title and low.startswith("# "):
                continue
            if any(x in low for x in _BOILERPLATE):
                drop_separator = True
                if "we can be of service" in low or "contact jerry at" in low:
                    contact_continuation=True
                if "there are absolutely no restrictions" in low:
                    masthead_notice=True
                if masthead_notice and "files on keelynet" in low:
                    masthead_notice=False
                continue
            if masthead_notice:
                if "files on keelynet" in low:
                    masthead_notice=False
                continue
            if low.startswith("march ") or low.startswith("date:"):
                masthead=False
                cleaned.append(line)
                continue
            if not low or low.startswith("zpe") or set(low) <= {"-"}:
                continue
            if low.isupper() and len(low)>12:
                masthead=False
                cleaned.append(line)
                continue
            # A markdown title may be followed by an unmarked article immediately.
            masthead=False
        if any(x in low for x in _BOILERPLATE):
            drop_separator = True
            if "we can be of service" in low or "contact jerry at" in low:
                contact_continuation=True
            continue
        cleaned.append(line)
    return "\n".join(cleaned).strip()+"\n"

def source_metadata(text: str) -> dict[str, object]:
    """Read the small KeelyNet YAML header without bringing a second YAML stack."""
    text=text.lstrip("\ufeff")
    if not text.startswith("---\n"):
        return {}
    close=text.find("\n---",4)
    if close < 0:
        return {}
    metadata={}; section=None
    for line in text[4:close].splitlines():
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line.startswith("  - ") and section:
            metadata.setdefault(section,[]).append(line[4:].strip().strip("\"'"))
            continue
        if line[:1].isspace():
            continue
        key,sep,value=line.partition(":")
        if not sep:
            continue
        value=value.strip().strip("\"'")
        if value:
            metadata[key.strip()]=value
            section=None
        else:
            metadata[key.strip()]=[]
            section=key.strip()
    return metadata

def titled_roundtable(text: str) -> str:
    """Normalize speaker headers to the Phase Conjugation panel's canonical role labels."""
    out=[]; seen=set()
    for line in text.splitlines():
        if line.startswith("### "):
            raw=line[4:].strip().lstrip("0123456789. ").casefold()
            for name,role,aliases in ROLES:
                if any(raw == alias or raw.startswith(alias+" ") or raw.startswith(alias+" (") for alias in aliases):
                    line=f"### {name} ({role})"; seen.add(name); break
        out.append(line)
    missing=[name for name,_,_ in ROLES if name not in seen]
    if missing:
        raise ValueError("Roundtable missing titled Sages: "+", ".join(missing))
    return "\n".join(out).strip()+"\n"

def build_dossier(*, title, filename, source_name, source_date, source_sha, summary,
                  freellmapi, qwen, flubuild, roundtable, synthesis, source_attachment,
                  freellmapi_model, qwen_model, flubuild_model, aimeat_key,
                  cloud_artifacts=()):
    """Build every Free Energy research message with the Phase Conjugation section map."""
    if any("<div style=" in item for item in (summary,freellmapi,qwen,flubuild,roundtable,synthesis)):
        raise ValueError("Raw HTML is not dossier content")
    roundtable=titled_roundtable(roundtable)
    summary=summary.strip(); freellmapi=freellmapi.strip(); qwen=qwen.strip(); flubuild=flubuild.strip(); synthesis=synthesis.strip()
    if not all((summary,freellmapi,qwen,flubuild,synthesis)):
        raise ValueError("A complete dossier requires its summary, three brains, and synthesis")
    return f"""# Tri-Brain Deep-Read Dossier: {title}

> **Primary Source:** `{source_name}`  
> **Source File:** `{filename}`  
> **Source Date:** {source_date or 'Not stated in source'}  
> **SHA-256:** `{source_sha}`  
> **Fleet Brains Executed:**
> • Cloudcity FreeLLMAPI · `{freellmapi_model}`
> • CloudcityMacMini Qwen MLX · `{qwen_model}`
> • Flubuild 16K · `{flubuild_model}`

---

## 1. Executive Summary & Source Digest

{summary}

---

## 2. Cloudcity FreeLLMAPI Theoretical Analysis

{freellmapi}

---

## 3. CloudcityMacMini Qwen MLX Electrodynamic Evaluation

{qwen}

---

## 4. Flubuild 16K Context Mathematical Physics Audit

{flubuild}

---

## 5. Live Sages Roundtable Dialogue (CloudcityMacMini 9-Seat Panel)

{roundtable}

---

## 6. Tri-Brain Comparative Synthesis Matrix

{synthesis}

---

## 7. Artifact Manifest & AIMEAT Memory Coordinates

- **Source File:** `{source_name}`
- **Dossier:** `{title}`
- **Source Digest:** `{source_sha}`
- **AIMEAT Memory Key:** `{aimeat_key}`
- **Clean source attachment:** `{source_attachment}`
{chr(10).join('- **Artifact:** `'+name+'`' for name in cloud_artifacts)}
"""

def canonicalize_dossier(markdown: str) -> str:
    """Apply the Phase Conjugation email's speaker labels and numbered section map."""
    markdown = titled_roundtable(markdown)
    markdown = markdown.replace("## 6. Artifact Manifest & AIMEAT Memory Coordinates",
                              "## 7. Artifact Manifest & AIMEAT Memory Coordinates")
    return markdown

def validate_dossier(markdown: str) -> None:
    required=("## 2. Cloudcity FreeLLMAPI Theoretical Analysis",
              "## 3. CloudcityMacMini Qwen MLX Electrodynamic Evaluation",
              "## 4. Flubuild 16K Context Mathematical Physics Audit",
              "## 5. Live Sages Roundtable Dialogue", "## 6. Tri-Brain Comparative Synthesis Matrix",
              "## 7. Artifact Manifest & AIMEAT Memory Coordinates")
    missing=[h for h in required if h not in markdown]
    if not any(line.startswith("## 1.") for line in markdown.splitlines()):
        missing.append("## 1. source-specific primary-source context")
    if missing: raise ValueError("Not a complete canonical Free Energy dossier: "+", ".join(missing))
    for name,role,_ in ROLES:
        if f"### {name} ({role})" not in markdown: raise ValueError("Missing canonical titled Sages speaker: "+name)
    low=markdown.casefold()
    if "<div style=" in low: raise ValueError("Raw HTML found in dossier")
    if any(x in low for x in _BOILERPLATE):
        raise ValueError("KeelyNet distribution masthead leaked into dossier")
    if re.search(r"(?m)^.*(?:214|604)[\s).-]*\d{3}[\s.-]*\d{4}.*$", markdown):
        raise ValueError("KeelyNet contact phone leaked into dossier")
