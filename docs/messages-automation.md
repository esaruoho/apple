---
layout: default
title: "Messages/iMessage Automation"
---

# Messages/iMessage Automation


[← Back to home](./)
Messages has the **thinnest sdef** — 3 commands: `send`, `login`, `logout`. Write-only by design.

**What works:** Send text/files to participants, list 201 chats, list participants with handles, URL schemes (`imessage://`, `sms://`) open compose window

**What doesn't work:** Read message content, search, delete, react, auto-reply, access history. No App Intents for sending. The only Intent is Focus Mode filtering.

**Workaround:** `~/Library/Messages/chat.db` (SQLite) is readable with Full Disk Access but SIP-protected.
