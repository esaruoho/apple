# AIMEAT whiteboard review gate — session

## How to get back

- Transcript: `file:///Users/esaruoho/.codex/sessions/2026/10/21/rollout-2026-10-21T22-16-28-01a15fe4-bcfd-7d82-bce6-1bae3e0d8dde.jsonl`
- Session ID: `01a15fe4-bcfd-7d82-bce6-1bae3e0d8dde`
- Resume: `codex --resume 01a15fe4-bcfd-7d82-bce6-1bae3e0d8dde`
- Session start timestamp verified from `session_meta`: `2026-10-21T19:16:28.605Z`.
- User request timestamp verified from retained message metadata: `2026-10-22T10:24:38.808Z` UTC.
- Identified by the exact whiteboard-workflow request in the transcript.
- Card: [aimeat-whiteboard.feature](aimeat-whiteboard.feature).
- Full transcript bundles are beside this card and gitignored because the transcript includes private infrastructure context.

Esa asked whether AIMEAT/Convey can prepare whiteboards from the existing folders in `~/work/merlib-dump/articles/boards`, with a human review of Markdown preparation before a deliberate “yes, but whiteboard” action triggers Gemini's paid image generation. The intent is a one-folder pilot and a red-button review gate, never bulk generation over the archive.

The installed Whiteboard skill already supports full output: Gemini smart prompts and images, a combined PDF, synopsis, companion Markdown and manifest. Its `--full` mode is invoked only by the explicit `yes-but-whiteboard` subcommand. The existing AIMEAT roundtable accepts UTF-8 Markdown/text on the Mini and returns hash-verified transcripts through the comms channel.

Added `bin/aimeat-whiteboard` with `prepare`, `collect` and `yes-but-whiteboard`. Preparation packages existing Markdown from one direct child folder with source paths and hashes into a single AIMEAT request. Collection matches the Mini's return by request filename and SHA-256, then files `_whiteboard-preparation.md` without overwriting an existing review by default. The final command calls the local Whiteboard skill against that reviewed Markdown and writes dated results beside the selected folder. Image-only folders stop with guidance to use the established Cloudcity OCR path; no laptop OCR was added.

The CLI `--help` path parsed and displayed the three commands. One review-only pilot was queued for `2026-08-12-whittaker-tesla-standing-columnar-wave`, using its `_whiteboard-source.md` and inventorying its PDF/PNG assets by name and byte size. The Mini's stale Convey install first failed on the missing `--seat` option. Existing payload `0db66f90cebf956d` then backed up and patched only the roundtable function/flag, preserved Cloudcity-Boot without a restart, and requeued that failed job. The Mini completed two source sections with 36 turns across all nine seats; source and result hashes matched the return record.

Collected `/Users/esaruoho/work/merlib-dump/articles/boards/2026-08-12-whittaker-tesla-standing-columnar-wave/_whiteboard-preparation.md` with the original source Markdown, returned transcript and review checklist. Inspection found the panel transcript contains conflicting interpretations, so the refreshed review file makes the source primary and directs the reviewer to repair closed-system conclusions before Gemini. The renderer count is seven because the source already has six numbered content boards and the skill's count includes its title slot. No image generation was invoked; no PNG/PDF whiteboard outputs were created. The manufacture path is designed but remains runtime-untested until the user deliberately runs `yes-but-whiteboard` after review.

No roundtable or Gemini tests were added. This record describes the single live Mini pilot only; the workflow has not been exercised across other board folders. The current card has verified prepare/collect scenarios and explicitly untested manufacture and image-only paths.

Implementation and initial card commit `d71a59c1` was pushed directly to Apple `main`, with no PR. Only this task's seven files were staged; `features/INDEX.md` and all other pre-existing work stayed unstaged. The report-card delivery line is being recorded as a follow-up card update.

## Continuation — bind the red button to the BBS / Free Energy Whiteboard contract

Esa required proof that the BBS or Free Energy Whiteboard skill is reliably used. Read the Apple repo skill (`skill.md`) and the installed BBS, Free Energy frontmatter, and Whiteboard skill instructions. The prior red-button path called the Whiteboard executable but did not force the Free Energy guardrails, did not verify the skill documents at runtime, and did not add required YAML provenance to generated companion Markdown.

Updated `bin/aimeat-whiteboard` so `yes-but-whiteboard --plan` checks those installed skill contracts and executable, then prints the exact command without calling the generator. The actual button now includes `--full --guardrails`; after a successful run, generated companion Markdown gets the required `whiteboard-boards` provenance fields and a source link back to the reviewed preparation. The plan was run against the actual Whittaker pilot: it resolved the expected skill paths, count 7, dated output path, and exact command. No generator, API, or Gemini call occurred. Manufacture remains @untested until Esa reviews the draft and deliberately invokes the red button.

## Continuation — require proof that guardrails really ran

After a Convey Canvas Sweet VTA render, the Whiteboard manifest reported `guardrails_active: false` despite open-system framing in the input. This exposed a real gap: Convey Canvas had no `--guardrails` option to force the skill mode. The AIMEAT red-button command already passed `--guardrails`, but only its plan had been exercised; tightened it to verify that the installed wrapper forwards the flag, that the generator implements forced activation, and that a completed render's manifest confirms `guardrails_active: true`. AIMEAT also now checks the requested PNG count, companion Markdown count/frontmatter, and combined PDF before it treats manufacture as successful. Actual AIMEAT image manufacture remains unrun to preserve the review/red-button boundary.


## Guarded Sweet VTA runtime proof via Convey

After adding the forced flag and manifest verification, ran the combined Sweet source through `convey canvas --guardrails --no-recall --count 4` into a separate dated output folder. The Whiteboard generator reported Guardrails ON (forced), and `manifest.json` verified `guardrails_active: true`. Output verification passed: four PNGs, four companion Markdown files with source-linked provenance frontmatter, a four-page PDF, and lossless `source.md`. Opened and inspected the overview; it visibly presents the open-system external-reservoir coupling and keeps Sweet's account distinct from Bearden's later interpretation. This proves the shared Convey renderer under active guardrails. The AIMEAT-specific red button remains review-gated and was not used for this Sweet source; its no-generation plan and output rejection checks remain the verified AIMEAT contract.

## Guardrail correction — remove evidence-gap board template

Esa identified the “What We Know / What’s Missing” panel as unwanted. Updated both installed Whiteboard generator copies and their skill guides: forced guardrails now prioritize the open-system reservoir-to-wheel/output path, source attribution, and source-grounded measurements. They explicitly prohibit evidence-gap, replication, measurement-question, and verification panels, generic proof-burden questions, and decorative question marks. AIMEAT’s skill preflight checks the open-system wording and these prohibitions, so stale skill copies fail closed. The first refreshed render revealed a conflicting measurement-question instruction embedded in the Sweet seed; that instruction has now been removed before the clean rerender.

## Final source-by-source render after seed cleanup

Removed the seed's assistant-written framing paragraph and duplicate source H1 titles, retaining the original SWEETNS, SWEET3, and SWEET4A source text under one heading each. Rendered four boards with the corrected `--guardrails` prompt: one overview plus all three source documents. The manifest reports `guardrails_active: true`; output verification passed for four PNGs, four source-linked companion Markdown files, the PDF, and `source.md`. Visually inspected all four boards: the unwanted “What We Know / What’s Missing” and measurement-question panels are absent. The overview still has a few garbled source-label strings from image rendering; the companion Markdown and bundled source preserve the readable source content. Opened the final overview in Preview.
