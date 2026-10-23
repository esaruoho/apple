"""Install the sole email renderer and migrate legacy archive imports.

REPORT-CARD >> features/email-math-renderer.feature
No email is sent and no background process is created.
"""
import argparse
import ast
import hashlib
import json
import os
from pathlib import Path
import shutil
import socket
import subprocess
import sys
import time

SHIM = '''"""Compatibility import; all rendering is owned by apple/shared/format_email.py."""
from pathlib import Path
import importlib.util
_path = Path(__file__).resolve().parent.parent / "apple/shared/format_email.py"
_spec = importlib.util.spec_from_file_location("aimeat_canonical_email_renderer", _path)
_renderer = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(_renderer)
md_to_html = _renderer.md_to_html
wrap_email_html = _renderer.wrap_email_html
render_email = _renderer.render_email
email_payload = _renderer.email_payload
source_attachments = _renderer.source_attachments
clean_latex = _renderer.clean_latex
inline_format = _renderer.inline_format
math_spans = _renderer.math_spans
RENDERER_PATH = _renderer.RENDERER_PATH
'''


def remove_nodes(source, predicate):
    lines = source.splitlines(keepends=True)
    for node in reversed(ast.parse(source).body):
        if predicate(node):
            lines[node.lineno-1:node.end_lineno] = []
    return ''.join(lines)


def replace_payload(source, function, replacement):
    node = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == function)
    targets = [n for n in node.body if isinstance(n, ast.Assign)
               and any(isinstance(t, ast.Name) and t.id == 'payload' for t in n.targets)]
    if len(targets) != 1:
        raise ValueError('Expected one mail payload in '+function)
    lines = source.splitlines(keepends=True)
    target = targets[0]
    lines[target.lineno-1:target.end_lineno] = [replacement+'\n']
    return ''.join(lines)


def patch_director(source):
    names = {'parse_balanced_braces','parse_fractions','clean_latex','inline_format','render_markdown_to_html'}
    source = remove_nodes(source, lambda n: (isinstance(n, ast.FunctionDef) and n.name in names)
                          or (isinstance(n, ast.ImportFrom) and n.module == 'format_email'))
    source = 'from format_email import email_payload, render_email as render_markdown_to_html, RENDERER_PATH\n'+source
    source = replace_payload(source, 'send_agentmail',
              '    payload = dict(email_payload(text_body, title=subject, filename="aimeat-analysis"), to=recipients, subject=subject)')
    if 'renderer_mtime = RENDERER_PATH' not in source:
        source = source.replace('    while True:\n        try:\n            files_to_process = scan_supported_files(TARGET_DIR)',
              '    renderer_mtime = RENDERER_PATH.stat().st_mtime_ns\n    while True:\n        try:\n'
              '            if RENDERER_PATH.stat().st_mtime_ns != renderer_mtime:\n'
              '                os.execv(sys.executable, [sys.executable, os.path.abspath(__file__), *sys.argv[1:]])\n'
              '            files_to_process = scan_supported_files(TARGET_DIR)')
    compile(source, 'aimeat_director.py', 'exec')
    return source


def patch_sender(source):
    source = remove_nodes(source, lambda n: isinstance(n, ast.ImportFrom) and n.module == 'format_email')
    source = 'from format_email import email_payload\n'+source
    source = source.replace('    inner_html = md_to_html(md_text, title=title)\n', '')
    source = source.replace('    rich_html = wrap_email_html(inner_html, title=title)\n', '')
    source = replace_payload(source, 'send_rich_email',
             '    payload = dict(email_payload(md_text, title=title, filename=fname), to=recipients, subject=subject)')
    compile(source, 'render_rich_email.py', 'exec')
    return source


def patch_mailer(source):
    source = remove_nodes(source, lambda n: isinstance(n, ast.FunctionDef)
                          and n.name in {'_md_inline','md_to_inner_html','md_to_html'})
    source = remove_nodes(source, lambda n: isinstance(n, ast.ImportFrom) and n.module == 'format_email')
    anchor = 'import aimeat_mail\n'
    source = source.replace(anchor, anchor+'from format_email import md_to_html as md_to_inner_html, render_email as md_to_html, source_attachments\n', 1)
    if "present = {a.get('filename') for a in reply['attachments']}" not in source:
        anchor = '    url=f"{AM_BASE}/inboxes/{INBOX}/messages/{enc(mid)}/reply"'
        source = source.replace(anchor,
            "    reply = dict(reply)\n    reply['attachments'] = list(reply.get('attachments', []))\n"
            "    present = {a.get('filename') for a in reply['attachments']}\n"
            "    reply['attachments'].extend(a for a in source_attachments(reply.get('text', ''), 'analysis') if a['filename'] not in present)\n"+anchor, 1)
    if "source_attachments(text, 'analysis')" not in source:
        anchor = '    try:\n        response = http(f"{AM_BASE}/inboxes/{INBOX}/messages/send", k, "POST", payload)'
        source = source.replace(anchor,
            "    present = {a.get('filename') for a in payload.get('attachments', [])}\n"
            "    payload.setdefault('attachments', []).extend(a for a in source_attachments(text, 'analysis') if a['filename'] not in present)\n"+anchor, 1)
    if "'shared/format_email.py']" not in source:
        source = source.replace("Path(__file__).resolve().parent.parent/'shared/cloud_source.py']",
                    "Path(__file__).resolve().parent.parent/'shared/cloud_source.py',\n                   Path(__file__).resolve().parent.parent/'shared/format_email.py']")
    return '\n'.join(line for line in source.split('\n') if not line.startswith(('_TH=', '_TD=')))


def patch_generic_mail(source):
    source = remove_nodes(source, lambda n: (isinstance(n, ast.FunctionDef) and n.name in {'_inline','md_to_html'})
                          or (isinstance(n, ast.ImportFrom) and n.module == 'format_email')
                          or (isinstance(n, ast.Try) and any(isinstance(x, ast.ImportFrom) and x.module == 'format_email' for x in n.body)))
    source = source.replace('sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "shared"))\n', '')
    anchor = 'from pathlib import Path\n'
    source = source.replace(anchor, anchor+'sys.path.insert(0, str(Path(__file__).resolve().parents[1] / "shared"))\nfrom format_email import md_to_html, source_attachments\n', 1)
    if 'source_attachments(text, "analysis")' not in source:
        source = source.replace('    if attachments:\n        msg["attachments"] = attachments',
            '    msg["attachments"] = list(attachments or [])\n'
            '    present = {a.get("filename") for a in msg["attachments"]}\n'
            '    msg["attachments"].extend(a for a in source_attachments(text, "analysis") if a["filename"] not in present)')
    return source


def patch_aimeat_mail(source):
    source = remove_nodes(source, lambda n: (isinstance(n, ast.FunctionDef) and n.name == 'analysis_html')
                          or (isinstance(n, ast.ImportFrom) and n.module == 'format_email'))
    source = source.replace('import cloud_assets\n', 'import cloud_assets\nfrom format_email import email_payload\n', 1)
    # Only the rendering assignment changes. Delivery checks, retry policy and
    # all concurrent non-renderer edits in the installed module remain intact.
    node = next(n for n in ast.parse(source).body if isinstance(n, ast.FunctionDef) and n.name == 'advance')
    targets = [n for n in ast.walk(node) if isinstance(n, ast.Assign)
               and any(isinstance(t, ast.Name) and t.id == 'payload' for t in n.targets)]
    if len(targets) != 1:
        raise ValueError('Expected one AIMEAT rendered mail payload')
    lines = source.splitlines(keepends=True)
    target = targets[0]
    lines[target.lineno-1:target.end_lineno] = ["        payload = email_payload(body, title=message.get('subject', 'AIMEAT analysis'), filename=state.get('analysis', 'analysis'))\n"]
    source = ''.join(lines)
    if "if any(a.get('filename') == name for a in payload['attachments']):" not in source:
        source = source.replace("        for name in state['files']:\n            if name.endswith",
                   "        for name in state['files']:\n            if any(a.get('filename') == name for a in payload['attachments']):\n                continue\n            if name.endswith")
    return source


CALLERS = {'bin/freellmask-mail':patch_mailer, 'bin/mail-free-energy-analysis':patch_generic_mail,
           'shared/aimeat_mail.py':patch_aimeat_mail}


def patch_archive(root):
    """Run on the archive-owning computer; source files then follow Syncthing."""
    replacements = {'format_email.py': SHIM}
    for name, patch in [('aimeat_director.py', patch_director), ('render_rich_email.py', patch_sender)]:
        path = root/name
        if path.exists():
            replacements[name] = patch(path.read_text())
    backup = root/'.email-renderer-backups'/str(time.time_ns())
    changed = []
    for name, text in replacements.items():
        path = root/name
        if path.exists() and path.read_text() == text:
            continue
        backup.mkdir(parents=True, exist_ok=True)
        if path.exists():
            shutil.copy2(path, backup/name)
        path.write_text(text)
        changed.append(name)
    return changed


def install(payload, work):
    if socket.gethostname().split('.')[0].lower() not in {'cloudcity', 'cloudcitymacmini'}:
        raise RuntimeError('Renderer deployment target must be CloudcityMacMini')
    manifest = json.loads((payload/'manifest.json').read_text())
    allowed = {'shared/format_email.py','shared/email_renderer_install.py'}
    if set(manifest) != allowed:
        raise ValueError('Unexpected renderer deployment file set')
    deadline = time.monotonic()+75
    while True:
        missing = [n for n,h in manifest.items() if not (payload/n).is_file()
                   or hashlib.sha256((payload/n).read_bytes()).hexdigest() != h]
        if not missing:
            break
        if time.monotonic() >= deadline:
            raise ValueError('Incomplete Syncthing payload: '+', '.join(missing))
        time.sleep(1)
    for name in manifest:
        compile((payload/name).read_text(), name, 'exec')
    apple = work/'apple'
    backup = payload/('backups-'+str(time.time_ns()))
    replacements = {name:(payload/name).read_text() for name in manifest}
    for name,patch in CALLERS.items():
        target = apple/name
        if target.exists():
            replacements[name] = patch(target.read_text())
    for name,text in replacements.items():
        compile(text,name,'exec')
    order = ['shared/format_email.py']+[n for n in replacements if n != 'shared/format_email.py']
    for name in order:
        target = apple/name
        if target.exists():
            old = backup/name
            old.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, old)
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name('.'+target.name+'.renderer-tmp')
        temporary.write_text(replacements[name])
        if target.exists():
            temporary.chmod(target.stat().st_mode)
        os.replace(temporary, target)
    archive = work/'merlib-dump'
    # Read-only proof: archive code is written by the originating computer.
    sys.path.insert(0, str(apple/'shared'))
    import format_email as renderer
    dossier = archive/'aimeat/phase-conjugation-tri-brain-analysis.dossier.md'
    verification = {'installed':manifest, 'ts':time.time(), 'renderer':str(renderer.RENDERER_PATH)}
    if dossier.exists():
        text = dossier.read_text()
        rendered = renderer.md_to_html(text)
        verification.update(equations=len(renderer.math_spans(text)),
                            rendered_equations=rendered.count('class="aimeat-math"'),
                            unsupported_preserved=rendered.count('Unrendered LaTeX preserved:'))
    verification['archive_adapters'] = {
        'shim': (archive/'format_email.py').exists() and 'aimeat_canonical_email_renderer' in (archive/'format_email.py').read_text(),
        'director': (archive/'aimeat_director.py').exists() and 'render_email as render_markdown_to_html' in (archive/'aimeat_director.py').read_text(),
        'sender': (archive/'render_rich_email.py').exists() and 'email_payload(md_text' in (archive/'render_rich_email.py').read_text()}
    (payload/'installed.json').write_text(json.dumps(verification, indent=2))
    return verification


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--payload', type=Path)
    parser.add_argument('--patch-archive', type=Path)
    args = parser.parse_args()
    if args.patch_archive:
        print(json.dumps(patch_archive(args.patch_archive), indent=2))
    elif args.payload:
        print(json.dumps(install(args.payload, Path.home()/'work'), indent=2))
    else:
        parser.error('Provide --payload or --patch-archive')


if __name__ == '__main__':
    main()
