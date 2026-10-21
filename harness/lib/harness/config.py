"""Config loading for the Apple Harness.

The config format is a **property list** — the Apple-native, stdlib-parseable
(`plistlib`) format, so the whitelabeled scaffold has ZERO third-party
dependencies (no PyYAML, no Homebrew, no pip). "Like Apple would make it."

Capabilities, not commands. Each capability (ocr/transcribe/ner/embed/reason)
declares how to run it LOCALLY (gated by a preflight that must prove it is
already installed, no download) and optionally on a FLEET belt (gated by a
heartbeat). The resolver (`capabilities.py`) picks a provider or errors — it
never silently downloads a model to "run it locally". See that module.

The whitelabel defaults below are honest for a stranger on ONE Mac: OS-shipped
ANE organs are local; whisp-transcribe is local but gated on the model being
ALREADY present (absent → a clear error, never a download); fm-reason is local
only on macOS 26. A private instance (harken) adds the fleet providers that
point heavy work at a Mini.
"""
from __future__ import annotations

import os
import plistlib
from pathlib import Path

# A preflight that proves whisp's large model is ALREADY cached (never triggers
# a download). A fresh machine fails this → transcribe routes to a belt or errors.
_WHISP_MODEL_PRESENT = (
    'test -d "$HOME/.cache/huggingface/hub/models--mlx-community--whisper-large-v3-mlx"'
)
# fm (FoundationModels) only runs locally on macOS 26+ (Tahoe).
_FM_LOCAL_OK = '[ "$(sw_vers -productVersion | cut -d. -f1)" -ge 26 ]'

DEFAULTS: dict = {
    "vault": "~/AppleHarnessVault",
    "embeds": "~/.apple-harness-embeds.jsonl",
    "bin_dir": "",                          # prefix for organ commands ("" = PATH)
    # filenames ending in these are harness-produced artifacts (e.g. a belt's
    # transcript written beside the source) — never scanned as new assets.
    "scan_ignore": [".transcript.txt", ".speakers.txt"],
    "modalities": {
        ".png": "image", ".jpg": "image", ".jpeg": "image", ".tiff": "image",
        ".tif": "image", ".gif": "image", ".bmp": "image", ".heic": "image",
        ".pdf": "pdf",
        ".mp3": "audio", ".m4a": "audio", ".wav": "audio", ".aiff": "audio",
        ".aif": "audio", ".flac": "audio",
        ".mp4": "video", ".mov": "video", ".m4v": "video",
        ".txt": "text", ".md": "text", ".markdown": "text", ".text": "text",
    },
    # which capability extracts each modality ("text" reads directly, no organ)
    "modality_capability": {
        "image": "ocr", "pdf": "ocr",
        "audio": "transcribe", "video": "transcribe",
        "text": "",          # "" = read the file directly, no organ, no capability
    },
    "capabilities": {
        # OS-shipped, Neural-Engine, no model download — always local.
        "ocr": {
            "local_cmd": "vision-ocr {path}",
            "local_preflight": "",           # "" = always available
            "prefer": "local",
            "on_unavailable": "error",
        },
        "ner": {
            "local_cmd": "apple-ner",
            "local_preflight": "",
            "prefer": "local",
            "on_unavailable": "error",
        },
        "embed": {
            "local_cmd": "apple-embed",
            "local_preflight": "",
            "prefer": "local",
            "on_unavailable": "error",
        },
        # HEAVY. Local whisp is gated on the model already being present, so it
        # can NEVER trigger a download. A stranger with the model uses it; one
        # without it gets an error (install explicitly). harken adds a fleet belt.
        "transcribe": {
            "local_cmd": "whisp {path}",
            "local_preflight": _WHISP_MODEL_PRESENT,
            "prefer": "local",               # harken overrides to "fleet"
            "on_unavailable": "error",
        },
        # Apple FoundationModels: local only on macOS 26. Off-Tahoe the preflight
        # fails and (if a belt is configured) routes to it; else errors.
        "reason": {
            "local_cmd": "fm",
            "local_preflight": _FM_LOCAL_OK,
            "prefer": "local",
            "on_unavailable": "error",
        },
    },
    # How to VOTE (the provider command comes from capability "reason").
    "reasoning": {
        "enabled": True,
        "votes": 3,
        "timeout": 120,
        "snippet_chars": 1000,
        "prompt": (
            "You are tagging one asset for a knowledge archive. "
            "Named entities found: {entities}. "
            "Excerpt (do not quote it back): {snippet}. "
            "Reply with 1-5 lowercase topical tags, comma-separated, nothing else."
        ),
    },
}


def _expand(value):
    return os.path.expanduser(value) if isinstance(value, str) else value


def _deep_merge(base: dict, over: dict) -> dict:
    out = dict(base)
    for k, v in over.items():
        out[k] = _deep_merge(out[k], v) if isinstance(v, dict) and isinstance(out.get(k), dict) else v
    return out


class Config:
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

    def _bin(self, cmd: str) -> str:
        """Prefix a bare organ command's head with bin_dir (absolute heads pass through)."""
        bd = _expand(self._d.get("bin_dir") or "")
        if not bd or not cmd:
            return cmd
        head, _, tail = cmd.partition(" ")
        head = os.path.join(bd, head)  # os.path.join returns head unchanged if absolute
        return f"{head}{(' ' + tail) if tail else ''}"

    def capability(self, name: str) -> dict:
        """A capability spec with bin_dir applied to its local/fleet commands."""
        spec = dict(self._d["capabilities"][name])
        for k in ("local_cmd", "fleet_cmd"):
            if spec.get(k):
                spec[k] = self._bin(spec[k])
        return spec

    def capability_for_modality(self, modality: str) -> str | None:
        return self._d["modality_capability"].get(modality)

    @property
    def reasoning(self) -> dict:
        return dict(self._d["reasoning"])

    @property
    def all_capabilities(self) -> dict:
        return {name: self.capability(name) for name in self._d["capabilities"]}

    def modality_for(self, path: str) -> str | None:
        return self._d["modalities"].get(os.path.splitext(path)[1].lower())

    @property
    def scan_ignore(self) -> list:
        return self._d.get("scan_ignore", [])
