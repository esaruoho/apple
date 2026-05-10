# Sal Archive Status

Updated: 2026-05-10T21:17:35Z

## Current State

- Extracted inline AppleScript examples: `597`
- Curriculum lesson modules indexed: `38` across `6` tracks
- Download/media targets indexed: `359`
- Unique target status counts:
  - `recovered`: `235`
  - `captured-in-mirror`: `12`
  - `external-reference`: `18`
  - `missing`: `3`

## By Site

- `configautomation.com` -> `recovered`: `5`, `captured-in-mirror`: `1`, `external-reference`: `2`
- `dictationcommands.com` -> `captured-in-mirror`: `2`, `external-reference`: `3`
- `iworkautomation.com` -> `recovered`: `79`
- `macosxautomation.com` -> `recovered`: `148`, `captured-in-mirror`: `9`, `external-reference`: `8`, `missing`: `3`
- `photosautomation.com` -> `recovered`: `3`, `external-reference`: `5`

## Remaining Work

- Missing packages: `3`
- Missing videos: `0`
- `macosxautomation.com` missing packages: `3` dead URLs.
- `iworkautomation.com` missing videos: `0`. `PresidentsSQLiteDB.zip` recovered 2026-05-06 via DB Events Examples bundle from Sal Soghoian.
- `photosautomation.com` missing videos: `0`. `installer.zip` and `Photos-to-Keynote.mp4` recovered 2026-05-06 directly from Sal Soghoian.

### Missing Packages

- `https://macosxautomation.com/405/us/media/apple/applescript/2008/aperturepdfworkflows.zip`
- `https://macosxautomation.com/applescript/apps/Script_Geek.zip`
- `https://macosxautomation.com/applescript/apps/Script_Geek_old.zip`

### Priority Video Queue


## Next Recommended Actions

- Transcribe retained local media and attach transcript paths to lessons and indexes.
- Extract recovered ZIP contents into curated script/example folders under `scripts/sal/`.
- Cross-link every recovered bundle, script, video, and transcript back into `indexes/sal-lessons.yaml`.
- Keep failure markers for dead URLs so the archive does not regress into false positives.
