# Final Cut Pro — AppleScript Examples

> Ready-to-use AppleScript snippets for Final Cut Pro
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Final Cut Pro
tell application "Final Cut Pro" to activate
```

```applescript
-- Check if Final Cut Pro is running
if application "Final Cut Pro" is running then
    tell application "Final Cut Pro" to activate
end if
```

## `get`

> Get data.

```applescript
tell application "Final Cut Pro"
    -- Get a property
    get name of front window
end tell
```
