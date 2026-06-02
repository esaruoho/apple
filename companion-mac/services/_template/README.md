# Service template

The "add a service" extension point for the companion-mac fabric. A service is
an inbox → process → outbox worker that runs on the companion and talks to the
local machine only through Syncthing-mirrored queue folders — never a live
connection.

## Instantiate a new service

```bash
cp -R services/_template services/myservice
cd services/myservice
cp service.conf.example service.conf
$EDITOR service.conf        # set SERVICE_NAME, POLL_INTERVAL, process_one()
```

Then register its queue folders and (optionally) a boot-app pane:

```bash
# 1. add the name to SERVICES in companion.conf, then:
bash ../../lib/queues.sh

# 2. add a pane line to lib/boot-app/panes.conf (see pane.applescript.snippet),
#    then rebuild:
cd ../../lib/boot-app && ./build.sh
```

## The contract

| Folder | Who writes | Meaning |
|---|---|---|
| `$QUEUE_DIR/<svc>-inbox/` | the local machine | a job to do |
| `$QUEUE_DIR/<svc>-outbox/` | the worker | the result, synced back |
| `$QUEUE_DIR/<svc>-processed/` | the worker | inputs already consumed |

`worker.sh` claims each input by moving it out of the inbox *before* processing,
so a Syncthing re-scan can never double-process it. It writes a heartbeat every
loop so `lib/preflight.sh` can see the service is alive without any SSH.

## What does NOT belong here

- Secrets/tokens → a service-local `.env` you also gitignore, never in git.
- One-shot bulk jobs (a 500-file download) → not a service. Run detached and
  report via a status command. See the wiki concept page.
