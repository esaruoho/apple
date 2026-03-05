# Finder — AppleScript Examples

> Ready-to-use AppleScript snippets for Finder
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Finder
tell application "Finder" to activate
```

```applescript
-- Check if Finder is running
if application "Finder" is running then
    tell application "Finder" to activate
end if
```

## `open`

> Open the specified object(s)

```applescript
tell application "Finder"
    open
end tell
```

## `print`

> Print the specified object(s)

```applescript
tell application "Finder"
    print
end tell
```

## `quit`

> Quit the Finder

```applescript
tell application "Finder"
    quit
end tell
```

## `activate`

> Activate the specified window (or the Finder)

```applescript
tell application "Finder"
    activate
end tell
```

## `close`

> Close an object

```applescript
tell application "Finder"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object

```applescript
tell application "Finder"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Move an item from its container to the trash

```applescript
tell application "Finder"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Duplicate one or more object(s)

```applescript
tell application "Finder"
    duplicate
end tell
```

## `exists`

> Verify if an object exists

```applescript
tell application "Finder"
    exists
end tell
```

## `make`

> Make a new element

```applescript
tell application "Finder"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location

```applescript
tell application "Finder"
    move
end tell
```

## `select`

> Select the specified object(s)

```applescript
tell application "Finder"
    select
end tell
```
