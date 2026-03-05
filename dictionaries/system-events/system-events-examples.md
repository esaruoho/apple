# System Events — AppleScript Examples

> Ready-to-use AppleScript snippets for System Events
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate System Events
tell application "System Events" to activate
```

```applescript
-- Check if System Events is running
if application "System Events" is running then
    tell application "System Events" to activate
end if
```

## `delete`

> Delete disk item(s).

```applescript
tell application "System Events"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `move`

> Move disk item(s) to a new location.

```applescript
tell application "System Events"
    move
end tell
```

## `open`

> Open disk item(s) with the appropriate application.

```applescript
tell application "System Events"
    open
end tell
```

## `select`

> set the selected property of the UI element

```applescript
tell application "System Events"
    select
end tell
```
