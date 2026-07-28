#!/usr/bin/env python3
# SHIM → canonical copy in convey: ~/work/convey/bin/wiki-generate.py
# Moved 2026-07-28 (Option A). Plain forward; base_dir default (CWD) is unchanged.
import os, sys
os.execv(sys.executable, [sys.executable,
    "/Users/esaruoho/work/convey/bin/wiki-generate.py", *sys.argv[1:]])
