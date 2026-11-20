---
description: Workflow to unstick a Mac App Store update stuck on an endless spinner — restart daemons, clear partial download, reinstall.
---
# Stuck App Store update — unstick workflow

**Symptom:** App Store ▸ Updates shows a never-ending spinner next to an app
(seen 2026-11-20 with Foreca Weather, a "Designed for iPad" app). The App Store
has no visible Stop/Retry button.

**Tool:** [`bin/appstore-unstick`](../../bin/appstore-unstick)

## Escalation ladder (stop at the first that works)

1. **In-app:** ⌘R (Store ▸ Reload Page) → click Update again. *Hovering over the spinner does NOT show a ⏹ stop button (checked on Sequoia, 2026-11-20), so the app itself gives you no way to cancel. Go straight to step 2.*
2. **Restart the App Store and its download processes** (fixes most cases — it worked on 2026-11-20):
   `appstore-unstick`
   This quits App Store and kills `storedownloadd`, `appstoreagent`, `commerce`.
   launchd restarts them when they're needed, so `pgrep` showing nothing afterwards is normal.
   Then go to Updates, press ⌘R and click Update.
3. **Clear the half-finished download:** `appstore-unstick --cache` opens
   `$(getconf DARWIN_USER_CACHE_DIR)com.apple.appstoreagent`. Delete the stuck
   app's partial download there, then run step 2 again.
4. **Sign out and back in:** Store ▸ Sign Out, then Sign In.
5. **Reinstall:** move the `.app` to the Trash and install it again from Store ▸ Purchased.
   Settings live in the app's container folder, so they usually survive. iPad-on-Mac apps are the
   most likely to need this.

## Notes
- This is a plain script with no LLM, and it doesn't send keystrokes to the screen.
- `killall` exits 1 when a daemon wasn't running; that's harmless.
