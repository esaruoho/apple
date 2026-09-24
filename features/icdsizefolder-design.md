# icdsizefolder Design

Esa's desired workflow is:

```bash
icdsizefolder
cd "/Volumes/T9/iCloudDrive AbletonCloud"
icdcopy 5
```

The important design constraint is that `5` must not mean "whatever happens to be
fifth right now." It must mean "row 5 from the latest visible list Esa just looked
at." Therefore `icdsizefolder` writes a manifest at:

```text
~/.cache/icdcopy/last-folders.json
```

The manifest stores absolute source paths, logical sizes, file counts, the scanned
root, and the row index. `icdcopy N` reads that manifest, resolves `N` to an absolute
source path, and uses the current working directory as the destination root.

`icdsizefolder` ranks folders by logical file size, not resident local disk blocks,
because the purpose is to decide which iCloud folder should be copied/freed next.
It also shows resident local size as a separate column so Esa can see how much is
currently occupying the internal disk.

Root-level files are deliberately excluded from `icdsizefolder`: every numbered row
must be an actual folder that can be copied by `icdcopy N`.

Preset roots keep the common workflows short:

```bash
icdsizefolder ableton
```

scans:

```text
~/Library/Mobile Documents/com~apple~CloudDocs/AbletonCloud
```

Failure modes:

- If no manifest exists, `icdcopy N` tells the user to run `icdsizefolder` first.
- If `N` is outside the saved range, it errors with the valid range.
- If the source was moved/deleted after the list was printed, normal `icdcopy`
  source-existence checks catch it before copying.

This keeps the command small while avoiding an unsafe implicit dependency on a
fresh dynamic ranking.
