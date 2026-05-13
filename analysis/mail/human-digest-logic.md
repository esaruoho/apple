# Human Only / HUMAN DIGEST — Smart Mailbox Logic Spec

> **2026-05-13 corrections after seeing the actual predicate dropdown.**
> Two earlier claims were wrong:
>
> 1. **There is NO "Sender is in my Contacts" predicate** in Mail's
>    smart-mailbox UI. The closest available positive human signals are
>    **"Sender is VIP"** (narrow, your curated VIP list) and
>    **"Sender is member of group"** (requires a Contacts.app group).
>    My Tier A spec assuming a free Contacts predicate is dead.
> 2. **There is NO "Message is addressed to mailing list" predicate.**
>    `List-Id` / `Sender` header detection is not exposed.
>
> The complete predicate dropdown on macOS Sequoia Mail:
>
> - Text-match: **Entire message**, From, Any recipient, Subject
> - Date: Date received, Date last viewed
> - Routing: Account, Message is/is not in mailbox
> - Sender flags: Sender is VIP, Sender is member of group
> - State: Message is flagged/unflagged, read/unread, has flag (color),
>   was replied to / not replied to, Priority is low/normal/high
> - Attachments: Contains attachments, Any attachment name,
>   Attachment type
>
> **Implication:** the only viable Human Only design is the `Entire
> message DoesNotContain` token blocklist. There is no Contacts-based
> precision tier. Expansion list at `human-only-expansion-list.md`.
> Single combined `Entire message` predicate matches across From + To +
> Subject + Body + raw HTML, so one row per token suffices.

Goal: a smart mailbox that shows only **human-sent email**. Newsletters,
transactional notifications, marketing, auto-replies, and list traffic
should be invisible. Personal correspondence and first-contact strangers
should remain.

Two design tiers because there is no single right cutoff. Pick one, or
run both side-by-side.

---

## Tier A — VIP + GROUP (the only positive human signal)

Mail does not have a "Sender is in my Contacts" predicate (earlier
versions of this doc claimed it does — that was wrong). The only
positive human signals exposed in the smart-mailbox UI are:

- **Sender is VIP** — your curated VIP list, narrow but ironclad
- **Sender is member of group** — requires a Contacts.app group; if
  you maintain a "Humans" group, this approximates the Contacts check

Combined (with `match any`) they give a tight, opt-in human inbox.
Misses anyone you haven't VIP'd or grouped.

---

## Tier B — HUMAN ONLY (token blocklist, the user's actual approach)

Shows everything that doesn't smell like bulk mail. Includes strangers.
Lets through the occasional weakly-tagged newsletter, but very few.

Smart Mailbox header: **Contains messages that match `all` of the following:**

All rows use the single predicate **`Entire message | does not contain
| TOKEN`**. `Entire message` matches across From + To + Subject + Body
+ raw HTML in one row, so per-field splits are unnecessary.

For the full token list (English + Finnish + ESP markers + platform
notifications) see `human-only-expansion-list.md`.

- Include messages from Trash: **off**
- Include messages from Sent: **off**

---

## Tier C — STRICTER (Tier B AND positive signal)

Build two smart mailboxes and look at the inner one:

1. **"Human Only"** = Tier B token blocklist
2. **"Human Only — VIPs+"** = a child smart mailbox under "Human Only"
   that additionally requires `Sender is VIP` OR `Sender is member of
   group "Humans"` (set match mode to `any` and have these as the only
   two positive predicates)

Mail's `MailboxChildren` plist field supports nesting, and the UI
exposes "Add Smart Mailbox to Folder" / drag-into-folder to organize.

---

## Why these tokens

- **`List-Unsubscribe` is the killer signal**, but Mail's smart-mailbox
  UI does not expose arbitrary header matching. The closest proxy is
  body-text "unsubscribe" — every legally-compliant bulk sender includes
  the word in the visible footer, since RFC 8058 + Gmail/Yahoo 2024
  sender requirements made it effectively mandatory.
- **`noreply` / `no-reply` family** catches automated transactional
  mail (order confirmations, password resets, calendar invites from
  systems) without false-positiving on real people, since "noreply" is
  vanishingly rare in human From addresses.
- **`@info` / `@hello` / `@team` family** is aggressive — small
  businesses sometimes email humans from `hello@theirsite.com`. Drop
  these from the list if it bites you.
- **ESP domains** (mailchimp, sendgrid, substack, etc.) catch the
  rebrand-sender case where a bulk sender shows up `from "Some
  Person <person@theircompany.com>"` but the underlying envelope sender
  is an ESP — Mail's "From" predicate sees the displayed From, not the
  envelope, so this only fires when the ESP didn't bother to rewrite.
  Worth keeping anyway; cheap to evaluate.

## Why "all of the following" not "any"

Each block is **exclusionary**: if ANY blocked token matches, the
message should be hidden. Boolean logic: `keep = NOT (token1 OR token2
OR ...)` = `(NOT token1) AND (NOT token2) AND ...`. Mail's smart
mailbox uses De Morgan's at the UI layer, so the all-of-DoesNotContain
form is the correct one.

## Build path

This file is the spec. Three ways to realize it:

1. **By hand in Mail UI** — 60+ predicates, fastest if you build it
   once and let iCloud sync to your other Macs. Mailbox menu → New
   Smart Mailbox → set name "HUMAN DIGEST" → click `+` per row → set
   each pop-up + value → Save. Painful but works today.

2. **UI scripting via System Events** — the deferred-but-planned path.
   Drive the same dialog programmatically. Mail's own write code runs,
   so the result survives Mail relaunch (unlike raw plist writes — see
   `smart-mailboxes.md`).

3. **AppleScript hail-mary** — `tell application "Mail" to make new
   smart mailbox with properties {name:"HUMAN DIGEST"}`. The sdef shows
   no smart-mailbox class, but it's a 5-second test worth running once.

## Maintenance pattern

When a newsletter slips through, append its giveaway token to the
relevant block. Track which token caught what in the comments of
each predicate (Mail lets you type a Name on Compound groups; we'll
use those names to label which block a token belongs to).
