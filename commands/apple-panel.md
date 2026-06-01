---
description: Open the Apple Panel — a local browser control surface where every capability is a card with a real Run button. Output renders inline. Local-only (127.0.0.1), Apple-native. Usage `/apple-panel`.
allowed-tools: Bash
argument-hint: "[--port N] [--no-open]  (no args = start on 8787 and open the browser)"
---

Start the local control panel and open it in the browser.

This starts a small local HTTP server that keeps running until the user stops it (Ctrl-C, or the **Stop server** button on the page). **Launch it in the background** so this turn doesn't block:

Use Bash with `run_in_background: true` to execute:

```
/Users/esaruoho/work/apple/bin/apple-panel $ARGUMENTS
```

Then report the URL it printed (e.g. `http://127.0.0.1:8787/`) and tell the user it's open in their browser. The page lists every wired capability as a card; clicking **Run** executes the tool on this Mac and shows the output inline.

Notes:
- Local only — bound to 127.0.0.1, not reachable from the network.
- The server runs only the curated registry inside `bin/apple-panel`; arguments are passed as discrete argv (no shell), so there's no injection surface.
- 🟢 cards are read-only; 🟠 cards make a change.
- To add a capability, append one entry to the `ACTIONS` list at the top of `bin/apple-panel`. See `wiki/concepts/apple-panel.md`.
