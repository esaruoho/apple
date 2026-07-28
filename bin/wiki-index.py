#!/usr/bin/env python3
# SHIM → canonical copy in convey (source of truth): ~/work/convey/bin/wiki-index.py
# Moved 2026-07-28 (Option A: convey owns the shared wiki tooling; apple keeps thin shims).
# apple's pre-commit hook + slash commands call this with NO path arg and relied on
# DEFAULT_WIKI = <script>/../wiki = apple/wiki. After the move that default would resolve
# to convey/wiki, so we inject apple's wiki path explicitly when no target is given.
import os, sys
CANON = "/Users/esaruoho/work/convey/bin/wiki-index.py"
APPLE_WIKI = "/Users/esaruoho/work/apple/wiki"
args = sys.argv[1:]
if not any(not a.startswith("-") for a in args):
    args = [APPLE_WIKI, *args]
os.execv(sys.executable, [sys.executable, CANON, *args])
