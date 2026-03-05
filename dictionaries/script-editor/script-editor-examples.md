# Script Editor — AppleScript Examples

> Ready-to-use AppleScript snippets for Script Editor
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Script Editor
tell application "Script Editor" to activate
```

```applescript
-- Check if Script Editor is running
if application "Script Editor" is running then
    tell application "Script Editor" to activate
end if
```

## `close`

> Close an object.

```applescript
tell application "Script Editor"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "Script Editor"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Script Editor"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "Script Editor"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "Script Editor"
    exists
end tell
```

## `get`

> Get the data for an object.

```applescript
tell application "Script Editor"
    -- Get a property
    get name of front window
end tell
```

## `make`

> Make a new object.

```applescript
tell application "Script Editor"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "Script Editor"
    move
end tell
```

## `open`

> Open an object.

```applescript
tell application "Script Editor"
    open
end tell
```

## `print`

> Print an object.

```applescript
tell application "Script Editor"
    print
end tell
```

## `quit`

> Quit an application.

```applescript
tell application "Script Editor"
    quit
end tell
```

## `save`

> Save an object.

```applescript
tell application "Script Editor"
    save front document
end tell
```

## `set`

> Set an object's data.

```applescript
tell application "Script Editor"
    set
end tell
```

## `save`

> Save an object.

```applescript
tell application "Script Editor"
    save front document
end tell
```
