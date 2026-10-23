# Report Card — Cloud images carry readable reproducible source documents

> Source: `features/cloud-source-markdown.feature` · printable rendering · regenerate with `python3 print-card.py`

**Grades:** @code-verified × 5 · @runtime-verified × 2 · @sim-verified × 4 · @stock × 1

**Scenarios: 6**


---


## 1. Every newly rendered cloud saves its exact inputs before the image

`@code-verified @runtime-verified`


- Given weighted words, sentences or extractive key ideas
- When the existing renderer creates a PNG
- Then it first saves a readable source.md with every supplied text item and weight
- And the Markdown contains a checksummed JSON rendering specification
- And wrappers and folder commands retain that source after deleting temporary files

<sub>cite: shared/cloud_source.py write_cloud_source write_spec read_spec · scripts/cloud-source-sidecars.py word sentence wrapper cli</sub>


## 2. Emailed PDFs return all three cloud types with their source files

`@code-verified @sim-verified`


- Given a PDF has readable prose and completed analyses
- When its Mini mail job prepares delivery
- Then wordcloud, sentencecloud and ideacloud PNGs and Markdown sources are archived and attached
- And idea selection reuses Convey's existing extractive key-takeaways
- And a missing cloud is reported explicitly

<sub>cite: shared/cloud_assets.py generate · shared/aimeat_mail.py advance</sub>


## 3. Wordcloud rendering falls back when Convey's wordcloud command fails

`@code-verified @sim-verified`


- Given the normal Convey wordcloud command returns a nonzero status
- When the normal Convey wordcloud command fails
- Then AIMEAT renders a black-background wordcloud using Pillow
- And it saves the exact weighted words to source Markdown and checksummed JSON
- And the analysis email remains held until the PNG and both source files verify

<sub>cite: shared/cloud_assets.py render_wordcloud_fallback generate · test_cloud_assets_wordcloud_fallback.py</sub>


## 4. An agent can recreate an image from Markdown without OCR

`@code-verified @runtime-verified`


- Given a saved cloud rendering source
- When cloud-assets render reads its checksummed specification on the Mini
- Then it renders the stored items with the matching renderer
- And modified machine inputs fail checksum verification

<sub>cite: shared/cloud_assets.py replay · shared/cloud_source.py read_spec</sub>


## 5. Email is sent as formatted HTML with a plain-text fallback

`@code-verified @sim-verified`


- Given analysis Markdown contains headings, bold, code, lists, links and tables
- When the threaded email payload is composed
- Then the HTML body contains the corresponding formatting tags
- And the plain-text body remains available
- And source Markdown is attached separately for agents

<sub>cite: bin/freellmask-mail md_to_html md_to_inner_html · shared/aimeat_mail.py advance</sub>


## 6. New source sidecars do not become new corpus material automatically

`@stock @sim-verified`


- Given a corpus folder contains prior cloud source Markdown
- When a cloud generator scans the corpus again
- Then generated source.md files are excluded
- And render commands reject the laptop

<sub>cite: scripts/cloud-source-sidecars.py word sentence cli · shared/cloud_assets.py mini</sub>

