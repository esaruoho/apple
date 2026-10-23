# Report Card — Owner emails deliver complete PDF material and analyses to AIMEAT

> Source: `features/aimeat-email-pdf.feature` · printable rendering · regenerate with `python3 print-card.py`

**Grades:** @built × 4 · @code-verified × 1 · @runtime-verified × 2 · @sim-verified × 5 · @stock × 1

**Scenarios: 6**


---


## 1. Owner PDF intake is durable and does not answer twice

`@built @sim-verified`


- Given an owner emails a PDF attachment or explicit PDF URL
- When the Mini mail pane polls the inbox
- Then it queues a message-ID keyed job before the legacy reply claim
- And an ambiguous send is retained as unconfirmed without automatic resending

<sub>cite: shared/aimeat_mail.py eligible enqueue process_pending advance · bin/freellmask-mail poll_once</sub>


## 2. Every PDF page and every text section is considered

`@built @sim-verified @runtime-verified`


- Given a PDF longer than twenty pages or fourteen text sections
- When the Mini extracts and reads the PDF
- Then every page has an embedded-text or OCR record
- And all text sections receive checkpointed readings without a part-count cutoff
- And pages with no recognized text are listed explicitly

<sub>cite: bin/mail-pdf-text.swift · shared/aimeat_mail.py extract_pdf chunks advance</sub>


## 3. The laptop receives the original and actual returned results

`@built @sim-verified`


- Given completed section analyses and a matching completed roundtable
- When Syncthing returns the exported artifacts
- Then the filing-only collector verifies hashes and files them in merlib-dump/aimeat
- And local edits are preserved
- And the Mini can run its roundtable directly from the job workspace while the laptop is asleep
- And the email reply carries the analysis and names its analysis types
- And all three cloud images carry readable source Markdown and rendering JSON

<sub>cite: shared/aimeat_mail.py publish collect advance · roundtable/bridge.py collect · shared/aimeat_mail.py merge_mail_inputs · shared/cloud_assets.py generate</sub>


## 4. Substack analysis mail is sent only after every requested analysis is complete

`@code-verified @sim-verified`


- Given a Substack source job has saved reading checkpoints
- When source synthesis times out, the roundtable fails, or any cloud artifact is missing
- Then the failure and checkpoints remain in the job state without sending an email
- And the handler sends only after nonempty analysis, matching completed roundtables,
- and all three cloud PNGs and Markdown rendering sources pass verification
- And source-analysis steps have a one-hour default deadline on the Mini
- And targeted Mini deployment replaces only the handler and preserves a backup

<sub>cite: shared/aimeat_mail.py bounded_source_step require_complete_analysis advance _process_pending · shared/aimeat_mail.py analysis_html ; roundtable/install_mail.py stage_handler install_handler · test_aimeat_source.py</sub>


## 5. Wordclouds use a black canvas and readable title

`@built @runtime-verified`


- Given an installed Convey or archive wordcloud generator
- When the dark-theme patch is applied and a cloud is rendered
- Then its cloud and surrounding figure have a black background
- And its title is white

<sub>cite: scripts/wordcloud-dark.py dark apply</sub>


## 6. Compute stays on CloudcityMacMini

`@stock @sim-verified`


- Given the laptop receives files through Syncthing
- When it runs the existing collector
- Then it copies artifacts without running OCR or a model
- And processing entry points reject the laptop

<sub>cite: shared/aimeat_mail.py mini collect process_pending</sub>

