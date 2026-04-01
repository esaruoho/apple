# Sal Capture Failures And Workarounds

Date: 2026-04-01

Related manifests:
- `sources/sal/macosxautomation.com/manifest.yaml`
- `sources/sal/iworkautomation.com/manifest.yaml`
- `sources/sal/photosautomation.com/manifest.yaml`
- `sources/sal/configautomation.com/manifest.yaml`
- `sources/sal/dictationcommands.com/manifest.yaml`

## Summary

The first-pass archive strategy worked well for `macosxautomation.com` and `iworkautomation.com`, but the other Sal domains required manual Wayback snapshot targeting. The main failure mode was not "site gone"; it was unstable acquisition paths.

## Failures Observed

### 1. Live shell fetches were inconsistent

- `photosautomation.com` failed fast from shell-based live capture even though browser-style access and archived snapshots existed.
- `configautomation.com` showed unreliable shell-side resolution and did not produce a trustworthy live crawl.

Interpretation:
- The domains are not uniformly dead; acquisition from this environment was inconsistent.
- Direct live crawling should not be treated as authoritative failure for these sites.

### 2. Wayback CDX discovery was unstable

- `dictationcommands.com` initially showed hundreds of archived URLs during CDX discovery.
- Later CDX queries for the same domain returned zero valid URLs.
- `configautomation.com` behaved similarly: broader CDX discovery produced candidate URLs earlier, then later CDX lookups returned none.

Interpretation:
- CDX-based "discover everything first" is not reliable enough by itself for these domains.
- A successful early discovery does not guarantee repeatability.

### 3. Direct Wayback snapshot crawling worked better than CDX discovery

Successful user-provided anchors:

- `http://web.archive.org/web/20240424181821/http://dictationcommands.com/`
- `http://web.archive.org/web/20240422004004/https://configautomation.com/`
- `http://web.archive.org/web/20240721142125/http://photosautomation.com/`

Result:
- `dictationcommands.com` direct snapshot produced core HTML pages, CSS, images, and mp4 demos.
- `configautomation.com` direct snapshot produced core section pages, CSS, images, and mp4 media.
- `photosautomation.com` direct snapshot produced core section pages, stylesheet, and banner image.

Interpretation:
- For fragile Sal domains, user-specified Wayback snapshot roots are a stronger preservation method than open-ended CDX discovery.

### 4. The wrapper originally treated empty capture runs as success

`bin/sal-mirror.py` initially updated manifests even when no meaningful site content had been captured. This created false-positive `captured` states.

Fix applied:
- the wrapper now raises an error when zero actual content files are present in the engine output
- manifests were corrected to avoid claiming success where capture was blocked or partial

## What Worked

- Live capture for `macosxautomation.com`
- Live capture for `iworkautomation.com`
- Direct snapshot crawl for `dictationcommands.com`
- Direct snapshot crawl for `configautomation.com`
- Direct snapshot crawl for `photosautomation.com`

## Remaining Gaps

- None of the mirrored domains have been fully normalized into `scripts/sal/*` yet.
- The direct snapshot captures for `dictationcommands.com`, `configautomation.com`, and `photosautomation.com` are partial slices, not proof of total site coverage.
- "All of Sal" still requires targeted gap analysis and follow-up snapshot expansion, especially for downloads, scripts, and orphaned pages.

## Recommended Next Pass

1. Inventory each mirrored site section by section.
2. Extract linked script/download targets from the mirrored HTML.
3. Use targeted Wayback roots for any missing branches instead of generic CDX-first discovery.
4. Normalize preserved scripts and examples into `scripts/sal/<site>/`.
