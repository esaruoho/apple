---
description: Safe discovery, dry-run, and unmount/purging of iOS Simulator runtimes, cryptex disk image DMGs, dyld shared caches, and unavailable device records via `xcrun simctl` and `bin/sim-purge`.
---

# iOS Simulator Runtime & Cache Purging — `xcrun simctl`

When disk space disappears after building or testing against iOS Simulators on
macOS, the culprit is often multi-gigabyte **Simulator Runtimes** and their
companion **dyld shared caches**. Together, a single simulator release (such as
iOS 26.3) consumes **~11.6 GB** of disk space across three linked layers:

1. **The Cryptex Disk Image DMG (~7.8 GB):**
   `/System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/<hash>.asset/AssetData/Restore/<build>.dmg`
   Downloaded via Apple's MobileAsset service and staged into the secure storage
   pool by `simdiskimaged`.
2. **The Active APFS Mount:**
   `/Library/Developer/CoreSimulator/Volumes/<Build>` (mounted from `/dev/diskXsY`
   as a read-only, sealed APFS cryptex volume).
3. **The Dyld Simulator Shared Cache (~3.8 GB):**
   `/Library/Developer/CoreSimulator/Caches/dyld/<HostBuild>/<SimRuntimeBuild>/`
   (contains `dyld_sim_shared_cache_arm64`, companion slice `.01`, map, and atlas).

**Hard rule:** Never use raw `rm` or `sudo rm` against these paths. The DMG is
actively mounted by the kernel, root/daemon-owned (`_nsurlsessiond`), and tracked
in SQLite state by `com.apple.CoreSimulator.CoreSimulatorService`. Bypassing Apple's
management daemon leaves zombie disk mounts, locked backing files, and corrupts
the CoreSimulator runtime registry.

The canonical Apple-native management path is **`xcrun simctl runtime`** and the
workspace helper **`bin/sim-purge`**.

## The Anatomy of a Simulator Runtime

CoreSimulator on modern macOS treats runtimes as patchable cryptex disk images.
When installed:

```bash
xcrun simctl runtime list -v
```

Emits the complete descriptor:
```text
== Disk Images ==
-- iOS --
iOS 26.3.1 (23D8133) - 25FE56B1-3134-494D-9D0A-ED539B50D6B8
    State: Ready
    Image Kind: Patchable Cryptex Disk Image
    Signature State: Verified
    Deletable: YES
    Mounting Mode: Disk Image Mount
    Mount Policy: Automatic
    Mount Path: /Library/Developer/CoreSimulator/Volumes/iOS_23D8133
    Image Path: /System/Library/AssetsV2/com_apple_MobileAsset_iOSSimulatorRuntime/.../*.dmg
    Size: 7.8G
    Bundle Path: /Library/Developer/CoreSimulator/Volumes/iOS_23D8133/.../iOS 26.3.simruntime
```

Key attributes:
- **`Deletable: YES`** — indicates the runtime is safely removable via `simctl`.
- **`Mount Path`** — where the cryptex volume is mounted.
- **Identifier** — accepts either the UUID (`25FE56B1-...`), the build (`23D8133`),
  the version string (`iOS 26.3.1`), or `all`.

## The Three Step Canonical Purge

### Step 1: Dry-Run Verification

Before modifying system state, verify what `simctl` will touch:

```bash
# Dry run for a specific build or UUID
xcrun simctl runtime delete 23D8133 --dry-run
# Output:
# Would delete P: 25FE56B1-3134-494D-9D0A-ED539B50D6B8 iOS (26.3.1 - 23D8133) (Ready)

# Or check what would be deleted across all runtimes
xcrun simctl runtime delete all --dry-run
```

### Step 2: Safe Deletion & Cache Tear-down

Executing the deletion command triggers the full lifecycle teardown:

```bash
# Gracefully shutdown any running simulator instances first
xcrun simctl shutdown all

# Delete the runtime by build number, UUID, or 'all'
xcrun simctl runtime delete 23D8133
```

When this runs:
1. `CoreSimulatorService` signals `simdiskimaged` to detach and unmount
   `/Library/Developer/CoreSimulator/Volumes/<Build>`.
2. The cryptex disk image in `/System/Library/AssetsV2/.../*.dmg` is unlinked and
   purged via `MobileAsset`.
3. `CoreSimulator` automatically tears down the companion dyld shared cache in
   `/Library/Developer/CoreSimulator/Caches/dyld/<HostBuild>/<RuntimeBuild>/`.

### Step 3: Prune Leftover Unavailable Device Records

Deleting the runtime leaves simulator devices (e.g. `iPhone 17 Pro`, `iPad Pro`)
in an `(unavailable)` state because their runtime profile is gone. Prune them:

```bash
xcrun simctl delete unavailable
```

`xcrun simctl list devices` will now be clean.

## Manual Dyld Cache Control

If you need to update or remove dyld shared caches without deleting the underlying
simulator runtime image, use:

```bash
# Remove dyld shared cache for a specific runtime or all runtimes
xcrun simctl runtime dyld_shared_cache remove --all

# Force re-generation of the dyld shared cache
xcrun simctl runtime dyld_shared_cache update --all --force
```

## The Workspace Tool: `bin/sim-purge`

To avoid memorizing multi-argument `xcrun simctl` incantations, the workspace provides
`bin/sim-purge`:

| Task | Command |
|---|---|
| View runtimes, mounts, & sizes | `bin/sim-purge list` |
| Dry-run check for a runtime | `bin/sim-purge dry-run 23D8133` |
| Dry-run check for everything | `bin/sim-purge dry-run all` |
| Safely unmount & purge runtime + cache | `bin/sim-purge delete 23D8133` |
| Prune unavailable device stubs | `bin/sim-purge prune` |
| Remove dyld shared cache only | `bin/sim-purge cache-remove --all` |

## Related Concepts

- [iphone-app-launch-devicectl.md](iphone-app-launch-devicectl.md) — driving real USB-tethered iPhones with `devicectl`
- [compatibility.md](compatibility.md) — macOS Sequoia / Darwin version requirements and Apple Silicon architectures
- [xpc-atlas.md](xpc-atlas.md) — CoreSimulator XPC daemons (`com.apple.CoreSimulator.SimulatorTrampoline`, `simdiskimaged`)
