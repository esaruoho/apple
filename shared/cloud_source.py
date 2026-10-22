"""Portable, readable rendering inputs for cloud images. Standard library only.

REPORT-CARD >> features/cloud-source-markdown.feature
Copied beside standalone Convey/archive generators by the installer.
"""
import hashlib
import json
from pathlib import Path


def encoded(spec):
    return json.dumps(spec, ensure_ascii=False, sort_keys=True, separators=(',', ':')).encode()


def write_spec(image, spec):
    image = Path(image)
    spec = dict(spec)
    spec.pop('spec_sha256', None)
    spec['spec_sha256'] = hashlib.sha256(encoded(spec)).hexdigest()
    source = image.with_suffix('.source.md')
    data = image.with_suffix('.render.json')
    image.parent.mkdir(parents=True, exist_ok=True)
    title = spec['kind'].replace('cloud', ' cloud').capitalize()
    lines = [f'# {title} — rendering source', '',
             'These are the exact text items and weights supplied to the renderer.',
             'Selections are extractive; prominence is not a claim of factual correctness.', '']
    if spec.get('source'):
        lines += [f"Source: {spec['source']['name']}", f"Source SHA-256: `{spec['source']['sha256']}`", '']
    for index, item in enumerate(spec['items'], 1):
        lines += [f"## {index} · weight {item['weight']}", '', item['text'], '']
    lines += ['## Machine-readable rendering input', '',
              'The JSON below is the complete rendering specification. No image OCR is needed.', '',
              '```cloud-render-json', json.dumps(spec, ensure_ascii=False, indent=2), '```', '']
    source.write_text('\n'.join(lines), encoding='utf-8')
    data.write_text(json.dumps(spec, ensure_ascii=False, indent=2)+'\n', encoding='utf-8')
    return source, data


def write_cloud_source(image, kind, items, settings):
    return write_spec(image, {'schema': 'cloud-render/1', 'kind': kind,
                              'items': [{'text': str(text), 'weight': weight} for text, weight in items],
                              'settings': settings})


def read_spec(path):
    text = Path(path).read_text(encoding='utf-8')
    if Path(path).suffix == '.json':
        spec = json.loads(text)
    else:
        marker = '```cloud-render-json\n'
        spec = json.loads(text.split(marker, 1)[1].split('\n```', 1)[0])
    digest = spec.pop('spec_sha256')
    if hashlib.sha256(encoded(spec)).hexdigest() != digest:
        raise ValueError('Cloud source checksum mismatch')
    if spec.get('schema') != 'cloud-render/1' or spec.get('kind') not in {'wordcloud', 'sentencecloud', 'ideacloud'}:
        raise ValueError('Unsupported cloud source')
    spec['spec_sha256'] = digest
    return spec
