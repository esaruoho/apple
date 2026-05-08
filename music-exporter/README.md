# music-exporter

Apple Music.app library + playlists via AppleScript sdef. Music is
Tier 1 — the sdef exposes everything; Library.musicdb is a private
format, so we go through AppleScript instead. Apple-native.

```bash
music-exporter status                            # tracks + playlist counts
music-exporter playlists --smart-only            # only smart playlists
music-exporter smart                             # same, shorter
music-exporter tracks --playlist Library --limit 100
music-exporter tracks --match 'Aphex|Boards of Canada'
music-exporter artists --limit 30                # by track count
music-exporter albums --limit 30
music-exporter export                            # vault: playlist index only
music-exporter export --with-tracks              # full track listings (slower)
```

Live on this Mac: **80,444 tracks** in the library.

Vault layout:

```
~/work/apple/exported/music/
├── INDEX.md
└── playlists/
    ├── _index.md
    ├── library.md
    ├── starred.md
    └── ...
```

Phase 2 (not built): rate / mark-loved / play / pause via the same
sdef. Plus a `play <selector>` that picks a track by regex and starts
playback — Loupedeck-button candidate.
