#!/usr/bin/env python3
"""Deploy/verify the transcript analysis return path over Syncthing.

REPORT-CARD >> features/transcript-vault-email-analysis.feature
No processes are started; commands use the existing PakettiBot direct bridge.
"""
import argparse
import hashlib
import json
import os
import shlex
import shutil
from pathlib import Path

QUEUE = Path.home() / 'work/comms/queue'
EXCHANGE = QUEUE / 'transcript-analysis-deploy'
FILES = ('apple/bin/freellmask-mail', 'convey/convey/cli.py',
         'convey/convey/actions/video', 'convey-packs/.stignore')


def enqueue(name, script, timeout=120):
    EXCHANGE.mkdir(parents=True, exist_ok=True)
    path = EXCHANGE / (name + '.py')
    path.write_text(script)
    command = f'run --direct --timeout {timeout} /opt/homebrew/bin/python3 ' + shlex.quote(str(path))
    inbox = QUEUE / 'pakettibot-inbox' / (name + '.cmd')
    temp = inbox.with_suffix('.partial')
    temp.write_text(command + '\n')
    os.replace(temp, inbox)
    print('Queued:', inbox)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('action', choices=('snapshot', 'deploy', 'collect', 'smoke'))
    args = parser.parse_args()
    if args.action == 'snapshot':
        enqueue('transcript-analysis-snapshot-20261009', '''from pathlib import Path
import hashlib,json,shutil,socket
root=Path('/Users/esaruoho/work')
target=root/'comms/queue/transcript-analysis-deploy/snapshot'
manifest={}
for rel in ''' + repr(FILES) + ''':
 p=root/rel
 if p.exists():
  dest=target/rel; dest.parent.mkdir(parents=True,exist_ok=True)
  shutil.copy2(p,dest)
  manifest[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
(target/'manifest.json').write_text(json.dumps(manifest,indent=2))
print(json.dumps({'host':socket.gethostname(),'snapshot':str(target),'files':manifest},indent=2))
''')
    elif args.action == 'deploy':
        build = Path('/private/tmp/transcript-analysis-remote')
        manifest = json.loads((build / 'manifest.json').read_text())
        for rel in manifest['files']:
            src = build / rel
            dest = EXCHANGE / 'release' / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(src, dest)
        shutil.copy2(build / 'manifest.json', EXCHANGE / 'release/manifest.json')
        script = (build / 'install.py').read_text()
        version = hashlib.sha256((build / 'manifest.json').read_bytes()).hexdigest()[:10]
        enqueue('transcript-analysis-install-' + version, script)
    elif args.action == 'smoke':
        result = json.loads((EXCHANGE / 'install-result.json').read_text())
        desired = json.loads(Path('/private/tmp/transcript-analysis-remote/manifest.json').read_text())
        if result['files'] != desired['files']:
            raise SystemExit('The latest remote release has not reported back yet')
        if any(check['exit'] for check in result['checks']):
            raise SystemExit('Remote installation checks have not passed')
        enqueue('transcript-analysis-live-20261009', '''from pathlib import Path
import json,subprocess,socket,time
root=Path('/Users/esaruoho/work')
source=root/'convey-packs/thane-heins/downloads/PART-4-EdisonMotors-Thane-Heins-Energy-Inc-EV-Regenerative-Acceleratio__USGlMn6x-_4.transcript.txt'
if not source.is_file(): raise SystemExit('Selected transcript is not on this peer')
command=[str(root/'apple/bin/convey'),'email-transcript',str(source),'--analyze',
         '--source','https://www.youtube.com/watch?v=USGlMn6x-_4',
         '--title','Thane Heins — Edison Motors regenerative acceleration, Part 4']
run=subprocess.run(command,capture_output=True,text=True,timeout=1050,cwd=root/'convey')
receipts=[]
for p in source.parent.glob(source.stem+'.email-*.analysis.json'):
 receipts.append({'path':str(p),'metadata':json.loads(p.read_text()),
                  'body_exists':p.with_suffix('.md').is_file()})
result={'host':socket.gethostname(),'finished_at':time.time(),'exit':run.returncode,
        'stdout':run.stdout,'stderr':run.stderr,'receipts':receipts}
(root/'comms/queue/transcript-analysis-deploy/live-result.json').write_text(json.dumps(result,indent=2))
print(json.dumps(result,indent=2))
raise SystemExit(run.returncode)
''', timeout=1200)
    elif args.action == 'collect':
        # Run the existing text-only return leg now; the scheduled collector keeps it current.
        import subprocess
        subprocess.run([str(Path.home() / 'work/apple/bin/convey'), 'ocr-collect',
                        '--transcripts-only'], check=True)


if __name__ == '__main__':
    main()
