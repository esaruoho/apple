---
name: Refuse to commit an account id, bank last-4, key or token
slug: refuse-to-commit-an-account-id-bank-last-4-key-or-token
kind: feature
confidence: 0.6
updated: 2026-11-02
---

## Summary
Convey feature: features/secret-scan.feature.

## Claims
- Scenario (L31): it blocks the exact pair that leaked (ran live 2026-08-16)
- Scenario (L39): the patterns are imported, never redefined (2026-08-16)
- Scenario (L49): two of those patterns are wrong for a repo and are dropped (measured 2026-08-16)
- Scenario (L61): deliberate examples can be kept (2026-08-16)
- Scenario (L69): it reads what will be COMMITTED, not what is on disk (2026-08-16)

## Relationships
