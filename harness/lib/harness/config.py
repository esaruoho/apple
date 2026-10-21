"""Config loading for the Apple Harness.

The config format is a **property list** — the Apple-native, stdlib-parseable
(`plistlib`) format, so the whitelabeled scaffold has ZERO third-party
dependencies (no PyYAML, no Homebrew, no pip). "Like Apple would make it."

A config binds the generic engine to concrete leaf tools. The scaffold ships
`config.example.plist` with LOCAL, Apple-native reference organs (vision-ocr,
apple-ner, apple-embed, fm) so a stranger with no fleet can run it on one Mac.
A private instance (e.g. `harken`) overrides the bindings — reasoning → fmremote
(the Mini), OCR → an async queue, vault → its own path — without editing engine
code.
"""
from __future__ import annotations

import os
import plistlib
from pathlib import Path

# The engine's built-in defaults. Every key here is overridable by the plist.
# These defaults are LOCAL and Apple-native: they run on one Mac, no network.
DEFAULTS: dict = {
    "vault": "~/AppleHarnessVault",        # where Asset Notes are written
    "embeds": "~/.apple-harness-embeds.jsonl",  # the semantic-memory store
    "bin_dir": "",                          # prefix for organ commands ("" = use PATH)
    "modalities": {
        # extension (lowercased, with dot) -> modality name
        ".png": "image", ".jpg": "image", ".jpeg": "image", ".tiff": "image",
        ".tif": "image", ".gif": "image", ".bmp": "image", ".heic": "image",
        ".pdf": "pdf",
        ".mp3": "audio", ".m4a": "audio", ".wav": "audio", ".aiff": "audio",
        ".aif": "audio", ".flac": "audio",
        ".mp4": "video", ".mov": "video", ".m4v": "video",
        ".txt": "text", ".md": "text", ".markdown": "text", ".text": "text",
    },
    "organs": {
        # modality -> extraction command. {path} is the absolute source path.
        # All reference organs are LOCAL and synchronous.
        "image": "vision-ocr {path}",
        "pdf": "vision-ocr {path}",
        "audio": "whisp {path}",     # the one non-Apple leaf (OpenAI Whisper);
        "video": "whisp {path}",     # ideal would be SFSpeechRecognizer.
        "text": "",                  # "" = read the file directly, no subprocess
    },
    "ner": "apple-ner",              # stdin text -> JSONL entities (Apple NaturalLanguage)
    "embed": "apple-embed",          # stdin lines -> JSONL {"t","v":[512]} (Apple NLEmbedding)
    "reasoning": {
        "enabled": True,
        "cmd": "fm",                 # LOCAL Apple FoundationModels (macOS 26).
                                     # A private instance overrides -> "fmremote".
        "votes": 3,                  # majority-vote: the model flip-flops.
        "timeout": 120,
        "snippet_chars": 1000,       # how much extract text the LLM may see.
        "prompt": (
            "You are tagging one asset for a knowledge archive. "
            "Named entities found: {entities}. "
            "Excerpt (do not quote it back): {snippet}. "
            "Reply with 1-5 lowercase topical tags, comma-separated, nothing else."
        ),
    },
}


def _expand(value):
    if isinstance(value, str):
        return os.path.expanduser(value)
    return value


def _deep_merge(base: dict, over: dict) -> dict:
    out = dict(base)
    for k, v in over.items():
        if isinstance(v, dict) and isinstance(out.get(k), dict):
            out[k] = _deep_merge(out[k], v)
        else:
            out[k] = v
    return out


class Config:
    """Resolved harness configuration — defaults deep-merged with a plist."""

    def __init__(self, data: dict):
        self._d = data

    @classmethod
    def load(cls, plist_path: str | None) -> "Config":
        data = DEFAULTS
        if plist_path:
            p = Path(os.path.expanduser(plist_path))
            if not p.exists():
                raise FileNotFoundError(f"config plist not found: {p}")
            with open(p, "rb") as f:
                over = plistlib.load(f)
            data = _deep_merge(DEFAULTS, over)
        return cls(data)

    # --- resolved accessors -------------------------------------------------
    @property
    def vault(self) -> Path:
        return Path(_expand(self._d["vault"]))

    @property
    def embeds(self) -> Path:
        return Path(_expand(self._d["embeds"]))

    @property
    def modalities(self) -> dict:
        return self._d["modalities"]

    def organ_cmd(self, modality: str) -> str:
        return self._d["organs"].get(modality, "")

    def _bin(self, cmd: str) -> str:
        """Prefix a bare organ command with bin_dir, if configured."""
        bd = _expand(self._d.get("bin_dir") or "")
        if not bd or not cmd:
            return cmd
        head, _, tail = cmd.partition(" ")
        return f"{os.path.join(bd, head)}{(' ' + tail) if tail else ''}"

    def ner_cmd(self) -> str:
        return self._bin(self._d["ner"])

    def embed_cmd(self) -> str:
        return self._bin(self._d["embed"])

    def organ_resolved(self, modality: str) -> str:
        return self._bin(self.organ_cmd(modality))

    @property
    def reasoning(self) -> dict:
        r = dict(self._d["reasoning"])
        r["cmd"] = self._bin(r["cmd"])
        return r

    def modality_for(self, path: str) -> str | None:
        ext = os.path.splitext(path)[1].lower()
        return self._d["modalities"].get(ext)
