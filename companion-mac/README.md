# companion-mac — a whitelabeled comms fabric for talking to a second Mac

Stand up a durable, Apple-native channel between this machine and a companion
Mac (a Mac Mini server, a spare laptop, whatever). The **mechanism is public**
— every file here is generic and config-driven. **Your wired-up instance is
private** — it exists only as gitignored config you fill in. Nothing in this
package names a host, a token, a peer, or a domain.

This is the open-source skeleton of a real running instance ("Cloudcity"); the
instance's secrets and data never enter the repo, purely because the files that
hold them are gitignored.

## The doctrine: robust wins over brittle

Channels, in the order you should reach for them:

1. **Syncthing file-drop** (default) — drop a file in `queue/<svc>-inbox/`; the
   companion's worker picks it up and writes to `queue/<svc>-outbox/`. No live
   connection. Survives mDNS death, keychain gaps, network blips.
2. **git push → auto-pull** — `lib/repo-puller.sh` runs on the companion and
   fast-forwards your repos every 60s, running a restart action on change.
3. **Syncthing-mirrored heartbeats** — each service drops a `*-heartbeat.json`;
   `lib/preflight.sh` reads freshness with zero network.
4. **SSH** — last resort. Preflight first (`preflight.sh --ssh`); never retry in
   a loop; reap zombies (`preflight.sh --reap`). SSH lands in `~`, so every
   remote command uses absolute paths.

## Layout

```
companion.conf.example     instance config (host, paths, services)  → copy to companion.conf (private)
repos.conf.example         repos the puller tracks                   → copy to repos.conf (private)
setup.sh                   idempotent local-side installer
lib/
  common.sh                config loader + ssh wrapper + helpers
  queues.sh                scaffold queue/<svc>-{inbox,outbox,processed}
  heartbeat.sh             write a liveness heartbeat
  preflight.sh             "is it up?" via heartbeats, then tcp, then ssh
  repo-puller.sh           the git auto-pull loop (runs on the companion)
  boot-app/
    panes.conf.example     which services get a visible iTerm pane
    gen-boot-app.py        panes.conf → iTerm AppleScript (with SSH window guard)
    build.sh               compile Companion-Boot.app (Login Item)
services/
  _template/               copy this to add a service (inbox→process→outbox)
```

## Quickstart

```bash
cd companion-mac
./setup.sh                 # creates companion.conf, edit it, re-run
# wire Syncthing so $COMMS_DIR is shared with the companion
cp -R services/_template services/example && cd services/example
cp service.conf.example service.conf      # edit process_one()
cd ../../lib/boot-app && cp panes.conf.example panes.conf && ./build.sh
bash ../preflight.sh       # check status
```

## What stays private (gitignored)

`companion.conf`, `repos.conf`, `panes.conf`, every `services/*/service.conf`
and `.env`, the generated `Companion-Boot.app`, all `state/`, logs, and stdout.
Per-service tokens live in a service-local `.env`, never in any tracked file.

## Reference instance

The private reference implementation is "Cloudcity" — see the wiki concept page
`wiki/concepts/companion-mac-fabric.md` for the full architecture narrative and
how this skeleton maps onto a real always-on server.
