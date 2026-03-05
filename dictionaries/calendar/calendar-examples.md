# Calendar — AppleScript Examples

> Ready-to-use AppleScript snippets for Calendar
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Calendar
tell application "Calendar" to activate
```

```applescript
-- Check if Calendar is running
if application "Calendar" is running then
    tell application "Calendar" to activate
end if
```

## `make`

```applescript
tell application "Calendar"
    -- Create new item
    make new document
end tell
```

## `save`

```applescript
tell application "Calendar"
    save front document
end tell
```
