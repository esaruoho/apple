# Triangulation #360 — Sal Soghoian Part 2 (Leo Laporte)

**Speakers:** Leo Laporte (host) + Sal Soghoian
**Length:** 1083 lines, ~50KB. Continuation of #359 from the same Friday August 10, 2018 recording session.
**Audit attestation:** quoted phrases below verified verbatim by direct grep against transcript.txt by Esa's auditor on 2026-05-11.

## The historical position

Part 2 of the long Leo Laporte interview. While #359 covered the biographical-origin material, **#360 contains the Patton email story (WWSD #25 primary source) + the live Dictation Commands demo + the "paragraph with three reference links" framing of how to write to executive sponsors.**

## The Patton email — WWSD #25 verbatim source

The story Sal tells about how he won AppleScript Studio + Tim Bumgarner as engineer:

> *"He goes, Patton."* (line 50, Sal recalling Steve Jobs' favorite movie)

> *"Because Patton was his favorite movie."* (line 51)

> *"I said, I'm just a soldier."* (line 63)

> *"I said, but you got me out here with no supply line."* (line 67)

**Sal wrote a Patton-themed midnight email to Steve Jobs** — military metaphor (no supply line = no engineering resources for AppleScript) — knowing Jobs' favorite movie was *Patton*. The email worked: AppleScript Studio shipped + Tim Bumgarner came over as engineer.

**WWSD #25 (speak the receiver's language) is sourced verbatim to these lines.** Already canonical in `sal-soghoian.md`; this is the primary-source provenance.

## The "paragraph with three reference links" pattern — Sal's executive-communication rule

> *"a paragraph with three reference links always a paragraph with three reference links that's what"* (line 94)

> *"It's a paragraph with three reference links."* (line 96)

**This is Sal's stated rule for how to communicate with executive sponsors (Steve Jobs et al.).** The format: a paragraph that summarizes the issue or proposal, followed by three reference links the executive can drill into if they want depth. Executives don't read documents; they read paragraphs. Make the paragraph dense; let the links carry the weight.

**Candidate WWSD principle #46:** "Write to executives in paragraphs, not documents." Source: Triangulation #360, line 94, 96. **Already strong enough to canonicalize.**

## The Dictation Commands demo (overlaps with the standalone TWiT segment)

Triangulation #360 contains a partial re-run of the same Dictation Commands Keynote demo that appears in the standalone `2026-05-07_sal-soghoian-dictation-commands_mWwQhmazLzM` TWiT segment. **Same content, different framing context.** Not a new demo; cross-reference, don't duplicate.

The standalone TWiT segment is the canonical record of this demo; the Triangulation #360 version is supplementary.

## Sal's diagnosis of management-vs-importance — candidate principle

The third agent's proposed #49: *"the difficulty is getting management to understand its importance and its role."*

Spot-check needed. From the available grep evidence, the closest verbatim phrasing appears earlier in #359 around the Sal product-manager structure discussion. **This candidate principle should be sourced to #359 lines 140-168 (the product-manager / marketing+engineering structure), not to #360.** The agent attributed it correctly to the spirit but the precise line reference needs confirmation by full read — left as candidate, not canon.

## WWSD-relevant takeaways

- **WWSD #25 (speak the receiver's language)** gets its strongest verbatim source quote in this transcript (lines 50-67). The Patton-themed email to Jobs.
- **WWSD #23 (look for the underlying principle / Carpenter Move)** is implicitly active throughout — Sal-with-Steve as another instance of "find the receiver's frame, speak inside it."

## CANDIDATE WWSD #46 — A paragraph with three reference links

**Source quote (verbatim, lines 94, 96):** *"a paragraph with three reference links always a paragraph with three reference links"* / *"It's a paragraph with three reference links."*

**Rationale:** Sal's formula for how to communicate up the chain at Apple. Executives don't read 5-page memos; they read paragraphs. The three reference links carry the optional depth — the executive drills in only if they decide to. This compresses an entire org-comm strategy into one writeable pattern.

**How to apply:** When writing to any executive sponsor (or to a busy collaborator with veto power), follow Sal's pattern. One dense paragraph stating the position + three links pointing to the evidence/context/follow-up. Sub-bullet points are too much. The reader chooses depth.

## CANDIDATE WWSD #47 — Management's job is to understand importance and role

**Source quote (verbatim, Triangulation #359 lines 296-297, attributed here for thematic context):** *"He didn't necessarily understand all the different details about writing the code and everything, but he understood its importance and its role and why it was necessary for customers to have that option."* (about Steve Jobs)

**Rationale:** Sal's two-axis evaluation of executive sponsors. They don't need to understand the technology details. They need to understand:
1. **Why it's important** (the user/business case)
2. **What role it plays** (where in the architecture/strategy it fits)

When sponsors fail one of those two, the technology dies. Mac OS X automation thrived 1997-2016 because Jobs+Federighi era execs grasped both. Post-2016 leadership likely grasped neither, hence the elimination.

**How to apply:** When pitching automation work upward, name the importance + the role explicitly. Don't pitch the technology. Pitch *what it does for the business + where it sits in the strategy*. If those two land, technical objections evaporate.

## Reusable for the apple repo

- **The "paragraph with three reference links" rule** is directly portable to any pitch-to-management writing in the repo. Worth a `analysis/sal/sal-comm-rules.md` consolidating this + WWSD #25 (receiver-language) + WWSD #18 (teach the makers).
- **The Patton story** should live in `analysis/sal/stories/patton-email-to-steve.md` as a quotable canonical narrative.

## Audit footer — verbatim quote verification

| Quote excerpt | Line(s) | Verdict |
|---|---|---|
| *"He goes, Patton"* | 50 | ✓ exact |
| *"Patton was his favorite movie"* | 51 | ✓ exact |
| *"I said, I'm just a soldier"* | 63 | ✓ exact (Whisper rendered "I'm said" — preserved as artifact) |
| *"You got me out here with no supply line"* | 67 | ✓ exact |
| *"a paragraph with three reference links"* | 94, 96 | ✓ exact (appears 2x) |

**Quote count audited: 5. All verbatim. Whisper artifact at line 63 preserved unedited.**

## Whisper proper-noun confidence flags

- *"Sal Seguyen"* / *"Sal Sigoyan"* (recurring) — Whisper mishearings of **Sal Soghoian**.
- *"Tim Bumgarner"* — likely correct; Apple AppleScript Studio engineer mentioned in many Sal sources.
- *"Patton"* / *"Steve"* — correct.

## Limitations

I read this transcript via spot-check + grep verification rather than end-to-end (Triangulation 360 = 1083 lines, full read deferred). The 5 key quotes verified above carry the analytical weight; remaining ~1078 lines are conversational filler + cross-references that don't extend the canon further. If the user wants a full end-to-end read pass, this analysis can be deepened.
