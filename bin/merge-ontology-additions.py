#!/usr/bin/env python3
# SHIM → canonical copy in convey: ~/work/convey/bin/merge-ontology-additions.py
# Moved 2026-07-28 (Option A). Plain forward.
import os, sys
os.execv(sys.executable, [sys.executable,
    "/Users/esaruoho/work/convey/bin/merge-ontology-additions.py", *sys.argv[1:]])
