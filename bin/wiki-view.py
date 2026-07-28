#!/usr/bin/env python3
# SHIM → canonical copy in convey: ~/work/convey/bin/wiki-view.py
# Moved 2026-07-28 (Option A). Injects apple's wiki path when no target given
# (preserves the old __file__-relative DEFAULT_WIKI = apple/wiki).
import os, sys
CANON = "/Users/esaruoho/work/convey/bin/wiki-view.py"
APPLE_WIKI = "/Users/esaruoho/work/apple/wiki"
args = sys.argv[1:]
if not any(not a.startswith("-") for a in args):
    args = [APPLE_WIKI, *args]
os.execv(sys.executable, [sys.executable, CANON, *args])
