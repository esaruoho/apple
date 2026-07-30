#!/usr/bin/env python3
"""fm_think — separate a reasoning model's THINKING from its ANSWER, once, for every caller.

Reasoning models (Qwen3 via mlx_lm.server, DeepSeek-R1, …) emit two different things and only
one of them is speech. The thinking is deliberation — it is *supposed* to read like
"wait, hold on, let me re-read that" — and it must never reach a human. The answer is the
only thing a user sees.

Two failure modes this module exists to kill:

  1. **Key roulette.** mlx_lm.server 0.31 returns the trace under `message.reasoning`; other
     builds use `message.reasoning_content`; some models inline it as `<think>…</think>` inside
     `content`. A caller that does `content or reasoning` publishes the trace whenever `content`
     is missing. Never chain them with `or`. `answer_of()` reads ONLY answer-bearing fields.

  2. **Truncated mid-think.** When max_tokens runs out before `</think>` closes, there is no
     answer at all — `content` is absent and the whole budget is a think block. That is an
     ERROR (`finish_reason == "length"`), not an answer. `split()` reports it as such so the
     caller can retry or say "I couldn't draft an answer" instead of vomiting the trace.

The thinking is still valuable — it shows HOW the bot reasons, so it can be corrected. So it is
never dropped, it is FILED: `log(...)` appends it to a JSONL on the Mini under the Syncthing
share, readable from any peer.

    from fm_think import split, log
    answer, thinking, meta = split(payload)      # answer is None when it only thought
    log(thinking, question=q, meta=meta)         # files it; never prints it

# FEATURE-CARD >> features/fm-think-no-leak.feature
"""
import json
import os
import re
import time
from pathlib import Path

__all__ = ["split", "strip_think", "log", "looks_like_thinking", "THINK_LOG"]

# Where filed thinking lands. Under comms/queue → Syncthing-mirrored off the Mini, so a trace
# produced by the Mini's bot is readable on the laptop with no SSH.
THINK_LOG = Path(os.environ.get(
    "FM_THINK_LOG",
    str(Path.home() / "work" / "comms" / "queue" / "paketti-faq" / "thinking.jsonl")))

_THINK_TAGS = r"think|thought|reasoning|scratchpad"
# A closed inline block: <think>…</think>
_CLOSED = re.compile(rf"<({_THINK_TAGS})\b[^>]*>(.*?)</\1>", re.S | re.I)
# An OPEN block that never closed (truncated mid-think) — everything after it is trace.
_OPEN = re.compile(rf"<({_THINK_TAGS})\b[^>]*>(.*)\Z", re.S | re.I)
# A stray close tag with no open (server already ate the opener, common with mlx streaming).
_STRAY_CLOSE = re.compile(rf"\A(.*?)</({_THINK_TAGS})>", re.S | re.I)

# Backtracking tics that only ever appear in deliberation, never in a delivered answer.
_TIC = re.compile(
    r"(?i)\b(wait,?\s+(no|hold on|let'?s|what|maybe|but|the user|is there|did i)|"
    r"hold on[,.]|let'?s re-?read|let me re-?read|re-?read the user|"
    r"okay,?\s+(so\s+)?the user (said|is asking|wants|asked)|"
    r"first,?\s+let'?s (check|see|look)|oh! wait|wait wait)\b")


def strip_think(text):
    """Remove every thinking block from a text, returning (answer, thinking).

    Handles closed `<think>…</think>`, an unclosed `<think>…` tail (truncation), and a stray
    `</think>` with no opener. `answer` is "" when the text was nothing but thinking."""
    if not text:
        return "", ""
    thinking = []

    def _grab(m):
        thinking.append(m.group(2))
        return ""

    out = _CLOSED.sub(_grab, text)
    m = _STRAY_CLOSE.match(out)
    if m:                                   # opener eaten by the server; head is the trace
        thinking.append(m.group(1))
        out = out[m.end():]
    m = _OPEN.search(out)
    if m:                                   # never closed → the rest is trace, no answer in it
        thinking.append(m.group(2))
        out = out[:m.start()]
    return out.strip(), "\n\n".join(t.strip() for t in thinking if t and t.strip()).strip()


def looks_like_thinking(text) -> bool:
    """True when a text is plainly a deliberation trace even with no tags — the last line of
    defense for a model that emits raw thinking with the tags stripped upstream. Requires two
    distinct backtracking tics so a normal answer that happens to say "wait" isn't nuked."""
    if not text:
        return False
    return len(set(m.group(0).lower() for m in _TIC.finditer(text))) >= 2


def split(payload):
    """Split an OpenAI-shaped chat-completion payload into (answer, thinking, meta).

    `answer` is None when the model produced no answer — either it spent the whole budget
    thinking (`meta["truncated_in_think"]`) or the response carried no answer field at all.
    Answer-bearing fields ONLY; `reasoning`/`reasoning_content` are collected as thinking and are
    never promoted to the answer."""
    if isinstance(payload, (str, bytes)):
        payload = json.loads(payload)
    choice = (payload.get("choices") or [{}])[0]
    msg = choice.get("message") or {}
    finish = choice.get("finish_reason")

    raw = msg.get("content") or choice.get("text") or payload.get("content") or ""
    answer, inline = strip_think(raw)
    # The server-side split fields are THINKING. Never an answer, no matter how empty content is.
    served = [msg.get("reasoning_content") or "", msg.get("reasoning") or "", inline]
    thinking = "\n\n".join(t.strip() for t in served if t and t.strip()).strip()

    if answer and looks_like_thinking(answer):
        thinking = (thinking + "\n\n" + answer).strip()
        answer = ""

    meta = {
        "finish_reason": finish,
        "model": payload.get("model"),
        "usage": payload.get("usage") or {},
        # No answer + hit the token ceiling = it ran out of budget inside the think block.
        "truncated_in_think": bool(not answer and thinking and finish == "length"),
    }
    return (answer or None), thinking, meta


def log(thinking, question="", meta=None, source="fm-mlx", path=None):
    """File a thinking trace as one JSONL line. Best-effort: never raises, never prints — a
    logging failure must not take down an answer. Returns True when it was written."""
    if not thinking:
        return False
    rec = {"ts": time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime()),
           "source": source, "question": (question or "")[:4000],
           "chars": len(thinking), "thinking": thinking[:60000]}
    rec.update(meta or {})
    p = Path(path or THINK_LOG)
    try:
        p.parent.mkdir(parents=True, exist_ok=True)
        with open(p, "a", encoding="utf-8") as fh:
            fh.write(json.dumps(rec, ensure_ascii=False) + "\n")
        return True
    except Exception:
        return False
