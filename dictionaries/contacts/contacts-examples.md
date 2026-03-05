# Contacts — AppleScript Examples

> Ready-to-use AppleScript snippets for Contacts
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Contacts
tell application "Contacts" to activate
```

```applescript
-- Check if Contacts is running
if application "Contacts" is running then
    tell application "Contacts" to activate
end if
```

## `make`

> Create a new object.

```applescript
tell application "Contacts"
    -- Create new item
    make new document
end tell
```

## `save`

> Save all Contacts changes. Also see the unsaved property for the application class.

```applescript
tell application "Contacts"
    save front document
end tell
```
