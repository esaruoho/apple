"""The reasoning binding + vote-to-judge.

The ONLY place the harness spends LLM tokens — and it never sees raw bytes,
only the entity list and a tiny curated snippet. The reasoning command is
bound in config: `fm` locally (macOS 26), or `fmremote` (routes to the Mini)
for a machine without local FoundationModels.

FoundationModels is non-deterministic and rationalises both ways, so a single
call is never a judge: we sample N times and take the majority, reporting k/N
and flagging ties. This is the same discipline `convey graph judge` encodes,
generalised so the scaffold needs no convey.
"""
from __future__ import annotations

import shlex
import subprocess
from collections import Counter


def _ask(cmd: list[str], prompt: str, timeout: int) -> str:
    try:
        res = subprocess.run(
            cmd + [prompt],
            capture_output=True,
            text=True,
            timeout=timeout,
        )
    except FileNotFoundError:
        raise RuntimeError(f"reasoning organ not found: {cmd[0]}")
    except subprocess.TimeoutExpired:
        raise RuntimeError(f"reasoning timed out ({timeout}s)")
    if res.returncode != 0:
        raise RuntimeError(f"{cmd[0]} exited {res.returncode}: {res.stderr.strip()[:200]}")
    return res.stdout.strip()


def _normalise_tags(raw: str) -> tuple[str, ...]:
    tags = [t.strip().lower() for t in raw.replace("\n", ",").split(",")]
    tags = [t for t in tags if t and len(t) < 40]
    return tuple(sorted(set(tags)))


def judge(cfg_reasoning: dict, entities: list[dict], snippet: str) -> dict:
    """Run the reasoning step N times, take the majority.

    Returns {"tags": [...], "vote": "k/N", "flip_flop": bool, "samples": [...]}.
    """
    cmd = shlex.split(cfg_reasoning["cmd"])
    votes = int(cfg_reasoning.get("votes", 3))
    timeout = int(cfg_reasoning.get("timeout", 120))
    nchars = int(cfg_reasoning.get("snippet_chars", 1000))

    ent_str = ", ".join(e["text"] for e in entities) or "(none)"
    prompt = cfg_reasoning["prompt"].format(
        entities=ent_str,
        snippet=snippet[:nchars],
    )

    samples: list[tuple[str, ...]] = []
    raw_samples: list[str] = []
    for _ in range(votes):
        raw = _ask(cmd, prompt, timeout)
        raw_samples.append(raw)
        samples.append(_normalise_tags(raw))

    counter = Counter(samples)
    (winner, n), *rest = counter.most_common()
    flip_flop = bool(rest and rest[0][1] == n)  # tie at the top
    return {
        "tags": list(winner),
        "vote": f"{n}/{votes}",
        "flip_flop": flip_flop,
        "samples": raw_samples,
    }
