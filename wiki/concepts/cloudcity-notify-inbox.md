---
description: Generic Syncthing-mediated notification bus. Any peer (this laptop, CloudcityMacMini, any future machine on the Syncthing mesh) drops a JSON file into `~/work/comms/queue/notify-inbox/` and AppleToolbox on the receiving Mac renders it as a native `UNUserNotificationCenter` banner with optional Open / Reveal click actions. Decoupled, durable, robust over SSH. Built 2026-05-25.
---

# Cloudcity notification bus — `notify-inbox/` over Syncthing

## The principle

To send a native macOS notification from one Mac to another **without SSH, without a network service, without a daemon listening on a port**:

1. Sender writes a JSON file into a Syncthing-mirrored folder.
2. Syncthing replicates the file to the receiving Mac (seconds, eventually-consistent).
3. AppleToolbox on the receiver FSEvents-watches the folder, parses each new `.json`, renders a banner.
4. Processed files move to `notify-processed/`; failed files move to `notify-failed/` with reason.

The whole "transport" is file-system + Syncthing. There is no daemon to be down, no port to be blocked, no SSH key to expire, no auth to fail. Senders don't care which receivers are online — Syncthing handles offline delivery.

## The JSON contract

```json
{
  "id":          "any-unique-string",
  "title":       "Hello",                 (required)
  "subtitle":    "from CloudcityMacMini", (optional)
  "body":        "Detail line",           (optional)
  "sender":      "CloudcityMacMini",      (optional — for logging)
  "open_path":   "/path/to/file.txt",     (optional — click opens this)
  "reveal_path": "/path/to/file.txt",     (optional — "Reveal in Finder" action)
  "sound":       "default"                (optional — or omit for silent)
}
```

Only `title` is strictly required. Everything else is optional; the receiver renders what it has.

## Wire format / lifecycle

```
~/work/comms/queue/notify-inbox/         ← any peer drops <id>.json here
                       │
                       │ Syncthing → receiver
                       ▼
                AppleToolbox NotifyInboxWatcher
                       │
                       │ UNMutableNotificationContent + .add(req)
                       ▼
              native banner (clickable)
                       │
                       ├── default click → opens open_path (if any)
                       ├── "Open" button → opens open_path
                       └── "Reveal" button → activates Finder on reveal_path
                       │
                       ▼
~/work/comms/queue/notify-processed/<unix>-<orig>.json    (success)
~/work/comms/queue/notify-failed/<unix>-<orig>.json       (failure)
~/work/mediabank/var/log/notify-inbox.log                 (one line per event)
```

The receiver:

1. Watches the inbox via `DispatchSource.makeFileSystemObjectSource(.write, .extend, .rename, .attrib)` + a 60s backstop poll.
2. Coalesces flurry-of-writes into one drain ~250 ms after the last event.
3. Skips `*.partial` / `*.syncthing.*` so Syncthing's intermediate files don't get parsed.
4. Builds a `UNMutableNotificationContent` per file, attaches `userInfo: {sender, source_file, open_path?, reveal_path?}`.
5. Moves the JSON to `processed/` or `failed/` after delivery.

## Sender side — `cloudcity-notify` CLI

`~/work/mediabank/bin/cloudcity-notify` is a one-liner front door:

```
cloudcity-notify                              # auto-hello with hostname + time
cloudcity-notify "Title" "Body"               # positional
cloudcity-notify --title T --body B \         # full
                 --open /path/to/file
```

It writes a `.partial` file then atomic-renames to `.json` so the watcher never sees a half-written file. Same pattern works from any peer — Mac Mini's whisp-worker writes a JSON on every boot to announce "🎙 Whisp worker online on CloudcityMacMini" with zero round-trip and zero SSH.

## Why files-over-Syncthing beats alternatives

| Alternative | Failure mode | Files-over-Syncthing equivalent |
|---|---|---|
| SSH + osascript on remote | mDNS hostname resolution fails, SSH agent locked out of Keychain, multiple zombie retries | None — JSON drop, Syncthing handles it |
| HTTP webhook to local server | Server down, port blocked, TLS cert expired, IPv4/IPv6 mismatch | None |
| MQTT / pub-sub broker | Broker is a SPOF, needs install + config + auth | None |
| Push Notification service (APNs) | Needs Apple Developer account, certs, server | None |
| Email | Slow, requires SMTP config, lands in spam | None |

The cost of Syncthing-mediated delivery is **eventual consistency** — typically <5 s on LAN, longer on offline-then-reconnect. For notifications about pipeline progress, that's a non-issue.

## Categories — multiple bus-clients in one inbox

Any peer that wants click actions to route somewhere specific can pick its own `categoryIdentifier`. AppleToolbox's `NotificationRouter` (see `concepts/appletoolbox-as-launchagent-surface.md`) dispatches by category:

- `VOICEMEMO_TRANSCRIBED` — VoiceMemoPipeline's own banners, with Open / Reveal actions for transcript files.
- `CLOUDCITY_NOTIFY` — generic inbox banners (this doc's case), with Open / Reveal actions for `open_path` / `reveal_path`.
- `TAG_DISPATCHED` — TagWatcherRunner's "N files queued" banners, opens `~/work/comms/queue/` on click.

Adding a new category = add an entry to NotificationRouter + register the category at startup. ~10 lines.

## Examples

**Boot announcement from whisp-worker on the Mini.** When the Mini's whisp-worker starts (initial boot or after `sync_repo` pulls a code change and self-restarts), it drops:

```json
{
  "id": "1779712890-32178-whisp-boot",
  "title": "🎙 Whisp worker online on CloudcityMacMini",
  "subtitle": "boot notification",
  "body": "Booted at 2026-05-25T12:42:39. Ready for jobs.",
  "sender": "CloudcityMacMini"
}
```

Esa sees this banner on his laptop ~3 s later. Proves the channel works end-to-end without him doing anything.

**Transcript-ready ping from this laptop's pipeline.** VoiceMemoPipeline's `reconcileResults()` could (it doesn't, but could) drop a notify-inbox JSON instead of firing locally; another peer would render the banner. Useful if Esa ever has two Macs and wants notifications on whichever is foreground.

## Companion concepts

- `concepts/appletoolbox-as-launchagent-surface.md` — explains how the receiving renderer lives inside AppleToolbox, plus the NotificationRouter pattern.
- `concepts/finder-tag-pipeline.md` — same dispatch shape, different cargo (PDFs/audio instead of notifications).
- `operations/voice-memos-process-tag-pipeline.md` — production use of the bus for "Sent to whisp" / "Transcribed" banners.

## Reference implementation

- Renderer: `NotifyInboxWatcher` in `~/work/apple/topbar/AppleToolbox.swift`.
- CLI: `~/work/mediabank/bin/cloudcity-notify`.
- Worker self-announce: `~/work/whisp-transcripts/whisp-worker` boot section.

## Status

- 2026-05-25 — bus built, renderer wired into AppleToolbox, whisp-worker boot ping verified Mini→laptop. CLI shipped in `~/work/mediabank/bin/`.
