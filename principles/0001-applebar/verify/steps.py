"""Stage 4 — Verify: no automated runner for this domain (yet).

Leave these unbound and the scenarios report as UNRUN; `convey verify` then keeps
the honestly-declared grade (@hw-untested / @untested / @stock) rather than
claiming a pass. Bind steps here if/when a runner exists (e.g. a SPICE harness,
an HTTP client, a media probe) — then passing scenarios grade up to @verified.
"""
from convey.steps import given, when, then, step  # noqa: F401
