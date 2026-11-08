#!/usr/bin/env python3
"""
Canonical Email Formatter (DRY Principle for Cloudcity & AIMEAT)
Converts Markdown and LaTeX math into rich, universal email HTML with clean typography,
stacked mathematical fractions, Greek/operator Unicode symbols, shaded tables, and blockquotes.
Used by:
- freellmask-mail
- mail-free-energy-analysis
- shared/aimeat_mail.py
- aimeat_director.py
- render_rich_email.py
"""

import base64
from dataclasses import dataclass, field
from typing import Optional
from html.parser import HTMLParser
from urllib.parse import urlsplit
from dataclasses import dataclass, field
from typing import Optional
from html.parser import HTMLParser
from urllib.parse import urlsplit
import html
from pathlib import Path
import re

RENDERER_PATH = Path(__file__).resolve()

# REPORT-CARD >> features/email-math-renderer.feature
class UnsupportedMath(ValueError):
    pass


class LatexHTML:
    """Small, bounded TeX parser. Unknown syntax is retained, never stripped."""
    symbols = dict(zip(
        'alpha beta gamma delta epsilon varepsilon zeta eta theta vartheta iota kappa lambda mu nu xi pi varpi rho varrho sigma varsigma tau upsilon phi varphi chi psi omega Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega'.split(),
        'α β γ δ ε ϵ ζ η θ ϑ ι κ λ μ ν ξ π ϖ ρ ϱ σ ς τ υ φ ϕ χ ψ ω Γ Δ Θ Λ Ξ Π Σ Υ Φ Ψ Ω'.split()))
    symbols.update(dict(zip(
        'cdot times partial nabla approx sim neq ne le leq ge geq implies to rightarrow leftarrow leftrightarrow propto infty pm mp sum prod int oint ell hbar forall exists in notin subset subseteq cup cap land lor ldots cdots dagger ast lVert rVert langle rangle'.split(),
        '· × ∂ ∇ ≈ ∼ ≠ ≠ ≤ ≤ ≥ ≥ ⇒ → → ← ↔ ∝ ∞ ± ∓ ∑ ∏ ∫ ∮ ℓ ℏ ∀ ∃ ∈ ∉ ⊂ ⊆ ∪ ∩ ∧ ∨ … ⋯ † ∗ ‖ ‖ ⟨ ⟩'.split())))

    def __init__(self, text):
        self.text, self.pos = text, 0

    def group(self, depth):
        while self.pos < len(self.text) and self.text[self.pos].isspace():
            self.pos += 1
        if self.pos >= len(self.text):
            raise UnsupportedMath('Missing argument')
        if self.text[self.pos] == '{':
            self.pos += 1
            result = self.parse(depth+1, True)
            return result
        return self.atom(depth+1)

    def atom(self, depth):
        if depth > 100:
            raise UnsupportedMath('Nesting limit')
        c = self.text[self.pos]
        self.pos += 1
        if c == '{':
            return self.parse(depth+1, True)
        if c in '_^':
            content = self.group(depth+1)
            tag = 'sub' if c == '_' else 'sup'
            return f'<{tag}>{content}</{tag}>'
        if c != '\\':
            if c == '}':
                raise UnsupportedMath('Unbalanced group')
            return html.escape(c)
        if self.pos >= len(self.text):
            raise UnsupportedMath('Trailing slash')
        begin = self.pos
        while self.pos < len(self.text) and self.text[self.pos].isalpha():
            self.pos += 1
        command = self.text[begin:self.pos]
        if not command:
            command = self.text[self.pos]
            self.pos += 1
            if command in '{ }_%&#$':
                return html.escape(command)
            if command in ',;:!':
                return '&#8201;' if command != '!' else ''
            raise UnsupportedMath('Unknown escaped symbol')
        if command in self.symbols:
            return self.symbols[command]
        if command in {'left', 'right'}:
            return ''
        if command in {'quad', 'qquad'}:
            return '&emsp;' * (2 if command == 'qquad' else 1)
        if command in {'sin', 'cos', 'tan', 'exp', 'log', 'ln', 'lim', 'max', 'min', 'det', 'Re', 'Im'}:
            return command
        if command in {'text', 'mathrm', 'operatorname', 'mathbf', 'boldsymbol', 'mathit'}:
            argument = self.group(depth+1)
            tag = 'b' if command in {'mathbf', 'boldsymbol'} else 'i' if command == 'mathit' else 'span'
            return f'<{tag}>{argument}</{tag}>'
        if command in {'frac', 'dfrac', 'tfrac'}:
            numerator, denominator = self.group(depth+1), self.group(depth+1)
            return ('<span style="display:inline-block;vertical-align:middle;text-align:center;padding:0 3px">'
                    f'<span style="display:block;border-bottom:1px solid currentColor">{numerator}</span>'
                    f'<span style="display:block">{denominator}</span></span>')
        if command == 'sqrt':
            if self.pos < len(self.text) and self.text[self.pos] == '[':
                raise UnsupportedMath('Root index retained in source')
            return '√<span style="border-top:1px solid currentColor">'+self.group(depth+1)+'</span>'
        if command in {'overline', 'bar', 'underline'}:
            decoration = 'underline' if command == 'underline' else 'overline'
            return f'<span style="text-decoration:{decoration}">{self.group(depth+1)}</span>'
        # KRON-MATH-ACCENTS v1: native email text, including K with a tilde.
        if command in {'tilde', 'widetilde', 'hat', 'widehat', 'dot', 'ddot'}:
            accent = {'tilde': '&#771;', 'widetilde': '&#771;', 'hat': '&#770;',
                      'widehat': '&#770;', 'dot': '&#775;', 'ddot': '&#776;'}[command]
            return self.group(depth+1) + accent
        if command == 'vec':
            return ('<span style="display:inline-block;text-align:center">'
                    '<span style="display:block;font-size:70%;line-height:0.6">→</span>'
                    + self.group(depth+1)+'</span>')
        raise UnsupportedMath('Unsupported command: '+command)

    def parse(self, depth=0, grouped=False):
        out = []
        while self.pos < len(self.text):
            if self.text[self.pos] == '}':
                if not grouped:
                    raise UnsupportedMath('Unbalanced closing group')
                self.pos += 1
                return ''.join(out)
            out.append(self.atom(depth))
        if grouped:
            raise UnsupportedMath('Unclosed group')
        return ''.join(out)


def math_spans(text):
    """Scan delimiters outside code; find/linear scanning avoids regex backtracking."""
    spans, i, fence = [], 0, None
    while i < len(text):
        if i == 0 or text[i-1] == '\n':
            end = text.find('\n', i)
            end = len(text) if end < 0 else end
            line = text[i:end].lstrip()
            marker = line[:3]
            if marker in {'```', '~~~'}:
                fence = None if fence == marker else marker if fence is None else fence
                i = end+1
                continue
            if fence:
                i = end+1
                continue
        if fence:
            i += 1
            continue
        if text[i] == '`':
            end = i+1
            while end < len(text) and text[end] == '`':
                end += 1
            close = text.find(text[i:end], end)
            i = len(text) if close < 0 else close+(end-i)
            continue
        if text.startswith('\\$', i) or text.startswith('\\\\', i):
            i += 2
            continue
        opener = next((token for token in ('\\[', '\\(', '$$', '$') if text.startswith(token, i)), None)
        if not opener:
            i += 1
            continue
        closer = {'\\[': '\\]', '\\(': '\\)', '$$': '$$', '$': '$'}[opener]
        start = i+len(opener)
        if opener == '$' and start == len(text):
            i += 1
            continue
        end = text.find(closer, start)
        while end >= 0 and end > 0 and text[end-1] == '\\':
            end = text.find(closer, end+len(closer))
        if end < 0:
            i += len(opener)
            continue
        # SPACED-INLINE-MATH v1: model output commonly uses $ \varphi $ and $ K $.
        formula = text[start:end].strip()
        currency_pair = (opener == '$' and end+1 < len(text) and text[end+1].isdigit())
        prose_pair = (opener == '$' and not any(c in formula for c in '_^=+*/<>') and not re.search(r'\\[A-Za-z]+', formula)
                      and any(len(word) > 1 for word in re.findall(r'[A-Za-z]+', formula)))
        if opener == '$' and ('\n' in text[start:end] or not formula or currency_pair or prose_pair or '`' in formula):
            i += 1
            continue
        spans.append((i, end+len(closer), formula, opener in {'\\[', '$$'}))
        i = end+len(closer)
    return spans


def render_math(source, display=False):
    try:
        content = LatexHTML(source).parse()
        fallback = False
    except (UnsupportedMath, RecursionError):
        content = '<code>'+html.escape(source)+'</code>'
        fallback = True
    style = "font-family:'Cambria Math','Times New Roman',serif;font-size:17px;color:#f0f6fc;"
    if display:
        style += 'display:block;overflow-x:auto;white-space:normal;padding:12px;margin:12px 0;background:#0d1117;border:1px solid #30363d;border-left:4px solid #388bfd;border-radius:6px;'
    label = ''  # Preserve unknown notation without injecting diagnostics into prose.
    return f'<span class="aimeat-math" style="{style}" aria-label="{html.escape(source, quote=True)}">{label}{content}</span>'


def protect_math(text):
    import hashlib
    prefix = 'AIMEATMATH'+hashlib.sha256(text.encode()).hexdigest()[:16]+'TOKEN'
    while prefix in text:
        prefix += 'X'
    chunks, replacements, cursor = [], [], 0
    for index, (start, end, formula, display) in enumerate(math_spans(text)):
        token = prefix+str(index)+'END'
        chunks.extend([text[cursor:start], token])
        replacements.append((token, render_math(formula, display)))
        cursor = end
    chunks.append(text[cursor:])
    return ''.join(chunks), replacements


def clean_latex(source, display=False):
    """Compatibility name; all math uses the same non-destructive parser."""
    return render_math(source, display)

def inline_format(t):
    t = html.escape(t)
    # Bold & Italic
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong style="color:#ffffff;">\1</strong>', t)
    t = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', r'<em>\1</em>', t)
    # Inline code
    t = re.sub(r'`([^`]+)`', r'<code style="background:#21262d; color:#f0f6fc; padding:2px 5px; border-radius:4px; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:13px; border:1px solid #30363d;">\1</code>', t)
    # Links
    def link(match):
        label, url = match.groups()
        decoded = html.unescape(url)
        if urlsplit(decoded).scheme.lower() not in {"https", "http", "mailto"}:
            return label + " (" + url + ")"
        return '<a href="' + url + '" style="color:#58a6ff; text-decoration:none;">' + label + '</a>'
    t = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', link, t)
    return t

def md_to_html(md_text, title=""):
    """Canonical Markdown→HTML body: headings, tables, blockquotes, lists, and LaTeX math."""
    md_text, math_replacements = protect_math(md_text or "")
    out = []
    para = []
    in_ul = False
    in_ol = False
    in_code = False
    code_block = []
    in_quote = False
    quote_block = []

    def close_para():
        nonlocal para
        if para:
            out.append(f'<p style="margin: 10px 0; line-height: 1.6; color: #c9d1d9;">{"<br>".join(inline_format(x) for x in para)}</p>')
            para = []

    def close_lists():
        nonlocal in_ul, in_ol
        if in_ul:
            out.append('</ul>')
            in_ul = False
        if in_ol:
            out.append('</ol>')
            in_ol = False

    def close_quote():
        nonlocal in_quote, quote_block
        if in_quote:
            content = "<br>".join(inline_format(x) for x in quote_block)
            out.append(f'<blockquote style="border-left: 4px solid #388bfd; background: #162235; padding: 12px 16px; margin: 14px 0; border-radius: 0 6px 6px 0; color: #a5d6ff; font-size: 14px; line-height: 1.5;">{content}</blockquote>')
            in_quote = False
            quote_block = []

    def cells(row):
        return [c.strip() for c in row.strip().strip("|").split("|")]

    lines = (md_text or "").strip().splitlines()
    i = 0
    while i < len(lines):
        line = lines[i]
        s = line.strip()

        # Code fences
        if s.startswith("```"):
            close_para(); close_lists(); close_quote()
            if not in_code:
                in_code = True; code_block = []
            else:
                code_text = html.escape("\n".join(code_block))
                out.append(f'<pre style="background: #0d1117; color: #f0f6fc; padding: 14px; border-radius: 6px; font-family: ui-monospace, Menlo, Consolas, monospace; font-size: 13px; overflow-x: auto; line-height: 1.45; border: 1px solid #30363d;"><code>{code_text}</code></pre>')
                in_code = False; code_block = []
            i += 1
            continue

        if in_code:
            code_block.append(line)
            i += 1
            continue

        # Blockquotes
        if s.startswith(">"):
            close_para(); close_lists()
            in_quote = True
            quote_block.append(s.lstrip("> ").strip())
            i += 1
            continue
        elif in_quote and not s:
            close_quote()

        # Display math block standalone ($$...$$)
        if s.startswith("$$") and s.endswith("$$") and len(s) > 4:
            close_para(); close_lists(); close_quote()
            eq_inner = s[2:-2].strip()
            formatted_eq = clean_latex(eq_inner, display=True)
            out.append(f'<div style="background:#0d1117; border:1px solid #30363d; border-left:4px solid #388bfd; padding:12px 18px; margin:16px 0; border-radius:6px; font-family:\'Cambria Math\',\'Times New Roman\',Georgia,serif; font-size:17px; text-align:center; color:#f0f6fc; overflow-x:auto;">{formatted_eq}</div>')
            i += 1
            continue

        # Tables
        if s.startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|?[\s:|-]+\|?\s*$", lines[i + 1]) and "-" in lines[i + 1]:
            close_para(); close_lists(); close_quote()
            head = cells(line)
            out.append('<table style="border-collapse:collapse; width:100%; margin:16px 0; font-size:14px; background:#161b22; border:1px solid #30363d; box-shadow:0 1px 3px rgba(0,0,0,0.3); border-radius:6px; overflow:hidden;">')
            out.append('<thead><tr>')
            for cell in head:
                out.append(f'<th style="background:#21262d; border:1px solid #30363d; padding:8px 12px; font-weight:600; color:#f0f6fc; text-align:left;">{inline_format(cell)}</th>')
            out.append('</tr></thead><tbody>')
            i += 2
            row_idx = 0
            while i < len(lines) and lines[i].strip().startswith("|"):
                row = cells(lines[i])
                width = max(len(head), len(row))
                row += [""] * (width - len(row))
                bg_col = "#161b22" if row_idx % 2 == 0 else "#0d1117"
                out.append(f'<tr style="background:{bg_col};">')
                for cell in row[:width]:
                    out.append(f'<td style="border:1px solid #30363d; padding:8px 12px; vertical-align:top; color:#c9d1d9;">{inline_format(cell)}</td>')
                out.append('</tr>')
                i += 1
                row_idx += 1
            out.append('</tbody></table>')
            continue

        # Headers
        h = re.match(r"^\s*(#{1,6})\s+(.+?)\s*$", line)
        if h:
            close_para(); close_lists(); close_quote()
            lvl = len(h.group(1))
            txt = inline_format(h.group(2))
            if lvl == 1:
                out.append(f'<h1 style="color:#f0f6fc; border-bottom:2px solid #30363d; padding-bottom:8px; margin-top:24px; font-size:22px; font-weight:700;">{txt}</h1>')
            elif lvl == 2:
                out.append(f'<h2 style="color:#f0f6fc; border-bottom:1px solid #30363d; padding-bottom:6px; margin-top:20px; font-size:18px; font-weight:600;">{txt}</h2>')
            elif lvl == 3:
                out.append(f'<h3 style="color:#e6edf3; margin-top:16px; font-size:16px; font-weight:600;">{txt}</h3>')
            else:
                out.append(f'<h4 style="color:#8b949e; margin-top:14px; font-size:14px; font-weight:600;">{txt}</h4>')
            i += 1
            continue

        # Horizontal Rule
        if re.match(r"^\s*---+\s*$", s):
            close_para(); close_lists(); close_quote()
            out.append('<hr style="border:0; border-top:1px solid #30363d; margin:20px 0;">')
            i += 1
            continue

        # Lists
        ul = re.match(r"^\s*[-*]\s+(.+?)\s*$", line)
        ol = re.match(r"^\s*(\d+)\.\s+(.+?)\s*$", line)
        if ul:
            close_para(); close_quote()
            if in_ol:
                out.append('</ol>'); in_ol = False
            if not in_ul:
                out.append('<ul style="margin:10px 0; padding-left:24px; color:#c9d1d9; line-height:1.6;">')
                in_ul = True
            out.append(f'<li style="margin-bottom:6px;">{inline_format(ul.group(1))}</li>')
            i += 1
            continue
        elif ol:
            close_para(); close_quote()
            if in_ul:
                out.append('</ul>'); in_ul = False
            if not in_ol:
                out.append(f'<ol start="{int(ol.group(1))}" style="margin:10px 0; padding-left:24px; color:#c9d1d9; line-height:1.6;">')
                in_ol = True
            out.append(f'<li style="margin-bottom:6px;">{inline_format(ol.group(2))}</li>')
            i += 1
            continue

        if not s:
            close_para(); close_lists(); close_quote()
        else:
            close_lists()
            para.append(line)
        i += 1

    if in_code:
        out.append('<pre><code>'+html.escape("\n".join(code_block))+'</code></pre>')
    if in_code:
        out.append('<pre><code>'+html.escape("\n".join(code_block))+'</code></pre>')
    close_para(); close_lists(); close_quote()
    body_html = "\n".join(out)
    for token, markup in math_replacements:
        body_html = body_html.replace(token, markup)
    return body_html

def render_provenance_badge(prov):
    if not prov:
        return ""
    if isinstance(prov, str):
        prov = html.escape(prov)
        return f'<div style="background:#0d1117; border:1px solid #30363d; border-radius:6px; padding:10px 14px; margin:0 0 20px 0; font-size:12px; line-height:1.6; color:#8b949e;">{prov}</div>'
    if not isinstance(prov, dict):
        return ""

    lines = []
    trigger = prov.get("trigger") or prov.get("origin")
    if trigger:
        lines.append(f'<div><strong style="color:#c9d1d9;">Trigger / Origin:</strong> {html.escape(str(trigger))}</div>')

    mid = prov.get("message_id")
    if mid:
        lines.append(f'<div><strong style="color:#c9d1d9;">Message-ID:</strong> <code style="background:#21262d; color:#f0f6fc; padding:1px 5px; border-radius:3px; font-size:11px;">{html.escape(str(mid))}</code></div>')

    space = prov.get("space")
    why = prov.get("why") or prov.get("route_reason")
    model = prov.get("model") or prov.get("engine")
    space_part = f'<strong style="color:#c9d1d9;">Space:</strong> <code style="background:#21262d; color:#58a6ff; padding:1px 5px; border-radius:3px; font-size:11px;">{html.escape(str(space))}</code>' if space else ""
    if why:
        space_part += f' <em>({html.escape(str(why))})</em>'
    engine_part = f'<strong style="color:#c9d1d9;">Engine:</strong> {html.escape(str(model))}' if model else ""
    row = " · ".join(p for p in (space_part, engine_part) if p)
    if row:
        lines.append(f'<div>{row}</div>')

    sources = prov.get("sources")
    if sources:
        if isinstance(sources, list):
            src_str = ", ".join(str(s) for s in sources[:6])
            if len(sources) > 6:
                src_str += f" (+{len(sources)-6} more)"
        else:
            src_str = str(sources)
        lines.append(f'<div><strong style="color:#c9d1d9;">Context Sources:</strong> {html.escape(src_str)}</div>')

    host = prov.get("host")
    ts = prov.get("timestamp")
    footer_bits = []
    if host:
        footer_bits.append(f"Host: {html.escape(str(host))}")
    if ts:
        footer_bits.append(f"Dispatched: {html.escape(str(ts))}")
    if footer_bits:
        lines.append('<div style="margin-top:4px; font-size:11px; color:#6e7681;">' + " · ".join(footer_bits) + '</div>')

    content = "\n    ".join(lines)
    return f"""<div style="background:#0d1117; border:1px solid #30363d; border-radius:6px; padding:10px 14px; margin:0 0 20px 0; font-size:12px; line-height:1.6; color:#8b949e;">
    <div style="font-weight:600; color:#58a6ff; font-size:11px; text-transform:uppercase; letter-spacing:0.5px; margin-bottom:4px;">Provenance & Origin</div>
    {content}
  </div>"""

def mail_id(markdown):
    """Stable, quotable id for one outgoing mail: the same body always yields the same id, so
    "CC-1a2b3c4d worked" can be matched back to the exact text via the mail-id ledger."""
    import hashlib
    return "CC-" + hashlib.sha256((markdown or "").encode("utf-8", "ignore")).hexdigest()[:8]


def record_mail_id(mid_, title="", markdown=""):
    """Best-effort append to comms/queue/mail-ids.jsonl (Syncthing-synced); never raises."""
    try:
        import json, time
        from pathlib import Path
        led = Path.home()/"work"/"comms"/"queue"/"mail-ids.jsonl"
        with led.open("a") as f:
            f.write(json.dumps({"mail_id": mid_, "title": (title or "")[:160],
                                "chars": len(markdown or ""), "head": (markdown or "")[:200],
                                "ts": time.strftime("%Y-%m-%dT%H:%M:%S")}) + "\n")
    except Exception:
        pass


def wrap_email_html(inner_html, title="AIMEAT Research Ingest", provenance=None, mail_id_=""):
    prov_badge = render_provenance_badge(provenance)
    id_html = (" · Mail ID: <strong style=\"color:#c9d1d9;\">" + html.escape(mail_id_) + "</strong>") if mail_id_ else ""
    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<meta name="color-scheme" content="dark">
<meta name="supported-color-schemes" content="dark">
<title>{html.escape(title)}</title>
<style>
  :root {{ color-scheme: dark; supported-color-schemes: dark; }}
  body {{ background-color: #0d1117 !important; color: #c9d1d9 !important; }}
  a {{ color: #58a6ff !important; }}
  h1, h2, h3, h4 {{ color: #f0f6fc !important; }}
  blockquote {{ background: #162235 !important; color: #a5d6ff !important; border-left-color: #388bfd !important; }}
  code {{ background: #21262d !important; color: #f0f6fc !important; }}
  pre {{ background: #0d1117 !important; color: #f0f6fc !important; border-color: #30363d !important; }}
  table {{ background: #161b22 !important; border-color: #30363d !important; }}
  th {{ background: #21262d !important; border-color: #30363d !important; color: #f0f6fc !important; }}
  td {{ border-color: #30363d !important; color: #c9d1d9 !important; }}
  hr {{ border-top-color: #30363d !important; }}
</style>
</head>
<body style="margin:0; padding:16px; background-color:#0d1117; color:#c9d1d9; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <div style="max-width:760px; margin:0 auto; background:#161b22; border:1px solid #30363d; border-radius:8px; padding:24px 32px; box-shadow:0 4px 16px rgba(0,0,0,0.4); color:#c9d1d9;">
    <div style="font-size:12px; color:#8b949e; margin-bottom:12px; border-bottom:1px solid #21262d; padding-bottom:8px;">
      AIMEAT Research Ingest · Fleet Multi-Brain Synthesis
    </div>
    {prov_badge}
    <main id="mail-content">{inner_html}</main>
    <div style="margin-top:32px; padding-top:12px; border-top:1px solid #21262d; font-size:11px; color:#8b949e; text-align:center;">
      AIMEAT · Cloudcity · Original Markdown and equations retained{id_html}
    </div>
  </div>
</body>
</html>"""


def source_attachments(markdown, filename="analysis"):
    """Lossless originals accompany rendered mail, including unsupported TeX."""
    import base64
    from pathlib import Path
    stem = Path(filename).stem or "analysis"
    def attachment(name, text, content_type):
        return dict(filename=name, content_type=content_type,
                    content=base64.b64encode(text.encode()).decode())
    result = [attachment(stem+".md", markdown, "text/markdown; charset=utf-8")]
    spans = math_spans(markdown)
    if spans:
        tex = "% Original math expressions, in source order. No normalization.\n\n"
        tex += "\n\n".join(markdown[start:end] for start,end,_,_ in spans)+"\n"
        result.append(attachment(stem+".tex", tex, "application/x-tex; charset=utf-8"))
    return result


def email_payload(markdown, title="AIMEAT Research Ingest", filename="analysis", provenance=None):
    mid_ = mail_id(markdown); record_mail_id(mid_, title, markdown)
    return dict(text=markdown + "\n\n— Mail ID: " + mid_, html=render_email(markdown, title=title, provenance=provenance),
                attachments=source_attachments(markdown, filename))


def render_email(markdown, title="AIMEAT Research Ingest", provenance=None):
    """Full HTML document; the body, mathematics and wrapper all live here."""
    return wrap_email_html(md_to_html(markdown), title=title, provenance=provenance, mail_id_=mail_id(markdown))


# REPORT-CARD >> ~/work/convey/features/mail-consolidation.feature
@dataclass
class MailContent:
    """All semantic material is assembled before document finalization."""
    markdown: str = ""
    notices: list[str] = field(default_factory=list)
    attachments: list[dict] = field(default_factory=list)
    provenance: Optional[dict] = None
    title: str = "AIMEAT Research Ingest"
    text_prefix: str = ""

    def text(self):
        return "\n\n".join([self.markdown] + [str(n) for n in self.notices if n])

    def payload(self):
        text = self.text()
        mid_ = mail_id(text); record_mail_id(mid_, self.title, text)
        return {"text": self.text_prefix + text + "\n\n— Mail ID: " + mid_, "html": render_email(text, title=self.title, provenance=self.provenance),
                **({"attachments": list(self.attachments)} if self.attachments else {})}


class _PrintSemantics(HTMLParser):
    """Share the Markdown parser; discard email presentation at the semantic boundary."""
    def __init__(self):
        super().__init__(convert_charrefs=False)
        self.parts = []
    def handle_starttag(self, tag, attrs):
        # Math layout properties are semantic; email colors/backgrounds never cross.
        keep = []
        for key, value in attrs:
            if key in {"href", "src", "alt", "start", "colspan", "rowspan"}:
                keep.append((key, value))
            elif key == "style" and tag == "span":
                style = ";".join(rule for rule in value.split(";")
                                 if rule.strip().split(":")[0] in
                                 {"display", "vertical-align", "text-align", "border-bottom", "border-top", "padding"})
                if style: keep.append((key, style))
        self.parts.append("<"+tag+"".join(' '+k+'="'+html.escape(v, quote=True)+'"' for k,v in keep)+">")
    def handle_endtag(self, tag): self.parts.append("</"+tag+">")
    def handle_data(self, data): self.parts.append(data)
    def handle_entityref(self, name): self.parts.append("&"+name+";")
    def handle_charref(self, name): self.parts.append("&#"+name+";")


def render_print(markdown, css=""):
    parser = _PrintSemantics()
    parser.feed(md_to_html(markdown))
    return ('<!DOCTYPE html><html><head><meta charset="utf-8"><style>'
            'body{background:white;color:#111;font:12pt sans-serif;margin:24pt}'
            'pre{white-space:pre-wrap;background:#eee;color:#111;padding:10pt}'
            'table{border-collapse:collapse;width:100%}td,th{border:1px solid #888;padding:5pt}'
            'a{color:#0645ad}h1,h2,h3{break-after:avoid}pre,tr{break-inside:avoid}'
            '@page{margin:18mm}'+css+'</style></head><body>'+''.join(parser.parts)+'</body></html>')
