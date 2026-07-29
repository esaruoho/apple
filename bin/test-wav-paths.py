#!/usr/bin/env python3
"""test-wav-paths — every entry path of bin/wav reaches its recorder call.

Why this exists: a bad sed/replace once dedented the `--app` branch's `return` out of
its `if` block, so plain `wav` hit it before the picker ran and died with
UnboundLocalError. Every OTHER path was tested and passed; the one nobody re-ran after
the edit was the bare, no-argument one — the most common way to start the tool.

So: drive each entry path with the recorder stubbed out, and assert what it would run.
No audio, no curses, no subprocesses. Fast enough to run on every commit.

Run:  python3 bin/test-wav-paths.py
"""
import contextlib
import importlib.machinery
import importlib.util
import io
import json
import os
import sys
import tempfile
import types

HERE = os.path.dirname(os.path.realpath(__file__))


def load(home):
    """Fresh module instance bound to a throwaway HOME (never Esa's real history)."""
    os.environ["HOME"] = home
    spec = importlib.util.spec_from_loader(
        "wav", importlib.machinery.SourceFileLoader("wav", os.path.join(HERE, "wav")))
    m = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(m)
    return m


def stub(m, picker_returns=None, procs=None):
    """Replace everything that touches the outside world; record what got launched."""
    launched = []

    class FakeProc:
        pid = 4242
        def wait(self): return 0

    def fake_popen(cmd, **kw):
        launched.append(cmd)
        if "--manifest" in cmd:
            mf = cmd[cmd.index("--manifest") + 1]
            json.dump({"path": os.path.join(tempfile.gettempdir(), "fake.wav"),
                       "silent": False, "peak_dbfs": -6}, open(mf, "w"))
            open(os.path.join(tempfile.gettempdir(), "fake.wav"), "a").close()
        return FakeProc()

    m.subprocess = types.SimpleNamespace(
        Popen=fake_popen,
        run=lambda c, **k: types.SimpleNamespace(returncode=0, stdout="[]", stderr=""),
        call=lambda c, **k: launched.append(c) or 0)
    m.time = types.SimpleNamespace(sleep=lambda s: None)
    m.audio_procs = lambda show_all=False: (procs if procs is not None else [
        {"name": "Live", "bundleID": "com.ableton.live", "playing": True, "isApp": True},
        {"name": "Schism Tracker", "bundleID": "org.schismtracker.SchismTracker",
         "playing": True, "isApp": True}])
    m.curses = types.SimpleNamespace(wrapper=lambda fn, *a: picker_returns)
    return launched


def run(m, argv, launched):
    """A path that RAISES is a failed path, not a failed test run — catch it, report it
    as that case's failure, and keep going so one break doesn't hide the others."""
    sys.argv = ["wav"] + argv
    out, err = io.StringIO(), io.StringIO()
    try:
        with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
            rc = m.main()
    except BaseException as e:                      # noqa: BLE001 — deliberate
        return None, f"{type(e).__name__}: {e}"
    return rc, out.getvalue() + err.getvalue()


def main():
    failures = []

    def check(label, cond, detail=""):
        print(f"  {'ok  ' if cond else 'FAIL'}  {label}" + (f"   {detail}" if not cond else ""))
        if not cond:
            failures.append(label)

    with tempfile.TemporaryDirectory() as home:
        picked = {"bundleID": "org.schismtracker.SchismTracker", "name": "Schism Tracker",
                  "seconds": 5, "after": 0, "then": {"kind": "none", "name": "nothing"}}

        # 1. bare `wav` — the path that broke, and the most common one
        m = load(home)
        launched = stub(m, picker_returns=picked)
        rc, txt = run(m, ["--no-activate"], launched)
        check("bare `wav` reaches the recorder",
              rc == 0 and launched and "--app" in launched[0], f"rc={rc} launched={launched} {txt[:120]}")

        # 2. quitting the picker is a clean no-op
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, _ = run(m, [], launched)
        check("quitting the picker records nothing", rc == 0 and not launched)

        # 3. --app, no UI
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--app", "schism", "--seconds", "3", "--no-activate"], launched)
        check("--app runs without the picker",
              rc == 0 and launched and "org.schismtracker.SchismTracker" in launched[0], txt[:120])

        # 4. --app that matches nothing fails loudly
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--app", "nosuchapp"], launched)
        check("--app with no match exits 1", rc == 1 and not launched and "no running app" in txt)

        # 5. --last with history (bare run above wrote it)
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--last", "--no-activate"], launched)
        check("--last replays a remembered combo",
              rc == 0 and launched and "--app" in launched[0], f"rc={rc} {txt[:120]}")

        # 6. --recent beyond the end
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--recent", "99"], launched)
        check("--recent past the end exits 1", rc == 1 and not launched and "only" in txt)

        # 7. --list-recent prints, records nothing
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--list-recent"], launched)
        check("--list-recent lists without recording", rc == 0 and not launched and "→" in txt)

        # 8. --stop with nothing running
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--stop"], launched)
        check("--stop with nothing running exits 1", rc == 1 and "nothing recording" in txt)

        # 9. --help never records
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--help"], launched)
        check("--help exits 0 and records nothing", rc == 0 and not launched)

        # 10. unknown flag
        m = load(home)
        launched = stub(m, picker_returns=None)
        rc, txt = run(m, ["--wat"], launched)
        check("unknown flag exits 1", rc == 1 and not launched and "unknown argument" in txt)

        # 11. `a` (all system audio) from the picker
        m = load(home)
        launched = stub(m, picker_returns={"all": True, "seconds": 2, "after": 0,
                                           "then": {"kind": "none", "name": "nothing"}})
        rc, txt = run(m, ["--no-activate"], launched)
        check("all-system-audio pick uses --all",
              rc == 0 and launched and "--all" in launched[0], f"{launched} {txt[:100]}")

    print()
    if failures:
        print(f"{len(failures)} FAILED: {', '.join(failures)}")
        return 1
    print("all wav entry paths OK")
    return 0


if __name__ == "__main__":
    sys.exit(main())
