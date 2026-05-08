# Stickies — Extraction Research

> Read-only study generated 2026-05-08 from live probe on Esa's Mac
> (macOS 15.6.1). No actions taken. This document describes what is
> accessible and proposes a `stickies-exporter/` package layout.

## TL;DR

Stickies is "**Tier 5: Nearly Dark**" automation:

| Surface | Available |
|---------|-----------|
| AppleScript dictionary (`sdef`) | ❌ error -192, no scripting |
| App Intents (Siri / Shortcuts) | ❌ no `Metadata.appintents/` |
| URL scheme | ❌ no `CFBundleURLTypes` |
| Direct filesystem read | ✅ `<UUID>.rtfd` per note |
| Direct filesystem write | ✅ drop new `.rtfd`, restart Stickies |
| `textutil` for conversion | ✅ rtfd ↔ txt / html / docx / rtf / webarchive |
| Services Menu hook ("Make Sticky") | ✅ accepts plain-text / rtf / flat-rtfd |

Esa has **10 stickies on disk** (titles: Stubblefield, imploosio, Sand
Battery, Orthogonal fields, Bill Beatty, Jeane Manning, Kentucky Water
Fuel Museum, Falstad CircuitJS URL, Leedskalnin, "Process Esko Leikas
audio recording to transcript"). Free-energy / archive research +
todo.

## Storage layout

```
~/Library/Containers/com.apple.Stickies/Data/Library/
├── Stickies/
│   ├── 1ECCD6E3-5958-4D1E-974B-7E19CDFB9AAA.rtfd/
│   │   └── TXT.rtf            ← the actual note (RTF format)
│   ├── 23D4B1CE-AC92-4515-BC90-AC9E042572E8.rtfd/
│   │   └── TXT.rtf
│   └── ... 10 .rtfd directories on this Mac ...
└── Preferences/
    └── com.apple.Stickies.plist     ← only migration flags, no per-note state
```

- One `.rtfd` directory per sticky (RTFD = RTF Directory bundle, can hold attachments alongside the .rtf).
- Filename is a fresh UUID. Stickies generates one when you create a note.
- The `TXT.rtf` inside is plain RTF — fonts, colors, hyperlinks, attachments all in standard `\rtf1` format.
- **Window position, sticky color, font choices are encoded inside the RTF itself** (in the `\colortbl` and font tables — see example below). There is no separate position/color plist. Color options correspond to standard RTF color names; window position is *not* persisted on disk on this Mac (Stickies probably re-derives it on launch from cascading defaults, and saves state only via NSWindow restore at quit time which lives elsewhere).

## RTF colortbl example (one of Esa's stickies)

```
{\colortbl;\red255\green255\blue255;\red62\green128\blue233;\red133\green133\blue142;}
{\*\expandedcolortbl;;\cssrgb\c30196\c58824\c93333;\cssrgb\c59216\c59216\c62353\c7843;}
```

The first non-default color (`\red62\green128\blue233`) is the link
color; the third is the text color. Sticky background (the yellow /
pink / blue / etc. note color) is NOT in this table — it's set per-window
by Stickies when it opens the rtfd, derived from a default or a user
choice via the Color menu. This means we can write a fresh `.rtfd`
with any text, but **we can't pre-set the sticky's window background
color from disk** — only the Color menu inside Stickies sets that.

## Reading

```bash
DIR=~/Library/Containers/com.apple.Stickies/Data/Library/Stickies

# Plain text of every sticky
for f in "$DIR"/*.rtfd; do
  echo "=== $(basename "$f" .rtfd) ==="
  textutil -convert txt -encoding UTF-8 -stdout "$f"
done

# Markdown
textutil -convert html -stdout one.rtfd | pandoc -f html -t markdown

# JSON metadata
for f in "$DIR"/*.rtfd; do
  uuid=$(basename "$f" .rtfd)
  modified=$(stat -f %Sm -t %FT%T "$f")
  body=$(textutil -convert txt -encoding UTF-8 -stdout "$f" 2>/dev/null)
  printf '{"uuid":"%s","modified":"%s","chars":%d}\n' \
    "$uuid" "$modified" "${#body}"
done
```

`textutil` ships with macOS — Apple-native, no Homebrew. Output
formats: `txt`, `html`, `rtf`, `rtfd`, `doc`, `docx`, `wordml`,
`odt`, `webarchive`.

## Writing (creating new stickies)

Two paths:

### A. Drop a new `.rtfd` into the directory (requires Stickies restart)

```bash
DIR=~/Library/Containers/com.apple.Stickies/Data/Library/Stickies
new_uuid=$(uuidgen)
echo "My new sticky body" > /tmp/sticky-body.txt
textutil -convert rtfd -output "$DIR/$new_uuid.rtfd" /tmp/sticky-body.txt
osascript -e 'quit app "Stickies"'
sleep 1
open -a Stickies
```

**Critical caveat**: if Stickies is running while you write a new
`.rtfd`, it will **not see your file until restart**, AND on its next
quit it will overwrite the directory based on its in-memory state —
risking loss of the new sticky. Always quit Stickies first.

### B. Use the Services Menu hook (no quit needed)

The probed sdef shows Stickies registers a `makeStickyFromTextService`
that accepts plain-text, rtf, or flat-rtfd input. Invoke it
programmatically:

```bash
echo "Sticky body" | /usr/bin/services -name "Make Sticky"   # if 'services' CLI is wired up

# Or via osascript:
osascript -e 'tell application "Stickies" to activate'
# then paste / use clipboard + automation
```

The cleanest approach is the Services Menu via UI scripting:

```applescript
set the clipboard to "My sticky text"
tell application "Stickies" to activate
delay 0.3
tell application "System Events"
  tell process "Stickies"
    click menu item "Make Sticky" of menu "Services" of menu item "Services" of menu "Stickies" of menu bar 1
  end tell
end tell
```

Both paths make Stickies the source-of-truth and avoid disk-write
races.

## Modifying existing stickies

`textutil -convert rtfd -output <UUID>.rtfd source.txt` works the
same way — overwrites the bundle. Same race caveat: quit Stickies
first.

For non-destructive append (preserve formatting), parse the RTF,
inject a new paragraph before the closing `}`, and write back. This
is brittle — better to read full text → modify → write back via
`textutil` round-trip, accepting that you lose color/font tweaks.

## Proposed `stickies-exporter/` package

Same shape as the others. Read-only by default; explicit `create` /
`update` flags for writes that auto-quit-then-restart Stickies.

```
stickies-exporter list                       # 10 stickies, UUID + title + char-count
stickies-exporter list --json
stickies-exporter list --since 2026-04
stickies-exporter cat 1ECCD6E3              # one sticky to stdout (selector grammar from voice-memos)
stickies-exporter cat "Stubblefield" --rtf  # raw RTF
stickies-exporter export                     # all stickies → ~/work/apple/exported/stickies/<slug>.md
stickies-exporter export --include-rtf       # also copy raw .rtfd next to .md
stickies-exporter create "<title>" --body-file path.md
stickies-exporter create --title "Quick" --body "text"
stickies-exporter append <selector> --body "additional line"
stickies-exporter delete <selector>          # backs up rtfd to ~/work/apple/exported/stickies/_archive/ first
stickies-exporter status                     # last run, count, total size
```

Selector grammar reused from voice-memos / safari: UUID prefix /
title substring / `#N` / `latest`.

Sidecar frontmatter:

```yaml
---
uuid: "E0EDCD1C-B714-4BB4-852D-E6C25F83874C"
title: "Stubblefield"
modified: "2026-04-05T21:12:00"
char_count: 12
rtf_link_color: "#3E80E9"
rtf_text_color: "#85858E"
has_attachments: false
---

# Stubblefield

…note body…
```

Vault layout:

```
~/work/apple/exported/stickies/
├── 2026-04-05__stubblefield__1ECCD6E3.md
├── 2026-04-07__imploosio__23D4B1CE.md
└── ...
```

Default symlink-mode like voice-memos: the `.rtfd` itself is
symlinked alongside the `.md` so you can drop into Obsidian and still
double-click the rtfd to open in TextEdit. The Stickies container is
already protected by Full Disk Access; reading is fine.

## Cross-reference (Phase 2)

Esa's stickies look like archive research stubs — Stubblefield,
Leedskalnin, Bill Beatty, Jeane Manning, Sand Battery — which overlap
heavily with the free-energy archive. A `stickies-exporter
xref --free-energy` would match each sticky title against the
Tesla/Schauberger/Mueller/etc. corpus and produce link suggestions.

Same pattern for `xref --safari` → match sticky URLs (the falstad.com
one) against the 3,088 dedup'd Safari URLs. The sticky becomes the
"why this is open" annotation for an open tab.

## Disk + safety

- Vault size after `export --all`: ~20 KB for 10 stickies.
- All reads non-destructive. Writes (create / update / delete) gate
  behind a `--write` confirmation flag and auto-quit Stickies first.
- Deletion archives the `.rtfd` to `_archive/` rather than `rm`.
- The Services Menu hook (Path B) avoids the quit-restart cycle but
  needs UI scripting which can be flaky.

## Recommended Phase 1 build

`list`, `cat`, `export` — read-only, 100% safe, gets every sticky
into your markdown vault under `exported/stickies/` immediately. The
write actions (`create`, `append`, `delete`) come in Phase 2 with the
quit-restart guard plus `--write` confirmation.
