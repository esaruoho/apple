# Safari — AppleScript Examples

> Ready-to-use AppleScript snippets for Safari
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Safari
tell application "Safari" to activate
```

```applescript
-- Check if Safari is running
if application "Safari" is running then
    tell application "Safari" to activate
end if
```
