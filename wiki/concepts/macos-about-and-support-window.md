---
description: About / Support / Help windows in an Apple-native app — clickable donation links, semantic colours, sizing to content, an offline README, and the AppKit trap that makes the app quit itself.
---

# About, Support and Help windows

Every shipped app here needs three things the standard AppKit furniture does badly: an About box
that actually shows its content, **clickable** support links (Ko-fi / PayPal / Patreon / Gumroad /
`mailto:`), and Help that works with no browser and no network. Each rule below cost a round of
"this is no good, dude".

## Do not use `orderFrontStandardAboutPanel` for anything with links

`NSApp.orderFrontStandardAboutPanel(options: [.credits: …])` puts the credits in a **small,
fixed-size, scrolling** box that cannot be resized. Anything past a short paragraph is hidden
behind a scrollbar, and the user has to scroll a dialog to find the donate link — so they don't.

Build a plain `NSWindow` and size it to the text's measured height:

```swift
view.frame = NSRect(x: 0, y: 0, width: width, height: 10_000)
manager.ensureLayout(for: container)
let needed = ceil(manager.usedRect(for: container).height) + 4
window.setContentSize(NSSize(width: width + 44, height: stack.fittingSize.height))
```

Result to aim for: **no scrollbar at all** (verify with `AXScrollBar` count == 0 via the
accessibility tree, not by eye).

## Links must live in an NSTextView, not an NSTextField

`NSTextField` will render an `.link` attribute but will not reliably handle the click. Use a
non-editable, selectable `NSTextView` with `drawsBackground = false`:

```swift
view.linkTextAttributes = [
    .foregroundColor: NSColor.linkColor,
    .underlineStyle: NSUnderlineStyle.single.rawValue,
    .cursor: NSCursor.pointingHand,
]
```

`mailto:` works as a link like any other — that is how "Email <author>" belongs in an About box.

## ALWAYS set a foreground colour — the default is black, not "the right one"

**An `NSAttributedString` with no `.foregroundColor` draws BLACK.** On a dark window in dark mode
that is nearly invisible. This is the single most likely way an About box ships unreadable.

```swift
.foregroundColor: NSColor.labelColor       // body — follows light AND dark
.foregroundColor: NSColor.linkColor        // links
view.textColor = .labelColor               // the text view's own default
view.backgroundColor = .textBackgroundColor
```

Never hardcode `.black` / `.white`; use the semantic colours so one build serves both appearances.

## The icon is 64pt

Apple's own About panel draws the app icon at **64pt**. Larger reads as oversized even when the
`.icns` geometry is correct — the icon looking too big has *two* independent causes, and fixing the
artwork alone does not fix this one. See [`macos-app-icon-sizing.md`](macos-app-icon-sizing.md) for
the artwork half (824/1024 grid).

```swift
let icon = NSImageView(image: NSApp.applicationIconImage)
icon.widthAnchor.constraint(equalToConstant: 64).isActive = true
```

## Help ships INSIDE the bundle

Opening a GitHub URL for Help means the app cannot document itself on a plane, on a bad
connection, or after the repo moves. Copy the README into the bundle at build time and show that:

```bash
cp README.md "$APP/Contents/Resources/README.md"
```

```swift
let url = Bundle.main.url(forResource: "README", withExtension: "md")
```

Keep "Documentation on GitHub" as a *second*, explicitly-labelled item — never the only one.

## THE TRAP: `applicationShouldTerminateAfterLastWindowClosed` must be `false`

If the app's main window is an `NSPanel` with `.utilityWindow` (every floating control panel here),
**AppKit does not count it** for the "last window closed" test. With `true`, the app decides its
last window is gone and **quits itself** the moment any transient window closes — choosing About,
or clicking a Support link, made the app vanish.

```swift
func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
```

Then make quitting explicit: the Quit item, and — if the panel *is* the app — a
`windowWillClose` on that specific window.

```swift
func windowWillClose(_ notification: Notification) {
    guard (notification.object as? NSWindow) === panel else { return }
    NSApp.terminate(nil)
}
```

## Modals from a non-activating panel: activate first, prefer sheets

A `.nonactivatingPanel` app is often **not active**. Calling `NSAlert.runModal()` then starts a
modal loop while the alert can sit *behind* other windows: the panel ignores every click and the
app looks frozen with no way out. Either activate first, or attach the alert to the panel:

```swift
NSApp.activate()
alert.beginSheetModal(for: panel) { response in … }   // cannot be buried; Escape dismisses
```

## A non-activating panel has no menu bar in practice

macOS only draws an app's menu bar while the app is **active**, and clicking a
`.nonactivatingPanel` deliberately does not activate it — that is the whole point (focus stays in
the host app, e.g. Ableton Live). So the menu bar exists but is almost never on screen.

Put the same commands somewhere that does not depend on activation:

- a **`⋯` button** in the panel that pops the menu with `menu.popUp(positioning:at:in:)`
- the same `NSMenu` as the content view's `menu`, so **right-click anywhere** works

`NSApp.activate()` at launch is *not* a fix — it shows the menu bar once, then the first click
into another app takes it away again.

## Support links come from the project, not from invention

Read them out of the repo (`.github/FUNDING.yml`, README "Support" section) rather than writing
plausible-looking URLs. Getting a donation link wrong is worse than omitting it.

## Verifying this without eyeballing it

All of it is checkable through the accessibility tree, which is how these bugs were actually
caught (screenshots of a *region* also capture whatever else is on screen — capture a single
window by id with `screencapture -l <windowid>` instead):

```swift
// button titles present, scrollbar count, and the ✓/✗ report text
if str(e, kAXRoleAttribute as String) == "AXButton" { buttons.append(str(e, kAXTitleAttribute as String)) }
```

Drive the menu item with `AXUIElementPerformAction(item, kAXPressAction)` and then assert the app
is **still running** — that is the regression test for the terminate trap above.

## Implementations in this repo family

- `~/work/LiveClipEnvelopes/LiveEnvelopePanel/main.swift` — the reference: custom About with
  clickable Ko-fi / BuyMeACoffee / PayPal / GitHub Sponsors / Patreon / Bandcamp / Gumroad /
  `mailto:`, bundled-README Help window, `⋯` + right-click menu, and a "Check Setup" report.

## Related

- [`macos-app-icon-sizing.md`](macos-app-icon-sizing.md) — the 824/1024 grid, and `lsregister -f`
- [`asobjc.md`](asobjc.md) — when a window like this does not need Swift at all
