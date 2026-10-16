#!/usr/bin/env python3
"""Parse iPhone Compass OCR text -> heading + where East is.

Reads OCR text on stdin, finds the heading (e.g. "237° SW" or "237"), and
prints the heading plus the rotation needed to face East (90°).

Run standalone with --selftest to exercise the parser with no phone attached.
"""
import re
import sys

CARDINALS = {
    "N": 0, "NNE": 22.5, "NE": 45, "ENE": 67.5, "E": 90, "ESE": 112.5,
    "SE": 135, "SSE": 157.5, "S": 180, "SSW": 202.5, "SW": 225, "WSW": 247.5,
    "W": 270, "WNW": 292.5, "NW": 315, "NNW": 337.5,
}


def parse(text: str):
    """Return (degrees:int|None, cardinal:str|None) from OCR text."""
    deg = None
    # A number immediately followed by a degree sign (°, o, or 0 misread) and
    # within 0..359 is the heading readout.
    for m in re.finditer(r"(\d{1,3})\s*°", text):
        v = int(m.group(1))
        if 0 <= v <= 359:
            deg = v
            break
    if deg is None:  # fallback: bare 1-3 digit number on its own
        for m in re.finditer(r"(?<!\d)(\d{1,3})(?!\d)", text):
            v = int(m.group(1))
            if 0 <= v <= 359:
                deg = v
                break
    card = None
    for tok in re.findall(r"\b([NSEW]{1,3})\b", text.upper()):
        if tok in CARDINALS:
            card = tok
            break
    if deg is None and card is not None:
        deg = int(CARDINALS[card])
    return deg, card


def turn_to_east(deg: int):
    """Shortest rotation to bring heading to 90° (East). +right / -left."""
    delta = (90 - deg) % 360
    if delta > 180:
        return -(360 - delta)  # turn left
    return delta  # turn right


def report(text: str) -> int:
    deg, card = parse(text)
    if deg is None:
        print("compass: could not read a heading from the screen.", file=sys.stderr)
        print("         Is the Compass app open with its degree readout visible?", file=sys.stderr)
        return 1
    c = f" {card}" if card else ""
    t = turn_to_east(deg)
    print(f"iPhone heading: {deg}°{c}  (the top of the phone points this way)")
    if abs(t) <= 2:
        print("EAST: the phone is already pointing East. ✅")
    elif t > 0:
        print(f"EAST (90°): turn the phone {t}° to the RIGHT (clockwise).")
    else:
        print(f"EAST (90°): turn the phone {abs(t)}° to the LEFT (counter-clockwise).")
    return 0


def selftest() -> int:
    cases = [
        ("237° SW\nHelsinki", 237, "SW"),
        ("90° E", 90, "E"),
        ("0° N\nsome place", 0, "N"),
        ("359°", 359, None),
        ("NE", 45, "NE"),
    ]
    ok = True
    for text, want_deg, want_card in cases:
        d, c = parse(text)
        passed = d == want_deg and c == want_card
        ok = ok and passed
        print(f"{'PASS' if passed else 'FAIL'}  {text!r:30} -> deg={d} card={c}  (want {want_deg}/{want_card})")
    # turn-to-east math
    checks = [(90, 0), (0, 90), (180, -90), (270, 180), (89, 1), (91, -1)]
    for deg, want in checks:
        got = turn_to_east(deg)
        passed = got == want
        ok = ok and passed
        print(f"{'PASS' if passed else 'FAIL'}  turn_to_east({deg}) = {got}  (want {want})")
    return 0 if ok else 1


if __name__ == "__main__":
    if "--selftest" in sys.argv:
        sys.exit(selftest())
    sys.exit(report(sys.stdin.read()))
