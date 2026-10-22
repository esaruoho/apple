#!/usr/bin/env python3
"""Mini-only 25-page extraction and real black wordcloud verification.

Uses a synthetic document and never sends email or calls a model.
REPORT-CARD >> features/aimeat-email-pdf.feature
"""
import importlib.util
import json
from pathlib import Path
import socket
import subprocess
import sys
import zlib


def verify(directory):
    if socket.gethostname().split('.')[0].lower() not in {'cloudcity', 'cloudcitymacmini'}:
        raise RuntimeError('Verification must run on the Mini')
    from PIL import Image, ImageDraw, ImageFont
    directory.mkdir(parents=True, exist_ok=True)
    objects = []
    def obj(data):
        objects.append(data.encode() if isinstance(data, str) else data)
        return len(objects)
    obj('<< /Type /Catalog /Pages 2 0 R >>')
    obj('PAGES')
    font = obj('<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>')
    image = Image.new('RGB', (1600, 400), 'white')
    drawing = ImageDraw.Draw(image)
    font_path = '/System/Library/Fonts/Supplemental/Arial.ttf'
    drawing.text((50, 100), 'FINAL PAGE TWENTY FIVE OCR MARKER', fill='black', font=ImageFont.truetype(font_path, 58))
    compressed = zlib.compress(image.tobytes())
    raster = obj(f'<< /Type /XObject /Subtype /Image /Width 1600 /Height 400 /ColorSpace /DeviceRGB /BitsPerComponent 8 /Filter /FlateDecode /Length {len(compressed)} >>\nstream\n'.encode()+compressed+b'\nendstream')
    pages = []
    for number in range(1, 26):
        if number == 25:
            stream = b'q 560 0 0 140 20 400 cm /Im1 Do Q'
        else:
            stream = f'BT /F1 12 Tf 30 700 Td (Page {number}: Open reservoir coupling, input power and measured output are recorded.) Tj ET'.encode()
        content = obj(f'<< /Length {len(stream)} >>\nstream\n'.encode()+stream+b'\nendstream')
        pages.append(obj(f'<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 {font} 0 R >> /XObject << /Im1 {raster} 0 R >> >> /Contents {content} 0 R >>'))
    objects[1] = ('<< /Type /Pages /Count 25 /Kids ['+' '.join(f'{p} 0 R' for p in pages)+'] >>').encode()
    data = bytearray(b'%PDF-1.4\n')
    offsets = [0]
    for number, content in enumerate(objects, 1):
        offsets.append(len(data))
        data.extend(f'{number} 0 obj\n'.encode()+content+b'\nendobj\n')
    start = len(data)
    data.extend(f'xref\n0 {len(objects)+1}\n0000000000 65535 f \n'.encode())
    data.extend(''.join(f'{offset:010d} 00000 n \n' for offset in offsets[1:]).encode())
    data.extend(f'trailer << /Size {len(objects)+1} /Root 1 0 R >>\nstartxref\n{start}\n%%EOF\n'.encode())
    pdf = directory/'twenty-five-pages.pdf'
    pdf.write_bytes(data)
    root = Path.home()/'work/apple'
    subprocess.run([str(root/'bin/mail-pdf-text'), str(pdf)], check=True, capture_output=True, text=True, timeout=120)
    result = json.loads(Path(str(pdf)+'.pages.json').read_text())
    assert len(result['pages']) == result['page_count'] == 25
    last = result['pages'][-1]
    assert last['number'] == 25 and last['method'] == 'vision-ocr'
    assert 'TWENTY FIVE' in last['text'].upper(), last
    source = directory/'verification.txt'
    source.write_text('\n'.join(p['text'] for p in result['pages']))
    cloud = directory/'verification.wordcloud.png'
    sys.path.insert(0, str(root/'shared'))
    import cloud_assets
    from cloud_source import read_spec
    files, errors = cloud_assets.generate(source)
    assert not errors, errors
    from PIL import ImageChops
    clouds = {}
    for kind in ('wordcloud', 'sentencecloud', 'ideacloud'):
        png = source.with_suffix('.'+kind+'.png')
        md = png.with_suffix('.source.md')
        spec = read_spec(md)
        assert spec['kind'] == kind and spec['items']
        if kind == 'ideacloud':
            assert not any('[0:00]' in item['text'] for item in spec['items'])
        replay = directory/('replayed-'+kind+'.png')
        cloud_assets.replay(md, replay)
        with Image.open(png) as original, Image.open(replay) as recreated:
            assert original.size == recreated.size
            assert ImageChops.difference(original.convert('RGB'), recreated.convert('RGB')).getbbox() is None
            assert original.convert('RGB').getpixel((0, 0)) == (0, 0, 0)
        clouds[kind] = {'png': str(png), 'markdown': str(md), 'items': len(spec['items']),
                        'replay_pixel_equal': True, 'background': 'black'}
    with Image.open(cloud) as image:
        rgb = image.convert('RGB')
        pixels = [rgb.getpixel(p) for p in ((0, 0), (image.width-1, 0), (0, image.height-1), (image.width-1, image.height-1))]
        assert all(p == (0, 0, 0) for p in pixels), pixels
    proof = {'host': socket.gethostname(), 'page_count': result['page_count'],
             'last_page': last, 'wordcloud': str(cloud), 'corner_pixels': pixels,
             'models_called': False, 'email_sent': False, 'clouds': clouds, 'artifacts': files}
    (directory/'verification.json').write_text(json.dumps(proof, indent=2))
    print(json.dumps(proof))


if __name__ == '__main__':
    verify(Path(sys.argv[1]))
