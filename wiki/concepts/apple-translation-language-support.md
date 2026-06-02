---
description: Apple's on-device Translation framework supports only 19 languages — Finnish is NOT one of them (verified 2026-06-02). Combined with FoundationModels also rejecting Finnish, there is no on-device path to Finnish on this stack.
---

# Apple Translation — supported languages (Finnish is NOT supported)

**Verified 2026-06-02 on CloudcityMacMini (macOS 26.3)** by querying the Translation
framework directly:

```swift
import Translation
let langs = await LanguageAvailability().supportedLanguages   // [Locale.Language]
```

## The supported set — 19 languages

```
ar  de  en  es  fr  hi  id  it  ja  ko  nl  pl  pt  ru  th  tr  uk  vi  zh
```

Arabic, German, English, Spanish, French, Hindi, Indonesian, Italian, Japanese,
Korean, Dutch, Polish, Portuguese, Russian, Thai, Turkish, Ukrainian, Vietnamese,
Chinese. (The raw list returns `en` and `zh` twice for regional variants → 21 entries,
19 distinct languages.)

## Finnish is NOT supported — and neither is any Nordic/Baltic language

`supportedLanguages.contains("fi")` → **NO.** Also absent: Swedish (sv), Norwegian (no),
Danish (da), Estonian, Latvian, Lithuanian, etc. So **you cannot install a Finnish⇄English
translation pack — there is no such pack.** The Translate.app / "Translation Languages"
settings list simply does not offer Finnish.

## The bigger consequence: no on-device Finnish at all on this stack

Two separate Apple on-device systems both refuse Finnish:

1. **Translation framework** — Finnish not in `supportedLanguages` (above).
2. **FoundationModels** (the on-device LLM) — a Finnish prompt throws
   `LanguageModelSession.GenerationError.unsupportedLanguageOrLocale` ("Unsupported
   language"). See [on-device-ml.md](on-device-ml.md).

So the FoundationModelsChat translation harness (detect non-English → translate to English
→ model → translate back) **works for the 18 non-English supported languages, but NOT for
Finnish.** A Finnish bedtime story for Tomas needs a *cloud* translator/model (or a
third-party on-device model with Finnish), not Apple's on-device stack.

**Practical rule for the harness:** if the detected language isn't in the 19-language set,
say plainly "Apple Translation doesn't support that language — write in English"; do NOT
tell the user to install a pack that doesn't exist (the 2026-06-02 bug Esa caught).

## How to re-verify (if Apple adds languages later)

Run the probe above on the target Mac; compare `supportedLanguages` to this list. Apple
expands the set over OS releases, so Finnish may appear in a future macOS — re-check before
assuming it's still absent.

## See also
- [on-device-ml.md](on-device-ml.md) — FoundationModels + the on-device framework family
- [fm-tool-ideas.md](fm-tool-ideas.md) — the FoundationModelsChat tool/harness roadmap
- `bin/apple-translate` — the CLI the harness shells to (Translation framework via a hidden SwiftUI host)
