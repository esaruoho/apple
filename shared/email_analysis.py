"""Durable exact-body mail analysis receipts, independent of any mail provider.

REPORT-CARD >> features/transcript-vault-email-analysis.feature
"""
from __future__ import annotations

import hashlib
import json
import os
import tempfile
from datetime import datetime, timezone
from pathlib import Path


def atomic_write(path: Path, content: str):
    fd, temp = tempfile.mkstemp(prefix='.analysis-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as out:
            out.write(content)
            out.flush()
            os.fsync(out.fileno())
        os.replace(temp, path)
    finally:
        if os.path.exists(temp):
            os.unlink(temp)


def prepare(source, text, *, recipient, subject, model, analyzed_text, origin=''):
    """Save the exact outgoing Markdown before send; metadata is a separate sidecar.

    The same composed answer for the same source and recipient has the same ID.
    Distinct answers remain separate records. A pending receipt is never proof of send.
    """
    source = Path(source).expanduser().absolute()
    data = source.read_bytes()
    sha = hashlib.sha256(data).hexdigest()
    key = json.dumps([sha, recipient, subject, text], ensure_ascii=False)
    run = hashlib.sha256(key.encode()).hexdigest()[:24]
    body = source.with_name(f'{source.stem}.email-{run}.analysis.md')
    receipt = body.with_suffix('.json')
    if receipt.exists():
        prior = json.loads(receipt.read_text())
        if prior.get('delivery') == 'sent' and body.exists() and body.read_text() == text:
            return receipt, prior
    meta = {
        'version': 1, 'run_id': run, 'source': str(source), 'source_sha256': sha,
        'body_sha256': hashlib.sha256(text.encode()).hexdigest(),
        'recipient': recipient, 'subject': subject, 'model': model,
        'origin': origin, 'delivery': 'pending',
        'composed_at': datetime.now(timezone.utc).isoformat(),
        'analyzed_chars': len(analyzed_text),
        'analyzed_sha256': hashlib.sha256(analyzed_text.encode()).hexdigest(),
    }
    atomic_write(body, text)
    atomic_write(receipt, json.dumps(meta, ensure_ascii=False, indent=2) + '\n')
    return receipt, meta


def delivered(receipt, meta, *, response=None, error=None):
    meta = dict(meta)
    meta['delivery'] = 'failed' if error else 'sent'
    meta['updated_at'] = datetime.now(timezone.utc).isoformat()
    if error:
        meta['error'] = str(error)
    elif isinstance(response, dict):
        for key in ('message_id', 'thread_id'):
            if response.get(key):
                meta[key] = response[key]
    atomic_write(Path(receipt), json.dumps(meta, ensure_ascii=False, indent=2) + '\n')
