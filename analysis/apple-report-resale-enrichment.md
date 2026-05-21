# Apple Report — Resale-Value Enrichment

How to extend `bin/apple-report` so that "what is this Mac worth on the local second-hand market" becomes part of the report. Drafted from the 2026-05-21 session where the user asked Finnish resale values for a Mac mini M2 Pro 32 GB / 1 TB and a MacBook Pro 14" M3 Pro 18 GB / 2 TB. The reasoning generalizes to any country and any second-hand marketplace, so the design is whitelabeled from the start.

## The pattern we manually executed

What a human (or an LLM with web search) currently does to price a Mac:

1. Run `apple-report` → get chip, RAM, internal SSD size, model identifier.
2. Translate that triplet into a search-shaped phrase per locale ("Mac mini M2 Pro 32GB hinta Suomi", "MacBook Pro 14 M3 Pro 18GB Verkkokauppa").
3. Hit three classes of source in parallel:
   - **New retail** — large electronics chain with current sticker (Verkkokauppa, Power, Gigantti / equivalents abroad).
   - **Price comparison aggregator** — Hintaopas / equivalents (Idealo DE, Prisjakt SE, PriceRunner UK).
   - **Used / private market** — Tori, TechBBS, mResell, Back Market, Swappa, eBay-localized.
4. Read out a triplet:
   - Low (one private-sale comp on TechBBS / Tori).
   - Refurb-with-warranty (mResell / Back Market).
   - New equivalent (Verkkokauppa / Apple direct).
5. Subtract today's used-market value from the new-equivalent to get the "cost-to-upgrade" delta.

This is a deterministic pipeline once the chip→search-term mapping exists. It is exactly the shape `apple-report` already excels at (deterministic, no LLM in the hot path, Apple-native).

## Whitelabel axes

The same tool should work for any user in any market. The locale-dependent inputs are:

| Axis | Example values | How it factors in |
|---|---|---|
| Country code | `FI`, `SE`, `DE`, `UK`, `US`, `JP` | Selects which source set to hit |
| VAT rate | 25.5% FI, 25% SE, 19% DE, 20% UK, 0% US-retail | Reported on new prices for tax-clarity |
| Currency | EUR, SEK, GBP, USD, JPY | Output formatting + FX-neutral comparisons |
| Locale phrase mapping | `hinta`, `pris`, `Preis`, `price` | Search-string construction |
| Source set | per-country YAML list | What URLs to scrape / link |

Country code is the only user-supplied input; the other four derive from it via a single config table.

## Three implementation shapes (ranked)

### Shape 1 — Hand-curated YAML ledger (cheapest, most reliable)

`bin/data/resale-<COUNTRY>.yaml` keyed by `chip × ram × ssd` bucket, hand-updated monthly from price comparison sites. `apple-report --resale FI` looks up the user's machine spec, emits:

```
=== RESALE (FI, May 2026) ===

  Model bucket            Mac mini M2 Pro / 32 GB / 1 TB
  Used (private comp)     1 200–1 400 €
  Refurb (12 mo warranty) 1 350–1 550 €
  New equivalent          ~2 000 €
  Ledger updated          2026-05-15
```

- **Pros:** Zero web calls. Works offline. No HTML brittleness. The ledger doubles as a record of how prices drifted — committable, diff-able. Pure Apple-native pedigree honored (stdlib `yaml` not available, but `json` is — use JSON ledger).
- **Cons:** Manual upkeep. Stale within ~30 days of a chip refresh or recession.
- **Verdict:** Ship first. The ledger becomes a useful artifact independent of the tool.

### Shape 2 — Stdlib scraper with `--fi-resale` flag

`urllib.request` hits a small set of stable URLs per country, regex/HTML-fragment extraction yields price ranges, results cached for 24 hours in `~/.cache/apple-report/resale-<country>.json`.

- **Pros:** Always current. Same single-shot deterministic-tool ergonomics as the rest of `apple-report`.
- **Cons:** Brittle — Verkkokauppa or Tori change layout, scraper breaks. Each country needs its own three-to-five-site scraper. Cache mitigates load but doesn't eliminate fragility. Could be flagged as bot traffic.
- **Verdict:** Worth building once Shape 1 proves the value of the feature. Treat it as a Shape 1 ledger-refresher rather than a hot-path query — run weekly, write JSON to disk, the report reads the JSON.

### Shape 3 — Pre-filled search-link emission

Report emits clickable Hintaopas / Tori / TechBBS / Verkkokauppa URLs pre-filled with the user's exact `chip RAM SSD` query string. User clicks, reads prices manually.

- **Pros:** Zero brittleness. Zero upkeep. Works for any country we have a URL template for.
- **Cons:** Loses the zero-roundtrip property — the human is back in the loop.
- **Verdict:** Useful as a fallback when a country has no ledger yet. Always include alongside Shape 1 output, so the user can sanity-check the ledger against live prices.

### Recommended combination

`apple-report --resale [COUNTRY]` does Shape 1 + Shape 3 by default. If a country lacks a ledger, falls back to Shape 3 alone with a "no ledger yet — submit one via PR" message. Shape 2 lives as a separate `bin/apple-resale-refresh` companion tool that updates ledgers, decoupled from the report path.

## File layout

```
apple/
  bin/
    apple-report                # existing; gains --resale flag
    apple-resale-refresh        # new; updates JSON ledgers
  bin/data/
    resale-FI.json
    resale-SE.json
    resale-DE.json
    resale-UK.json
    resale-US.json
    resale-locales.json         # country → VAT, currency, search-phrase, URL templates
  commands/
    apple-resale.md             # slash: /apple-resale [country]
    apple-resale-refresh.md     # slash: /apple-resale-refresh
  analysis/
    apple-report-resale-enrichment.md   # this file
```

## Ledger JSON schema (Shape 1)

```json
{
  "country": "FI",
  "currency": "EUR",
  "vat_pct": 25.5,
  "updated": "2026-05-21",
  "sources_consulted": [
    "https://www.verkkokauppa.com/",
    "https://hintaopas.fi/",
    "https://www.tori.fi/",
    "https://bbs.io-tech.fi/",
    "https://mresell.fi/"
  ],
  "buckets": [
    {
      "chip": "Apple M2 Pro",
      "form_factor": "Mac mini",
      "ram_gb": 32,
      "ssd_tb": 1,
      "used_low": 1200,
      "used_high": 1400,
      "refurb_low": 1350,
      "refurb_high": 1550,
      "new_equivalent": 2000,
      "notes": "Last new stock thinning; M4 Pro is current line."
    }
  ]
}
```

`form_factor` lets one ledger cover Mac mini, MacBook Pro 14", MacBook Pro 16", iMac, etc. The matcher in `apple-report` reads chip + RAM + SSD + form-factor from `system_profiler` output and selects the closest bucket (exact match preferred, nearest-RAM-and-SSD fallback).

## Source-set template per country

Belongs in `bin/data/resale-locales.json`. One entry sketches the pattern:

```json
{
  "FI": {
    "currency": "EUR",
    "vat_pct": 25.5,
    "vat_label": "ALV",
    "price_phrase": "hinta",
    "search_engines": {
      "new_retail":  "https://www.verkkokauppa.com/fi/search?query={q}",
      "aggregator":  "https://hintaopas.fi/?q={q}",
      "private":     "https://www.tori.fi/recommerce/forsale/search?q={q}",
      "forum":       "https://bbs.io-tech.fi/search/?keywords={q}",
      "refurb":      "https://mresell.fi/?s={q}"
    }
  },
  "SE": {
    "currency": "SEK",
    "vat_pct": 25.0,
    "vat_label": "moms",
    "price_phrase": "pris",
    "search_engines": {
      "new_retail":  "https://www.elgiganten.se/search?query={q}",
      "aggregator":  "https://www.prisjakt.nu/search?search={q}",
      "private":     "https://www.blocket.se/annonser/hela_sverige?q={q}",
      "forum":       "https://www.swedroid.se/search/?q={q}",
      "refurb":      "https://www.inrego.se/?s={q}"
    }
  }
}
```

The same JSON describes Germany (Idealo + eBay-Kleinanzeigen + Rebuy), UK (PriceRunner + Gumtree + Music Magpie), US (Swappa + eBay-completed-sales + Back Market US), Japan (Kakaku.com + Mercari + Sofmap).

## Slash-command surface

- `/apple-report` — unchanged.
- `/apple-report --resale FI` — emits hardware report plus the resale block.
- `/apple-resale FI` — emits only the resale block for the current machine.
- `/apple-resale FI "MacBook Pro 14\" M3 Pro 18GB 2TB"` — emits a resale block for a hypothetical machine (lets the user price machines they don't own).
- `/apple-resale-refresh FI` — refresh the FI ledger (Shape 2 scraper if implemented; otherwise prints "manual refresh required, see analysis doc").

## What this unlocks

Once the ledger format is committed and one country (FI) lives in the repo, the same shape is contributed by anyone in any country via a single PR adding `resale-XX.json` + a row in `resale-locales.json`. The tool itself doesn't change. This is the same whitelabel discipline as `commands/install.sh` — one general mechanism, per-locale data.

Combined with the device-report-to-vault pipeline (`~/work/cc/vault/devices/<hostname>.md`), the Cloudcity BBS surface gains a "fleet" view: every Mac the user owns rendered as a card with current spec, current local resale, and total fleet net-worth. Sal's Audit App lineage applied to hardware itself.

## Open questions to settle before building

1. **Refresh cadence.** Monthly? Weekly? Drift between Shape 1 ledger and Shape 2 scraper output is the signal — set the cadence so drift stays under 10 %.
2. **Bucket granularity.** Per-RAM-tier (8 / 16 / 24 / 32 / 48 / 64 GB) × per-SSD-tier (256 GB / 512 GB / 1 TB / 2 TB / 4 TB / 8 TB) × per-chip — that is ~150 buckets per chip generation. Almost all are empty in the wild. The ledger should only store buckets with at least one real comp.
3. **Hostname privacy.** Should the vault device card include serial number? Probably yes for personal inventory, no for any public-facing dashboard.
4. **FX handling.** When pricing a Mac in EUR for a Finnish user looking at US Back Market stock, do we convert or do we just report side-by-side? Side-by-side is safer.
5. **Sal lineage.** What is the WWSD equivalent of resale pricing? Probably "data the user already has, surfaced where they already are." The user already runs `apple-report`. Adding resale to the same command is the natural Sal move; spawning a separate "valuation app" with its own GUI is the anti-Sal move.

## Status

Design only. No code written. This document is the artifact for "if we want to build it, here is how."
