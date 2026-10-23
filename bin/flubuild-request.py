#!/usr/bin/env python3
"""Bound a Flubuild request using the server's own tokenizer before generation."""
import json
import sys
import urllib.error
import urllib.request

BASE = "http://127.0.0.1:8000"


def prepare(body, rpc):
    models = rpc("/v1/models")["data"]
    model = next((item for item in models if item["id"] == body["model"]), None)
    if model is None:
        raise ValueError("Requested model is not served: " + body["model"])
    limit = model.get("max_model_len")
    if not limit:
        return body, ""
    body = dict(body, messages=[dict(message) for message in body["messages"]])
    budget = int(limit) - int(body["max_tokens"])
    if budget <= 0:
        raise ValueError(f"Reply allowance {body['max_tokens']} leaves no input space in the {limit}-token context.")

    def count(messages):
        return rpc("/tokenize", {"model": body["model"], "messages": messages,
                                 "add_generation_prompt": True})["count"]

    messages = body["messages"]
    if count(messages) > budget:
        raise ValueError("Complete prompt exceeds Flubuild context; refusing a partial analysis.")
    return body, ""


def main():
    timeout = float(sys.argv[1])

    def rpc(path, payload=None):
        data = json.dumps(payload).encode() if payload is not None else None
        request = urllib.request.Request(BASE + path, data=data,
                                         headers={"Content-Type": "application/json"})
        with urllib.request.urlopen(request, timeout=timeout) as response:
            return json.load(response)

    try:
        body, note = prepare(json.load(sys.stdin), rpc)
        reply = rpc("/v1/chat/completions", body)
        if note:
            reply["fm_context_note"] = note
        print(json.dumps(reply))
    except urllib.error.HTTPError as error:
        detail = error.read().decode(errors="replace")[:6000]
        print(f"Flubuild HTTP {error.code}: {detail}", file=sys.stderr)
        return 1
    except Exception as error:
        print(f"Flubuild request failed: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
