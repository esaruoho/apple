# Preview — AppleScript Examples

> Ready-to-use AppleScript snippets for Preview
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Preview
tell application "Preview" to activate
```

```applescript
-- Check if Preview is running
if application "Preview" is running then
    tell application "Preview" to activate
end if
```

## `close`

> Close an object.

```applescript
tell application "Preview"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "Preview"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Preview"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "Preview"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "Preview"
    exists
end tell
```

## `get`

> Get the data for an object.

```applescript
tell application "Preview"
    -- Get a property
    get name of front window
end tell
```

## `make`

> Make a new object.

```applescript
tell application "Preview"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "Preview"
    move
end tell
```

## `open`

> Open an object.

```applescript
tell application "Preview"
    open
end tell
```

## `print`

> Print an object.

```applescript
tell application "Preview"
    print
end tell
```

## `quit`

> Quit an application.

```applescript
tell application "Preview"
    quit
end tell
```

## `save`

> Save an object.

```applescript
tell application "Preview"
    save front document
end tell
```

## `set`

> Set an object's data.

```applescript
tell application "Preview"
    set
end tell
```
