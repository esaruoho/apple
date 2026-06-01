---
description: Build + open Fleet.app — a single-window viewer that shows THIS Mac's Machine Card side-by-side with every peer (live Bonjour LAN discovery + Syncthing-published cards). Peer skills with an inbox (ocr/voicebox/whisp/pakettibot) are buttons that route a file to that machine. Usage `/fleet`.
allowed-tools: Bash
argument-hint: (no args)
---

Build and open Fleet.app. Safe to re-run.

Use Bash to execute (one call, then stop):

```
bash /Users/esaruoho/work/apple/fleet/build.sh && open /Users/esaruoho/work/apple/fleet/Fleet.app
```

After it completes, report that Fleet is open and remind the user:
- First launch prompts for **Local Network** access — allow it so LAN peers appear.
- Peers running Fleet on the same network show up automatically (live green dot).
- The Mac Mini appears via its Syncthing-published card (machine-card-CloudcityMacMini.json) once its publisher loop is running.
