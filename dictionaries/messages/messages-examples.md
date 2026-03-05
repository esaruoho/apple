# Messages — AppleScript Examples

> Ready-to-use AppleScript snippets for Messages
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Messages
tell application "Messages" to activate
```

```applescript
-- Check if Messages is running
if application "Messages" is running then
    tell application "Messages" to activate
end if
```
