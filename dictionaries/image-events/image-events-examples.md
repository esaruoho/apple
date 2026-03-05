# Image Events — AppleScript Examples

> Ready-to-use AppleScript snippets for Image Events
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Image Events
tell application "Image Events" to activate
```

```applescript
-- Check if Image Events is running
if application "Image Events" is running then
    tell application "Image Events" to activate
end if
```

## `delete`

> Delete disk item(s).

```applescript
tell application "Image Events"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `move`

> Move disk item(s) to a new location.

```applescript
tell application "Image Events"
    move
end tell
```

## `open`

> Open disk item(s) with the appropriate application.

```applescript
tell application "Image Events"
    open
end tell
```

## `close`

> Close an image

```applescript
tell application "Image Events"
    close front window
end tell
```

## `save`

> Save an image to a file in one of various formats

```applescript
tell application "Image Events"
    save front document
end tell
```
