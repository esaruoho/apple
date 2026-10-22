"""Build or replay readable cloud artifacts using the installed Convey renderers.

REPORT-CARD >> features/cloud-source-markdown.feature
Rendering is Mini-only. Reading a Markdown specification needs no image/OCR.
"""
import argparse
import importlib.machinery
import importlib.util
from pathlib import Path
import socket
import subprocess
import sys

from cloud_source import read_spec, write_spec
import hashlib

ROOT = Path(__file__).resolve().parents[1]
ACTIONS = Path.home()/'work/convey/convey/actions'


def mini():
    if socket.gethostname().split('.')[0].lower() not in {'cloudcity', 'cloudcitymacmini'}:
        raise RuntimeError('Cloud rendering is CloudcityMacMini-only')


def load(name):
    sys.path.insert(0, str(ACTIONS))
    loader = importlib.machinery.SourceFileLoader('cloud_'+Path(name).stem.replace('-', '_'), str(ACTIONS/name))
    module = importlib.util.module_from_spec(importlib.util.spec_from_loader(loader.name, loader))
    loader.exec_module(module)
    return module


def artifacts(source, kind):
    base = source.with_suffix('.'+kind)
    return [base.with_suffix(base.suffix+suffix) for suffix in ('.png', '.source.md', '.render.json')]


def generate(source):
    mini()
    source = Path(source)
    provenance = {'name': source.name, 'sha256': hashlib.sha256(source.read_bytes()).hexdigest()}
    files, errors = [], {}
    for kind in ('wordcloud', 'sentencecloud', 'ideacloud'):
        outputs = artifacts(source, kind)
        try:
            fresh = all(p.exists() for p in outputs) and read_spec(outputs[1]).get('source') == provenance
            if not fresh:
                if kind == 'ideacloud':
                    video = load('video')
                    video.make_keyideas(source.parent, source.stem, dry=False,
                                        text_override=source.read_text(), time_labels=False)
                    for suffix in ('.png', '.source.md', '.render.json', '.md'):
                        old = source.with_suffix('.keyideas'+suffix)
                        if not old.exists():
                            raise RuntimeError('Key-takeaways renderer produced no '+suffix)
                        old.replace(source.with_suffix('.ideacloud'+suffix))
                else:
                    subprocess.run([str(Path.home()/'work/convey/bin/convey'), kind, str(source),
                                    '--out', str(outputs[0]), '--no-open'], check=True,
                                   capture_output=True, text=True, timeout=180)
                if not all(p.exists() for p in outputs):
                    raise RuntimeError('Renderer did not preserve PNG and source sidecars')
                spec = read_spec(outputs[1])
                spec['kind'] = kind
                spec['source'] = provenance
                write_spec(outputs[0], spec)
            files.extend(p.name for p in outputs)
            ideas = source.with_suffix('.ideacloud.md')
            if kind == 'ideacloud' and ideas.exists():
                files.append(ideas.name)
        except Exception as error:
            errors[kind] = str(error)
    return files, errors


def replay(source_md, output):
    mini()
    spec = read_spec(source_md)
    pairs = [(item['text'], item['weight']) for item in spec['items']]
    if spec['kind'] == 'wordcloud':
        load('wordcloud-generator.py').render_wordcloud(dict(pairs), str(output), title=spec['settings'].get('title', ''))
    else:
        load('sentencecloud-generator.py').render_poster(pairs, Path(output), width=spec['settings']['width'], quiet=True)
    write_spec(output, spec)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['build', 'render'])
    parser.add_argument('source', type=Path)
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    if args.action == 'render':
        if not args.out:
            parser.error('render needs --out')
        replay(args.source, args.out)
    else:
        import json
        files, errors = generate(args.source)
        print(json.dumps({'files': files, 'errors': errors}))
        return int(bool(errors))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
