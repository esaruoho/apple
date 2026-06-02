# merlib-dump mirror health — read-only audit (2026-06-02)

A full read-only sweep of `~/work/merlib-dump` with the Apple-native, zero-token,
zero-guardrail tooling. Scope: **24,710 .md · 15,781 .html/.htm · 11,294 .pdf**.
Regenerate any section by re-running the tool named.

## Frontmatter — `merlib-frontmatter`

`merlib-frontmatter ~/work/merlib-dump --require title,tags`

- markdown files: **23,553**
- with frontmatter: 17,174
- **no frontmatter: 6,349 (27%)** — invisible to any tag/metadata view
- **malformed (broken `---` fence): 30** — these actually fail YAML parsers (urgent)
- missing title+tags: 9,208
- **`--fix-title --dry-run` → 5,729 files would get a good H1-derived title**, zero
  writes. Ready to apply on green-light.

## Link rot — `merlib-linkcheck`

`merlib-linkcheck ~/work/merlib-dump --by-collection --ignore-md-docs`

- internal links checked: **372,316** · external (not fetched): 179,483
- **broken internal links: 78,854** (after dropping markdown-doc false positives;
  85,832 before)
- empty/tiny files: 6

Worst collections (the repair priority list):

| broken | collection |
|--------|-----------|
| 24,658 | Cheniere.org |
| 20,406 | mirrors |
| 11,887 | archivebox |
|  6,882 | tesla.hu |
|  5,326 | free-energy.ws |
|  3,227 | merlib-mirror |
|  2,906 | sources |
|  1,188 | r-charge.net |
|  1,171 | Free Energy CD-rom |
|    535 | Energy From The Vacuum |

**High-leverage next step:** rank missing *targets* by how many pages reference
them (a single uncaptured CSS/logo breaks thousands of links). Fixing the top ~50
missing resources likely clears tens of thousands of broken links. → planned
`merlib-linkcheck --missing-targets`.

## Image-only PDFs — `ocr-triage` (+ `pdf-textlen`)

`ocr-triage ~/work/merlib-dump` (detection only; submission is `--submit` → Cloudcity)

- PDFs scanned: **11,294**
- text-layer OK: **9,115 (81%)**
- **image-only (need OCR): 2,140 (19%)** — < 50 chars/page on a 5-page sample
- unreadable / 0-page: 39

Detection is on-device via PDFKit (`pdf-textlen` samples the first 5 pages, so even
a 1,036-page scan returns in ~1s). **No local OCR ever** — `--submit` queues the
2,140 to the Cloudcity Syncthing OCR pipeline + logs to MASTER-OCR-LEDGER.

## The actionable backlog this surfaces

1. **30 malformed frontmatter** files — fix first (they break parsers).
2. **5,729 missing titles** — one `merlib-frontmatter --fix-title` run catalogs them.
3. **6,349 no-frontmatter** files — need a frontmatter stub + tagging pass.
4. **~50 top missing link targets** (once `--missing-targets` lands) — clears most of
   the 78,854 broken links.
5. **2,140 image-only PDFs** — one `ocr-triage --submit` queues them all to OCR.

Every number above came from on-device tools in minutes, no Claude tokens, no
network, no FM guardrails.

## See also

- [merlib-mirror-tooling.md](../concepts/merlib-mirror-tooling.md) — the tool menu
- `bin/merlib-linkcheck` · `bin/merlib-frontmatter` · `bin/ocr-triage` · `bin/pdf-textlen`
