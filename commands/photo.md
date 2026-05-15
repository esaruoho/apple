---
description: Snap a webcam photo via AVFoundation, no UI. Apple-native. Usage `/photo <out.jpg>`.
allowed-tools: Bash
argument-hint: <output.jpg>
---

Capture one frame from the default webcam to JPEG. Deterministic.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/sal-take-photo $ARGUMENTS && open -R $ARGUMENTS
```

After the command completes, report only the output path.
