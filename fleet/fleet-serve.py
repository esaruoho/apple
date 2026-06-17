#!/usr/bin/env python3
"""fleet-serve — make ANY Mac a live Fleet peer WITHOUT macOS 13 / SwiftUI.

Fleet.app needs macOS 13 only to draw its window. Participating in the fleet
does not: a machine just has to advertise itself and hand over its card. This
does exactly that, using tools that have shipped on macOS for ~15 years —
`python3` (stdlib only) and `dns-sd`. No Network.framework, no SwiftUI.

It speaks the SAME wire protocol as Fleet.app:
  - advertises `_machinecard._tcp` on the LAN via `dns-sd -R`
  - on each inbound connection, sends this machine's FULL card as
    [4-byte big-endian length][JSON]  (auto-trust same-LAN)

So an old Mac Pro runs THIS and appears — live, green dot, full data — in the
Fleet window on every modern Mac on the LAN. It doesn't render the fleet
itself (no GUI), but it's a first-class peer.

Usage:
    fleet-serve.py                 # advertise as this machine's hostname
    fleet-serve.py --name Foo      # override the advertised name (testing)
    fleet-serve.py --card PATH     # use a specific machine-card emitter

Deps: python3 + dns-sd. The card comes from ../bin/machine-card (portable —
native system_profiler, no apple-report needed).
"""
import atexit
import json
import os
import signal
import socket
import struct
import subprocess
import sys
import threading
from pathlib import Path

HERE = Path(__file__).resolve().parent
DEFAULT_CARD = HERE.parent / "bin" / "machine-card"
SERVICE = "_machinecard._tcp"


def parse_args(argv):
    name = socket.gethostname().split(".")[0]
    card = str(DEFAULT_CARD)
    it = iter(argv)
    for a in it:
        if a == "--name":
            name = next(it, name)
        elif a == "--card":
            card = next(it, card)
    return name, card


def card_bytes(card_path):
    """Full card JSON (auto-trust LAN). Degrades to a minimal card if the
    emitter is missing, so the peer still appears with at least its id."""
    try:
        out = subprocess.run([card_path], capture_output=True, timeout=40).stdout
        if out.strip():
            return out
    except Exception as e:
        sys.stderr.write(f"fleet-serve: machine-card failed ({e}); minimal card\n")
    return json.dumps({
        "schema": "machine-card/1",
        "id": socket.gethostname().split(".")[0],
        "identity": {"computer_name": socket.gethostname().split(".")[0]},
    }).encode()


def handle(conn, card_path):
    try:
        payload = card_bytes(card_path)
        conn.sendall(struct.pack(">I", len(payload)) + payload)
        # Fleet also sends its card on the same connection; drain briefly so
        # the socket closes cleanly. We don't render, so we discard it.
        conn.settimeout(2.0)
        try:
            conn.recv(1 << 16)
        except Exception:
            pass
    except Exception:
        pass
    finally:
        try:
            conn.close()
        except Exception:
            pass


def main():
    name, card_path = parse_args(sys.argv[1:])

    sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    sock.bind(("0.0.0.0", 0))
    port = sock.getsockname()[1]
    sock.listen(16)

    # Advertise over Bonjour. dns-sd -R stays in the foreground for the life of
    # the registration, so keep it as a child process.
    if not (subprocess.run(["which", "dns-sd"], capture_output=True).stdout.strip()):
        sys.stderr.write("fleet-serve: dns-sd not found — cannot advertise on this macOS.\n")
        return 1

    # Reap any STALE registration before spawning ours. `dns-sd -R` runs forever
    # until killed; if a prior fleet-serve was SIGKILLed (pane restart), its child
    # dns-sd reparents to PID 1 and lives on. Without this reap, every restart
    # leaked one orphaned dns-sd — 4556 of them piled up on the Mini (2026-06-17),
    # hit the per-user process limit (5333), and fork() began failing machine-wide.
    # Match on our own (name, service) so we never touch another machine's ad.
    subprocess.run(
        ["pkill", "-f", f"dns-sd -R {name} {SERVICE} local"],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    reg = subprocess.Popen(
        ["dns-sd", "-R", name, SERVICE, "local", str(port)],
        stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
    )

    # Make the dns-sd child die WITH us on graceful termination (SIGTERM/SIGINT/exit),
    # so a clean restart never leaks. SIGKILL still can't be caught — which is exactly
    # why the startup reap above is the real guarantee.
    def _cleanup(*_a):
        try:
            reg.terminate()
        except Exception:
            pass
    atexit.register(_cleanup)
    signal.signal(signal.SIGTERM, lambda *_: (_cleanup(), os._exit(0)))

    sys.stderr.write(
        f"fleet-serve: '{name}' advertising {SERVICE} on :{port} "
        f"(pid {os.getpid()}, card={card_path})\n"
    )

    try:
        while True:
            conn, _ = sock.accept()
            threading.Thread(target=handle, args=(conn, card_path), daemon=True).start()
    except KeyboardInterrupt:
        pass
    finally:
        _cleanup()
    return 0


if __name__ == "__main__":
    sys.exit(main())
