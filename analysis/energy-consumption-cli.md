---
title: macOS energy consumption via CLI — answer to Dima
date: 2026-06-30
type: analysis
audience: Dima (collaborator)
status: draft-reply
---

# macOS energy consumption via CLI — what we can address for Dima

Dima already has a script that reads **current power-adapter wattage**. He wants the
Activity-Monitor **"Energy" tab** ("which apps consume the most energy over time") from the
command line. Short version: **yes, it's available** — Activity Monitor's Energy Impact
column is just a front-end over Apple CLIs. The one thing macOS does *not* give you for free
is a persistent *historical* per-app database; you have to log and aggregate it yourself.

## 1. Per-app energy impact — the direct Activity Monitor equivalent

### `powermetrics --samplers tasks` (the real answer, needs sudo)
This is exactly the data feeding Activity Monitor's Energy tab.

```bash
sudo powermetrics --samplers tasks --show-process-energy -i 5000 -n 1
```

- `--show-process-energy` adds the per-process **Energy Impact** column (same metric AM shows).
- `-i 5000` = sample window in ms, `-n 1` = number of samples.
- Sort the output by the energy column to get the top consumers.

To accumulate **over time** (e.g. every 60s for an hour, logged to a file):

```bash
sudo powermetrics --samplers tasks --show-process-energy \
  -i 60000 -n 60 -f text > ~/energy-log.txt
```

Then aggregate per-process across samples → a ranked "who burned the most this hour" report.
This is the piece worth turning into a small tool (see §5).

### `top` power column (no sudo, instantaneous)
```bash
top -l 1 -o power -stats pid,command,power
```
The **POWER** column is the same per-process energy-impact number. No sudo needed, but it's a
*snapshot*, not accumulated — good for "what's spiking right now", weak for "over the day".

## 2. System-level power draw in watts (Apple Silicon + Intel)

```bash
sudo powermetrics --samplers cpu_power,gpu_power -i 1000 -n 5
```
Reports CPU / GPU / ANE / package power in mW. On Apple Silicon this is the combined
package power — the closest thing to "how many watts is this Mac pulling right now".

## 3. Power source / adapter / battery (what Dima's script already does)

> Dima's existing script is **`system_profiler SPPowerDataType | grep Wattage`** — the
> current adapter wattage. `apple-energy adapter` is a superset of exactly that line.


```bash
system_profiler SPPowerDataType      # adapter wattage, charging state, battery health/cycles
pmset -g batt                        # current source + % + time remaining
pmset -g ac                          # AC adapter details
pmset -g pslog                       # streams power-source changes over time (good for logging)
pmset -g rawlog                      # raw battery telemetry stream
ioreg -rw0 -c AppleSmartBattery      # low-level: amperage, voltage, instantaneous draw
```
Confirmed on this Mac: `system_profiler SPPowerDataType` → `Wattage (W): 87`. If Dima's
adapter script uses `ioreg`, `system_profiler` is a friendlier one-liner for the same fact.

`pmset -g pslog` is the underrated one for *over-time* work — it emits a timestamped line on
every power-source transition, so you can log charge/discharge behavior cheaply without sudo.

## 4. The honest limitation

macOS keeps **no queryable historical per-app energy store**. Activity Monitor's
"Avg Energy Impact" is computed from a rolling ~8-hour in-memory window that isn't exposed
via any CLI or file. So "which apps consumed the most over the *last day*" can't be *read
back* — it has to be *recorded* by sampling `powermetrics` on an interval and aggregating.
That's the gap a small tool fills.

## 5. What we could build (apple repo `bin/` tool)

A natural fit for the apple toolbox — `bin/apple-energy`:

- **`apple-energy now`** → `top` power column, ranked, no sudo. Instant snapshot.
- **`apple-energy watch [minutes]`** → wraps `sudo powermetrics --samplers tasks`, logs each
  sample, aggregates per-process energy, prints a ranked "top consumers over the window"
  report at the end. This is the actual Activity-Monitor-over-time-on-CLI deliverable.
- **`apple-energy power`** → system watts via `cpu_power,gpu_power`.
- **`apple-energy adapter`** → `system_profiler SPPowerDataType` one-liner (replaces/extends
  Dima's adapter script).

All Apple-shipped CLIs, no Homebrew, no deps — same constraints as the rest of the toolbox.

## TL;DR for the reply

- **"Which apps over time"** → `sudo powermetrics --samplers tasks --show-process-energy`
  (sample on an interval + aggregate). This *is* the Energy tab's data source.
- **No-sudo quick look** → `top -l 1 -o power -stats pid,command,power`.
- **System watts** → `sudo powermetrics --samplers cpu_power,gpu_power`.
- **Adapter/battery** → `system_profiler SPPowerDataType`, `pmset -g pslog` for over-time
  source logging.
- **Caveat** → macOS exposes no historical per-app energy DB; you log + aggregate yourself.
