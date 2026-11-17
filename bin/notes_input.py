"""Read-only Notes snapshots + on-Mini Vision + durable run records.
REPORT-CARD >> features/notes-process.feature
"""
import base64, datetime, hashlib, importlib.machinery, importlib.util, json, os, shutil, socket, subprocess, uuid
from pathlib import Path

HERE = Path(__file__).resolve().parent


def save_json(path, value):
    path = Path(path)
    tmp = path.with_suffix(path.suffix + '.tmp')
    with tmp.open('w', encoding='utf-8') as f:
        json.dump(value, f, ensure_ascii=True, indent=2)
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp, path)


def load_variants():
    loader = importlib.machinery.SourceFileLoader('notes_source_variants', str(HERE / 'notes-variants'))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


def snapshot(c, nid, root):
    pk = int(nid.rsplit('/p', 1)[1])
    row = c.execute('''select n.ZTITLE1, n.ZMODIFICATIONDATE1, d.ZDATA,
        coalesce(n.ZISPASSWORDPROTECTED,0), coalesce(n.ZMARKEDFORDELETION,0)
        from ZICCLOUDSYNCINGOBJECT n join ZICNOTEDATA d on d.Z_PK=n.ZNOTEDATA
        where n.Z_PK=?''', (pk,)).fetchone()
    if not row or row[3] or row[4]:
        raise ValueError('source missing, locked or deleted')
    title, modified, blob = row[:3]
    text = load_variants().note_text(blob)
    images = []
    for ident, uti, mid, filename in c.execute('''select a.ZIDENTIFIER,a.ZTYPEUTI,m.ZIDENTIFIER,m.ZFILENAME
        from ZICCLOUDSYNCINGOBJECT a left join ZICCLOUDSYNCINGOBJECT m on a.ZMEDIA=m.Z_PK
        where a.ZNOTE=? and coalesce(a.ZMARKEDFORDELETION,0)=0 and a.ZTYPEUTI is not null''', (pk,)):
        image = uti in ('public.png', 'public.jpeg', 'public.heic', 'public.heif', 'public.tiff',
                        'public.image', 'public.gif', 'public.webp')
        paths = []
        if mid and filename:
            for base in (root / 'Accounts').glob('*/Media'):
                paths.extend(p for p in (base / mid).rglob('*') if p.is_file() and p.name == filename)
        images.append(dict(id=ident, uti=uti, image=image, path=str(paths[0]) if paths else None,
                           candidates=[str(p) for p in paths]))
    return dict(note_id=nid, title=title, text=text, modified=modified,
                age=max(0, datetime.datetime.now().timestamp() - (modified + 978307200)),
                attachments=images, source_gzip_base64=base64.b64encode(blob).decode())


def runs_root(state):
    override = os.environ.get('NOTES_PROCESS_RUNS')
    if override:
        return Path(override).expanduser()
    queue = Path.home() / 'work/comms/queue'
    if state == Path.home() / '.local/share/notes-process' and queue.exists():
        return queue / 'notes-process-runs'
    return state / 'runs'


def start_run(state, source, tag, key):
    run_id = 'NP-' + datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ-') + uuid.uuid4().hex[:12]
    run = runs_root(state) / run_id
    run.mkdir(parents=True, mode=0o700)
    save_json(run / 'source.json', source)
    (run / 'source.txt').write_text(source['text'], encoding='utf-8')
    save_json(run / 'status.json', dict(id=run_id, state='preparing', tag=tag, key=key,
                                       host=socket.gethostname(), note_id=source['note_id']))
    return run


def vision_images(source, run):
    # OCR belongs on Cloudcity, never on Esa's laptop. Require the Cloudcity host
    # name (or an explicit remote verification override) before any Vision call.
    if any(a['image'] for a in source['attachments']):
        if 'cloudcity' not in socket.gethostname().lower() and not os.environ.get('NOTES_VISION_ON_MINI'):
            raise RuntimeError('Vision must run on Cloudcity; set NOTES_VISION_ON_MINI=1 on the Mini')
    results = []
    for i, attachment in enumerate(source['attachments']):
        item = dict(attachment)
        if not item['image']:
            item['state'] = 'unsupported_attachment'
        elif not item['path']:
            item.update(state='missing', error='image not downloaded from iCloud')
        else:
            src = Path(item['path'])
            dest = run / f'image-{i}{src.suffix}'
            shutil.copyfile(src, dest)
            item.update(saved_file=dest.name, sha256=hashlib.sha256(dest.read_bytes()).hexdigest())
            item['state'] = 'ok'
            for name, flags in (('text', []), ('labels', ['--classify'])):
                try:
                    r = subprocess.run([str(HERE / 'vision-ocr'), str(dest), *flags],
                                       capture_output=True, text=True, timeout=120)
                    item[name] = r.stdout.strip()
                    item[name + '_stderr'] = r.stderr
                    item[name + '_returncode'] = r.returncode
                    if r.returncode:
                        item['state'] = 'error'
                except subprocess.TimeoutExpired:
                    item[name] = ''
                    item[name + '_error'] = 'Vision timed out after 120 seconds'
                    item['state'] = 'error'
        results.append(item)
        save_json(run / 'vision.json', results)
    save_json(run / 'vision.json', results)
    return results


def make_prompt(text, tag, vision):
    """The note IS the message: send it verbatim so the model talks to Esa about it.
    Images join as plain text he wrote on the page. Never add processing/report/label framing:
    2026-11-15 and 2026-11-17 "image evidence" wording turned every reply into a pipeline report."""
    import re
    text = re.sub(re.escape(tag) + r'(?![\w-])', '', text, flags=re.I).replace('\ufffc', '').strip()
    pictures = [v.get('text', '').strip() for v in vision if v.get('state') == 'ok' and v.get('text', '').strip()]
    if not pictures:
        return text
    chunks = [text]
    for i, ptext in enumerate(pictures, 1):
        name = 'my picture' if len(pictures) == 1 else f'my picture {i}'
        chunks.append(f'[Text from {name}:]\n{ptext}')
    chunks.append('(Talk with me about this as one thing: my note plus the picture. '
                  'Engage the idea itself; do not describe the picture or how it was read.)')
    return '\n\n'.join(chunks)
