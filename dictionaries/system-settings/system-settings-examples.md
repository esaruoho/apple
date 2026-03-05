# System Settings — AppleScript Examples

> Ready-to-use AppleScript snippets for System Settings
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate System Settings
tell application "System Settings" to activate
```

```applescript
-- Check if System Settings is running
if application "System Settings" is running then
    tell application "System Settings" to activate
end if
```
