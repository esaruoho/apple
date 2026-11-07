"""Shared AgentMail send/reply policy. Never retry ambiguous network failures.
REPORT-CARD >> ~/work/convey/features/mail-consolidation.feature
"""
from __future__ import annotations
import json
import os
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path
from html.parser import HTMLParser
from dataclasses import replace
from format_email import MailContent

DEFAULT_INBOX = "cloudcity-llm@agentmail.to"
AM_BASE = "https://api.agentmail.to/v0"


def _key():
    env = os.environ.get("AGENTMAIL_API_KEY")
    kp = Path.home() / ".agentmail.key"
    return env.strip() if env else kp.read_text().strip() if kp.exists() else None


def _default_html(text):
    from format_email import render_email
    return render_email(text)


class _Document(HTMLParser):
    def __init__(self):
        super().__init__(); self.html = self.body = self.theme = 0; self.closed = False
    def handle_starttag(self, tag, attrs):
        if self.closed: raise ValueError("content after HTML closure")
        data = dict(attrs)
        if tag == "html": self.html += 1
        if tag == "body": self.body += 1
        if tag == "meta" and data.get("name") == "color-scheme" and data.get("content") == "dark": self.theme += 1
        if tag in {"script", "iframe", "object"} or any(k.startswith("on") for k in data):
            raise ValueError("active HTML is not supported")
        for key in ("href", "src"):
            if key in data and urllib.parse.urlsplit(data[key]).scheme.lower() not in {"http", "https", "mailto", "cid"}:
                raise ValueError("unsafe HTML URL")
    def handle_endtag(self, tag):
        if tag == "html": self.closed = True
    def handle_data(self, data):
        if self.closed and data.strip(): raise ValueError("content after HTML closure")


def canonical_document(document):
    """Compatibility hatch for source-owned canonical wrappers, never inbound HTML.

    New callers should supply MailContent. Existing complex report components retain
    their canonical document until migrated; bare fragments/documents fail closed.
    """
    check = _Document(); check.feed(document); check.close()
    if (check.html, check.body, check.theme, check.closed) != (1, 1, 1, True) or "max-width:760px" not in document:
        raise ValueError("explicit HTML must use the canonical email wrapper")
    return document


def _post(url, key, payload, timeout):
    req = urllib.request.Request(url, data=json.dumps(payload).encode(), method="POST",
          headers={"Authorization": "Bearer "+key, "Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=timeout) as response:
        if response.status not in (200,201,202): raise RuntimeError("AgentMail status "+str(response.status))
        raw = response.read().decode()
        result = json.loads(raw) if raw.strip() else {}
        if not isinstance(result, dict): raise ValueError("invalid AgentMail response")
        return result


def send_message(content, *, subject="", to=None, cc=None, bcc=None, inbox=None,
                 message_id=None, key=None, base=None, timeout=60, canonical_html=None):
    """Raises on failure; returns only the actual endpoint response on success.

    /reply intentionally omits /send-only subject/to fields. Only an explicit 413
    permits one reduction attempt. All omitted filenames are reported in both bodies.
    Original content/attachments are never mutated. No retry for ambiguous failures.
    """
    key = key or _key()
    if not key: raise RuntimeError("no AgentMail key")
    inbox = inbox or os.environ.get("AGENTMAIL_INBOX") or DEFAULT_INBOX
    prefix = (base or AM_BASE)+"/inboxes/"+urllib.parse.quote(inbox,safe="")+"/messages/"
    url = prefix+(urllib.parse.quote(message_id,safe="")+"/reply" if message_id else "send")
    metadata = {} if message_id else {"subject":subject,"to":[to] if isinstance(to,str) else list(to or [])}
    for name, value in (("cc",cc),("bcc",bcc)):
        if value: metadata[name] = [value] if isinstance(value,str) else list(value)
    for attachment in content.attachments:
        if not attachment.get("filename") or not attachment.get("content"):
            raise ValueError("missing attachment filename or content")
    payload = {**metadata, **content.payload()}
    if canonical_html is not None: payload["html"] = canonical_document(canonical_html)
    try:
        return _post(url,key,payload,timeout)
    except urllib.error.HTTPError as error:
        if error.code != 413 or not content.attachments: raise
    names = ", ".join(a["filename"] for a in content.attachments)
    warning = "Delivery warning: the email service rejected the payload size. Attachments omitted: "+names+". Original inbound attachments remain in the original email, where applicable."
    # This exact generated receipt is the only attachment-success claim we own.
    markdown = content.markdown.replace("Here's the printable one-pager of the previous answer — attached. Same content, just formatted.",
                                        "The printable PDF could not be attached because of the email service size limit.")
    reduced = replace(content, markdown=markdown, attachments=[], notices=[*content.notices,warning])
    return _post(url,key,{**metadata, **reduced.payload()},timeout)


def reply_to_message(message_id, content, **kwargs):
    return send_message(content,message_id=message_id,**kwargs)


def agentmail_send(subject, text, to, *, cc=None, bcc=None, inbox=None, html=None,
                   attachments=None, timeout=60, quiet=False, content=None):
    """Backward-compatible fresh sender: dict on success, None on explicit failure."""
    try:
        return send_message(content or MailContent(text,attachments=list(attachments or []),title=subject),
                            subject=subject,to=to,cc=cc,bcc=bcc,inbox=inbox,
                            canonical_html=html,timeout=timeout)
    except Exception as error:
        if not quiet: print("agentmail_send: delivery failed:",error)
        return None
