#!/usr/bin/env python3
"""Syncthing deployment for the existing Mini mail pane; no process launch.

REPORT-CARD >> features/aimeat-email-pdf.feature
"""
import argparse
import hashlib
import importlib.util
import json
from pathlib import Path
import shlex
import shutil
import socket
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]
WORK = Path.home()/'work'
FILES = ['bin/freellmask-mail', 'shared/aimeat_mail.py', 'bin/mail-pdf-text',
         'bin/mail-pdf-text.swift', 'roundtable/bridge.py', 'roundtable/install_mail.py',
         'roundtable/verify_mail.py', 'scripts/wordcloud-dark.py']


def stage(action):
    digest = hashlib.sha256(b''.join((ROOT/n).read_bytes() for n in FILES)).hexdigest()[:16]
    payload = WORK/'comms/queue/aimeat-mail-deploy'/digest
    manifest = {}
    for name in FILES:
        target = payload/name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT/name, target)
        manifest[name] = hashlib.sha256(target.read_bytes()).hexdigest()
    (payload/'manifest.json').write_text(json.dumps(manifest))
    if action == 'activate':
        command = 'cloudcity restart'
    elif action == 'verify':
        command = 'run --direct --timeout 180 '+shlex.join([
            '/opt/homebrew/bin/python3', str(payload/'roundtable/verify_mail.py'), str(payload/'proof')])
    else:
        command = 'run --direct --timeout 120 '+shlex.join([
            '/opt/homebrew/bin/python3', str(payload/'roundtable/install_mail.py'), action,
            '--payload', str(payload)])
    request = WORK/'comms/queue/pakettibot-inbox'/f'aimeat-mail-{action}-{time.time_ns()}.cmd'
    request.write_text(command+'\n')
    print(json.dumps({'payload': str(payload), 'request': str(request),
                      'reply': str(WORK/'comms/queue/pakettibot-outbox'/(request.stem+'.out.txt'))}))


def install(payload):
    if socket.gethostname().split('.')[0].lower() not in {'cloudcity', 'cloudcitymacmini'}:
        raise RuntimeError('Install on CloudcityMacMini only')
    manifest = json.loads((payload/'manifest.json').read_text())
    for name in FILES:
        path = payload/name
        if hashlib.sha256(path.read_bytes()).hexdigest() != manifest[name]:
            raise RuntimeError(f'Incomplete payload: {name}')
        if name.endswith('.py') or name == 'bin/freellmask-mail':
            compile(path.read_text(), str(path), 'exec')
    # Compilation belongs on the Mini, never the laptop.
    binary = payload/'mail-pdf-text.checked'
    subprocess.run(['xcrun', 'swiftc', '-O', str(payload/'bin/mail-pdf-text.swift'),
                    '-o', str(binary), '-framework', 'PDFKit', '-framework', 'Vision',
                    '-framework', 'AppKit'], check=True, capture_output=True, text=True, timeout=90)
    backup = payload/('backups-'+str(time.time_ns()))
    for name in FILES:
        target = WORK/'apple'/name
        if target.exists():
            saved = backup/'apple'/name
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, saved)
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(payload/name, target)
    (WORK/'apple/bin/mail-pdf-text').chmod(0o755)
    cache = Path.home()/'.cache/apple/mail-pdf-text'
    cache.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(binary, cache)
    cache.chmod(0o755)
    spec = importlib.util.spec_from_file_location('theme', payload/'scripts/wordcloud-dark.py')
    theme = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(theme)
    for path in (WORK/'convey/convey/actions/wordcloud-generator.py', WORK/'merlib-dump/scripts/wordcloud-generator.py'):
        if path.exists():
            saved = backup/path.relative_to(WORK)
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, saved)
    changed = theme.apply(WORK)
    receipt = {'installed': True, 'host': socket.gethostname(), 'theme_changed': changed,
                      'activation': 'Existing Cloudcity-Boot mail pane requires cloudcity restart',
                      'payload': str(payload), 'files': manifest, 'installed_at': time.time()}
    (payload/'installed.json').write_text(json.dumps(receipt, indent=2))
    print(json.dumps(receipt))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['stage', 'install', 'activate', 'verify'])
    parser.add_argument('--payload', type=Path)
    args = parser.parse_args()
    if args.action == 'install':
        install(args.payload)
    else:
        stage(args.action if args.action in {'activate', 'verify'} else 'install')
