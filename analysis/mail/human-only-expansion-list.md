# Human Only — Token Expansion List

Companion to `human-digest-logic.md`. The user's screenshot 2026-05-13
shows 11 initial rows; this list is what to add next. All rows use the
same shape: `Entire message | does not contain | TOKEN`.

Predicate `Entire message` matches across From / To / Subject / Body /
inline HTML, so one row per token is enough — don't fan out across
fields.

Organized by **block** so you can pick whole categories at once.
Tokens already in the user's screenshot are NOT repeated here.

---

## Block 1 — English compliance-footer phrases

These are the legal-disclaimer + opt-out phrases every CAN-SPAM /
GDPR-compliant bulk sender prints. Very high signal, near-zero false
positives.

```
view this email in your browser
view in browser
click here to unsubscribe
to unsubscribe
manage your preferences
manage your subscription
email preferences
update preferences
notification settings
manage notification
no longer wish to receive
opt out
opt-out
you signed up
you are receiving this
you're receiving this
this email was sent to
this message was sent to
why am I getting this
was this email forwarded
all rights reserved
```

## Block 2 — Finnish compliance-footer phrases

```
poista tilaus
lopeta tilaus
peruuta tilaus
tilauksen lopettaminen
et halua vastaanottaa
et enää halua vastaanottaa
muokkaa tilausta
muokkaa asetuksia
sähköpostiosoitteesi
tämä viesti lähetettiin
näytä selaimessa
selaimessasi
lähetetty osoitteeseen
viestin tilaaminen
tilauksesi
```

## Block 3 — Automation / no-reply tells

```
noreply
no-reply
donotreply
do not reply
do-not-reply
please do not reply
this is an automated
automated message
automatically generated
this email was automatically
mailer-daemon
postmaster
notifications@
alerts@
```

## Block 4 — Platform-specific notification phrases

User already has GitHub. Same pattern generalizes — every notification
platform emits "Manage your X notifications" or "Notification settings"
boilerplate.

```
Manage your LinkedIn
Manage your Twitter
Manage your X notifications
Manage your Notion
Manage your Slack
Manage your Discord
Manage your Reddit
Manage your Medium
Manage your Substack
Manage your Patreon
Manage your Bandcamp
Manage your Spotify
Manage your YouTube
Manage email notifications
Email notification settings
You can change your notification
```

## Block 5 — ESP / bulk-sender domain markers in HTML

`Entire message` includes the raw HTML source, so tracking-pixel URLs
and unsubscribe-link domains are visible to the predicate.

```
list-manage.com
campaign-archive
mailchimp
sendgrid.net
mailgun
constantcontact
ccsend
klaviyo
convertkit
substackcdn
beehiiv
mailerlite
hubspotemail
hsforms
pardot
marketo
eloqua
mandrillapp
postmarkapp
sparkpostmail
amazonses
salesforce-marketing
```

## Block 6 — Subject-pattern bulk tells

(`Entire message` catches these too; still worth listing because they're
very common.)

```
[Newsletter]
weekly digest
weekly roundup
monthly digest
daily digest
Auto:
Automatic reply
Out of office
```

---

## Recommended add order

If you're typing these by hand, start with the high-leverage low-count
blocks:

1. **Block 1 (~21 rows)** — biggest precision win. The compliance-footer
   phrases are present in essentially every newsletter.
2. **Block 2 (~15 rows)** — Finnish coverage. Critical for your inbox
   specifically.
3. **Block 3 (~14 rows)** — automation tells.
4. **Block 4 (~16 rows)** — platform notifications. Add only the
   platforms you actually get email from.
5. **Block 5 (~22 rows)** — ESP markers. Catches the long tail.
6. **Block 6 (~8 rows)** — subject patterns. Add last; lowest marginal
   gain since `Entire message` will catch most of these via body
   content already.

Total if you add everything: ~96 new rows on top of your existing 11
= ~107 row smart mailbox. Mail handles this fine; the criteria
evaluator is in-memory against the Envelope Index.

## False-positive watchlist

These tokens look tempting but I'd skip them — they fire on legit human
mail too often:

| Token | False-positive |
|-------|---------------|
| `info@` | Small businesses email humans from `info@theirsite.com` |
| `hello@` | Same, especially solo founders / agencies |
| `support@` | Real human-written support replies |
| `team@` | Same |
| `digest` | Real summary emails from humans |
| `notification` (alone) | Sometimes in human-written subjects |
| `update` (alone) | Way too generic |
| `weekly` (alone) | Same |
| `© 2026` | Even some human emails have signature footers |
| `mailto:` | In every email's HTML source |

If you find a newsletter slipping through, prefer adding a more
specific phrase from its footer than a generic token.

## Maintenance loop

When something gets through:
1. Open the email.
2. View → Message → Raw Source (Cmd-Opt-U).
3. Find a phrase in the footer that's near-impossible to occur in
   human mail (e.g. "You're receiving this because you subscribed at"
   or the specific compliance line).
4. Add it as a new `Entire message | does not contain | PHRASE` row.
5. Save the smart mailbox.

The list is additive, never destructive. iCloud syncs it to other Macs.
