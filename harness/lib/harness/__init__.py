"""The Apple Harness — a zero-token-first local ingestion engine.

Whitelabeled scaffold. Composes native Apple organs (Vision OCR, NaturalLanguage
NER, NLEmbedding, FoundationModels) behind an idempotent, crash-only execution
ledger. No third-party dependencies: Python stdlib + Apple-shipped frameworks.
"""
__all__ = ["config", "ledger", "organs", "reasoning", "loop"]
__version__ = "0.1.0"
