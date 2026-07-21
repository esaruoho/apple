# MacMini

> Headless small-form Mac. The always-on box. In this skill, MacMini means **CloudcityMacMini** — the server that runs PakettiBot, Voicebox, OCR worker, repo-puller, and the Syncthing inbox.

## Role

The **server tier** of Esa's setup. Plugged in 24/7, on Ethernet, never sleeps, runs the workloads MacBookPro can't sustain. Reachable via:

1. **Syncthing file drop** (default channel — see `~/.claude/CLAUDE.md` mandatory rule)
2. **Git push → auto-pull** via `repo-puller.sh`
3. **`!pk run --direct`** via the pakettibot file bridge
4. **SSH** (last resort, must preflight)

## Connectivity / Internet

As of **2026-07-21** the Mini has its **own standalone 24/7 5G internet uplink** — a Telia 5G line at **€24.95/month** — so the always-on server is online independent of any other machine.

- **Why standalone:** the workspace has no wired uplink the Mini can rely on. The earlier plan (iPhone USB → MacBookPro → Thunderbolt → CalDigit TS4+ → Ethernet → Mini, via macOS Internet Sharing) was **abandoned**: it makes the server's internet hostage to Esa's MacBook Pro + iPhone being physically present and plugged in. For a box that must run while Esa is away, that's a liability, not connectivity.
- **Speed (measured 2026-07-21 via `networkQuality` on the Mini):** **↓ 870.6 Mbps** / **↑ 100.5 Mbps**, idle latency 33.9 ms, under-load responsiveness Medium (186 ms / 322 RPM). Near-gigabit down — faster than most Finnish home fibre baselines.
- **Tracked in finances:** `~/work/cc/vault/finances/manual-bills.json` → "Telia 5G (Workspace / CloudcityMacMini)", €24.95/mo, category `telecom`. Distinct from the ~€32/mo "Telia Internet" **home** (Vuosaari) line.
- **Internet Sharing gotcha (for the record):** iPhone USB tethering spawns a new `enNN` + duplicate "iPhone USB" network service on every re-enumeration; macOS refuses to remove the ghosts via `networksetup` (only wiping the *not-connected* ones in System Settings → Network works). The live tether is always the sole interface holding a `172.20.10.x` address. On Sequoia+ the Internet Sharing daemon is `com.apple.NetworkSharing` (not the old `com.apple.InternetSharing`).

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
