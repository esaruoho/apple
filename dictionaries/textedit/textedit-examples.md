# TextEdit — AppleScript Examples

> Ready-to-use AppleScript snippets for TextEdit
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate TextEdit
tell application "TextEdit" to activate
```

```applescript
-- Check if TextEdit is running
if application "TextEdit" is running then
    tell application "TextEdit" to activate
end if
```

## `close`

> Close an object.

```applescript
tell application "TextEdit"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "TextEdit"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "TextEdit"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "TextEdit"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "TextEdit"
    exists
end tell
```

## `get`

> Get the data for an object.

```applescript
tell application "TextEdit"
    -- Get a property
    get name of front window
end tell
```

## `make`

> Make a new object.

```applescript
tell application "TextEdit"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "TextEdit"
    move
end tell
```

## `open`

> Open an object.

```applescript
tell application "TextEdit"
    open
end tell
```

## `print`

> Print an object.

```applescript
tell application "TextEdit"
    print
end tell
```

## `quit`

> Quit an application.

```applescript
tell application "TextEdit"
    quit
end tell
```

## `save`

> Save an object.

```applescript
tell application "TextEdit"
    save front document
end tell
```

## `set`

> Set an object's data.

```applescript
tell application "TextEdit"
    set
end tell
```
