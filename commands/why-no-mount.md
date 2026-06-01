---
description: Diagnose why a USB stick / external drive isn't mounting. Walks the USB→block→filesystem ladder, prints a verdict + copy-paste repair step. Zero LLM roundtrip. Usage `/why-no-mount [disk-id]`.
allowed-tools: Bash
argument-hint: "[disk4 | disk4s1 | --list | --probe-only X]  (no args = auto-detect every unmounted external volume)"
---

A drive didn't show up in Finder. Run the deterministic diagnostic — Apple-native, no LLM analysis.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/why-no-mount $ARGUMENTS
```

The tool itself prints the diagnostic ladder, the verdict, the smoking guns, and the recommended next step. After it completes, **report its output verbatim**. Do not re-interpret, summarize, or invent extra steps — the variables in its narrative are already filled from live `diskutil` / `system_profiler` / `log` data.

Notes:
- No args → auto-detects every UNMOUNTED external volume and diagnoses each.
- A disk id (`disk4`, `disk4s1`) → diagnoses that target.
- `--list` → just shows external volumes + mount state.
- `--probe-only X` → inspect only; does NOT attempt a live mount.
- The repair commands it prints (`fsck_*`, `dd`, `diskutil repairVolume`) need `sudo` and some WRITE to the disk — the user runs those deliberately, the slash does not.
