# Terminal — AppleScript Examples

> Ready-to-use AppleScript snippets for Terminal
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Terminal
tell application "Terminal" to activate
```

```applescript
-- Check if Terminal is running
if application "Terminal" is running then
    tell application "Terminal" to activate
end if
```

## `open`

> Open a document.

```applescript
tell application "Terminal"
    open
end tell
```

## `close`

> Close a document.

```applescript
tell application "Terminal"
    close front window
end tell
```

## `save`

> Save a document.

```applescript
tell application "Terminal"
    save front document
end tell
```

## `print`

> Print a document.

```applescript
tell application "Terminal"
    print
end tell
```

## `quit`

> Quit the application.

```applescript
tell application "Terminal"
    quit
end tell
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "Terminal"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Terminal"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `duplicate`

> Copy object(s) and put the copies at a new location.

```applescript
tell application "Terminal"
    duplicate
end tell
```

## `exists`

> Verify if an object exists.

```applescript
tell application "Terminal"
    exists
end tell
```

## `make`

> Make a new object.

```applescript
tell application "Terminal"
    -- Create new item
    make new document
end tell
```

## `move`

> Move object(s) to a new location.

```applescript
tell application "Terminal"
    move
end tell
```
