# TV — AppleScript Examples

> Ready-to-use AppleScript snippets for TV
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate TV
tell application "TV" to activate
```

```applescript
-- Check if TV is running
if application "TV" is running then
    tell application "TV" to activate
end if
```

## `close`

> Close an object

```applescript
tell application "TV"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object

```applescript
tell application "TV"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an element from an object

```applescript
tell application "TV"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Duplicate one or more object(s)

```applescript
tell application "TV"
    duplicate
end tell
```

## `exists`

> Verify if an object exists

```applescript
tell application "TV"
    exists
end tell
```

## `make`

> Make a new element

```applescript
tell application "TV"
    -- Create new item
    make new document
end tell
```

## `move`

> Move playlist(s) to a new location

```applescript
tell application "TV"
    move
end tell
```

## `open`

> Open the specified object(s)

```applescript
tell application "TV"
    open
end tell
```

## `quit`

> Quit the application

```applescript
tell application "TV"
    quit
end tell
```

## `save`

> Save the specified object(s)

```applescript
tell application "TV"
    save front document
end tell
```

## `select`

> select the specified object(s)

```applescript
tell application "TV"
    select
end tell
```
