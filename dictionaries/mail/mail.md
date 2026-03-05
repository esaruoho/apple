# Mail — AppleScript Reference

> Extracted from scripting dictionary via `sdef`
> 16 commands, 25 classes, 4 suites

```applescript
tell application "Mail"
    -- commands go here
end tell
```

## Standard Suite

> Common classes and commands for all applications.

### Commands

#### `delete`

Delete an object.

- **Direct parameter**: `specifier` — The object(s) to delete.

#### `duplicate`

Copy an object.

- **Direct parameter**: `specifier` — The object(s) to copy.
- **to**: `location specifier` *(optional)* — The location for the new copy or copies.
- **with properties**: `record` *(optional)* — Properties to set in the new copy or copies right away.

#### `move`

Move an object to a new location.

- **Direct parameter**: `specifier` — The object(s) to move.
- **to**: `location specifier` — The new location for the object(s).

## Text Suite

> A set of basic classes for text processing.

### Classes

#### `rich text`

Rich (styled) text

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `RGB color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `number` | rw | The size in points of the first character. |

**Contains**: `paragraph`, `word`, `character`, `attribute run`, `attachment`

#### `attachment`

Represents an inline text attachment. This class is used mainly for make commands.

*Inherits from: `rich text`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `file name` | `file` | rw | The file for the attachment |

#### `paragraph`

This subdivides the text into paragraphs.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `RGB color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `number` | rw | The size in points of the first character. |

**Contains**: `word`, `character`, `attribute run`, `attachment`

#### `word`

This subdivides the text into words.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `RGB color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `number` | rw | The size in points of the first character. |

**Contains**: `character`, `attribute run`, `attachment`

#### `character`

This subdivides the text into characters.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `RGB color` | rw | The color of the character. |
| `font` | `text` | rw | The name of the font of the character. |
| `size` | `number` | rw | The size in points of the character. |

**Contains**: `attribute run`, `attachment`

#### `attribute run`

This subdivides the text into chunks that all have the same attributes.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color` | `RGB color` | rw | The color of the first character. |
| `font` | `text` | rw | The name of the font of the first character. |
| `size` | `number` | rw | The size in points of the first character. |

**Contains**: `paragraph`, `word`, `character`, `attachment`

## Mail

> Classes and commands for the Mail application

### Commands

#### `bounce`

Does nothing at all (deprecated)

- **Direct parameter**: `message` — the message to bounce

#### `check for new mail`

Triggers a check for email.

- **for**: `account` *(optional)* — Specify the account that you wish to check for mail

#### `extract name from`

Command to get the full name out of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "John Doe"

- **Direct parameter**: `text` — fully formatted email address
- **Returns**: `text` — the full name

#### `extract address from`

Command to get just the email address of a fully specified email address. E.g. Calling this with "John Doe <jdoe@example.com>" as the direct object would return "jdoe@example.com"

- **Direct parameter**: `text` — fully formatted email address
- **Returns**: `text` — the email address

#### `forward`

Creates a forwarded message.

- **Direct parameter**: `message` — the message to forward
- **opening window**: `boolean` *(optional)* — Whether the window for the forwarded message is shown. Default is to not show the window.
- **Returns**: `outgoing message` — the message to be forwarded

#### `GetURL`

Opens a mailto URL.

- **Direct parameter**: `text` — the mailto URL

#### `import Mail mailbox`

Imports a mailbox created by Mail.

- **at**: `file` — the mailbox or folder of mailboxes to import

#### `mailto`

Opens a mailto URL.

- **Direct parameter**: `text` — the mailto URL

#### `perform mail action with messages`

Script handler invoked by rules and menus that execute AppleScripts. The direct parameter of this handler is a list of messages being acted upon.

- **Direct parameter**: `specifier` — the message being acted upon
- **in mailboxes**: `mailbox` *(optional)* — If the script is being executed by the user selecting an item in the scripts menu, this argument will specify the mailboxes that are currently selected. Otherwise it will not be specified.
- **for rule**: `rule` *(optional)* — If the script is being executed by a rule action, this argument will be the rule being invoked. Otherwise it will not be specified.

#### `redirect`

Creates a redirected message.

- **Direct parameter**: `message` — the message to redirect
- **opening window**: `boolean` *(optional)* — Whether the window for the redirected message is shown. Default is to not show the window.
- **Returns**: `outgoing message` — the redirected message

#### `reply`

Creates a reply message.

- **Direct parameter**: `message` — the message to reply to
- **opening window**: `boolean` *(optional)* — Whether the window for the reply message is shown. Default is to not show the window.
- **reply to all**: `boolean` *(optional)* — Whether to reply to all recipients. Default is to reply to the sender only.
- **Returns**: `outgoing message` — the reply message

#### `send`

Sends a message.

- **Direct parameter**: `outgoing message` — the message to send
- **Returns**: `boolean` — true if sending was successful, false if not

#### `synchronize`

Command to trigger synchronizing of an IMAP account with the server.

- **with**: `account` — The account to synchronize

### Classes

#### `outgoing message`

A new email message

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `sender` | `text` | rw | The sender of the message |
| `subject` | `text` | rw | The subject of the message |
| `visible` | `boolean` | rw | Controls whether the message window is shown on the screen. The default is false |
| `message signature` | `` | rw | The signature of the message |
| `id` | `integer` | r | The unique identifier of the message |

**Contains**: `bcc recipient`, `cc recipient`, `recipient`, `to recipient`

#### `message viewer`

Represents the object responsible for managing a viewer window

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `drafts mailbox` | `mailbox` | r | The top level Drafts mailbox |
| `inbox` | `mailbox` | r | The top level In mailbox |
| `junk mailbox` | `mailbox` | r | The top level Junk mailbox |
| `outbox` | `mailbox` | r | The top level Out mailbox |
| `sent mailbox` | `mailbox` | r | The top level Sent mailbox |
| `trash mailbox` | `mailbox` | r | The top level Trash mailbox |
| `sort column` | `ViewerColumns` | rw | The column that is currently sorted in the viewer |
| `sorted ascending` | `boolean` | rw | Whether the viewer is sorted ascending or not |
| `mailbox list visible` | `boolean` | rw | Controls whether the list of mailboxes is visible or not |
| `preview pane is visible` | `boolean` | rw | Controls whether the preview pane of the message viewer window is visible or not |
| `visible columns` | `` | rw | List of columns that are visible. The subject column and the message status column will always be visible |
| `id` | `integer` | r | The unique identifier of the message viewer |
| `visible messages` | `` | rw | List of messages currently being displayed in the viewer |
| `selected messages` | `` | rw | List of messages currently selected |
| `selected mailboxes` | `` | rw | List of mailboxes currently selected in the list of mailboxes |

**Contains**: `message`

#### `signature`

Email signatures

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `content` | `text` | rw | Contents of email signature. If there is a version with fonts and/or styles, that will be returned over the plain text version |
| `name` | `text` | rw | Name of the signature |

### Enumerations

#### `saveable file format`

- `native format` — Native format

#### `DefaultMessageFormat`

- `plain format` — Plain Text
- `rich format` — Rich Text

#### `HeaderDetail`

- `all` — All
- `custom` — Custom
- `default` — Default
- `no headers` — No headers

#### `LdapScope`

- `base` — LDAP scope of 'Base'
- `one level` — LDAP scope of 'One Level'
- `subtree` — LDAP scope of 'Subtree'

#### `QuotingColor`

- `blue` — Blue
- `green` — Green
- `orange` — Orange
- `other` — Other
- `purple` — Purple
- `red` — Red
- `yellow` — Yellow

#### `ViewerColumns`

- `attachments column` — Column containing the number of attachments a message contains
- `message color` — Used to indicate sorting should be done by color
- `date received column` — Column containing the date a message was received
- `date sent column` — Column containing the date a message was sent
- `flags column` — Column containing the flags of a message
- `from column` — Column containing the sender's name
- `mailbox column` — Column containing the name of the mailbox or account a message is in
- `message status column` — Column indicating a messages status (read, unread, replied to, forwarded, etc)
- `number column` — Column containing the number of a message in a mailbox
- `size column` — Column containing the size of a message
- `subject column` — Column containing the subject of a message
- `to column` — Column containing the recipients of a message
- `date last saved column` — Column containing the date a draft message was saved

## Mail Framework

> Classes and commands for the Mail framework

### Classes

#### `message`

An email message

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `id` | `integer` | r | The unique identifier of the message. |
| `all headers` | `text` | r | All the headers of the message |
| `background color` | `HighlightColors` | rw | The background color of the message |
| `mailbox` | `mailbox` | rw | The mailbox in which this message is filed |
| `content` | `rich text` | r | Contents of an email message |
| `date received` | `date` | r | The date a message was received |
| `date sent` | `date` | r | The date a message was sent |
| `deleted status` | `boolean` | rw | Indicates whether the message is deleted or not |
| `flagged status` | `boolean` | rw | Indicates whether the message is flagged or not |
| `flag index` | `integer` | rw | The flag on the message, or -1 if the message is not flagged |
| `junk mail status` | `boolean` | rw | Indicates whether the message has been marked junk or evaluated to be junk by the junk mail filter. |
| `read status` | `boolean` | rw | Indicates whether the message is read or not |
| `message id` | `text` | r | The unique message ID string |
| `source` | `text` | r | Raw source of the message |
| `reply to` | `text` | r | The address that replies should be sent to |
| `message size` | `integer` | r | The size (in bytes) of a message |
| `sender` | `text` | r | The sender of the message |
| `subject` | `text` | r | The subject of the message |
| `was forwarded` | `boolean` | r | Indicates whether the message was forwarded or not |
| `was redirected` | `boolean` | r | Indicates whether the message was redirected or not |
| `was replied to` | `boolean` | r | Indicates whether the message was replied to or not |

**Contains**: `bcc recipient`, `cc recipient`, `recipient`, `to recipient`, `header`, `mail attachment`

#### `account`

A Mail account for receiving messages (POP/IMAP). To create a new receiving account, use the 'pop account', 'imap account', and 'iCloud account' objects

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `delivery account` | `` | rw | The delivery account used when sending mail from this account |
| `name` | `text` | rw | The name of an account |
| `id` | `text` | r | The unique identifier of the account |
| `password` | `text` | rw | Password for this account. Can be set, but not read via scripting |
| `authentication` | `Authentication` | rw | Preferred authentication scheme for account |
| `account type` | `TypeOfAccount` | r | The type of an account |
| `email addresses` | `` | rw | The list of email addresses configured for an account |
| `full name` | `text` | rw | The users full name configured for an account |
| `empty junk messages frequency` | `integer` | rw | Number of days before junk messages are deleted (0 = delete on quit, -1 = never delete) |
| `empty trash frequency` | `integer` | rw | Number of days before messages in the trash are permanently deleted (0 = delete on quit, -1 = never delete) |
| `empty junk messages on quit` | `boolean` | rw | Indicates whether the messages in the junk messages mailboxes will be deleted on quit |
| `empty trash on quit` | `boolean` | rw | Indicates whether the messages in deleted messages mailboxes will be permanently deleted on quit |
| `enabled` | `boolean` | rw | Indicates whether the account is enabled or not |
| `user name` | `text` | rw | The user name used to connect to an account |
| `account directory` | `file` | r | The directory where the account stores things on disk |
| `port` | `integer` | rw | The port used to connect to an account |
| `server name` | `text` | rw | The host name used to connect to an account |
| `move deleted messages to trash` | `boolean` | rw | Indicates whether messages that are deleted will be moved to the trash mailbox |
| `uses ssl` | `boolean` | rw | Indicates whether SSL is enabled for this receiving account |

**Contains**: `mailbox`

#### `imap account`

An IMAP email account

*Inherits from: `account`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `compact mailboxes when closing` | `boolean` | rw | Indicates whether an IMAP mailbox is automatically compacted when you quit Mail or switch to another mailbox |
| `message caching` | `MessageCachingPolicy` | rw | Message caching setting for this account |
| `store drafts on server` | `boolean` | rw | Indicates whether drafts will be stored on the IMAP server |
| `store junk mail on server` | `boolean` | rw | Indicates whether junk mail will be stored on the IMAP server |
| `store sent messages on server` | `boolean` | rw | Indicates whether sent messages will be stored on the IMAP server |
| `store deleted messages on server` | `boolean` | rw | Indicates whether deleted messages will be stored on the IMAP server |

#### `iCloud account`

An iCloud or MobileMe email account

*Inherits from: `imap account`*

#### `pop account`

A POP email account

*Inherits from: `account`*

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `big message warning size` | `integer` | rw | If message size (in bytes) is over this amount, Mail will prompt you asking whether you want to download the message (-1 = do not prompt) |
| `delayed message deletion interval` | `integer` | rw | Number of days before messages that have been downloaded will be deleted from the server (0 = delete immediately after downloading) |
| `delete mail on server` | `boolean` | rw | Indicates whether POP account deletes messages on the server after downloading |
| `delete messages when moved from inbox` | `boolean` | rw | Indicates whether messages will be deleted from the server when moved from your POP inbox |

#### `smtp server`

An SMTP account (for sending email)

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | The name of an account |
| `password` | `text` | rw | Password for this account. Can be set, but not read via scripting |
| `account type` | `TypeOfAccount` | r | The type of an account |
| `authentication` | `Authentication` | rw | Preferred authentication scheme for account |
| `enabled` | `boolean` | rw | Indicates whether the account is enabled or not |
| `user name` | `text` | rw | The user name used to connect to an account |
| `port` | `integer` | rw | The port used to connect to an account |
| `server name` | `text` | rw | The host name used to connect to an account |
| `uses ssl` | `boolean` | rw | Indicates whether SSL is enabled for this receiving account |

#### `mailbox`

A mailbox that holds messages

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | rw | The name of a mailbox |
| `unread count` | `integer` | r | The number of unread messages in the mailbox |
| `account` | `account` | r |  |
| `container` | `mailbox` | r |  |

**Contains**: `mailbox`, `message`

#### `rule`

Class for message rules

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `color message` | `HighlightColors` | rw | If rule matches, apply this color |
| `delete message` | `boolean` | rw | If rule matches, delete message |
| `forward text` | `text` | rw | If rule matches, prepend this text to the forwarded message. Set to empty string to include no prepended text |
| `forward message` | `text` | rw | If rule matches, forward message to this address, or multiple addresses, separated by commas. Set to empty string to disable this action |
| `mark flagged` | `boolean` | rw | If rule matches, mark message as flagged |
| `mark flag index` | `integer` | rw | If rule matches, mark message with the specified flag. Set to -1 to disable this action |
| `mark read` | `boolean` | rw | If rule matches, mark message as read |
| `play sound` | `text` | rw | If rule matches, play this sound (specify name of sound or path to sound) |
| `redirect message` | `text` | rw | If rule matches, redirect message to this address or multiple addresses, separate by commas. Set to empty string to disable this action |
| `reply text` | `text` | rw | If rule matches, reply to message and prepend with this text. Set to empty string to disable this action |
| `run script` | `` | rw | If rule matches, run this compiled AppleScript file. Set to empty string to disable this action |
| `all conditions must be met` | `boolean` | rw | Indicates whether all conditions must be met for rule to execute |
| `copy message` | `mailbox` | rw | If rule matches, copy to this mailbox |
| `move message` | `mailbox` | rw | If rule matches, move to this mailbox |
| `highlight text using color` | `boolean` | rw | Indicates whether the color will be used to highlight the text or background of a message in the message list |
| `enabled` | `boolean` | rw | Indicates whether the rule is enabled |
| `name` | `text` | rw | Name of rule |
| `should copy message` | `boolean` | rw | Indicates whether the rule has a copy action |
| `should move message` | `boolean` | rw | Indicates whether the rule has a move action |
| `stop evaluating rules` | `boolean` | rw | If rule matches, stop rule evaluation for this message |

**Contains**: `rule condition`

#### `rule condition`

Class for conditions that can be attached to a single rule

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `expression` | `text` | rw | Rule expression field |
| `header` | `text` | rw | Rule header key |
| `qualifier` | `RuleQualifier` | rw | Rule qualifier |
| `rule type` | `RuleType` | rw | Rule type |

#### `recipient`

An email recipient

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `address` | `text` | rw | The recipients email address |
| `name` | `text` | rw | The name used for display |

#### `bcc recipient`

An email recipient in the Bcc: field

*Inherits from: `recipient`*

#### `cc recipient`

An email recipient in the Cc: field

*Inherits from: `recipient`*

#### `to recipient`

An email recipient in the To: field

*Inherits from: `recipient`*

#### `container`

A mailbox that contains other mailboxes.

*Inherits from: `mailbox`*

#### `header`

A header value for a message. E.g. To, Subject, From.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `content` | `text` | rw | Contents of the header |
| `name` | `text` | rw | Name of the header value |

#### `mail attachment`

A file attached to a received message.

| Property | Type | Access | Description |
|----------|------|--------|-------------|
| `name` | `text` | r | Name of the attachment |
| `MIME type` | `text` | r | MIME type of the attachment E.g. text/plain. |
| `file size` | `integer` | r | Approximate size in bytes. |
| `downloaded` | `boolean` | r | Indicates whether the attachment has been downloaded. |
| `id` | `text` | r | The unique identifier of the attachment. |

### Enumerations

#### `Authentication`

- `password` — Clear text password
- `apop` — APOP
- `kerberos 5` — Kerberos V5 (GSSAPI)
- `ntlm` — NTLM
- `md5` — CRAM-MD5
- `external` — External authentication (TLS client certificate)
- `Apple token` — Apple token
- `none` — None

#### `HighlightColors`

- `blue` — Blue
- `gray` — Gray
- `green` — Green
- `none` — None
- `orange` — Orange
- `other` — Other
- `purple` — Purple
- `red` — Red
- `yellow` — Yellow

#### `MessageCachingPolicy`

- `do not keep copies of any messages` — Do not use this option (deprecated). If you do, Mail will use the 'all messages but omit attachments' policy
- `only messages I have read` — Do not use this option (deprecated). If you do, Mail will use the 'all messages but omit attachments' policy
- `all messages but omit attachments` — All messages but omit attachments
- `all messages and their attachments` — All messages and their attachments

#### `RuleQualifier`

- `begins with value` — Begins with value
- `does contain value` — Does contain value
- `does not contain value` — Does not contain value
- `ends with value` — Ends with value
- `equal to value` — Equal to value
- `less than value` — Less than value
- `greater than value` — Greater than value
- `none` — Indicates no qualifier is applicable

#### `RuleType`

- `account` — Account
- `any recipient` — Any recipient
- `cc header` — Cc header
- `matches every message` — Every message
- `from header` — From header
- `header key` — An arbitrary header key
- `message content` — Message content
- `message is junk mail` — Message is junk mail
- `sender is in my contacts` — Sender is in my contacts
- `sender is in my previous recipients` — Sender is in my previous recipients
- `sender is member of group` — Sender is member of group
- `sender is not in my contacts` — Sender is not in my contacts
- `sender is not in my previous recipients` — sender is not in my previous recipients
- `sender is not member of group` — Sender is not member of group
- `sender is VIP` — Sender is VIP
- `subject header` — Subject header
- `to header` — To header
- `to or cc header` — To or Cc header
- `attachment type` — Attachment Type

#### `TypeOfAccount`

- `pop` — POP
- `smtp` — SMTP
- `imap` — IMAP
- `iCloud` — iCloud
- `unknown` — Unknown
