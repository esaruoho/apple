# Shortcuts — AppleScript Examples

> Ready-to-use AppleScript snippets for Shortcuts
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Shortcuts
tell application "Shortcuts" to activate
```

```applescript
-- Check if Shortcuts is running
if application "Shortcuts" is running then
    tell application "Shortcuts" to activate
end if
```
