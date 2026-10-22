# Report Card — One selected archive folder gets a reviewed preparation before paid whiteboard generation

> Source: `features/aimeat-whiteboard.feature` · printable rendering · regenerate with `python3 print-card.py`

**Intent:** As Esa I want the existing Mini roundtable to prepare board content for one selected folder So that I can review the Markdown before explicitly triggering Gemini whiteboard images.

**Grades:** @designed × 1 · @runtime-verified × 2 · @stock × 1 · @untested × 2

**Scenarios: 5**


---


## 1. Prepare one folder from its existing Markdown

`@runtime-verified`


- Given one direct child folder under articles/boards has usable Markdown
- When I run `aimeat-whiteboard prepare <folder>`
- Then one provenance-linked request enters the existing synced AIMEAT intake
- And no Gemini image-generation call occurs
- And no other board folder is enrolled

<sub>cite: bin/aimeat-whiteboard prepare markdown_sources</sub>


## 2. Collect a completed Mini roundtable as an editable preparation

`@runtime-verified`


- Given Cloudcity returns the matching source-hash roundtable transcript
- When I collect the printed preparation id
- Then `_whiteboard-preparation.md` is written inside the selected folder
- And an existing review file is preserved unless `--replace` is explicit

<sub>cite: bin/aimeat-whiteboard collect</sub>


## 3. Explicitly manufacture reviewed boards

`@designed @untested`


- Given I have reviewed and edited `_whiteboard-preparation.md`
- When I run `aimeat-whiteboard yes-but-whiteboard <folder>`
- Then the installed Whiteboard skill receives that Markdown and the selected board count
- And its dated output contains the skill's PNG, PDF, synopsis, companion Markdown and manifest

<sub>cite: bin/aimeat-whiteboard manufacture ; ~/.agents/skills/whiteboard/bin/whiteboard-generate.sh</sub>


## 4. Image-only source is kept on the Cloudcity OCR path

`@untested`


- Given a selected folder contains no usable Markdown
- When I prepare it
- Then the command stops before submitting content
- And it directs image-only PDF text extraction to the existing Cloudcity OCR pipeline

<sub>cite: bin/aimeat-whiteboard markdown_sources</sub>


## 5. Existing board outputs remain untouched

`@stock`


- Given the selected folder or any unselected folder already contains board outputs
- When preparation or manufacture runs
- Then existing outputs are neither deleted nor automatically regenerated

<sub>cite: bin/aimeat-whiteboard prepare collect manufacture</sub>

