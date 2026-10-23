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
        if opener == '$' and (start == len(text) or text[start].isspace()):
            i += 1
            continue
        end = text.find(closer, start)
        while end >= 0 and end > 0 and text[end-1] == '\\':
            end = text.find(closer, end+len(closer))
        if end < 0:
            i += len(opener)
            continue
        if opener == '$' and ('\n' in text[start:end] or not text[start:end] or text[end-1].isspace()):
            i += 1
            continue
        spans.append((i, end+len(closer), text[start:end], opener in {'\\[', '$$'}))
        i = end+len(closer)
    return spans


def render_math(source, display=False):
    try:
        content = LatexHTML(source).parse()
        fallback = False
    except (UnsupportedMath, RecursionError):
        content = '<code>'+html.escape(source)+'</code>'
        fallback = True
    style = "font-family:'Cambria Math','Times New Roman',serif;font-size:17px;"
    if display:
        style += 'display:block;overflow-x:auto;white-space:normal;padding:12px;margin:12px 0;background:#f8fafc;border-left:3px solid #2563eb;'
    label = 'Unrendered LaTeX preserved: ' if fallback else ''
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
    t = re.sub(r'\*\*([^*]+)\*\*', r'<strong style="color:#0f172a;">\1</strong>', t)
    t = re.sub(r'(?<!\*)\*([^*\n]+)\*(?!\*)', r'<em>\1</em>', t)
    # Inline code
    t = re.sub(r'`([^`]+)`', r'<code style="background:#f1f5f9; color:#0f172a; padding:2px 5px; border-radius:4px; font-family:ui-monospace,Menlo,Consolas,monospace; font-size:13px;">\1</code>', t)
    # Links
    t = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2" style="color:#2563eb; text-decoration:none;">\1</a>', t)
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
            out.append(f'<p style="margin: 10px 0; line-height: 1.6; color: #334155;">{"<br>".join(inline_format(x) for x in para)}</p>')
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
            out.append(f'<blockquote style="border-left: 4px solid #3b82f6; background: #eff6ff; padding: 12px 16px; margin: 14px 0; border-radius: 0 6px 6px 0; color: #1e40af; font-size: 14px; line-height: 1.5;">{content}</blockquote>')
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
                out.append(f'<pre style="background: #0f172a; color: #f8fafc; padding: 14px; border-radius: 6px; font-family: ui-monospace, Menlo, Consolas, monospace; font-size: 13px; overflow-x: auto; line-height: 1.45;"><code>{code_text}</code></pre>')
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
            out.append(f'<div style="background:#f8fafc; border:1px solid #cbd5e1; border-left:4px solid #2563eb; padding:12px 18px; margin:16px 0; border-radius:6px; font-family:\'Cambria Math\',\'Times New Roman\',Georgia,serif; font-size:17px; text-align:center; color:#0f172a; overflow-x:auto;">{formatted_eq}</div>')
            i += 1
            continue

        # Tables
        if s.startswith("|") and i + 1 < len(lines) and re.match(r"^\s*\|?[\s:|-]+\|?\s*$", lines[i + 1]) and "-" in lines[i + 1]:
            close_para(); close_lists(); close_quote()
            head = cells(line)
            out.append('<table style="border-collapse:collapse; width:100%; margin:16px 0; font-size:14px; background:#ffffff; box-shadow:0 1px 3px rgba(0,0,0,0.05); border-radius:6px; overflow:hidden;">')
            out.append('<thead><tr>')
            for cell in head:
                out.append(f'<th style="background:#f1f5f9; border:1px solid #cbd5e1; padding:8px 12px; font-weight:600; color:#0f172a; text-align:left;">{inline_format(cell)}</th>')
            out.append('</tr></thead><tbody>')
            i += 2
            row_idx = 0
            while i < len(lines) and lines[i].strip().startswith("|"):
                row = cells(lines[i])
                width = max(len(head), len(row))
                row += [""] * (width - len(row))
                bg_col = "#ffffff" if row_idx % 2 == 0 else "#f8fafc"
                out.append(f'<tr style="background:{bg_col};">')
                for cell in row[:width]:
                    out.append(f'<td style="border:1px solid #cbd5e1; padding:8px 12px; vertical-align:top; color:#334155;">{inline_format(cell)}</td>')
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
                out.append(f'<h1 style="color:#0f172a; border-bottom:2px solid #e2e8f0; padding-bottom:8px; margin-top:24px; font-size:22px; font-weight:700;">{txt}</h1>')
            elif lvl == 2:
                out.append(f'<h2 style="color:#1e293b; border-bottom:1px solid #e2e8f0; padding-bottom:6px; margin-top:20px; font-size:18px; font-weight:600;">{txt}</h2>')
            elif lvl == 3:
                out.append(f'<h3 style="color:#334155; margin-top:16px; font-size:16px; font-weight:600;">{txt}</h3>')
            else:
                out.append(f'<h4 style="color:#475569; margin-top:14px; font-size:14px; font-weight:600;">{txt}</h4>')
            i += 1
            continue

        # Horizontal Rule
        if re.match(r"^\s*---+\s*$", s):
            close_para(); close_lists(); close_quote()
            out.append('<hr style="border:0; border-top:1px solid #e2e8f0; margin:20px 0;">')
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
                out.append('<ul style="margin:10px 0; padding-left:24px; color:#334155; line-height:1.6;">')
                in_ul = True
            out.append(f'<li style="margin-bottom:6px;">{inline_format(ul.group(1))}</li>')
            i += 1
            continue
        elif ol:
            close_para(); close_quote()
            if in_ul:
                out.append('</ul>'); in_ul = False
            if not in_ol:
                out.append(f'<ol start="{int(ol.group(1))}" style="margin:10px 0; padding-left:24px; color:#334155; line-height:1.6;">')
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

    close_para(); close_lists(); close_quote()
    body_html = "\n".join(out)
    for token, markup in math_replacements:
        body_html = body_html.replace(token, markup)
    return body_html

def wrap_email_html(inner_html, title="AIMEAT Research Ingest"):
    return f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>{html.escape(title)}</title>
</head>
<body style="margin:0; padding:16px; background-color:#f8fafc; font-family:-apple-system,BlinkMacSystemFont,'Segoe UI',Roboto,Helvetica,Arial,sans-serif;">
  <div style="max-width:760px; margin:0 auto; background:#ffffff; border:1px solid #e2e8f0; border-radius:8px; padding:24px 32px; box-shadow:0 2px 4px rgba(0,0,0,0.04);">
    <div style="font-size:12px; color:#64748b; margin-bottom:12px; border-bottom:1px solid #f1f5f9; padding-bottom:8px;">
      AIMEAT Research Ingest · Fleet Multi-Brain Synthesis
    </div>
    {inner_html}
    <div style="margin-top:32px; padding-top:12px; border-top:1px solid #f1f5f9; font-size:11px; color:#94a3b8; text-align:center;">
      AIMEAT · Cloudcity · Original Markdown and equations retained
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


def email_payload(markdown, title="AIMEAT Research Ingest", filename="analysis"):
    return dict(text=markdown, html=render_email(markdown, title=title),
                attachments=source_attachments(markdown, filename))


def render_email(markdown, title="AIMEAT Research Ingest"):
    """Full HTML document; the body, mathematics and wrapper all live here."""
    return wrap_email_html(md_to_html(markdown), title=title)
