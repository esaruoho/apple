# Console — AppleScript Examples

> Ready-to-use AppleScript snippets for Console
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Console
tell application "Console" to activate
```

```applescript
-- Check if Console is running
if application "Console" is running then
    tell application "Console" to activate
end if
```
