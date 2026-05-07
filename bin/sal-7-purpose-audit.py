#!/usr/bin/env python3
"""
Phase 5 — Sal's Seven-Purpose Framework audit (WWSD #30, sourced to WWDC 717 lines 480-504).

For every workflow under scripts/workflows/, score against Sal's 7 criteria:
  1. Need to remain in context (don't break flow)        ← infers from "tell application" without `activate`
  2. Multi-step (≥3 manual steps)                        ← infers from line count >= 8
  3. Requires dexterity                                  ← infers from "set position" / "set bounds" / "set size"
  4. Moves data between apps                             ← infers from ≥2 distinct `tell application "X"` blocks
  5. Transforms data type                                ← infers from "as <type>" coercion or "export ... as"
  6. Does something not in the app's UI                  ← infers from `do shell script` or `do JavaScript`
  7. Things user wants but doesn't know how              ← infers from accessibility / hardware / system actions

Workflows scoring 3+ → earn voice + Spotlight + Loupedeck (3-channel)
Workflows scoring 1-2 → script-only
Workflows scoring 0  → re-evaluate

Output: analysis/sal/seven-purpose-audit.md
"""
import re
from pathlib import Path
from collections import Counter

ROOT = Path(__file__).resolve().parent.parent
WORKFLOWS = ROOT / "scripts/workflows"
LAUNCHERS = ROOT / "scripts/launchers"
OUT = ROOT / "analysis/sal/seven-purpose-audit.md"

def score(text):
    """Return (score, [reasons])."""
    reasons = []
    line_count = len([l for l in text.splitlines() if l.strip() and not l.strip().startswith("--")])
    tell_apps = re.findall(r'tell application "([^"]+)"', text)
    distinct_apps = set(tell_apps)

    s = 0
    # 1. Remain in context — uses `tell ... without activate`
    if tell_apps and "activate" not in text:
        s += 1
        reasons.append("1:no-activate")
    # 2. Multi-step — line count >= 8
    if line_count >= 8:
        s += 1
        reasons.append(f"2:lines={line_count}")
    # 3. Requires dexterity — geometric set ops
    if re.search(r"\bset (position|bounds|size)\b", text):
        s += 1
        reasons.append("3:geometry")
    # 4. Moves data between apps — ≥2 distinct apps
    if len(distinct_apps) >= 2:
        s += 1
        reasons.append(f"4:apps={len(distinct_apps)}")
    # 5. Transforms data type — "as " coercion or export
    if re.search(r"\bas (text|string|record|list|integer|real|date|alias|file|JPEG|PNG|PDF)\b", text) or re.search(r"\bexport.*\bas\b", text, re.IGNORECASE):
        s += 1
        reasons.append("5:coercion")
    # 6. Not in UI — shell or JS
    if "do shell script" in text or "do JavaScript" in text:
        s += 1
        reasons.append("6:shell-or-js")
    # 7. User-wants-doesn't-know — System Events, Accessibility, key codes, hardware
    if re.search(r"System Events|System Preferences|key code|keystroke|System Settings", text):
        s += 1
        reasons.append("7:system-events")

    return s, reasons

def main():
    rows = []
    for path in sorted(list(WORKFLOWS.rglob("*.applescript")) + list(LAUNCHERS.rglob("*.applescript"))):
        try:
            text = path.read_text()
        except Exception:
            continue
        s, reasons = score(text)
        rel = path.relative_to(ROOT)
        rows.append((s, str(rel), reasons))

    # Tallies
    by_score = Counter(r[0] for r in rows)
    triple_channel = [r for r in rows if r[0] >= 3]
    script_only = [r for r in rows if 1 <= r[0] < 3]
    reevaluate = [r for r in rows if r[0] == 0]

    lines = []
    lines.append("---")
    lines.append("title: Sal's Seven-Purpose Framework — Audit of apple-skill workflow catalog")
    lines.append("date: 2026-05-07")
    lines.append("source: WWSD principle #30, derived from WWDC 2016 session 717 transcript lines 480-504")
    lines.append("generator: bin/sal-7-purpose-audit.py")
    lines.append("---")
    lines.append("")
    lines.append("# Framework recap (WWSD #30)")
    lines.append("")
    lines.append("Build a voice command (= grant a Siri phrase + Spotlight .app + Loupedeck button) when a workflow scores 3+ on:")
    lines.append("")
    lines.append("1. **Remain in context** — don't break flow")
    lines.append("2. **Multi-step** — ≥3 manual steps")
    lines.append("3. **Requires dexterity** — precise mouse/sequencing")
    lines.append("4. **Moves data between apps**")
    lines.append("5. **Transforms data type**")
    lines.append("6. **Not in app's UI**")
    lines.append("7. **User wants but doesn't know how**")
    lines.append("")
    lines.append("# Tallies")
    lines.append("")
    lines.append(f"- Total workflows scanned: **{len(rows)}**")
    lines.append(f"- Score 3+ (triple-channel candidates): **{len(triple_channel)}**")
    lines.append(f"- Score 1-2 (script-only): **{len(script_only)}**")
    lines.append(f"- Score 0 (re-evaluate): **{len(reevaluate)}**")
    lines.append("")
    lines.append("Score distribution:")
    for s in sorted(by_score.keys()):
        lines.append(f"- {s}: {by_score[s]}")
    lines.append("")

    lines.append("# Triple-channel candidates (score 3+)")
    lines.append("")
    lines.append("These earn voice (dictation command), Spotlight (osacompile .app), and Loupedeck button. Sorted by score descending then path.")
    lines.append("")
    lines.append("| Score | Workflow | Reasons |")
    lines.append("|-------|----------|---------|")
    for s, p, r in sorted(triple_channel, key=lambda x: (-x[0], x[1])):
        lines.append(f"| {s} | `{p}` | {', '.join(r)} |")
    lines.append("")

    lines.append("# Script-only workflows (score 1-2)")
    lines.append("")
    lines.append("Keep as scripts; do not allocate Siri/Loupedeck channel.")
    lines.append("")
    lines.append("| Score | Workflow | Reasons |")
    lines.append("|-------|----------|---------|")
    for s, p, r in sorted(script_only, key=lambda x: (-x[0], x[1])):
        lines.append(f"| {s} | `{p}` | {', '.join(r)} |")
    lines.append("")

    lines.append("# Re-evaluate (score 0)")
    lines.append("")
    lines.append("These workflows didn't trigger any of the 7 criteria. Likely launchers or one-line activations. Triage each: keep as launcher, or reconsider whether the workflow earns its existence.")
    lines.append("")
    lines.append("| Workflow |")
    lines.append("|----------|")
    for s, p, r in sorted(reevaluate, key=lambda x: x[1]):
        lines.append(f"| `{p}` |")
    lines.append("")

    lines.append("# Heuristic limits")
    lines.append("")
    lines.append("This audit is heuristic, not authoritative. Manual review is needed for borderline workflows. Specific blind spots:")
    lines.append("")
    lines.append("- Criterion 7 (\"user wants but doesn't know how\") is the hardest to detect from source — it's a UX judgment. The current heuristic catches System Events / keystroke usage, which is a proxy at best.")
    lines.append("- Single-line launchers correctly score 0 (they're trivial). They should be evaluated separately as candidates for Loupedeck buttons regardless of this audit.")
    lines.append("- Workflows that pipeline through `set theData to ...` and pass it across apps without explicit `tell` blocks may underscore on criterion 4.")
    lines.append("")
    lines.append("# Next step")
    lines.append("")
    lines.append("For each triple-channel candidate, generate the three artifacts:")
    lines.append("")
    lines.append("1. Run `bin/dictation-commands-to-shortcuts.py` style to emit a Siri phrase + Shortcut")
    lines.append("2. Run `bin/spotlight-export.sh` (already existing) to ensure it's compiled to an .app for Spotlight")
    lines.append("3. Add to `bin/loupedeck-import-dictation-commands.py`'s catalog")
    lines.append("")
    OUT.write_text("\n".join(lines))
    print(f"Wrote {OUT}")
    print(f"  Triple-channel: {len(triple_channel)} | Script-only: {len(script_only)} | Re-evaluate: {len(reevaluate)}")

if __name__ == "__main__":
    main()
