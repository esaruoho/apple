# Music — AppleScript Examples

> Ready-to-use AppleScript snippets for Music
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Music
tell application "Music" to activate
```

```applescript
-- Check if Music is running
if application "Music" is running then
    tell application "Music" to activate
end if
```

## `print`

> Print the specified object(s)

```applescript
tell application "Music"
    print
end tell
```

## `close`

> Close an object

```applescript
tell application "Music"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object

```applescript
tell application "Music"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an element from an object

```applescript
tell application "Music"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Duplicate one or more object(s)

```applescript
tell application "Music"
    duplicate
end tell
```

## `exists`

> Verify if an object exists

```applescript
tell application "Music"
    exists
end tell
```

## `make`

> Make a new element

```applescript
tell application "Music"
    -- Create new item
    make new document
end tell
```

## `move`

> Move playlist(s) to a new location

```applescript
tell application "Music"
    move
end tell
```

## `open`

> Open the specified object(s)

```applescript
tell application "Music"
    open
end tell
```

## `quit`

> Quit the application

```applescript
tell application "Music"
    quit
end tell
```

## `save`

> Save the specified object(s)

```applescript
tell application "Music"
    save front document
end tell
```

## `select`

> select the specified object(s)

```applescript
tell application "Music"
    select
end tell
```
