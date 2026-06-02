---
description: Whitelabeled, Apple-native comms fabric for talking to a second Mac — public mechanism, private instance. The open-source skeleton of Cloudcity.
---

# Companion-Mac Fabric

> How to communicate with a different computer — durably, Apple-native, and
> whitelabeled so the *mechanism* is public while the *instance* stays private.

The package lives at `companion-mac/`. The reference (private) instance is
**CloudcityMacMini**; its operational detail lives only in the `cloudcity`
skill (`~/.claude/skills/cloudcity/skill.md`), never in this repo.

## The seam: public mechanism, private instance

The whole point. Two halves that must never bleed into each other:

| Public (committed = "creation code") | Private (gitignored = "the actual mirror") |
|---|---|
| `lib/*.sh`, `services/_template/`, `*.example`, `setup.sh`, `README.md` | `companion.conf`, `repos.conf`, `panes.conf`, `services/*/service.conf`, `.env` |
| the *shape* of the queue (`queue/<svc>-{inbox,outbox,processed}`) | the files that flow through it |
| the boot-app *generator* | the generated `Companion-Boot.app` |
| generic host placeholder `companion.local` / `$COMPANION_HOST` | the real hostname, SSH alias, Tailscale name |

Privacy is achieved **purely by gitignore** — the populated instance is private
on virtue of its files not being in the repo, not by any in-repo secrecy. Anyone
can clone the skeleton, fill in one gitignored config, and run their own. Your
Cloudcity is just one private instance of the public pattern.

This is the same split the repo already uses for `*-exporter/.env`,
`mini-onboarding/`, and `exported/` — generalized into a standalone package.

## Channel hierarchy — robust wins over brittle

Reach for channels in this order. The first four ride Syncthing/git and survive
mDNS death, keychain gaps, and network blips; SSH does not.

1. **Syncthing file-drop** (default) — `queue/<svc>-inbox/` → worker →
   `queue/<svc>-outbox/`. No live connection. `lib/queues.sh` scaffolds it;
   `services/_template/worker.sh` implements the worker side of the contract.
2. **git push → auto-pull** — `lib/repo-puller.sh` runs on the companion,
   fast-forwards each repo in `repos.conf` every 60s, runs a post-pull action
   on change, defers restarts while work is in flight.
3. **Heartbeats** — each service drops `queue/<name>-heartbeat.json` every loop
   (`lib/heartbeat.sh`). `lib/preflight.sh` reads freshness by mtime — zero
   network when healthy.
4. **SSH** — last resort. `preflight.sh --ssh` verifies it actually resolves +
   authenticates for *this* shell before you rely on it; `preflight.sh --reap`
   kills zombie ssh/scp. SSH lands in `~`, so every remote command uses
   **absolute paths**. Two failures → stop, fall back to Syncthing, never loop.

## The file-drop bridge contract

| Folder | Writer | Meaning |
|---|---|---|
| `queue/<svc>-inbox/` | local machine | a job |
| `queue/<svc>-outbox/` | companion worker | the result, synced back |
| `queue/<svc>-processed/` | companion worker | consumed inputs |

The worker **claims** each input by moving it out of the inbox *before*
processing — so a Syncthing re-scan can never double-process. Validated
end-to-end: drop → claim → `process_one` → outbox → archive → heartbeat.

## The boot-app pane pattern

Every long-running service gets a **visible iTerm pane** that at minimum tails
its log — "if I can't see it working, I can't trust it's working." `panes.conf`
lists `Name|command` lines; `gen-boot-app.py` emits the iTerm AppleScript
(carrying the SSH-launch window guard that rescues `open` over SSH from error
-1728); `build.sh` compiles `Companion-Boot.app`, which you set as a Login Item.

**One-shot bulk jobs are not services** — they run detached (`nohup … & disown`)
and report via a status command, not a permanent pane.

## Adding a service

`cp -R services/_template services/<name>`, fill in `service.conf`
(`process_one`), add the name to `SERVICES` in `companion.conf`, run
`lib/queues.sh`, add a `panes.conf` line, rebuild the boot-app. Per-service
secrets go in a service-local gitignored `.env`, never in a tracked file.

## Cross-refs

- Package: `companion-mac/README.md`
- Private reference instance: `~/.claude/skills/cloudcity/skill.md` (Syncthing
  default, repo-puller, the 8 panes, SSH preflight)
- Onboarding precedent: `mini-onboarding/`
- Server device profile: `wiki/devices/MacMini.md`
- iPhone notify path: `wiki/concepts/iphone-notify-pipeline.md`
