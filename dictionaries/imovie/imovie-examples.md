# iMovie — AppleScript Examples

> Ready-to-use AppleScript snippets for iMovie
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate iMovie
tell application "iMovie" to activate
```

```applescript
-- Check if iMovie is running
if application "iMovie" is running then
    tell application "iMovie" to activate
end if
```

## `close`

> Close an object.

```applescript
tell application "iMovie"
    close front window
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "iMovie"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "iMovie"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "iMovie"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "iMovie"
    exists
end tell
```

## `get`

> Get the data for an object.

```applescript
tell application "iMovie"
    -- Get a property
    get name of front window
end tell
```

## `make`

> Make a new object.

```applescript
tell application "iMovie"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "iMovie"
    move
end tell
```

## `open`

> Open an object.

```applescript
tell application "iMovie"
    open
end tell
```

## `print`

> Print an object.

```applescript
tell application "iMovie"
    print
end tell
```

## `quit`

> Quit an application.

```applescript
tell application "iMovie"
    quit
end tell
```

## `save`

> Save an object.

```applescript
tell application "iMovie"
    save front document
end tell
```

## `set`

> Set an object's data.

```applescript
tell application "iMovie"
    set
end tell
```
