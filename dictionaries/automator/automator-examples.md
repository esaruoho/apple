# Automator — AppleScript Examples

> Ready-to-use AppleScript snippets for Automator
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Automator
tell application "Automator" to activate
```

```applescript
-- Check if Automator is running
if application "Automator" is running then
    tell application "Automator" to activate
end if
```

## `close`

> Close an object.

```applescript
tell application "Automator"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "Automator"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Automator"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "Automator"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "Automator"
    exists
end tell
```

## `get`

> Get the data for an object.

```applescript
tell application "Automator"
    -- Get a property
    get name of front window
end tell
```

## `make`

> Make a new object.

```applescript
tell application "Automator"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "Automator"
    move
end tell
```

## `open`

> Open an object.

```applescript
tell application "Automator"
    open
end tell
```

## `print`

> Print an object.

```applescript
tell application "Automator"
    print
end tell
```

## `quit`

> Quit an application.

```applescript
tell application "Automator"
    quit
end tell
```

## `save`

> Save an object.

```applescript
tell application "Automator"
    save front document
end tell
```

## `set`

> Set an object's data.

```applescript
tell application "Automator"
    set
end tell
```
