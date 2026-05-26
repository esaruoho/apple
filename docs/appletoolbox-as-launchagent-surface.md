---
layout: default
title: "AppleToolbox as the unified LaunchAgent surface"
---

---
description: Architectural pattern — instead of one LaunchAgent per watcher (one for tag-watcher, one for voice-memo-watcher, one for notification-handler …), consolidate them as Swift `Timer`-driven subsystems inside AppleToolbox. Inherits FDA, dispatches native `UNUserNotificationCenter` banners, single log surface to look at when something stalls. Crystallised 2026-05-25 → 2026-05-26 while building the voice-memo → whisp pipeline.
---

# AppleToolbox as the unified LaunchAgent surface


[← Back to home](./)
## The principle

Every "polling watcher with side-effects" on this Mac runs **inside AppleToolbox**, not as its own LaunchAgent.

- Voice Memos title scanner (`#process` → whisp-inbox) → `VoiceMemoPipeline` Swift class.
- Finder-tag dispatcher (`process` tag → router → workers) → `TagWatcherRunner` Swift class.
- Cloudcity notification renderer (any peer drops JSON → native banner) → `NotifyInboxWatcher` Swift class.
- Stickies → Claude trigger → Swift `Timer` + `DispatchSource.makeFileSystemObjectSource`.

All four are owned by `AppDelegate.applicationDidFinishLaunching`, all four poll on the AppleToolbox main runloop, all four log to `~/work/mediabank/var/log/<name>.log`.

There is exactly one LaunchAgent on the system: `com.esaruoho.appletoolbox`. Old watcher LaunchAgents (`com.esa.tag-watcher`, etc.) get **renamed to `.disabled.<label>.plist`** rather than deleted, so restoring them is `mv` + `launchctl load`.

## Why consolidate

Every separate LaunchAgent costs:

- **A TCC grant.** macOS TCC (Privacy & Security) is per-binary. A standalone Python LaunchAgent that needs to read protected paths (Voice Memos' `CloudRecordings.db`, Stickies' container, anywhere under `~/Library/Group Containers/`) needs its own Full Disk Access grant. AppleToolbox already has FDA; **child processes inherit it for the duration of the exec chain**. One TCC grant covers every watcher AppleToolbox spawns.
- **A separate process to find when something's wrong.** With N LaunchAgents you have N stderr/stdout pairs in `/tmp/`, N launchd labels to `launchctl list | grep`, N "is this thing actually running" questions. One AppleToolbox = one process to check.
- **A separate notification pathway.** A bash/Python LaunchAgent that wants to fire a banner has to shell out to `osascript display notification` (limited, no click actions, no userInfo) OR run terminal-notifier (not installed by default). AppleToolbox sits inside Swift with `UNUserNotificationCenter` available natively — clickable banners with action buttons and structured `userInfo` payloads are a 5-line addition.
- **Drift.** Esa observed (2026-05-25): the `com.esa.tag-watcher` LaunchAgent had been firing every 60 s for weeks but its log showed no entries past May 21. Reason unclear (launchd quietly throttled? plist corrupted?). When the dispatcher moved inside AppleToolbox and ran off an `NSTimer`, the issue vanished and dispatched files immediately produced native banners.

## The contract

Each subsystem follows the same shape:

```swift
final class FooRunner: NSObject {
    private let interval: TimeInterval = 60
    private var timer: Timer?
    private let logFile: String

    override init() {
        self.logFile = "\(NSHomeDirectory())/work/mediabank/var/log/foo-runner.log"
        super.init()
        ensureLogDir()
    }

    func start() {
        log("starting (interval=\(Int(interval))s)")
        DispatchQueue.main.async { [weak self] in self?.tick() }
        let t = Timer(timeInterval: interval, repeats: true) {
            [weak self] _ in self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        DispatchQueue.global(qos: .utility).async { [weak self] in self?.work() }
    }

    private func work() {
        // The actual periodic job. Off the main runloop.
        // Spawn child processes (Process()), read files, parse output,
        // fire UNUserNotificationCenter banners on success/failure.
    }

    private func log(_ msg: String) { /* append to logFile + fputs stderr */ }
}
```

Wired into `AppDelegate.applicationDidFinishLaunching`:

```swift
let foo = FooRunner()
fooRunner = foo
foo.start()
```

And the LaunchAgent that previously owned the work gets retired:

```
launchctl bootout gui/$(id -u)/com.esa.foo-watcher
mv ~/Library/LaunchAgents/com.esa.foo-watcher.plist \
   ~/Library/LaunchAgents/.disabled.com.esa.foo-watcher.plist
```

## Notification routing — one delegate, many categories

`UNUserNotificationCenter` allows exactly **one** delegate per app. With multiple subsystems wanting click handlers, the AppDelegate owns a `NotificationRouter` that dispatches by `categoryIdentifier`:

```swift
final class NotificationRouter: NSObject, UNUserNotificationCenterDelegate {
    weak var voicememo:   VoiceMemoPipeline?
    weak var notifyInbox: NotifyInboxWatcher?

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        switch response.notification.request.content.categoryIdentifier {
        case "VOICEMEMO_TRANSCRIBED":
            voicememo?.handle(response: response)
        case "CLOUDCITY_NOTIFY":
            notifyInbox?.handle(response: response)
        case "TAG_DISPATCHED":
            // …open ~/work/comms/queue/
            break
        default: break
        }
        completionHandler()
    }
}
```

Each subsystem registers its own `UNNotificationCategory` (with action buttons like "Open transcript", "Reveal in Finder") and uses its own category id. The router demuxes.

## When NOT to consolidate

There are still legitimate uses for a separate LaunchAgent:

- **Truly independent lifecycle.** If a service needs to survive AppleToolbox restarts during development hot-rebuilds, keep it separate.
- **Long-running synchronous work** that would block AppleToolbox's main runloop if run inline. Use a child Process() instead.
- **Different TCC posture.** A service that explicitly should NOT inherit AppleToolbox's FDA (e.g. a sandboxed renderer) needs its own bundle.
- **Cross-user services.** AppleToolbox runs as the logged-in user; per-system services (`/Library/LaunchDaemons/`) need to stay separate.

## Reference implementation

`~/work/apple/topbar/AppleToolbox.swift`:

- `VoiceMemoPipeline` — SQLite poller for Voice Memos' `CloudRecordings.db`, submits `#process`-tagged memos to `whisp-inbox`, fires `🎙 Sent to whisp` + `✓ Voice memo transcribed` banners.
- `NotifyInboxWatcher` — FSEvents-watches `~/work/comms/queue/notify-inbox/` for `*.json`, renders each as a native banner.
- `TagWatcherRunner` — runs `bin/tag-watcher` as a child Process every 60 s, parses its `dispatched: N` output, fires `📋 N files dispatched` banner with the filename list.
- `NotificationRouter` — single UN delegate, demuxes by category.

All four log to `~/work/mediabank/var/log/<subsystem>.log`.

## Companion concepts

- `concepts/cloudcity-notify-inbox.md` — the Syncthing-mediated notification bus that NotifyInboxWatcher consumes.
- `concepts/finder-tag-pipeline.md` — the dispatch shape (tag → Syncthing inbox → Mac Mini worker) that TagWatcherRunner now owns.
- `operations/voice-memos-process-tag-pipeline.md` — concrete end-to-end use.
- `concepts/stickies-claude-trigger.md` — first instance of this pattern (predates the consolidation principle being named).

## Status

- 2026-05-25 — VoiceMemoPipeline + NotifyInboxWatcher built inside AppleToolbox.
- 2026-05-26 — TagWatcherRunner consolidated in; `com.esa.tag-watcher.plist` disabled. Pattern named.
