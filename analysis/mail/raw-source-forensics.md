# Newsletter forensics — finding the right blocking phrase

When a newsletter sneaks past your "Human Only" smart mailbox, open it
in Mail and press **Cmd-Opt-U** (View → Message → Raw Source). You get
the full RFC 822 message: headers + body + raw HTML in one window.

This document is the field guide for extracting a single high-signal
phrase from that source view that you can drop into the smart mailbox
as a new `Entire message does not contain` row.

---

## What `Entire message` actually sees (and what's uncertain)

Confirmed from your existing 11-row smart mailbox: `Entire message`
matches against the **visible body text** (English + Finnish words
appear in normal body content). It almost certainly also matches the
**raw HTML source** of the email, which means link `href=` URLs and
tracking-pixel domains are visible to the predicate.

**Uncertain:** whether `Entire message` extends to RFC headers like
`List-Unsubscribe`, `List-Id`, `Precedence`, `X-Mailer`, etc. Apple
doesn't document this. **Easy 30-second test:** add a row
`Entire message does not contain List-Unsubscribe` and see if your
Human Only count drops. If it does, headers are in scope and you have
a nuclear option — the single phrase `List-Unsubscribe` would block
nearly every newsletter on the planet, since RFC 8058 / Gmail+Yahoo
2024 sender rules make it effectively mandatory.

Even if headers are NOT in scope, the body + HTML source has more than
enough fingerprintable surface. The strategy below works either way.

---

## The five fingerprint categories (in raw source view)

### 1. Unsubscribe-link host domain (highest signal)

Scroll to the bottom of the raw source. You'll see something like:

```html
<a href="https://hs-39172081.s.hubspotemail.net/unsubscribe?...">
  Unsubscribe
</a>
```

**Add as token:** `hubspotemail.net` — every email from this ESP will
match. One row blocks the entire sender.

Common host-domain patterns to recognize:

| Domain fragment | What it is |
|-----------------|-----------|
| `list-manage.com` | Mailchimp |
| `email.substack.com` | Substack |
| `e.notion.so`, `notify.notion.so` | Notion |
| `notifications.linkedin.com`, `e.linkedin.com` | LinkedIn |
| `notifications.github.com`, `noreply.github.com` | GitHub |
| `email.bandcamp.com`, `support.bandcamp.com` | Bandcamp |
| `e.patreon.com` | Patreon |
| `email.substack.com` | Substack |
| `hs-XXXXXXXX.s.hubspotemail.net` | HubSpot |
| `t.sidekickopen.com` | HubSpot Sidekick |
| `email.medium.com` | Medium |
| `t.bnc.lt`, `bnc.lt` | Branch.io (notifications) |
| `sgs.email.sendgrid.com` | SendGrid |
| `mailgun.org` | Mailgun |
| `klaviyomail.com` | Klaviyo |
| `email.convertkit.com` | ConvertKit |
| `email.mailerlite.com` | MailerLite |
| `amazonses.com` | Amazon SES (very generic) |
| `mandrillapp.com` | Mandrill |
| `postmarkapp.com` | Postmark |
| `email.beehiiv.com` | Beehiiv |
| `campaign-archive.com` | Mailchimp archive |

### 2. ESP-specific RFC headers

Look at the top headers section. ESP-stamped headers are usually obvious:

```
X-Mailer: MailChimp Mailer
X-Campaign: 12345-newsletter-2026-05
X-MC-User: abc123
Feedback-ID: 12345-newsletter:hubspot
X-SG-EID: ...
X-Mailgun-Sending-Ip: ...
X-Klaviyo-...
X-Mc-Subaccount-Id: ...
X-Marketo-...
```

**Add as token:** the distinctive header NAME, e.g. `X-Mailer: MailChimp`
or `Feedback-ID:` (alone). If `Entire message` doesn't cover headers,
this row will silently do nothing — that's the diagnostic.

### 3. Compliance-footer boilerplate (always present)

Search the visible body for the legal-required language:

- `You're receiving this because`
- `You signed up for`
- `Vastaanotat tämän viestin koska` (Finnish equivalent)
- `Sähköpostiosoitteesi on lisätty`
- `If you no longer wish to receive`
- `Was this email forwarded to you?`
- `Why did I get this email?`

Copy a 5-8 word slice that's unlikely to appear in human-written mail.
Specificity matters: `"You're receiving this"` is too short and might
false-positive; `"You're receiving this because you subscribed at"` is
ironclad.

### 4. Sender's per-campaign signature line

Sometimes the unsubscribe footer says something like:

```
Substack Inc. · 548 Market St · PMB 72296 · San Francisco
© 2026 Notion Labs, Inc.
This message was sent to you because you have a free account
```

The **postal address line** + `© YYYY` line is a CAN-SPAM legal
requirement for US senders — never present in human mail.

**Add as token:** something like `Substack Inc. ·` (with the middle-dot
character) or the city in the address line, IF the sender is one you
specifically want to silence and the city is unusual enough.

### 5. Tracking-pixel + click-tracking URL prefixes

Search the raw HTML for `<img` and look at the source URL:

```html
<img src="https://e.notion.so/o.gif?campaign=12345" width="1" height="1">
```

The host (`e.notion.so`) is the same as category 1 — same blocking row
works. The path (`/o.gif`) and query (`?campaign=`) are also rare in
human mail but not unique enough alone.

Similarly look for `<a href="https://click.email.X.com/...">`. The
click-tracker host is the most reliable fingerprint.

---

## Workflow per slipping newsletter

1. Open the email in Mail.
2. **Cmd-Opt-U** → Raw Source.
3. Scroll to the very bottom of the source view (or Cmd-F for
   `Unsubscribe`).
4. Find the `<a href="...">` of the Unsubscribe link.
5. Note the **host domain** (everything between `https://` and the
   next `/`).
6. Mail → Mailbox → Edit Smart Mailbox → Human Only → click `+`.
7. New row: `Entire message | does not contain | <that host domain>`.
8. Click OK.
9. Verify: the message should immediately drop out of Human Only.
   If it doesn't, the host domain wasn't visible to `Entire message`
   (rare — usually means it was only in a header, not body HTML).
   Fallback: try the bottom-of-footer compliance-phrase from category 3.

The host domain is almost always the right answer because:

- It's unique to the ESP / sender.
- It appears in the body's HTML, which `Entire message` definitely sees.
- It blocks every future email from that ESP in one row.
- It almost never appears in legitimate human mail.

## Building a regression test

Once you've added the row, file the slipping email's raw source into:

```
~/work/apple/exported/mail/human-only-slips/<date>-<sender>.eml.txt
```

(or similar). When you later debug "did my new row work?", you have
the canonical example. This is the same kind of fingerprint library
that Sal-style automation builds over time: each slip teaches the
filter one more thing.

## Anti-pattern: blocking the sender's name

Tempting and wrong. If you add `Entire message does not contain
"Notion"`, you also block messages from your coworker who happens to
mention Notion in a sentence. Block the **infrastructure domain**
(`e.notion.so`), not the brand. The infrastructure domain is invariant
across the sender's marketing campaigns and absent from human mail.
