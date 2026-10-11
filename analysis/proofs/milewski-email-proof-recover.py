"""Bounded recovery client; run on Cloudcity, never as a daemon."""
import hashlib, importlib.machinery, importlib.util, json, pathlib
loader=importlib.machinery.SourceFileLoader("mail_agent", "/Users/esaruoho/work/apple/bin/freellmask-mail")
spec=importlib.util.spec_from_loader(loader.name,loader)
a=importlib.util.module_from_spec(spec); loader.exec_module(a)
mid="<9C9858D8-8902-4D35-811B-CECB16D2CC2C@gmail.com>"
k=a.am_key()
full=a.http(f"{a.AM_BASE}/inboxes/{a.INBOX}/messages/{a.enc(mid)}",k)
listing=a.http(f"{a.AM_BASE}/inboxes/{a.INBOX}/messages?limit=100",k)
if any("sent" in m.get("labels",[]) and m.get("thread_id")==full["thread_id"] for m in listing["messages"]):
    raise SystemExit("Existing reply found; recovery suppressed")
att=full["attachments"][0]
raw=a._att_bytes(k,mid,att["attachment_id"])
assert hashlib.sha256(raw).hexdigest()=="1e19b0a6ca62ee45c94f1c3b78eaa662383dac375b6715d2b4b7436e31c9b96c"
name,text=a._extract_one(k,mid,att)
assert len(text)>10000, (name,len(text))
question="Analyze this attached John Milewski PDF. Identify title and author, explain the proposed reservoir and coupling mechanism, supporting observations, and distinguish the author's claims from inference. Cite evidence from the beginning and end where present."
answer,model=a.fm_research(question,"",text,tries=2)
assert not a._is_requeue(answer), "Model output failed quality gate"
root=pathlib.Path('/Users/esaruoho/work/comms/queue/findersearch-ocr/1e19b0a6ca62ee45c94f1c3b78eaa662383dac375b6715d2b4b7436e31c9b96c')
root.joinpath('email-proof-analysis.md').write_text(answer)
reply={"text":answer,"html":a.md_to_html(answer),"attachments":a.inbound_atts_b64(k,mid,[att])}
result=a.send_inbox_reply(k,mid,reply)
receipt={"model":model,"source_sha256":hashlib.sha256(raw).hexdigest(),"extracted_chars":len(text),"reply":result,"inbound_message_id":mid,"thread_id":full['thread_id']}
root.joinpath('email-proof-receipt.json').write_text(json.dumps(receipt,indent=2))
print(json.dumps(receipt,indent=2))
