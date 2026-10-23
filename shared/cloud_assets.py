"""Build or replay readable cloud artifacts using the installed Convey renderers.

REPORT-CARD >> features/cloud-source-markdown.feature
Rendering is Mini-only. Reading a Markdown specification needs no image/OCR.
"""
import argparse
from collections import Counter
import importlib.machinery
import importlib.util
from pathlib import Path
import re
import socket
import subprocess
import sys
import math

from cloud_source import read_spec, write_spec, write_cloud_source
import hashlib

ROOT = Path(__file__).resolve().parents[1]
ACTIONS = Path.home()/'work/convey/convey/actions'

STOPWORDS = set('a an and are as at be been being but by can could did do does for from had has have he her hers him his how i if in into is it its may might more most must my no not of on or our ours she should so than that the their theirs them then there these they this those to too up us very was we were what when where which who will with would you your'.split())


def render_wordcloud_fallback(source, output):
    """Render a deterministic black word cloud using the Mini's Pillow install."""
    from PIL import Image, ImageDraw, ImageFont

    source, output = Path(source), Path(output)
    tokens = re.findall(r"[a-z][a-z0-9'-]{2,29}", source.read_text(encoding='utf-8').lower())
    counts = Counter(token.strip("'-") for token in tokens)
    counts = Counter({word: count for word, count in counts.items()
                      if word not in STOPWORDS and not word.isdigit()})
    items = counts.most_common(100)
    if not items:
        raise RuntimeError('Wordcloud fallback found no usable words')

    width, height = 1600, 1000
    title = source.stem
    font_path = '/System/Library/Fonts/Supplemental/Arial.ttf'
    palette = ['#f2c14e', '#e76f51', '#7bdff2', '#b2f7ef', '#cdb4db', '#f7aef8', '#a8dadc']
    image = Image.new('RGB', (width, height), 'black')
    draw = ImageDraw.Draw(image)
    try:
        title_font = ImageFont.truetype(font_path, 34)
    except OSError:
        title_font = ImageFont.load_default()
    draw.text((width // 2, 35), title, fill='white', font=title_font, anchor='mt')

    maximum, minimum = items[0][1], items[-1][1]
    x, y, row_height = 36, 115, 0
    gap_x, gap_y = 22, 18
    for index, (word, weight) in enumerate(items):
        ratio = (weight - minimum) / max(1, maximum - minimum)
        size = int(24 + 64 * math.sqrt(max(0.0, ratio)))
        try:
            font = ImageFont.truetype(font_path, size)
        except OSError:
            font = ImageFont.load_default()
        box = draw.textbbox((0, 0), word, font=font)
        item_width, item_height = box[2] - box[0], box[3] - box[1]
        if x + item_width + gap_x > width - 36:
            x, y = 36, y + row_height + gap_y
            row_height = 0
        if y + item_height > height - 32:
            break
        draw.text((x, y), word, fill=palette[index % len(palette)], font=font)
        x += item_width + gap_x
        row_height = max(row_height, item_height)

    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)
    write_cloud_source(output, 'wordcloud', items,
                       {'width': width, 'height': height, 'background': '#000000',
                        'renderer': 'Pillow fallback', 'title': title})


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
                    try:
                        subprocess.run([str(Path.home()/'work/convey/bin/convey'), kind, str(source),
                                        '--out', str(outputs[0]), '--no-open'], check=True,
                                       capture_output=True, text=True, timeout=180)
                    except subprocess.CalledProcessError:
                        if kind != 'wordcloud':
                            raise
                        render_wordcloud_fallback(source, outputs[0])
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
        try:
            load('wordcloud-generator.py').render_wordcloud(dict(pairs), str(output), title=spec['settings'].get('title', ''))
        except SystemExit:
            render_wordcloud_fallback_from_pairs(pairs, output, spec['settings'].get('title', ''))
    else:
        load('sentencecloud-generator.py').render_poster(pairs, Path(output), width=spec['settings']['width'], quiet=True)
    write_spec(output, spec)


def render_wordcloud_fallback_from_pairs(pairs, output, title):
    """Replay a readable wordcloud source without the optional wordcloud package."""
    from PIL import Image, ImageDraw, ImageFont

    output = Path(output)
    width, height = 1600, 1000
    palette = ['#f2c14e', '#e76f51', '#7bdff2', '#b2f7ef', '#cdb4db', '#f7aef8', '#a8dadc']
    image = Image.new('RGB', (width, height), 'black')
    draw = ImageDraw.Draw(image)
    font_path = '/System/Library/Fonts/Supplemental/Arial.ttf'
    try:
        title_font = ImageFont.truetype(font_path, 34)
    except OSError:
        title_font = ImageFont.load_default()
    draw.text((width // 2, 35), title, fill='white', font=title_font, anchor='mt')
    items = sorted(pairs, key=lambda pair: pair[1], reverse=True)[:100]
    maximum = max((weight for _, weight in items), default=1)
    minimum = min((weight for _, weight in items), default=1)
    x, y, row_height = 36, 115, 0
    for index, (word, weight) in enumerate(items):
        size = int(24 + 64 * math.sqrt(max(0.0, (weight - minimum) / max(1, maximum - minimum))))
        try:
            font = ImageFont.truetype(font_path, size)
        except OSError:
            font = ImageFont.load_default()
        box = draw.textbbox((0, 0), word, font=font)
        item_width, item_height = box[2] - box[0], box[3] - box[1]
        if x + item_width + 22 > width - 36:
            x, y = 36, y + row_height + 18
            row_height = 0
        if y + item_height > height - 32:
            break
        draw.text((x, y), word, fill=palette[index % len(palette)], font=font)
        x += item_width + 22
        row_height = max(row_height, item_height)
    output.parent.mkdir(parents=True, exist_ok=True)
    image.save(output)


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
