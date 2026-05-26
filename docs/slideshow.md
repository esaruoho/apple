---
layout: default
title: "Slideshow — Folder → Fullscreen Presentation"
---

# Slideshow — Folder → Fullscreen Presentation


[← Back to home](./)
**Underlying principle:** A folder of images is a presentation waiting to happen. Any folder, any screen, sequential or random. The same seed as WhiteboardKnob (folder → browse images) but unattended — auto-advance instead of manual knob control.

```bash
python3 bin/slideshow.py /path/to/images              # sequential on secondary screen
python3 bin/slideshow.py --shuffle /path/to/images     # random order
python3 bin/slideshow.py --interval 3 /path            # 3 seconds per slide
python3 bin/slideshow.py --screen 0 /path              # force main screen
python3 bin/slideshow.py                               # folder picker dialog
```

**Controls:** Escape/Q=quit, Right/Space=next, Left=prev, P=pause (counter turns orange)

**Architecture:** Python + Pillow + tkinter. Swift one-liner detects all screens via `NSScreen`. No Preview, no Finder, no permissions issues — Python reads files directly.

**Pattern relationship:**
- **WhiteboardKnob** = manual browse (Loupedeck knob, one image at a time, user-paced)
- **Slideshow** = unattended display (auto-advance, any screen, ambient)
- Same input (folder of images), different interaction model. The folder is the data; the tool is the lens.

**Wrapper scripts:** Any project can create a thin shell wrapper that calls `slideshow.py` with a hardcoded folder. The tool stays generic; the wrapper carries the context.
