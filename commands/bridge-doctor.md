---
description: Diagnose a "the Mini bridge is dead!" situation correctly — checks LAPTOP disk + Syncthing minDiskFree guard FIRST (the usual real cause), then folder errors + heartbeats, and prints a plain verdict. Usage `/bridge-doctor`.
allowed-tools: Bash
argument-hint: (no args)
---

Run the bridge doctor before assuming the Mini is down.

Use Bash to execute (one call):

```
/Users/esaruoho/work/apple/bin/bridge-doctor
```

Why: when heartbeats go stale and the file bridge stops responding, it is almost
never the Mini — it's usually THIS laptop low on disk, tripping Syncthing's
per-folder `minDiskFree` guard so Syncthing silently stops writing incoming files.
The bridge only *looks* dead. This tool checks disk first and tells you plainly.
See `wiki/concepts/apple-silicon-ml.md` neighbours and the cloudcity skill.
