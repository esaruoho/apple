# Why a Drive Won't Mount — the diagnostic ladder

> *When you plug in a USB stick and it never shows up in Finder, the answer is almost always at exactly one of three layers. Find the layer, and you've found the cause.* Codified from a live 2026-06-01 diagnosis into the zero-token tool `bin/why-no-mount` + slash `/why-no-mount`.

The core apple-skill principle in action: a pattern of manual diagnosis, organized, becomes a one-command tool. The *narrative* is frozen; only the *variables* (vendor, speed, filesystem type, log lines) change per device.

## The ladder

A drive has to pass three layers before Finder shows it. Diagnose top-down — the first ❌ is your answer.

| Layer | Question | Apple-native probe | What a PASS looks like |
|---|---|---|---|
| **1. Electrical / USB enumeration** | Did the device power up and announce itself on the bus? | `system_profiler SPUSBDataType` | Device appears with vendor, speed (e.g. *up to 5 Gb/s*), and `Current Required` ≤ `Current Available`. SMART: Verified. |
| **2. Block device / kernel** | Did the kernel create `/dev/diskN` and read the partition map? | `diskutil list`, `diskutil info <id>` | `/dev/diskN` + `/dev/diskNsM` exist; partition scheme (MBR/GPT) and a content type (`DOS_FAT_32`, `Apple_HFS`, `Apple_APFS`…) are reported. |
| **3. Filesystem** | Can macOS read the filesystem *inside* the partition and mount it? | `diskutil info`, `diskutil mount [readOnly]`, the unified `log` | `Mounted: Yes`, a `Mount Point`, a non-zero `Volume Total Space`, a readable `Volume Name`. |

Most "it won't mount" cases pass 1 and 2 and fail at **3** — the hardware is fine, the *filesystem* is damaged.

## The smoking guns at Layer 3

These are the signals the tool keys on. Any one of them means "the filesystem header is unreadable," not "the hardware is broken":

- **`Volume Total Space: 0 B` while the partition holds real bytes** — `diskutil` cannot read the boot sector / BPB (FAT) or superblock (HFS/APFS) that declares the volume's size. The single strongest tell.
- **Blank `Volume Name`** — the label lives in the same header; if it's blank on an unmounted volume, the header is unreadable.
- **`diskarbitrationd: disk is not readable /dev/diskN`** in the unified log — the auto-mount daemon itself rejected the disk. This is *why* Finder never showed it.
- **`storagekitd: Caching diskN, isValid=0`** — StorageKit agrees the filesystem is invalid.
- **Both normal AND read-only mount fail** — if read-only also fails, the damage is in core structures (boot sector / FAT tables), not just a "dirty unmount" flag. If read-only *succeeds* but read-write fails, the data is still readable — copy it off, then repair.

## Reading the verdict

| Symptom pattern | Verdict | Fix |
|---|---|---|
| Mounted already / mounts on probe | Was just not auto-mounted | nothing — it's fine |
| RW mount fails, **RO mount succeeds** | Dirty filesystem, data intact | copy data off, then `fsck` / `diskutil repairVolume` |
| RW + RO both fail, `Total Space 0 B`, log "not readable" | **Filesystem structurally corrupt** | dry-run `fsck` → image with `dd` → repair `fsck -y` |
| `Current Required > Current Available` | Power-starved | powered hub / direct Mac port |
| Not in `diskutil` at all, not in USB tree | Never enumerated | cable / port / hub — not the data |

## Repair commands (filesystem-keyed)

The tool prints the right one for the detected filesystem. All need `sudo`; the `-y` / `repairVolume` forms **write to the disk**.

- FAT/FAT32: `fsck_msdos -n /dev/rdiskNsM` (dry run) → `fsck_msdos -y …` (repair)
- exFAT: `fsck_exfat …`
- HFS+: `fsck_hfs …`
- APFS: `fsck_apfs …` or `diskutil verifyVolume` / `repairVolume`
- Universal Apple front-end: `diskutil verifyVolume <id>` (read-only) then `diskutil repairVolume <id>`
- **Image before repairing if the data matters:** `sudo dd if=/dev/rdiskNsM of=~/Desktop/diskNsM-image.img bs=1m`
- NTFS: macOS is read-only — repair on Windows with `chkdsk`.

Note the **raw** device node `/dev/rdiskNsM` (the `r` prefix) for `fsck`/`dd` — it's the unbuffered character device, which is what these tools want.

## The tool

```
why-no-mount                 # auto-detect: diagnose every UNMOUNTED external volume
why-no-mount disk4           # diagnose every volume on whole-disk disk4
why-no-mount disk4s1         # diagnose one specific volume
why-no-mount --list          # list external volumes + mount state
why-no-mount --probe-only X  # inspect only; do NOT attempt a live mount
why-no-mount --minutes 60 X  # widen the unified-log scan window (default 30 min)
```

- Source: `bin/why-no-mount` (python3 stdlib + Apple-shipped CLIs only — no Homebrew/pip).
- Slash: `/why-no-mount` (zero LLM roundtrip after invocation).
- Filters helper partitions (EFI, APFS container store, Microsoft Reserved) so auto-detect only flags real data volumes.
- Default mode attempts a live mount of an unmounted target (benign — connects a healthy stick, fails gracefully on a corrupt one). `--probe-only` skips that.
- Log scanning uses fixed-string matching in Python — no regex, so no catastrophic-backtracking risk.

## Lineage

Born from a real diagnosis: a 62.5 GB SMI FAT32 stick enumerated perfectly on USB 3.1 (504 mA, SMART Verified), the kernel made `/dev/disk4s1`, but `diskutil` reported `Volume Total Space: 0 B`, both mounts failed, and the log showed `diskarbitrationd: disk is not readable`. Hardware fine, FAT32 boot sector corrupt. The hand-walk became this tool the same session.
