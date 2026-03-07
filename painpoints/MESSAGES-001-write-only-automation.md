# MESSAGES-001: Messages Is Write-Only by Design

**App:** Messages.app
**Intent:** Read messages, search conversation history, or auto-reply programmatically
**Severity:** Automation wall — only 3 commands, all write-direction, no read access whatsoever
**Status:** Open
**Filed:** 2026-03-07

---

## The Friction

Messages has exactly 3 AppleScript commands:

| Command | Direction |
|---|---|
| `send` | Write |
| `log in` | Write |
| `log out` | Write |

That's it. You can shout into the void. You cannot listen.

**What you cannot do:**
- Read incoming messages
- Search conversation history
- Get unread message count
- List conversations or participants
- Auto-reply based on content
- Forward messages to another service
- Archive or export conversations

Messages is a **one-way valve**. Automation can push messages out but cannot observe, react to, or process anything coming in. Every "smart reply" or "message triage" workflow is impossible by design.

---

## What Sal Would Say

> "The power of the computer should reside in the hands of the one using it."

The user has hundreds of conversations. They want to search them, sort them, react to them, route them. Messages says: "No. You may send. That is all."

Sal's Principle #2: **Solve a real problem.** The real problem is communication management. People get more messages than they can process. Automation should help triage, summarize, and respond. Messages blocks all of this.

Sal's Principle #5: **Use what the user already has.** The user already has their entire message history sitting in `~/Library/Messages/chat.db`. The data is right there. But Apple provides no sanctioned way to access it programmatically. The SQLite database exists; the automation surface pretends it doesn't.

---

## The Automation Surface (from our probe)

From the probe data: Messages has **3 AppleScript commands** (`send`, `log in`, `log out`) and **6 classes** (`application`, `chat`, `text chat`, `buddy`, `participant`, `message`).

The classes suggest Apple *designed* for read access — there are `message`, `chat`, and `buddy` objects in the dictionary. But no commands operate on them for reading. The scaffolding is there; the verbs are missing.

Messages has **no App Intents**, **no URL scheme** for queries, and **no CLI tool**. The Shortcuts integration is limited to "Send Message" — the same write-only pattern.

---

## What It Should Be

```applescript
-- Check for unread messages and auto-reply if away
tell application "Messages"
    set unread to every message where read status is false
    repeat with msg in unread
        if content of msg contains "urgent" then
            send "I'm away but will respond to urgent items within 1 hour." to buddy (sender of msg)
        end if
    end repeat
end tell
```

```bash
# Or via Shortcuts
shortcuts run "Message Triage"
# Action: Get Unread Messages -> Filter by keyword -> Send Reply
```

Read access does not mean privacy violation. The user owns their messages. They should be able to script their own data.

---

## Fix Paths

1. **Apple (ideal):** Add read commands to the Messages scripting dictionary — `get messages`, `search conversations`, `unread count`. The classes already exist; they just need verbs. Gate it behind the same Automation privacy prompt that protects other apps.
2. **Shortcuts (partial):** Add "Get Messages From," "Search Messages," and "Get Unread Count" Shortcuts actions. These would enable reactive workflows without direct AppleScript access.
3. **`chat.db` direct read (hack):** Messages stores everything in `~/Library/Messages/chat.db` (SQLite). Tools like `imessage-exporter` can read it. But this bypasses Apple's APIs entirely, breaks on schema changes, and requires Full Disk Access.
4. **Notification-based (fragile):** Use System Events to watch for notification banners from Messages. Unreliable, loses data when notifications are dismissed, and cannot access message content.

---

## The Privacy Question

Apple likely restricts Messages read access for privacy. That's reasonable — but the solution should be **user-gated access**, not **no access**. macOS already has the Automation privacy framework (System Settings > Privacy > Automation). Messages read access should be behind that same gate: the user explicitly grants permission, and then their scripts can read their own messages.

Blocking the user from scripting their own data is not privacy. It's paternalism.

---

---

*Part of the [Apple Automation Atlas](../README.md). Tagged for the attention of anyone at Apple who still believes the power of the computer should reside in the hands of the one using it.*

**Filed by [@esaruoho](https://github.com/esaruoho)** -- software tester, UI enthusiast, amateur scripter, automation/workflow obsessive, and user experience evaluator. Reporting the missing bits and pieces one at a time.