---
description: The user-visible renamed title of a Voice Memo lives in ZENCRYPTEDTITLE (and ZCUSTOMLABELFORSORTING) — NOT in ZCUSTOMLABEL, which Voice Memos uses internally for an ISO timestamp string. Searching ZCUSTOMLABEL for a user-typed string silently returns zero rows. Discovered 2026-05-25 while building the voice-memo → whisp pipeline.
---

# Voice Memos `ZENCRYPTEDTITLE` holds the renamed title — `ZCUSTOMLABEL` does NOT

## The trap (and why this doc exists)

Apple Voice Memos' Core-Data SQLite database lives at:

```
~/Library/Group Containers/group.com.apple.VoiceMemos.shared/Recordings/CloudRecordings.db
```

The `ZCLOUDRECORDING` table has three VARCHAR columns that LOOK like they could each be "the title":

```
ZCUSTOMLABEL           VARCHAR
ZCUSTOMLABELFORSORTING VARCHAR
ZENCRYPTEDTITLE        VARCHAR
```

The natural assumption — and the one I made on 2026-05-25 — is that `ZCUSTOMLABEL` holds the user's renamed title. The column name says "custom label". When the user opens Voice Memos.app and renames a recording from `New Recording 47` to `Ruoho-Gasik-Kortela talk 1 #process`, that renamed title MUST go into `ZCUSTOMLABEL`, right?

**Wrong.** Empirically verified on macOS Sequoia 15.6.1:

| Column                    | What it actually contains                                   | Example value for a renamed memo                  |
|---------------------------|-------------------------------------------------------------|---------------------------------------------------|
| `ZCUSTOMLABEL`            | **Internal ISO timestamp string** (NOT the user title)      | `"2026-05-25T06:03:19Z"`                          |
| `ZCUSTOMLABELFORSORTING`  | User-visible renamed title (lowercase or sort-folded)       | `"Ruoho-Gasik-Kortela talk 1 #process"`           |
| `ZENCRYPTEDTITLE`         | **User-visible renamed title** (plaintext, despite the name)| `"Ruoho-Gasik-Kortela talk 1 #process"`           |

The name `ZENCRYPTEDTITLE` strongly suggests encrypted bytes — but in practice it stores the title in plaintext UTF-8. The "encrypted" naming is presumably historical (perhaps Voice Memos *intended* to encrypt at some point, or some Apple internal stream uses the column under encryption that doesn't apply on macOS).

If you SELECT a recently renamed recording, both `ZENCRYPTEDTITLE` and `ZCUSTOMLABELFORSORTING` contain the title; `ZCUSTOMLABEL` contains the recording's start-time ISO string.

For UNRENAMED recordings (still showing the default `"New Recording N"` in the UI), all three columns can hold the auto-generated title — which is why a casual probe of `ZCUSTOMLABEL` against old recordings won't reveal the trap. The breakage only appears once the user actively renames.

## The verified query

To find Voice Memos whose user-visible title matches a substring (case-insensitive), use `ZENCRYPTEDTITLE` (preferred) with `ZCUSTOMLABELFORSORTING` and `ZCUSTOMLABEL` as fall-throughs via `COALESCE`:

```sql
SELECT Z_PK, ZUNIQUEID, ZPATH, ZDATE, ZDURATION,
       COALESCE(ZENCRYPTEDTITLE, ZCUSTOMLABELFORSORTING, ZCUSTOMLABEL, '') AS title
  FROM ZCLOUDRECORDING
 WHERE lower(COALESCE(ZENCRYPTEDTITLE, ZCUSTOMLABELFORSORTING, ZCUSTOMLABEL, ''))
       LIKE '%#process%'
 ORDER BY ZDATE DESC;
```

Diagnostic queries that hide the trap (DON'T trust them):

```sql
-- This returns ZERO rows for any renamed memo — silently:
SELECT * FROM ZCLOUDRECORDING WHERE ZCUSTOMLABEL LIKE '%#process%';

-- This returned 401 (the renamed memo) only because it concatenates
-- all three columns; the match came from ZCUSTOMLABELFORSORTING, NOT
-- from ZCUSTOMLABEL. Easy to misread.
SELECT * FROM ZCLOUDRECORDING
 WHERE lower(IFNULL(ZCUSTOMLABEL,''))
     ||lower(IFNULL(ZCUSTOMLABELFORSORTING,''))
     ||lower(IFNULL(ZENCRYPTEDTITLE,'')) LIKE '%#process%';
```

## How the trap actually manifested

While building the voice-memo → whisp pipeline (`operations/voice-memos-process-tag-pipeline.md`), the Swift watcher inside AppleToolbox polled CloudRecordings.db every 30 s for `ZCUSTOMLABEL LIKE '%#process%'`. The user had renamed a recording to `Ruoho-Gasik-Kortela talk 1 #process` and was expecting the pipeline to submit it to the Mac Mini. Hours of "the pipeline isn't picking it up" debugging followed:

- First hypothesis: FDA missing → fixed but didn't change behaviour.
- Second hypothesis: SQLite URI mode broken by the space in `Group Containers/` → fixed but didn't change behaviour.
- Third hypothesis: `SQLITE_TRANSIENT` Swift bit-cast misbehaving → replaced with inline literal but didn't change behaviour.
- Fourth probe: added a diagnostic that printed the **3 most recent `ZCUSTOMLABEL` values**. They came back as `2026-05-25T08:32:05Z`, `2026-05-25T07:28:57Z`, `2026-05-25T06:03:19Z`. The trap revealed itself: `ZCUSTOMLABEL` doesn't hold the title.

The CLI sqlite3 probe that ran *earlier* and appeared to confirm the column choice was actually a query that concatenated all three columns; the match came from a different column than the one I was filtering on in Swift. **A concatenated-column query can mask a column-naming error.** When debugging "the data is there but my SELECT doesn't see it", always run a SELECT that prints the value of each candidate column for the exact row you expect to match — don't trust concatenation-based existence proofs.

## How to apply

- **Any code that searches Voice Memo titles** — Spotlight bridges, watchers, tag scanners, the voice-memo → whisp pipeline — MUST query `ZENCRYPTEDTITLE` (with `COALESCE` fallback) or it will silently miss any renamed memo.
- **`voice-memos-export` and friends** in `~/work/apple/voice-memos-exporter/` should be audited for `ZCUSTOMLABEL`-only reads of the title; they will appear to work on default-titled memos and silently degrade on renamed ones.
- **When debugging "DB has the row but my query returns nothing"**, log the value of every candidate column for the row you expect to match, not just a concatenation. The concatenation passes when ANY column has the match; only per-column SELECTs reveal which one actually does.

## Related

- `concepts/voice-memos-tsrp-atom.md` — the OTHER hidden-title trap: Apple's auto-generated transcripts live in a `tsrp` atom appended to the .m4a file, not in any SQLite column.
- `operations/voice-memos-process-tag-pipeline.md` — the live pipeline that depends on this column knowledge (`#process` tag in `ZENCRYPTEDTITLE` → whisp on the Mini).

## ZCLOUDRECORDING column reference (relevant subset)

| Column                    | Type      | Notes                                                              |
|---------------------------|-----------|--------------------------------------------------------------------|
| `Z_PK`                    | INTEGER   | Core-Data primary key.                                             |
| `ZUNIQUEID`               | VARCHAR   | UUID-shaped stable id (e.g. `30E971EB-C672-...`). Use this for dedup. |
| `ZPATH`                   | VARCHAR   | Bare filename inside Recordings/ (e.g. `"20260525 090319.m4a"`).  |
| `ZDATE`                   | TIMESTAMP | Core-Data offset — add `978307200` to get unix epoch.              |
| `ZDURATION`               | FLOAT     | Seconds.                                                           |
| `ZCUSTOMLABEL`            | VARCHAR   | **Internal ISO timestamp string**, NOT the user title. ⚠           |
| `ZCUSTOMLABELFORSORTING`  | VARCHAR   | User title (sort-folded variant — see ZENCRYPTEDTITLE).            |
| `ZENCRYPTEDTITLE`         | VARCHAR   | **User-visible renamed title** in plaintext UTF-8.                 |
| `ZFLAGS`                  | INTEGER   | Bit 3 (mask `0x08`) = has Apple-native transcript in .m4a tail.    |
| `ZFOLDER`                 | INTEGER   | FK to `ZFOLDER` table.                                             |
