---
description: The Mini's webcam pipeline outputs — where they live, why mosaics+timelapses were un-synced from the laptop (2026-09-18), and how to pull on demand over Tailscale instead of Syncthing-mirroring.
---

# Webcam: pull-on-demand, not Syncthing-mirror

The Cloudcity Mini (`cloudcitymacmini`, Tailscale `100.117.30.102`) runs a webcam pipeline
(`webcam-capture` / `webcam-mosaic` / `webcam-timelapse` / `webcam-guardian`, defined in
`convey/systems.yaml`, principle 0043). This page records where its outputs live and how the
laptop reaches them **without** mirroring 39 GB locally.

## Where the outputs live (on the Mini)

| Output | Path on the Mini | Size (2026-09-18) | Notes |
|---|---|---|---|
| **Full-size frames** (non-mosaic) | `/Volumes/CLOUDCITY4TB/webcam/captures/<YYYY-MM-DD>/*.jpg` | ~4 GB | 30-day retention (`WEBCAM_KEEP_HOURS=720`); ~208 KB/frame, every 180 s. **Never synced to the laptop** — Mini-only, on the 4TB. Regenerable source for mosaics/timelapses. |
| **Hourly mosaics** | `~/work/comms/queue/webcam-mosaics/*.png` | 11 GB | 20 frames/mosaic, 5×tile. |
| **Timelapse videos** | `~/work/comms/queue/webcam-timelapses/*.mp4` | 29 GB | daily (4k + 1080p) + weekly ISO-week 1080p roll-ups. |

Config: `~/work/comms/cloudcity-boot/webcam.env.example`; live `~/work/comms/queue/webcam.env`.

## The 2026-09-18 change: un-synced mosaics + timelapses

Historically mosaics + timelapses were Syncthing-mirrored to the laptop (webcam.env still says
"Esa wants BOTH videos to cross to the laptop"; principle 0043 = mosaic "pinged to this computer").
That piled **~39 GB** onto the space-constrained laptop and contributed to a disk-full event.
Esa's call: switch to **pull-on-demand**.

Applied on the laptop (same proven pattern as `/queue/convey-video-results`):
1. Added to **laptop-local** `~/work/comms/.stignore` (untracked — does NOT propagate to the Mini):
   ```
   /queue/webcam-mosaics
   /queue/webcam-timelapses
   /queue/webcam-captures
   ```
2. Reloaded ignores + rescanned via the Syncthing REST API
   (`POST /rest/db/scan?folder=comms`, verified with `GET /rest/db/ignores?folder=comms`).
3. **Only after** confirming the ignore was active, deleted the local copies → reclaimed ~39 GB.
   Because the paths are ignored, the deletion did **not** propagate; Mini masters stayed intact
   (verified 11 GB / 29 GB still present and updating).

**Order is load-bearing**: ignore → confirm → delete. Deleting first would propagate the deletion
to the Mini. See the `convey-video-results` block in `.stignore` for the prior instance.

## How to pull on demand (works today, zero Mini changes)

SSH is already enabled on the Mini over Tailscale, so `rsync`/`scp` pull anything:

```bash
# newest daily 1080p timelapse
rsync -h --progress cloudcity:'~/work/comms/queue/webcam-timelapses/*-1080p.mp4' ~/Downloads/webcam-pull/timelapses/
# recent mosaics
rsync -h cloudcity:'~/work/comms/queue/webcam-mosaics/*.png' ~/Downloads/webcam-pull/mosaics/
# a given day's full-size frames (4TB)
rsync -h cloudcity:'/Volumes/CLOUDCITY4TB/webcam/captures/2026-09-18/*.jpg' ~/Downloads/webcam-pull/fullsize/
```

## Native Finder browsing (SMB) — pending a Mini-side toggle

Tailscale gives reachability, but macOS **File Sharing (SMB) is currently OFF** on the Mini (only a
`Public Folder` share point exists, `smbd` not running), and passwordless sudo is not set, so it
can't be enabled remotely. To get Finder ⌘K → `smb://cloudcitymacmini` browsing:

1. On the Mini: **System Settings → General → Sharing → File Sharing ON**, add the three webcam
   folders above as Shared Folders (⇧⌘G to paste the 4TB path), grant `esaruoho` access.
2. A reminder RTF (`~/Desktop/ENABLE-FILE-SHARING.rtf`) was left open in TextEdit on the Mini
   2026-09-18 for exactly this.

No macFUSE / SSHFS is ever needed — SMB over Tailscale is the native path; SSHFS only matters if a
permanently-mounted-disk feel is wanted.

## Related

- [[fleet_files_bridge]] — reaching LAN-only Macs via the Mini (SSH jump / `ssh -L` relay / WoL).
- [[feedback_bridge_dead_is_laptop_disk]] — Syncthing `minDiskFree` guard; the doom loop where a
  full disk makes Syncthing spam an unrotated log that fills the disk further.
- `convey/systems.yaml` webcam-* services; `convey/principles/0043-*` (autonomous webcam mosaic).
