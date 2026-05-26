# MacMini

> Headless small-form Mac. The always-on box. In this skill, MacMini means **CloudcityMacMini** — the server that runs PakettiBot, Voicebox, OCR worker, repo-puller, and the Syncthing inbox.

## Role

The **server tier** of Esa's setup. Plugged in 24/7, on Ethernet, never sleeps, runs the workloads MacBookPro can't sustain. Reachable via:

1. **Syncthing file drop** (default channel — see `~/.claude/CLAUDE.md` mandatory rule)
2. **Git push → auto-pull** via `repo-puller.sh`
3. **`!pk run --direct`** via the pakettibot file bridge
4. **SSH** (last resort, must preflight)

## Automation surface

Identical software stack to MacBookPro/MacBookAir — full AppleScript, Shortcuts, App Intents, Cocoa. Two differences in practice:

- **No keyboard / mouse at the device** — UI scripting via System Events still works because there's a logged-in GUI session, but no human will rescue a stuck modal dialog. Design for headless.
- **Always-on means LaunchAgents fire on schedule** — unlike MacBookPro which sleeps, the MacMini is the right target for cron-style work, polling watchers, periodic OCR/whisper jobs.

## Cross-device fabric — inbound to MacMini

The MacMini is mostly a **receiver**:

- **Syncthing** inbound from MacBookPro / iPhone
- **AirDrop** receive (less used because Syncthing is the durable channel)
- **AirPlay** receive disabled by default to avoid accidental routing
- **Screen Sharing / VNC** for occasional debugging
- **Continuity** features mostly unused — the MacMini is not in the Continuity cluster Esa carries around

## Trigger surface — what runs on the MacMini

- **Syncthing inboxes** — `~/work/comms/queue/<service>-inbox/` (pakettibot, voicebox, ocr, whisp)
- **`repo-puller.sh`** — polls every 60s, pulls tracked repos with deferred-restart safety
- **PakettiBot** — Discord bot running under Cloudcity-Boot.app
- **Voicebox** — TTS synthesis worker
- **OCR worker** — paperless-equivalent for the lookthrough/ pipeline
- **Whisp worker daemon** — YouTube transcription queue

## Painpoints specific to MacMini-as-server

- **Headless TCC** — Full Disk Access and Automation permissions must be granted via Screen Sharing once; can't be deferred to "first launch when I'm there"
- **mDNS reachability** — `CloudcityMacMini.local` resolution fails when the laptop is on a different SSID or VPN; always run `mini-up` preflight before SSH (`~/.claude/skills/cloudcity/skill.md`)
- **No GPU display attached** — some Metal code paths assume a connected display; verify before relying on GPU compute headlessly
- **Container-read TCC filter** — LaunchAgent-spawned bash cannot list app container directories; use AppleToolbox.app (with FDA grant) instead of bare LaunchAgent (`feedback_launchd_cannot_read_app_containers.md`)

## Cross-refs

- Cloudcity channel hierarchy: `~/.claude/skills/cloudcity/skill.md` and `~/.claude/CLAUDE.md` (Syncthing-default rule)
- HomePod sensor pipeline lives on this box: `wiki/entities/homepod.md`
- iPhone → MacMini notification path: `wiki/concepts/iphone-notify-pipeline.md`
- Voicebox / OCR / Whisp queues: see the `bbs` and `voicebox` skills
