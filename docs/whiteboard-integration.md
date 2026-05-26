---
layout: default
title: "Whiteboard Integration"
---

# Whiteboard Integration


[← Back to home](./)
The Apple skill uses the **BBS Whiteboard skill** (`~/.claude/skills/whiteboard/`) to generate visual educational whiteboards. When Esa asks for whiteboards in this workspace:

```bash
~/.claude/skills/whiteboard/bin/whiteboard-generate.sh --full --count N --text "content"
```

Output goes to `/Users/esaruoho/work/apple/whiteboards/`
