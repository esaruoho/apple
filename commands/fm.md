---
description: Apple's on-device LLM (FoundationModels / Apple Intelligence) — local, private, no Ollama. macOS 26 only (the Mini). Usage `/fm "<prompt>"` or pipe text in; `/fm --check` for availability.
allowed-tools: Bash
argument-hint: "\"<prompt>\"  |  --check  |  --system \"...\" \"<prompt>\""
---

Run a prompt through Apple's on-device LLM.

Use Bash to execute (one call):

```
/Users/esaruoho/work/apple/bin/fm $ARGUMENTS
```

Notes:
- macOS 26 (Tahoe) + Apple Intelligence enabled. On the fleet that's CloudcityMacMini;
  on older macOS the tool prints a clear "needs macOS 26" message.
- Apple-native: FoundationModels framework on the Neural Engine — no Ollama, no pip,
  no network. Verified on the Mini (2026-06-01): `--check` → available, ~2 s replies.
- Prompt from args or stdin (`echo text | fm` to summarize). `--system` sets instructions.
- See `wiki/concepts/apple-silicon-ml.md`. Reachable across the fleet via the Syncthing
  runner / Fleet.
