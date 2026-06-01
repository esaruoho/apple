---
description: Run the Apple-Panel job worker — executes panel-inbox jobs that Fleet dispatches to THIS machine over Syncthing, writing output to panel-results. The remote arm of the Fleet × Panel runner. Usage `/panel-worker` (daemon), `/panel-worker --once`, `/panel-worker --status`.
allowed-tools: Bash
argument-hint: "[--once | --status]  (no args = watch forever)"
---

Run the panel-worker. Pass `$ARGUMENTS` through.

Use Bash to execute:

```
/Users/esaruoho/work/apple/bin/panel-worker $ARGUMENTS
```

Notes:
- A peer running Fleet drops a job naming THIS machine + a curated action id into
  `~/work/comms/queue/panel-inbox/`. The worker validates the id against this
  machine's own apple-panel registry, runs it, and writes `panel-results/<job>.json`,
  which Syncthing mirrors back to the requester.
- Security: a job carries an action **id**, never a command. Unknown ids are
  rejected. No network listener — Syncthing is the only transport.
- To keep it running on the Mac Mini, add it to Cloudcity-Boot; on a laptop, a
  LaunchAgent or AppleToolbox timer. `--once` is for testing; `--status` shows
  queue depth and last heartbeat.
