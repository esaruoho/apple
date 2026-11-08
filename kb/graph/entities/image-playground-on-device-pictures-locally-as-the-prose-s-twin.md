---
name: image-playground — on-device pictures, locally, as the prose's twin
slug: image-playground-on-device-pictures-locally-as-the-prose-s-twin
kind: feature
confidence: 0.6
updated: 2026-11-08
---

## Summary
Convey feature: features/image-playground.feature.

## Claims
- Scenario (L70): The CLI generates an image from a prompt
- Scenario (L79): Bare prompt → derived filename, auto-open
- Scenario (L86): A failed run never opens a stale same-named file
- Scenario (L95): Transient "image creation failed" is retried, not surrendered
- Scenario (L105): Image Playground distills — it does not honor detailed prompts
- Scenario (L113): Illustrate Selection in Converse (⌘2) inserts a picture inline
- Scenario (L124): The image loop — every message in Converse also draws a picture
- Scenario (L137): A relative -o path lands in the user's cwd, not "/"
- Scenario (L146): Apple's content guardrail is explained, not echoed
- Scenario (L156): A question phrase still yields the subject
- Scenario (L163): --check reports availability and the styles this Mac supports
- Scenario (L170): Headless generation is impossible by Apple's design
- Scenario (L180): /image draws a one-off picture inside Converse, no model call
- Scenario (L190): Illustrate ON pairs every reply with a picture
- Scenario (L202): A picture can't be drawn while Converse is in the background
- Scenario (L209): Images embed without file-system access

## Relationships
