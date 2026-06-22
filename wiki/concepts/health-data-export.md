---
description: How to get Apple Health data off the iPhone and into useful files on the Mac. HealthKit has no scripting API; the only export is a manual iPhone tap producing export.zip, which bin/health-export parses into CSVs + summary.
---

# Health data export (iPhone → Mac → files)

## The hard constraint

There is **no macOS or iPhone scripting API to read Health data**. HealthKit is
gated behind on-device entitlements granted only to signed apps the user has
explicitly authorised; Apple ships no CLI, Shortcuts action, or AppleScript verb
for "export all health data". The support page
[`iph5ede58c3d`](https://support.apple.com/en-gb/guide/iphone/iph5ede58c3d/ios)
("View and share health data") covers *live sharing* and *iCloud backup* — not a
file export.

So the export is necessarily a **manual tap on the iPhone**, which must not be
UI-hijacked (see `feedback_never_ui_hijack_active_session`). Division of labour:

```
iPhone (manual, once)  →  AirDrop / Files  →  Mac: bin/health-export (repeatable)
```

## Step 1 — produce export.zip on the iPhone

Health app → tap **profile photo** (top-right) → scroll to bottom →
**Export All Health Data** → Export. It builds `export.zip` (minutes; often
100 MB–1 GB+). Share sheet → **AirDrop** to this Mac (lands in `~/Downloads`),
or Save to Files → iCloud Drive.

## Step 2 — parse on the Mac

`bin/health-export` (`/health-export`) — pure Python stdlib, streams the XML via
`ElementTree.iterparse` so a multi-hundred-MB file never loads into RAM.

```
bin/health-export ~/Downloads/export.zip            # full parse → ./health-export-out
bin/health-export ~/Downloads/export.zip --list     # just list types + counts
bin/health-export ~/Downloads/export.zip --only StepCount,HeartRate --outdir ~/health
```

Accepts the `.zip`, an extracted `export.xml`, or a directory containing either.

### Outputs

| File | What |
|---|---|
| `records/<Type>.csv` | raw rows: startDate, endDate, value, unit, sourceName |
| `daily/<Type>.csv` | per-day aggregate — **sum** for counts/distance/energy, **mean** for rates (heart-rate, SpO2, weight, BP…) |
| `summary.md` | profile (sex/DOB), date range, every metric with count + first/last + sources, workout tally |
| `workouts.csv` | one row per workout (type, duration, distance, energy) |
| `manifest.json` | machine-readable index |

### export.xml shape (for reference)

```xml
<HealthData>
  <Me HKCharacteristicTypeIdentifierBiologicalSex="…" HKCharacteristicTypeIdentifierDateOfBirth="…"/>
  <Record type="HKQuantityTypeIdentifierStepCount" sourceName="iPhone" unit="count"
          startDate="2024-01-01 08:00:00 +0200" endDate="…" value="500"/>
  <Workout workoutActivityType="HKWorkoutActivityTypeRunning" duration="30.5" .../>
</HealthData>
```

Also inside the zip but not parsed here: `export_cda.xml` (clinical CDA form),
`electrocardiograms/*.csv` (ECG waveforms), `workout-routes/*.gpx` (GPS tracks).

## What it's useful for

CSVs open directly in Numbers/Excel for charts; `daily/` is the right grain for
trend plots; `manifest.json` feeds downstream tooling; the GPX routes (in the zip)
load into any mapping tool.
