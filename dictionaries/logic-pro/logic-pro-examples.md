# Logic Pro — AppleScript Examples

> Ready-to-use AppleScript snippets for Logic Pro
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Logic Pro
tell application "Logic Pro" to activate
```

```applescript
-- Check if Logic Pro is running
if application "Logic Pro" is running then
    tell application "Logic Pro" to activate
end if
```

## `close`

> Close an object.

```applescript
tell application "Logic Pro"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "Logic Pro"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Logic Pro"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "Logic Pro"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "Logic Pro"
    exists
end tell
```

## `get`

> Get the data for an object.

```applescript
tell application "Logic Pro"
    -- Get a property
    get name of front window
end tell
```

## `make`

> Make a new object.

```applescript
tell application "Logic Pro"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "Logic Pro"
    move
end tell
```

## `open`

> Open an object.

```applescript
tell application "Logic Pro"
    open
end tell
```

## `print`

> Print an object.

```applescript
tell application "Logic Pro"
    print
end tell
```

## `quit`

> Quit an application.

```applescript
tell application "Logic Pro"
    quit
end tell
```

## `save`

> Save an object.

```applescript
tell application "Logic Pro"
    save front document
end tell
```

## `set`

> Set an object's data.

```applescript
tell application "Logic Pro"
    set
end tell
```
