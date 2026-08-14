---
description: Four AppKit window traps that each cost a crash or a silent misbehaviour in a shipped app here — isReleasedWhenClosed, borderless canBecomeKey, deallocating inside windowWillClose, and the title-bar budget when fitting an aspect ratio.
---

# AppKit window gotchas

Every one of these was found the hard way in an app in this repo, not read in a doc. They apply to
any multi-window AppKit app — Fleet, Overlay, iPhoneMirror, ApplePanel — so check this page before
debugging "the window crashed / ignored me / is the wrong size".

## 1. `isReleasedWhenClosed` double-releases under ARC

A programmatically created `NSWindow` (`init(contentRect:styleMask:backing:defer:)`) defaults to
**`isReleasedWhenClosed = true`**. If you also hold it in a property, closing it releases it twice:
once by AppKit, once by ARC.

```swift
window = MirrorWindow(contentRect: r, styleMask: style, backing: .buffered, defer: false)
window.isReleasedWhenClosed = false     // REQUIRED whenever you keep a reference
```

**Symptom:** `EXC_BAD_ACCESS` / `SIGSEGV` in `objc_release`, inside
`AutoreleasePoolPage::releaseUntil` → `objc_autoreleasePoolPop`, with a stack that shows only
`-[NSApplication run]` and no code of yours. That "my code isn't even in the trace" shape is the
tell for an over-release, and the crash lands one event-loop turn *after* the real mistake.

Read the report rather than guessing:

```bash
ls -t ~/Library/Logs/DiagnosticReports/YourApp* | head -1
# .ips = one JSON header line, then the payload JSON:
python3 -c 'import json,sys;raw=open(sys.argv[1]).read();p=json.loads(raw[raw.index("\n")+1:]);print(p["exception"]);
[print(" ",f.get("symbol","")) for f in p["threads"][p.get("faultingThread",0)]["frames"][:12]]' <file.ips>
```

## 2. A borderless window CANNOT become key

`NSWindow.canBecomeKey` and `canBecomeMain` return **false** when the style mask is `.borderless`.

**Symptom:** you strip the title bar for a clean screen recording, then every front-window command
starts hitting the *wrong* window — because clicking the borderless one makes nothing key, and your
`front` accessor silently falls back to whatever it guesses.

```swift
final class MirrorWindow: NSWindow {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { true }
}
```

Two companions, both needed in practice:

- Track focus explicitly instead of guessing. `keyWindow` first, then the last window that posted
  `windowDidBecomeKey`, and only then a fallback.
- Make the content view focus its own window on click. With no title bar, the image is the only hit
  target:

  ```swift
  override func mouseDown(with event: NSEvent) {
      window?.makeKeyAndOrderFront(nil)
      super.mouseDown(with: event)
  }
  ```

## 3. Never deallocate an object inside its own `windowWillClose`

If a controller is owned only by an array, removing it from that array *inside* its own delegate
callback deallocates it mid-callback.

```swift
func mirrorClosed(_ m: Mirror) {
    DispatchQueue.main.async { [weak self] in       // next run-loop turn, on a live object
        self?.mirrors.removeAll { $0 === m }
    }
}
```

Also clear `window.delegate = nil` on close — the delegate reference is `weak`/`unowned`, so a
dangling one is its own crash.

## 4. The title bar is not content — budget it before fitting an aspect ratio

`contentAspectRatio` constrains the *content*, but `window.frame` includes the title bar. Fitting a
window into a cell using `frame.height` makes every window slightly too tall.

```swift
let chrome = max(0, window.frame.height - window.contentLayoutRect.height)
var w = cell.width, h = w / aspect
if h + chrome > cell.height { h = cell.height - chrome; w = h * aspect }
window.setFrame(NSRect(x: cell.midX - w/2, y: cell.midY - (h + chrome)/2,
                       width: w, height: h + chrome), display: true, animate: false)
```

And tile against **`NSScreen.visibleFrame`**, never `frame` — `visibleFrame` already excludes the
menu bar and the Dock, so windows do not slide underneath either.

## 5. SourceKit lies about a multi-file target

Once a target compiles more than one file (e.g. an app plus `shared/SupportHelp.swift`), the
editor's per-file diagnostics report phantom errors — `Cannot find 'AppHelpView' in scope`,
`'main' attribute cannot be used in a module that contains top-level code`, `Reference to member
'titled' cannot be resolved`. **`swiftc` is the authority.** If `build.sh` succeeds, the code is
fine; do not "fix" these.

Related: a multi-file target cannot use top-level code, so the entry point must be
`@main` + `-parse-as-library` rather than statements at the bottom of the file.

## Related

- [`macos-app-icon-sizing.md`](macos-app-icon-sizing.md) — the other thing shipped wrong first
- [`macos-about-and-support-window.md`](macos-about-and-support-window.md) — the shared Help panel
- [`../entities/iphonemirror.md`](../entities/iphonemirror.md) — where all four of these were found
