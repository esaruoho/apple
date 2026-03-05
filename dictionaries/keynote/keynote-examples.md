# Keynote — AppleScript Examples

> Ready-to-use AppleScript snippets for Keynote
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Keynote
tell application "Keynote" to activate
```

```applescript
-- Check if Keynote is running
if application "Keynote" is running then
    tell application "Keynote" to activate
end if
```

## `duplicate`

> Copy an object.

```applescript
tell application "Keynote"
    duplicate
end tell
```

## `get`

> Returns the value of the specified object(s).

```applescript
tell application "Keynote"
    -- Get a property
    get name of front window
end tell
```

## `set`

> Sets the value of the specified object(s).

```applescript
tell application "Keynote"
    set
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Keynote"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `make`

> Create a new object.

```applescript
tell application "Keynote"
    -- Create new item
    make new document
end tell
```
