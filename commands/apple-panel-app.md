---
description: Build + open ApplePanel.app — the Apple Panel as a native WKWebView window (not a browser tab). Boots the local panel server, shows it in a dedicated Mac app, kills the server on quit. Usage `/apple-panel-app`.
allowed-tools: Bash
argument-hint: (no args)
---

Build and open ApplePanel.app. Safe to re-run.

Use Bash to execute (one call, then stop):

```
bash /Users/esaruoho/work/apple/panel-app/build.sh && open /Users/esaruoho/work/apple/panel-app/ApplePanel.app
```

After it completes, report that the Apple Panel app is open.

Notes:
- It's a native AppKit + WKWebView app — no browser, no Dock-cluttering Safari tab.
- It launches `bin/apple-panel --no-open` as a child, reads the port that server
  actually bound from its stdout, and loads `http://127.0.0.1:<port>/` in the webview.
- Quitting the app (⌘Q) or closing the window terminates the child server — no orphans.
- Loopback only; no Local Network permission prompt.
