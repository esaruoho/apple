# Photos — AppleScript Examples

> Ready-to-use AppleScript snippets for Photos
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Photos
tell application "Photos" to activate
```

```applescript
-- Check if Photos is running
if application "Photos" is running then
    tell application "Photos" to activate
end if
```

## `count`

> Return the number of elements of a particular class within an object.

```applescript
tell application "Photos"
    -- Count items
    set itemCount to count of every window
    return itemCount
end tell
```

## `exists`

> Verify that an object exists.

```applescript
tell application "Photos"
    exists
end tell
```

## `open`

> Open a photo library

```applescript
tell application "Photos"
    open
end tell
```

## `quit`

> Quit the application.

```applescript
tell application "Photos"
    quit
end tell
```

## `duplicate`

> Duplicate an object.  Only media items can be duplicated

```applescript
tell application "Photos"
    duplicate
end tell
```

## `make`

> Create a new object.  Only new albums and folders can be created.

```applescript
tell application "Photos"
    -- Create new item
    make new document
end tell
```

## `delete`

> Delete an object.  Only albums and folders can be deleted.

```applescript
tell application "Photos"
    -- Delete an item
    -- delete <specifier>
end tell
```
