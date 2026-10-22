# Report Card — A text file in the AIMEAT folder receives a grounded MLX roundtable beside it

> Source: `features/aimeat-roundtable.feature` · printable rendering · regenerate with `python3 print-card.py`

**Intent:** As Esa I want one text-file drop to start the existing panel automatically So that its Bearden and Prigogine readings return to the work without manual dispatch.

**Grades:** @code-verified × 3 · @runtime-untested × 3 · @runtime-verified × 5 · @stock × 1

**Scenarios: 9**


---


## 1. New stable text file starts the Sages panel and streams saved turns

`@runtime-verified`


- Given Cloudcity-Boot runs the intake against the synced AIMEAT folder
- When a UTF-8 text file finishes arriving
- Then every seat in the Mini's full bench discusses it through the existing Convey MLX roundtable
- And Rigel and the other generalist voices join the grounded historical voices
- And a roundtable Markdown result and JSON status appear beside the source

<sub>cite: roundtable/bridge.py main process stream_section render</sub>


## 2. The whole document is assigned explicit source sections

`@code-verified @runtime-untested`


- Given source text exceeds one panel context
- When the document is processed
- Then every source character belongs to a recorded section
- And completion requires the requested turns and all selected seats in every section

<sub>cite: roundtable/bridge.py sections process</sub>


## 3. Restart and source revision preserve provenance

`@code-verified @runtime-untested`


- Given an interrupted document has completed sections
- When intake resumes
- Then completed sections are skipped
- And completed documents are not regenerated on each poll
- And changed source bytes receive a new archived job

<sub>cite: roundtable/bridge.py job_for process render</sub>


## 4. A failed local MLX endpoint cannot start an SSH retry

`@code-verified @runtime-untested`


- Given the Mini's local MLX endpoint is unavailable
- When a bounded roundtable job runs
- Then its failure is saved for bounded retry
- And the bridge disables SSH fallback and kills timed-out subprocess groups

<sub>cite: bin/fm-mlx FM_MLX_NO_SSH ; roundtable/bridge.py stream_section</sub>


## 5. Existing extracted sidecars are not submitted automatically

`@stock`


- Given existing PDF text sidecars and roundtable results in the AIMEAT folder
- When the watcher scans
- Then generated sidecars and results are excluded
- And source documents remain unchanged

<sub>cite: roundtable/bridge.py candidates</sub>


## 6. The laptop cannot execute the inference worker

`@runtime-verified`


- Given the current host is RayMac rather than CloudcityMacMini
- When the worker or remote installer is invoked
- Then it refuses before loading the model or compiling the Mini's Boot app

<sub>cite: roundtable/bridge.py require_mini verify_panel main ; roundtable/install.py install</sub>


## 7. Folded persona instructions survive the dependency-free roster reader

`@runtime-verified`


- Given Sages contains multiline Prigogine and Hilarion instructions
- When the Mini prepares its derived AIMEAT roster
- Then those instructions are prose rather than literal YAML fold markers
- And the original Sages roster is unchanged

<sub>cite: roundtable/bridge.py fold_roster prepare_roster verify_panel</sub>


## 8. The whole bench is discovered instead of hardcoding a subset

`@runtime-verified`


- Given the Mini declares its full bench in all.yaml or in Sages plus Classic
- When a new file arrives without seat overrides
- Then every distinct declared participant is seated
- And two full panel rounds are requested for every source section

<sub>cite: roundtable/bridge.py prepare_roster process main ; test_aimeat_roundtable.py test_full_installed_bench_gets_two_turns_per_person_including_rigel</sub>


## 9. Generated results return through comms without changing the archive share

`@runtime-verified`


- Given the archive share is send-only on the originating computer
- When the Mini streams a discussion
- Then it publishes hash-linked Markdown and status through the two-way comms share
- And the existing local watcher files only matching source revisions
- And collection performs no model inference

<sub>cite: roundtable/bridge.py render collect ; bin/tag-watcher main</sub>
