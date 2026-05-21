---
description: Build + open the "Turn into Voice" Finder Quick Action Shortcut. After import, enable for Finder. Then right-click any .txt/.md/.rtf → Quick Actions → Turn into Voice submits the file to the Syncthing → Mac Mini → Voicebox pipeline. WAV lands in voicebox-results/. Usage `/turn-into-voice`.
allowed-tools: Bash
argument-hint: (no args)
---

Build the signed `.shortcut` and open it so Shortcuts.app imports it.

Use Bash (one call, then stop):

```
/Users/esaruoho/work/apple/bin/build-turn-into-voice-shortcut.py && open '/Users/esaruoho/work/apple/shortcuts/finder/Turn into Voice.shortcut'
```

After import, tell the user (one line):
- In Shortcuts.app, open **Turn into Voice** → ⓘ → ✅ **Use as Quick Action → Finder**, then right-click any text file → **Quick Actions → Turn into Voice**. Results appear at `~/work/comms/queue/voicebox-results/<id>.wav` after the Mini's worker processes them.
