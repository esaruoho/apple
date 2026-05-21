# apps-exporter

Four small Apple consumer apps in one package: **Clock**, **Weather**,
**Stocks**, **Maps**. Each on its own is too thin for a full exporter
directory — most of their state lives in CloudKit — but each has a
useful slice on disk:

| App | What's on disk | Where |
|---|---|---|
| Clock | World Clock cities (full geo + tz) | `~/Library/Containers/com.apple.clock/.../com.apple.mobiletimer.plist` |
| Weather | Saved locations + Me-card home/work | `~/Library/Group Containers/group.com.apple.weather/.../group.com.apple.weather.plist` |
| Stocks | Tracked tickers (mined from CK bplist) | `~/Library/Group Containers/group.com.apple.stocks/.../com.apple.stocks.private-production-dbstore.json` |
| Maps | Navigation prefs + RAP submissions + last camera | container + group container plists |

Apple-native only. No `pip`, no `brew`.

## Commands

```bash
apps-exporter status              # one-line summary per app
apps-exporter clock               # full Clock data (markdown to stdout)
apps-exporter weather             # ditto
apps-exporter stocks              # ditto
apps-exporter maps                # ditto
apps-exporter <app> --json        # raw JSON instead of markdown

apps-exporter export              # write all four to ~/work/cc/vault/sources/
apps-exporter export --vault PATH # override the vault root
```

## Vault placement

Default destination is `~/work/cc/vault/sources/<app>/<app>.md`, joining
the 25 existing per-app vault sources (`books/`, `mail/`, `safari/`, …)
with YAML frontmatter `{source, exporter, extracted_at}`.

## Why one package, not four

Each of these is a ~30-line plist reader. Four directories with their
own README + .env + wrapper is overhead with no payoff. Bundling them
honours the apple-skill principle that the package boundary should
match the work boundary, not the app boundary.

## Run via `apple-grand-export`

`apple-grand-export` includes `apps-exporter:export` so the four are
refreshed alongside every other vault source. To run them in isolation
use the subcommands directly.

## What's *not* here

- Real-time weather conditions (those are HTTP calls to Apple's weather
  service, not on disk).
- Live stock quotes (same — Yahoo/Apple's stockskit pipes).
- Maps favorites/recents/offline regions (pure CloudKit; no local copy
  for these on macOS).

If those become important, they belong as separate exporters that wrap
the relevant APIs rather than reading local plists.
