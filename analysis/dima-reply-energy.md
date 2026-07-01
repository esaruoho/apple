---
title: Reply to Dima — energy consumption via CLI
date: 2026-06-30
type: email-draft
---

# Reply to Dima — energy via CLI

Hey Dima,

Yes — turns out the Activity Monitor "Energy" tab is just a friendly front-end over a few Apple-shipped CLIs, so you can get all of it from the terminal. Your `system_profiler SPPowerDataType | grep Wattage` is the adapter piece; here's the rest.

**Which apps consume the most energy (the Energy-tab data) — needs sudo:**

```
sudo powermetrics --samplers tasks --show-process-energy
```

`--show-process-energy` adds the per-process **Energy Impact** column — literally the same metric Activity Monitor shows. Add `-i 60000 -n 60` to sample every 60s for an hour, then aggregate per process to get "who burned the most over the window."

**Quick look without sudo** (instantaneous, not accumulated):

```
top -l 2 -o power -stats pid,command,power
```

The POWER column is the same energy-impact number. Use `-l 2` and read the second listing — the first always reads 0.0 because it needs a delta.

**Actual system watts (CPU/GPU/package, in mW):**

```
sudo powermetrics --samplers cpu_power,gpu_power -i 1000 -n 5
```

**The one catch:** macOS keeps *no* queryable historical per-app energy store. Activity Monitor's "Avg Energy Impact" is a rolling in-memory window that isn't exposed anywhere. So "top apps over the last day" can't be *read back* — you have to *log* powermetrics on an interval and aggregate it yourself.

So I wrapped exactly that into a little Apple-native tool (no Homebrew, no deps) — `apple-energy`:

- `apple-energy now` — no-sudo snapshot, top apps by energy impact
- `apple-energy watch 10` — samples powermetrics for 10 min and prints a ranked "top consumers over the window" report (this is the Energy-tab-over-time piece)
- `apple-energy power` — system watts
- `apple-energy adapter` — your wattage one-liner + battery state

Happy to send it over if it's useful.

Cheers,
Esa
