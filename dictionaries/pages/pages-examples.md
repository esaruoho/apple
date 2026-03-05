# Pages — AppleScript Examples

> Ready-to-use AppleScript snippets for Pages
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Pages
tell application "Pages" to activate
```

```applescript
-- Check if Pages is running
if application "Pages" is running then
    tell application "Pages" to activate
end if
```

## `set`

> Sets the value of the specified object(s).

```applescript
tell application "Pages"
    set
end tell
```

## `delete`

> Delete an object.

```applescript
tell application "Pages"
    -- Delete an item
    -- delete <specifier>
end tell
```

## `make`

> Create a new object.

```applescript
tell application "Pages"
    -- Create new item
    make new document
end tell
```

## `make`

> Create a new object.

```applescript
tell application "Pages"
    -- Create new item
    make new document
end tell
```
