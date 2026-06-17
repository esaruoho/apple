---
description: Take a photo with the iPhone (Continuity Camera) and put it on the clipboard. Cmd-V pastes the picture. Usage `/iphone-clip`.
allowed-tools: Bash
argument-hint: [--keep <path>] [--device <substr>] [--list]
---

Capture a still from the iPhone via Continuity Camera and copy it to the macOS
clipboard as an image, ready to Cmd-V into Claude / Mail / Messages.

Use Bash to execute (one call, then stop):

```
/Users/esaruoho/work/apple/bin/iphone-clip $ARGUMENTS
```

After it completes, report only that the photo is on the clipboard (and the
saved path if `--keep` was used).
