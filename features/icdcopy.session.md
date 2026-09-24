# icdcopy Session

## How to Get Back

- Transcript file: unavailable from this sandboxed turn.
- Session ID: unavailable from this sandboxed turn.
- Resume command: unavailable because the session ID is not exposed here.
- Date: 2026-09-10.

## Request

Esa needed a reliable way to copy very large iCloud Drive Ableton project folders,
especially HLER projects, to `/Volumes/T9/iCloudDrive AbletonCloud`.
Finder folder copies were failing with `error -8062`, and manual one-file-at-a-time
copying was not acceptable.

## Findings

`/Volumes/T9/iCloudDrive AbletonCloud` exists and has ample free space. The current
machine has `/opt/homebrew/bin/rsync` version 3.4.1, which supports the needed modern
flags. The specific project `082_HLER itis 2022-07-09 Project` reports roughly
33.29 GiB logical size while only about 11 GiB is resident locally, confirming that
ordinary disk-usage output under-reports iCloud placeholder content.

## Decision

The wrapper provides the command shape Esa asked for:

```bash
icdcopy SOURCE DESTINATION_FOLDER
```

It uses rsync for the actual copy, keeps partial files for resumability, verifies
with a checksum dry-run, and never deletes the source.

## Boundaries

The command deliberately avoids becoming an iCloud eviction or move tool. The safe
workflow is copy, verify, then make a separate decision about source cleanup.

## Follow-Up Fix

Esa ran:

```bash
icdcopy "/Users/esaruoho/Library/Mobile\ Documents/com\~apple\~CloudDocs/AbletonCloud/083_HLER_bunkkeri\ 2022_07_19\ Project" "/Volumes/T9/iCloudDrive AbletonCloud"
```

That failed because backslash-escaped paths inside quotes are passed to Bash as
literal backslashes. The wrapper now normalizes common Terminal/Finder path escapes
when the exact path does not exist, so both styles work:

```bash
icdcopy "/Users/esaruoho/Library/Mobile Documents/com~apple~CloudDocs/AbletonCloud/083_HLER_bunkkeri 2022_07_19 Project" "/Volumes/T9/iCloudDrive AbletonCloud"
icdcopy "/Users/esaruoho/Library/Mobile\ Documents/com\~apple\~CloudDocs/AbletonCloud/083_HLER_bunkkeri\ 2022_07_19\ Project" "/Volumes/T9/iCloudDrive AbletonCloud"
```

The first fix was incomplete: it handled escaped spaces but did not test escaped
`~`. Bash expanded the replacement `~` to `/Users/esaruoho`, producing:

```text
/Users/esaruoho/Library/Mobile Documents/com/Users/esaruohoapple/Users/esaruohoCloudDocs/...
```

The normalizer now replaces `\~` with escaped literal `~`, verified against the
exact failed source argument shape before any destination copy is recommended.

## Follow-Up Fix: rsync Blocked on iCloud Materialization

The first design claim was also too strong: rsync is a good resumable copier, but it
does not make iCloud materialization reliable by itself. It can block silently when
FileProvider is asked to read a dataless item.

`icdcopy` now runs `icloud-materialize.swift` before rsync. The helper enumerates the
source tree, calls Foundation's `startDownloadingUbiquitousItem(at:)` for nonlocal
iCloud files, and waits with named-file status before the rsync copy begins. It has a
bounded per-file wait, so a stuck iCloud item fails with the exact path instead of
leaving the terminal frozen.

Verified against `083_HLER_bunkkeri 2022_07_19 Project`: the helper found 222 files,
74 not downloaded, and with a 5-second test timeout failed on the exact pending file
instead of hanging:

```text
12-Audio 0005 [2022-07-19 193615].aif
NSURLUbiquitousItemDownloadingStatusNotDownloaded
```

## Follow-Up Fix: Default Output Was Too Noisy

The first materializer printed one line per file and exposed Apple's raw
`NSURLUbiquitousItemDownloadingStatus...` enum names. That is not acceptable for a
one-command copy tool.

The default output is now compact, with counts:

```text
icloud-materialize: scanned 222 file(s), 204 ready, 18 requested from iCloud
icloud-materialize: downloading 18 iCloud file(s)
icloud-materialize: downloads ready 07/18
```

Raw per-file statuses are only available from the helper's `--verbose` mode.

The progress count is zero-padded to the total width so terminal text does not
resize while the count advances: `01/60`, `44/60`, `001/120`.

After Esa reported repeated identical lines such as:

```text
icloud-materialize: downloads ready 0/60; waiting on wsx 0003 [2023-08-03 191710].aif
```

the progress loop changed again. It now reports count changes immediately, and if
nothing changes it reports elapsed no-progress time and timeout remaining instead of
printing the same line again.

## Space Incident

Esa started with roughly 99 GB free and dropped to roughly 30 GB free. The large
resident data was not visible as normal HLER project folders. Targeted inspection
found:

```text
/Users/esaruoho/Library/Caches/CloudKit/com.apple.bird  59G
```

This was local CloudKit/iCloud cache, mostly `MMCS/ClonedFiles/.../fileContent`
objects, created while iCloud materialized large files. Copying files to T9 does not
automatically evict the local iCloud/CloudKit cache.

Cleanup performed:

```bash
killall bird cloudd
rm -rf /Users/esaruoho/Library/Caches/CloudKit/com.apple.bird
```

After cleanup:

```text
CloudKit cache: 62M
internal free space: 84G
```

## Follow-Up Feature: Copy by Folder Rank

Esa wanted a workflow where a folder-size list becomes a numbered copy target:

```bash
icdsizefolder
cd "/Volumes/T9/iCloudDrive AbletonCloud"
icdcopy 5
```

The design requirement is that `5` must refer to the list the user just saw, not a
freshly recomputed list that may have changed. So `icdsizefolder` writes a manifest
to `~/.cache/icdcopy/last-folders.json`, and `icdcopy N` resolves the number from
that manifest. The destination for one-argument numeric copy is the current working
directory.

Follow-up correction: `icdsizefolder` must default intelligently. Outside iCloud
Drive it defaults to:

```text
~/Library/Mobile Documents/com~apple~CloudDocs
```

Inside iCloud Drive, it scans the current subtree. So if Esa is in:

```text
~/Library/Mobile Documents/com~apple~CloudDocs/FE
```

then plain `icdsizefolder` ranks folders inside `FE`.

It also prints a compact in-place scan heartbeat every few seconds because iCloud
filesystem walks can look dead while FileProvider is answering metadata calls. The
heartbeat deliberately omits the current deep path because that was noisy in large
trees such as `gear/Clavia...` and `Renoise/Tools/...`.

The default iCloud root is broad and produced a useful top-level ranking, where
`AbletonCloud` was row 3. For day-to-day Ableton cleanup, `icdsizefolder ableton`
was added as a preset for the long `~/Library/Mobile Documents/com~apple~CloudDocs/AbletonCloud`
path.

Follow-up formatting fix: the table now zero-pads row numbers (`01`, `02`, ...),
and the `files` column sizes itself to the largest count so six-digit file counts do
not push the folder names out of alignment.

## Follow-Up Fix: Five-Minute iCloud Timeout Was Too Short

`107_HLER_2023_08_03_B_sleepybyes Project` timed out after five minutes with
`0/45` ready. Immediately afterward, a rescan showed:

```text
icloud-materialize: scanned 48 file(s), 48 ready, 0 requested from iCloud
```

So iCloud had accepted the requests but completed them after the wrapper had already
given up. `icdcopy` now gives iCloud up to two hours by default before declaring the
download phase stuck.

## Follow-Up Correction: Zero Visible Progress Can Still Be Useful

`022_L11_2021_03_04_radiomix Project` showed the bad opposite case: iCloud accepted
44 requests but stayed at `0/44` ready for minutes. That is an iCloud/FileProvider
stall-looking state, but later `088_HLER bunkkeri jotain - ihan siisti Project`
proved the visible ready counter can remain at zero while iCloud is still doing the
download in the background.

Observed timing for `088`:

```text
12:16:43  start; 0/47 ready, 16K local
12:18:35  old process was killed
12:18:35  rerun; 927M local, already ready
12:19:21  copy + checksum verify OK
```

Therefore normal `icdcopy` no longer uses a no-progress abort. It also no longer
uses an overall materialization timeout. It keeps waiting until iCloud reports the
files ready or the user interrupts. The `--max-wait` and `--no-progress-timeout`
options remain only for diagnostics when invoking `icloud-materialize.swift`
directly.

## Follow-Up Fix: FileProvider Status Lagged Behind Resident Bytes

`151_HLER_Ogeli_check Project` showed the next failure: after waiting, the folder was
already resident locally (`893M`), but the materializer could still keep waiting.
That means FileProvider's download-status string was not a sufficient readiness
source.

The helper now also checks POSIX resident blocks with `stat`: if `st_blocks * 512`
covers `st_size`, the file is treated as ready even when FileProvider status lags.
This matches the observed behavior where quitting and rerunning immediately worked
because the bytes were already there.

## Follow-Up: 083 Was Abandoned, 141 Became the Current Target

Esa copied `083_HLER_bunkkeri 2022_07_19 Project` manually because the first
wrapper iterations were too noisy and unreliable. The next target became
`141_2024-10-26-hlerjouhikko Project`.

Inspection showed:

```text
141_2024-10-26-hlerjouhikko Project
logical size: 0.96 GiB
resident local size: 80K
```

No old `icdcopy`, `icloud-materialize`, or `rsync` job was running at that point.

## Follow-Up Fix: Manual Rerun After `.DS_Store` Difference Was Bad Behavior

`141_2024-10-26-hlerjouhikko Project` copied 1.03 GB successfully, but verification
failed on:

```text
>fc.t....... Samples/.DS_Store
```

That is Finder folder-view metadata, not Ableton project data. The wrapper now
excludes `.DS_Store` and `._*` sidecars from copy/verify and automatically reruns
rsync repair passes for real verification differences before asking for user action.

## Follow-Up Fix: `icdcopy` Syntax Error Report

At 2026-09-10 13:04 EEST, Esa reported:

```text
/Users/esaruoho/work/apple/bin/icdcopy: line 145: syntax error near unexpected token `fi'
```

Inspection of the current script showed the line-145 area was balanced, and
`bash -n /Users/esaruoho/work/apple/bin/icdcopy` passed. The current executable on
PATH also resolves to `/Users/esaruoho/work/apple/bin/icdcopy`, prints usage
normally, and no old `icdcopy`, `icloud-materialize`, `rsync`, or `icdsizefolder`
worker was still running.

The stale usage note saying iCloud/disk stalls require rerunning was corrected to
match the current behavior: iCloud downloads wait without an overall timeout, while
interrupted rsync copies can still be rerun to resume.
