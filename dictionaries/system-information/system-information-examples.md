# System Information — AppleScript Examples

> Ready-to-use AppleScript snippets for System Information
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate System Information
tell application "System Information" to activate
```

```applescript
-- Check if System Information is running
if application "System Information" is running then
    tell application "System Information" to activate
end if
```

## `close`

> Close an object.

```applescript
tell application "System Information"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "System Information"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "System Information"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "System Information"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "System Information"
    exists
end tell
```

## `get`

> Get the data for an object.

```applescript
tell application "System Information"
    -- Get a property
    get name of front window
end tell
```

## `make`

> Make a new object.

```applescript
tell application "System Information"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "System Information"
    move
end tell
```

## `open`

> Open an object.

```applescript
tell application "System Information"
    open
end tell
```

## `print`

> Print an object.

```applescript
tell application "System Information"
    print
end tell
```

## `quit`

> Quit an application.

```applescript
tell application "System Information"
    quit
end tell
```

## `save`

> Save an object.

```applescript
tell application "System Information"
    save front document
end tell
```

## `set`

> Set an object's data.

```applescript
tell application "System Information"
    set
end tell
```
