#!/usr/bin/env python3
"""Syncthing deployment for the existing Mini mail pane; no process launch.

REPORT-CARD >> features/aimeat-email-pdf.feature
"""
import argparse
import hashlib
import importlib.util
import json
import os
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
         'bin/mail-pdf-text.swift', 'roundtable/install_mail.py',
         'roundtable/verify_mail.py', 'scripts/wordcloud-dark.py', 'scripts/cloud-source-sidecars.py',
         'shared/cloud_source.py', 'shared/cloud_assets.py', 'bin/cloud-assets']
HANDLER_FILES = ['roundtable/install_mail.py', 'shared/aimeat_mail.py', 'shared/cloud_assets.py']


def stage_handler():
    """Stage only the mail handler; leave other Mini-owned files untouched."""
    digest = hashlib.sha256(b''.join((ROOT/n).read_bytes() for n in HANDLER_FILES)).hexdigest()[:16]
    payload = WORK/'comms/queue/aimeat-mail-deploy'/('handler-'+digest)
    manifest = {}
    for name in HANDLER_FILES:
        target = payload/name
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT/name, target)
        manifest[name] = hashlib.sha256(target.read_bytes()).hexdigest()
    (payload/'manifest.json').write_text(json.dumps(manifest))
    command = 'run --direct --timeout 120 '+shlex.join([
        '/opt/homebrew/bin/python3', str(payload/'roundtable/install_mail.py'),
        'handler', '--payload', str(payload)])
    request = WORK/'comms/queue/pakettibot-inbox'/f'aimeat-mail-handler-{time.time_ns()}.cmd'
    request.write_text(command+'\n')
    print(json.dumps({'payload': str(payload), 'request': str(request),
                      'reply': str(WORK/'comms/queue/pakettibot-outbox'/(request.stem+'.out.txt'))}))


def install_handler(payload, work=None):
    """Atomically install only the AIMEAT handler and its cloud renderer on the Mini."""
    if socket.gethostname().split('.')[0].lower() not in {'cloudcity', 'cloudcitymacmini'}:
        raise RuntimeError('Install on CloudcityMacMini only')
    payload = Path(payload)
    manifest = json.loads((payload/'manifest.json').read_text())
    if set(manifest) != set(HANDLER_FILES):
        raise ValueError('Unexpected AIMEAT handler payload')
    deadline = time.monotonic()+75
    while True:
        missing = [n for n,h in manifest.items() if not (payload/n).is_file()
                   or hashlib.sha256((payload/n).read_bytes()).hexdigest() != h]
        if not missing:
            break
        if time.monotonic() >= deadline:
            raise ValueError('Incomplete Syncthing payload: '+', '.join(missing))
        time.sleep(1)
    for name in HANDLER_FILES:
        source = payload/name
        if name.endswith('.py'):
            compile(source.read_text(), str(source), 'exec')
    apple = (work or Path.home()/'work')/'apple'
    backups = {}
    installed = {}
    for name in HANDLER_FILES:
        if name == 'roundtable/install_mail.py':
            continue
        source = payload/name
        target = apple/name
        backup = payload/('backup-'+str(time.time_ns()))/Path('apple')/Path(name)
        if target.exists():
            backup.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(target, backup)
            backups[name] = str(backup)
        target.parent.mkdir(parents=True, exist_ok=True)
        temporary = target.with_name('.'+target.name+'.handler-tmp')
        shutil.copyfile(source, temporary)
        if target.exists():
            temporary.chmod(target.stat().st_mode)
        os.replace(temporary, target)
        installed[name] = hashlib.sha256(target.read_bytes()).hexdigest()
    receipt = {'installed': True, 'host': socket.gethostname(),
               'files': installed, 'backups': backups,
               'installed_at': time.time(), 'activation': 'existing mail pane reloads on file change'}
    (payload/'handler-installed.json').write_text(json.dumps(receipt, indent=2))
    print(json.dumps(receipt))
    return receipt


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
    (WORK/'apple/bin/cloud-assets').chmod(0o755)
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
    spec = importlib.util.spec_from_file_location('sidecars', payload/'scripts/cloud-source-sidecars.py')
    sidecars = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(sidecars)
    for name in ('convey/convey/actions/wordcloud-generator.py', 'convey/convey/actions/sentencecloud-generator.py',
                 'convey/convey/actions/wordcloud', 'convey/convey/actions/sentencecloud',
                 'convey/convey/actions/video', 'convey/convey/cli.py', 'convey/convey/actions/cloud_source.py',
                 'merlib-dump/scripts/wordcloud-generator.py', 'merlib-dump/scripts/cloud_source.py'):
        path = WORK/name
        if path.exists():
            saved = backup/name
            saved.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, saved)
    source_changes = sidecars.apply(WORK, payload/'shared/cloud_source.py')
    # Keep concurrent roundtable fixes intact. Install only the mail collector
    # hook on older checkouts, rather than copying this shared worker wholesale.
    bridge = WORK/'apple/roundtable/bridge.py'
    text = bridge.read_text()
    before_bridge = text
    if 'from aimeat_mail import collect as collect_mail' not in text:
        begin = text.index('def collect(')
        at = text.index('    copied = 0\n', begin)
        text = text[:at]+('    sys.path.insert(0, str(ROOT / "shared"))\n'
                         '    from aimeat_mail import collect as collect_mail\n'
                         '    copied = collect_mail(folder)\n')+text[at+len('    copied = 0\n'):]
    if 'from aimeat_mail import merge_mail_inputs' not in text:
        marker = '            if args.verb == "submit" and not args.source:\n'
        if text.count(marker) != 1:
            raise RuntimeError('Roundtable watch loop changed; cannot insert mail input hook safely')
        text = text.replace(marker, '            if args.verb == "watch":\n'
                            '                sys.path.insert(0, str(ROOT / "shared"))\n'
                            '                from aimeat_mail import merge_mail_inputs\n'
                            '                paths = merge_mail_inputs(paths, args.stable_seconds)\n'+marker)
    compile(text, str(bridge), 'exec')
    if text != before_bridge:
        saved = backup/'apple/roundtable/bridge.py'
        saved.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(bridge, saved)
        bridge.write_text(text)
    receipt = {'installed': True, 'host': socket.gethostname(), 'theme_changed': changed,
                      'cloud_source_changes': source_changes,
                      'activation': 'Existing Cloudcity-Boot mail pane requires cloudcity restart',
                      'payload': str(payload), 'files': manifest, 'installed_at': time.time()}
    (payload/'installed.json').write_text(json.dumps(receipt, indent=2))
    print(json.dumps(receipt))


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['stage', 'install', 'activate', 'verify', 'handler'])
    parser.add_argument('--payload', type=Path)
    args = parser.parse_args()
    if args.action == 'handler':
        if args.payload:
            install_handler(args.payload)
        else:
            stage_handler()
    elif args.action == 'install':
        install(args.payload)
    else:
        stage(args.action if args.action in {'activate', 'verify'} else 'install')
