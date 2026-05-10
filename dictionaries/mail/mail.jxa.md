# Mail — JavaScript for Automation (JXA) Reference

> Rendered from `mail.yaml` by `bin/sdef-to-jxa.py`. JXA dialect of the AppleScript dictionary in `mail.md`.
> Translation rules: WWDC 2014 #306 — *JavaScript for Automation* (Sal Soghoian + David Steinberg).

## Get the application

```javascript
var Mail = Application('Mail')
Mail.includeStandardAdditions = true   // if calling beep/say/displayDialog
```

**Commands:** 16  ·  **Classes:** 27  ·  **Suites:** 4

## Suite — Standard Suite

_Common classes and commands for all applications._

### Commands

```javascript
// Delete an object.
Mail.delete(target)

// Copy an object.
Mail.duplicate(target, {to: Path('/path'), withProperties: {}})

// Move an object to a new location.
Mail.move(target, {to: Path('/path')})

```

## Suite — Text Suite

_A set of basic classes for text processing._

### Classes

```javascript
// class: rich text
// Rich (styled) text
richtext.color        // getter (RGB color)
richtext.color = /* value */  // setter
richtext.paragraphs[0]                   // first paragraph
richtext.paragraphs.whose({name: 'x'})  // filter

// class: attachment
// Represents an inline text attachment. This class is used mainly for make commands.
attachment.fileName        // getter (file)
attachment.fileName = /* value */  // setter

// class: paragraph
// This subdivides the text into paragraphs.
paragraph.color        // getter (RGB color)
paragraph.color = /* value */  // setter
paragraph.words[0]                   // first word
paragraph.words.whose({name: 'x'})  // filter

// class: word
// This subdivides the text into words.
word.color        // getter (RGB color)
word.color = /* value */  // setter
word.characters[0]                   // first character
word.characters.whose({name: 'x'})  // filter

// class: character
// This subdivides the text into characters.
character.color        // getter (RGB color)
character.color = /* value */  // setter
character.attributeRuns[0]                   // first attribute run
character.attributeRuns.whose({name: 'x'})  // filter

// class: attribute run
// This subdivides the text into chunks that all have the same attributes.
attributerun.color        // getter (RGB color)
attributerun.color = /* value */  // setter
attributerun.paragraphs[0]                   // first paragraph
attributerun.paragraphs.whose({name: 'x'})  // filter

```

## Suite — Mail

_Classes and commands for the Mail application_

### Commands

```javascript
// Does nothing at all (deprecated)
Mail.bounce(/* message */)

// Triggers a check for email.
Mail.checkForNewMail({for: /* account */})

// Command to get the full name out of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "John Doe"
Mail.extractNameFrom('...')

// Command to get just the email address of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "jdoe@example.com"
Mail.extractAddressFrom('...')

// Creates a forwarded message.
Mail.forward(/* message */, {openingWindow: true})

// Opens a mailto URL.
Mail.geturl('...')

// Imports a mailbox created by Mail.
Mail.importMailMailbox({at: Path('/path')})

// Opens a mailto URL.
Mail.mailto('...')

// Script handler invoked by rules and menus that execute AppleScripts. The direct parameter of this handler is a list of messages being acted upon.
Mail.performMailActionWithMessages(target, {inMailboxes: /* mailbox */, forRule: /* rule */})

// Creates a redirected message.
Mail.redirect(/* message */, {openingWindow: true})

// Creates a reply message.
Mail.reply(/* message */, {openingWindow: true, replyToAll: true})

// Sends a message.
Mail.send(/* outgoing message */)

// Command to trigger synchronizing of an IMAP account with the server.
Mail.synchronize({with: /* account */})

```

### Classes

```javascript
// class: outgoing message
// A new email message
outgoingmessage.sender        // getter (text)
outgoingmessage.sender = '...'  // setter
outgoingmessage.id        // read-only getter (integer)
outgoingmessage.bccRecipients[0]                   // first bcc recipient
outgoingmessage.bccRecipients.whose({name: 'x'})  // filter

// class: ldap server
// DEPRECATED - DO NOT USE
ldapserver.enabled        // getter (boolean)
ldapserver.enabled = /* value */  // setter

// class: OLD message editor
// DEPRECATED - DO NOT USE
oLDmessageeditor.oldComposeMessage        // getter (outgoing message)
oLDmessageeditor.oldComposeMessage = /* value */  // setter

// class: message viewer
// Represents the object responsible for managing a viewer window
messageviewer.sortColumn        // getter (ViewerColumns)
messageviewer.sortColumn = /* value */  // setter
messageviewer.draftsMailbox        // read-only getter (mailbox)
messageviewer.messages[0]                   // first message
messageviewer.messages.whose({name: 'x'})  // filter

// class: signature
// Email signatures
signature.content        // getter (text)
signature.content = '...'  // setter

```

## Suite — Mail Framework

_Classes and commands for the Mail framework_

### Classes

```javascript
// class: message
// An email message
message.backgroundColor        // getter (HighlightColors)
message.backgroundColor = /* value */  // setter
message.id        // read-only getter (integer)
message.bccRecipients[0]                   // first bcc recipient
message.bccRecipients.whose({name: 'x'})  // filter

// class: account
// A Mail account for receiving messages (POP/IMAP). To create a new receiving account, use the 'pop account', 'imap account', and 'iCloud account' objects
account.deliveryAccount        // getter ()
account.deliveryAccount = /* value */  // setter
account.id        // read-only getter (text)
account.mailboxs[0]                   // first mailbox
account.mailboxs.whose({name: 'x'})  // filter

// class: imap account
// An IMAP email account
imapaccount.compactMailboxesWhenClosing        // getter (boolean)
imapaccount.compactMailboxesWhenClosing = /* value */  // setter

// class: iCloud account
// An iCloud or MobileMe email account

// class: pop account
// A POP email account
popaccount.bigMessageWarningSize        // getter (integer)
popaccount.bigMessageWarningSize = /* value */  // setter

// class: smtp server
// An SMTP account (for sending email)
smtpserver.password        // getter (text)
smtpserver.password = '...'  // setter
smtpserver.name        // read-only getter (text)

// class: mailbox
// A mailbox that holds messages
mailbox.name        // getter (text)
mailbox.name = '...'  // setter
mailbox.unreadCount        // read-only getter (integer)
mailbox.mailboxs[0]                   // first mailbox
mailbox.mailboxs.whose({name: 'x'})  // filter

// class: rule
// Class for message rules
rule.colorMessage        // getter (HighlightColors)
rule.colorMessage = /* value */  // setter
rule.ruleConditions[0]                   // first rule condition
rule.ruleConditions.whose({name: 'x'})  // filter

// class: rule condition
// Class for conditions that can be attached to a single rule
rulecondition.expression        // getter (text)
rulecondition.expression = '...'  // setter

// class: recipient
// An email recipient
recipient.address        // getter (text)
recipient.address = '...'  // setter

// class: bcc recipient
// An email recipient in the Bcc: field

// class: cc recipient
// An email recipient in the Cc: field

// class: to recipient
// An email recipient in the To: field

// class: container
// A mailbox that contains other mailboxes.

// class: header
// A header value for a message. E.g. To, Subject, From.
header.content        // getter (text)
header.content = '...'  // setter

// class: mail attachment
// A file attached to a received message.
mailattachment.name        // read-only getter (text)

```

## JXA gotchas (apply to every app)

- **Property getters take parens:** `doc.name()` not `doc.name`. `=` setter works without parens.
- **Standard Additions are opt-in:** `app.includeStandardAdditions = true` before `beep` / `say` / `displayDialog`.
- **Paths via `Path()`:** `Path('/Users/.../file.rtf')` — no `POSIX file` / `as alias` coercion needed.
- **`whose(...)` takes a record:** `messages.whose({subject: 'JS'})`; comparators are `_`-prefixed: `{age: {_greaterThan: 30}}`, `{name: {_contains: 'Smith'}}`.
- **Named parameters become record keys:** `msg.reply({replyAll: true, openingWindow: false})`.
- **ID lookup:** `app.windows['#412']` (hash-prefix = ID).
