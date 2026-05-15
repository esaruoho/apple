---
description: Generate a high-resolution QR PNG from text via CoreImage. Apple-native, no deps. Usage `/qr "<text>" <out.png>`.
allowed-tools: Bash
argument-hint: "<text>" <output.png>
---

Generate a QR code PNG via CoreImage. Deterministic.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/sal-qr $ARGUMENTS && open -R "$(echo $ARGUMENTS | awk '{print $NF}')"
```

After the command completes, report only the output path.
