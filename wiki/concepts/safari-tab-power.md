---
description: Finding the power-hungry Safari tab — PID↔tab fingerprinting, why background tabs must not be JS-probed, bin/safari-hogs.
---
# Safari tab power: which tab is the hog?

Tool: [`bin/safari-hogs`](../../bin/safari-hogs) · slash `/safari-hogs` · card `features/safari-hogs.feature`.

## What macOS gives you (probed 2026-11-10, Safari 26 / WebKit 20624)
- Every Safari tab group runs in a `com.apple.WebKit.WebContent` XPC process under
  `/System/Volumes/Preboot/Cryptexes/App/.../StagedFrameworks/Safari/...`. Mail and Keyboard Maestro
  have their own WebContent processes under `/System/Library/Frameworks/WebKit...`, so filter on the **Safari path**.
- `lsappinfo` names them only "Safari Web Content" / "(Cached)". **Service workers do carry the
  domain**: "Safari Service Worker (youtube.com)". There is **no public PID→tab URL API**. Activity Monitor uses private SPI.
- Processes do not map 1:1 to tabs: 568 tabs ran in ~13 WebContent processes. Sleeping tabs have no live process.
- `top -stats pid,cpu,power` gives an energy column per PID.

## The fingerprint trick (PID ↔ tab)
`do JavaScript` a 400 ms busy loop in one tab and watch which WebContent PID's cumulative CPU
(`ps -o time`) jumps. That PID hosts the tab. It needs Safari ▸ Develop ▸ *Allow JavaScript from Apple Events* (already on).

## 🔴 Trap: never JS-probe background tabs
`do JavaScript` on a tab Safari has put to sleep **reloads it**. A Google Sheet tab reported `performance` age **0 s**
right after the probe. With hundreds of tabs, a full sweep would itself become the power hog.
So only each window's **current tab** gets probed. A hot PID with no front tab is reported as
"background tab(s) in pid N". The tool doesn't guess at them.

## AppleScript gotcha
Inside `tell application "Safari"`, the word `tab` means Safari's **tab class**, not the tab character.
`i & tab & …` silently produced an empty result. Use `character id 9`.

## Per-tab metrics
Media playing (the classic battery drain), DOM node count, iframes, bytes fetched and page age.
Process power and CPU belong to the **process**, which can be shared by several tabs.
