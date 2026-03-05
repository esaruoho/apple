# Mail — AppleScript Examples

> Ready-to-use AppleScript snippets for Mail
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Mail
tell application "Mail" to activate
```

```applescript
-- Check if Mail is running
if application "Mail" is running then
    tell application "Mail" to activate
end if
```

## `delete`

> Delete an object.

```applescript
tell application "Mail"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy an object.

```applescript
tell application "Mail"
    duplicate
end tell
```

## `move`

> Move an object to a new location.

```applescript
tell application "Mail"
    move
end tell
```
