# Numbers — AppleScript Examples

> Ready-to-use AppleScript snippets for Numbers
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Numbers
tell application "Numbers" to activate
```

```applescript
-- Check if Numbers is running
if application "Numbers" is running then
    tell application "Numbers" to activate
end if
```

## `set`

> Sets the value of the specified object(s).

```applescript
tell application "Numbers"
    set
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Numbers"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `make`

> Create a new object.

```applescript
tell application "Numbers"
    -- Create new item
    make new document
end tell
```
