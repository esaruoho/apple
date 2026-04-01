# Admin 001: Configurator Overview

Track: Admin And Deployment
Level: 4
Category: Configurator Automation

## Source

- Site: `configautomation`
- Page: `sources/sal/configautomation.com/mirror/wayback-20240422/web.archive.org/web/20240422004004/https:/configautomation.com/index.html`

## Goal

Introduce Apple Configurator workflows as deployment automation rather than consumer scripting.

## What This Lesson Allows

- Expand the curriculum from personal automation into operational automation
- Teach that Apple's automation story includes device preparation and configuration
- Connect app scripting habits to repeatable admin procedures

## Repo Pairing

- Workflow: `scripts/workflows/system-events/system-events-list-running-apps.applescript`

Why this pairing:
The repo does not yet contain extracted Configurator scripts, so the best bridge is a system-oriented script that trains the same operational mindset.

## Suggested Teaching Flow

1. Read the preserved Configurator overview.
2. Explain how deployment automation differs from personal convenience scripting.
3. Run the list-running-apps workflow.
4. Discuss how inventory, inspection, and repeatability become more important at deployment scale.

## Practice

- Run `scripts/workflows/system-events/system-events-disk-usage.applescript`.
- List three tasks in a lab or fleet context that should be automated rather than performed manually.

## Modern Equivalent

- Type: `repo-workflow`
- Target: `scripts/workflows/system-events/system-events-list-running-apps.applescript`

## Outcome

The learner sees that Sal's automation universe included operational administration, not only end-user workflow tricks.
