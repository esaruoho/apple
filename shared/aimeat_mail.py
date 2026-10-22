"""Durable owner-email PDF jobs, drained by the existing Mini mail pane.

REPORT-CARD >> features/aimeat-email-pdf.feature
No inference or OCR is permitted in the laptop collector.
"""
import base64
import email.utils
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import socket
import subprocess
import tempfile
import time
import urllib.parse
import urllib.request

ROOT = Path(__file__).resolve().parents[1]
QUEUE = Path.home() / 'work/comms/queue/aimeat-mail-jobs'
RETURNS = Path.home() / 'work/comms/queue/aimeat-mail-results'
ROUNDTABLE_RETURNS = Path.home() / 'work/comms/queue/aimeat-roundtable-results'
FOLDER = Path.home() / 'work/merlib-dump/aimeat'


def mini():
    if socket.gethostname().split('.')[0].lower() not in {'cloudcity', 'cloudcitymacmini'}:
        raise RuntimeError('Email PDF processing is CloudcityMacMini-only')


def sha(data):
    return hashlib.sha256(data).hexdigest()


def atomic(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    if isinstance(data, str):
        data = data.encode()
    with tempfile.NamedTemporaryFile(dir=path.parent, delete=False) as f:
        f.write(data)
        temp = f.name
    os.replace(temp, path)


def save(path, value):
    atomic(path, json.dumps(value, ensure_ascii=False, indent=2))


def pdf_attachments(message):
    return [a for a in (message.get('attachments') or [])
            if (a.get('content_type') or '').lower() == 'application/pdf'
            or (a.get('filename') or '').lower().endswith('.pdf')]


def pdf_sources(message):
    sources = list(pdf_attachments(message))
    body = message.get('text') or message.get('extracted_text') or ''
    for url in dict.fromkeys(re.findall(r'https?://[^\s<>"\x27]+', body)):
        url = url.rstrip('.,);')
        path = urllib.parse.urlsplit(url).path
        if path.lower().endswith('.pdf'):
            sources.append({'filename': Path(path).name, 'source_url': url})
    return sources


def eligible(message, owners):
    return email.utils.parseaddr(message.get('from') or '')[1].lower() in owners and bool(pdf_sources(message))


def enqueue(message, queue=None):
    mini()
    queue = queue or QUEUE
    identity = sha(message['message_id'].encode())[:24]
    job = queue / identity
    job.mkdir(parents=True, exist_ok=True)
    if not (job / 'state.json').exists():
        save(job / 'email.json', message)
        save(job / 'state.json', {'id': identity, 'status': 'queued', 'created': time.time(),
                                 'assets': [], 'error': None, 'attempts': 0})
    return job


def publish(job, state, folder=None, returns=None):
    folder, returns = folder or FOLDER, returns or RETURNS
    destination = returns / state['id']
    files = []
    for name in state.get('files', []):
        path = folder / name
        data = path.read_bytes()
        atomic(destination / name, data)
        files.append({'name': name, 'sha256': sha(data)})
    save(destination / 'manifest.json', {'schema': 'aimeat-mail/1', 'id': state['id'],
                                       'status': state['status'], 'error': state.get('error'),
                                       'files': files})
    save(job / 'state.json', state)


def collect(folder, returns=None):
    """Hash-checked filing only; preserve local edits and reject unsafe paths."""
    count = 0
    for manifest in (returns or RETURNS).glob('*/manifest.json'):
        try:
            state = json.loads(manifest.read_text())
            if state['schema'] != 'aimeat-mail/1':
                continue
            receipt = folder / '.mail-imports' / (manifest.parent.name + '.json')
            previous = json.loads(receipt.read_text()) if receipt.exists() else {}
            imported = dict(previous)
            for entry in state['files']:
                name, digest = entry['name'], entry['sha256']
                if Path(name).name != name or name in {'.', '..', ''}:
                    continue
                data = (manifest.parent / name).read_bytes()
                if sha(data) != digest:
                    continue
                target = folder / name
                if target.is_symlink():
                    continue
                if target.exists():
                    current = sha(target.read_bytes())
                    if current == digest:
                        imported[name] = digest
                        continue
                    if current != previous.get(name):
                        continue  # a local edit or unrelated file: never overwrite it
                atomic(target, data)
                imported[name] = digest
                count += 1
            save(receipt, imported)
        except (OSError, ValueError, KeyError, TypeError):
            continue  # Syncthing can deliver a manifest before its blobs
    return count


def extract_pdf(path):
    mini()
    out = subprocess.run([str(ROOT / 'bin/mail-pdf-text'), str(path)],
                         capture_output=True, text=True, timeout=3600, check=True)
    # Framework diagnostics never become document text: the helper writes JSON to a file.
    return read_pdf_result(path)


def read_pdf_result(path):
    result = json.loads(Path(str(path) + '.pages.json').read_text())
    pages = result['pages']
    if len(pages) != result['page_count'] or [p['number'] for p in pages] != list(range(1, len(pages)+1)):
        raise RuntimeError('PDF page coverage is incomplete')
    if not any(p['text'].strip() for p in pages):
        raise RuntimeError('No readable PDF text; original retained for inspection')
    return '\n\n'.join(f"[Page {p['number']}; {p['method']}]\n{p['text']}" for p in pages), result


def chunks(text, size=8000):
    return [text[i:i+size] for i in range(0, len(text), size)]


def merge_mail_inputs(paths, stable_seconds=5, queue=None):
    """Let the existing Mini roundtable pane process email while the laptop sleeps."""
    sources = []
    for state_path in (queue or QUEUE).glob('*/state.json'):
        try:
            state = json.loads(state_path.read_text())
            for asset in state.get('assets', []):
                name = asset['text']
                if Path(name).name != name:
                    continue
                source = state_path.parent/'workspace'/name
                if source.is_file() and not source.is_symlink() and time.time()-source.stat().st_mtime >= stable_seconds:
                    sources.append(source)
        except (OSError, ValueError, KeyError, TypeError):
            continue
    # A later Syncthing copy in the archive is the same input, not a second job.
    identities = {(p.name, sha(p.read_bytes())) for p in sources}
    return [p for p in paths if (p.name, sha(p.read_bytes())) not in identities]+sources


def advance(agent, key, job, state, folder, returns):
    """One checkpointed step per poll; no background worker or new service."""
    message = json.loads((job / 'email.json').read_text())
    if state['status'] == 'queued':
        files, assets = [], []
        for index, att in enumerate(pdf_sources(message), 1):
            original = Path(att.get('filename') or f'document-{index}.pdf').name
            stem = re.sub('[^A-Za-z0-9_-]+', '-', Path(original).stem)[:70] or 'document'
            name = f"{stem}-{state['id'][:12]}-{index}.pdf"
            pdf = folder / name
            if not pdf.exists():
                if (att.get('size') or 0) > agent.MAX_ATT:
                    raise RuntimeError(f'{original}: exceeds attachment size limit; not read')
                if att.get('source_url'):
                    request = urllib.request.Request(att['source_url'], headers={'User-Agent': 'Cloudcity-AIMEAT/1'})
                    with urllib.request.urlopen(request, timeout=90) as response:
                        data = response.read(agent.MAX_ATT+1)
                else:
                    data = agent._att_bytes(key, message['message_id'], att['attachment_id'])
                if not data or len(data) > agent.MAX_ATT or not data.startswith(b'%PDF-'):
                    raise RuntimeError(f'{original}: invalid, empty or oversized PDF')
                atomic(pdf, data)
            state.setdefault('files', [])
            if name not in state['files']:
                state['files'].append(name)
            publish(job, state, folder, returns)
            if not Path(str(pdf)+'.pages.json').exists():
                text, coverage = extract_pdf(pdf)
            else:
                text, coverage = read_pdf_result(pdf)
            pieces = [text] if len(text.encode()) <= 1024*1024 else chunks(text, 200000)
            if len(pieces) > 1:
                full_text = pdf.with_suffix('.text.txt')  # excluded from automatic roundtable enrollment
                atomic(full_text, text)
                files.append(full_text.name)
            offset = 0
            for part, piece in enumerate(pieces, 1):
                txt = pdf.with_suffix('.txt') if len(pieces) == 1 else pdf.with_suffix(f'.part-{part:04}.txt')
                atomic(txt, piece)
                assets.append({'pdf': name, 'text': txt.name, 'sha256': sha(txt.read_bytes()),
                               'range': [offset, offset+len(piece)], 'page_count': coverage['page_count'],
                               'source_url': att.get('source_url'),
                               'empty_pages': [p['number'] for p in coverage['pages'] if not p['text'].strip()]})
                offset += len(piece)
                files.append(txt.name)
            files.extend([name, name+'.pages.json'])
        email_name = f"email-{state['id']}.json"
        atomic(folder / email_name, (job / 'email.json').read_bytes())
        state.update(assets=assets, files=list(dict.fromkeys(files+[email_name])), status='reading', reads=[], next_part=0)
    elif state['status'] == 'reading':
        parts = [(a, i, part) for a in state['assets']
                 for i, part in enumerate(chunks((folder/a['text']).read_text()), 1)]
        index = state['next_part']
        if index < len(parts):
            asset, number, part = parts[index]
            answer, model = agent._fm_call([
                {'role': 'system', 'content': agent.CHAPTER_SYSTEM},
                {'role': 'user', 'content': f"{asset['text']} — part {number}\n\n{part}"}],
                max_tokens=1800, temperature=0.2)
            if not answer.strip() or agent._has_leak(answer) or agent._is_reasoning_dump(answer):
                raise RuntimeError(f'Unusable read for part {index+1}; will retry')
            state['reads'].append({'source': asset['text'], 'part': number, 'analysis': answer, 'model': model})
            state['next_part'] += 1
        else:
            state['synthesis'] = ['\n\n'.join(f"{r['source']} part {r['part']}\n{r['analysis']}" for r in state['reads'])]
            state['status'] = 'synthesis'
    elif state['status'] == 'synthesis':
        text = '\n\n'.join(state['synthesis'])
        if len(text) > 10000:
            # Reduce every portion, saving all primary reads. No first-N-parts cap.
            level = state.setdefault('reduce', {'parts': chunks(text), 'done': []})
            index = len(level['done'])
            if index < len(level['parts']):
                answer, model = agent._fm_call([
                    {'role': 'system', 'content': agent.ACROSS_SYSTEM},
                    {'role': 'user', 'content': level['parts'][index]}], max_tokens=1000, temperature=0.2)
                if not answer.strip() or agent._has_leak(answer) or agent._is_reasoning_dump(answer):
                    raise RuntimeError('Unusable synthesis; will retry')
                level['done'].append(answer)
            else:
                reduced = '\n\n'.join(level['done'])
                if len(reduced) >= len(text):
                    raise RuntimeError('Synthesis did not reduce; all primary reads retained')
                state.setdefault('synthesis_levels', []).append(level['done'])
                state['synthesis'] = level['done']
                del state['reduce']
        else:
            question = message.get('text') or message.get('extracted_text') or message.get('subject') or 'Analyze this PDF'
            route = question+'\n'+text
            context, slugs = agent.wiki_context(route)
            space, why = agent.route_space(message.get('from'), message.get('subject'), route, slugs)
            answer, model = agent.research_email_material(question, '', text, space=space, wiki_ctx=context)
            if agent._is_requeue(answer):
                raise RuntimeError('Final analysis not sendable; primary reads retained')
            details = '\n\n'.join(f"## {r['source']} · part {r['part']}\n\n{r['analysis']}" for r in state['reads'])
            coverage = '\n'.join(f"- {a['pdf']}: {a['page_count']} pages; pages with no recognized text: {a['empty_pages']}" for a in state['assets'])
            body = ('# Email PDF analysis\n\nAnalysis types: full-text section readings; archive-grounded synthesis; '
                    'nine-person Qwen/MLX roundtable (separate transcript); wordcloud.\n\n'
                    'AI-generated interpretations are separate from source evidence.\n\n'
                    f'## Extraction coverage\n\n{coverage}\n\n## Synthesis\n\n{answer}\n\n# Section readings\n\n{details}')
            name = f"email-{state['id']}.analysis.md"
            atomic(folder/name, body)
            atomic(job/'base-analysis.md', body)
            state.update(analysis=name, model=model, space=space, status='roundtable')
            state['files'].append(name)
    elif state['status'] == 'roundtable':
        transcripts = []
        for asset in state['assets']:
            source = folder / asset['text']
            status_path = Path(str(source)+'.roundtable.json')
            # The laptop is the sole writer in the send-only archive. The Mini
            # consumes its canonical result channel, not a beside-source copy.
            candidates = []
            for path in ROUNDTABLE_RETURNS.glob('*/state.json'):
                try:
                    result = json.loads(path.read_text())
                    if result.get('source') == asset['text'] and result.get('sha256') == asset['sha256']:
                        candidates.append((result.get('created', 0), path, result))
                except (OSError, ValueError):
                    continue
            canonical = max(candidates, key=lambda item: item[0]) if candidates else None
            if canonical:
                _, status_path, result = canonical
            elif status_path.exists():
                result = json.loads(status_path.read_text())
            else:
                return
            if result.get('sha256') != asset['sha256']:
                raise RuntimeError('Roundtable source hash mismatch')
            if result['status'] == 'failed':
                raise RuntimeError('Roundtable failed; inspect its status before retrying')
            if result['status'] != 'complete':
                return
            transcript = status_path.parent/'transcript.md' if canonical else Path(str(source)+'.roundtable.md')
            if sha(transcript.read_bytes()) != result['result_sha256']:
                return
            if canonical:
                data = transcript.read_bytes()
                transcript = Path(str(source)+'.roundtable.md')
                atomic(transcript, data)
                status_path = Path(str(source)+'.roundtable.json')
                save(status_path, result)
            transcripts.append(transcript)
            for path in (transcript, status_path):
                if path.name not in state['files']:
                    state['files'].append(path.name)
            cloud = source.with_suffix('.wordcloud.png')
            if not cloud.exists():
                try:
                    subprocess.run([str(Path.home()/'work/convey/bin/convey'), 'wordcloud', str(source),
                                    '--out', str(cloud), '--no-open'], check=True, capture_output=True, timeout=180)
                except Exception as error:
                    state['wordcloud_error'] = str(error)
            if cloud.exists() and cloud.name not in state['files']:
                state['files'].append(cloud.name)
        analysis = (job/'base-analysis.md').read_text()
        analysis += '\n\n# Roundtables\n\n'+'\n\n'.join(p.read_text() for p in transcripts)
        if state.get('wordcloud_error'):
            analysis += '\n\nWordcloud generation failed: '+state['wordcloud_error']
        atomic(folder/state['analysis'], analysis)
        state['status'] = 'ready-to-send'
    elif state['status'] in {'ready-to-send', 'failure-ready-to-send'}:
        failed = state['status'] == 'failure-ready-to-send'
        if failed:
            body = ('AIMEAT could not complete this PDF job. No complete analysis is claimed.\n\n'
                    f"Job: {state['id']}\nError: {state['failure']}\n"
                    f"Saved files in merlib-dump/aimeat: {', '.join(state.get('files', []))}\n\n"
                    'Analysis types requested: section readings, archive-grounded synthesis, '
                    'nine-person roundtable and wordcloud. Completed checkpoints are retained for recovery.')
        else:
            body = (folder/state['analysis']).read_text()
        payload = {'text': body, 'html': agent.md_to_html(body), 'attachments': []}
        for name in state['files']:
            if name.endswith(('.pdf', '.analysis.md', '.wordcloud.png')):
                data = (folder/name).read_bytes()
                if len(data) <= 15*1024*1024:
                    kind = 'application/pdf' if name.endswith('.pdf') else ('image/png' if name.endswith('.png') else 'text/markdown')
                    payload['attachments'].append({'filename': name, 'content_type': kind,
                                                   'content': base64.b64encode(data).decode()})
        # A timeout can mean AgentMail accepted the message. Never resend automatically.
        state['status'] = 'sending-unconfirmed'
        publish(job, state, folder, returns)
        response = agent.send_inbox_reply(key, message['message_id'], payload)
        state.update(status='failed-notified' if failed else 'complete', sent=time.time(), response=response)


def process_pending(agent, key, queue=None, folder=None, returns=None):
    mini()
    queue = queue or QUEUE
    queue.mkdir(parents=True, exist_ok=True)
    with (queue/'.worker.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            return
        return _process_pending(agent, key, queue, folder, returns)


def _process_pending(agent, key, queue, folder, returns):
    returns = returns or RETURNS
    paths = list(queue.glob('*/state.json'))
    for path in sorted(paths, key=lambda p: json.loads(p.read_text()).get('serviced', 0)):
        state = json.loads(path.read_text())
        if state['status'] in {'complete', 'sending-unconfirmed', 'failed', 'failed-notified'} or state.get('retry_after', 0) > time.time():
            continue
        workspace = folder or path.parent/'workspace'
        workspace.mkdir(parents=True, exist_ok=True)
        try:
            advance(agent, key, path.parent, state, workspace, returns)
            state['error'] = None
            state['attempts'] = 0
        except Exception as error:
            state['error'] = str(error)
            state['attempts'] += 1
            state['retry_after'] = time.time()+60*state['attempts']
            if state['attempts'] >= 3 and state['status'] != 'sending-unconfirmed':
                state['resume_status'] = state['status']
                state['failure'] = str(error)
                state['status'] = 'failure-ready-to-send'
            print(f"AIMEAT PDF {state['id']}: {state['error']}", flush=True)
        publish(path.parent, state, workspace, returns)
        state['serviced'] = time.time()
        save(path, state)
        break  # bounded work per poll; oldest serviced job is next
