# Screen Sharing — AppleScript Examples

> Ready-to-use AppleScript snippets for Screen Sharing
> Copy any snippet and run with: `osascript -e '<snippet>'`

## Basics

```applescript
-- Activate Screen Sharing
tell application "Screen Sharing" to activate
```

```applescript
-- Check if Screen Sharing is running
if application "Screen Sharing" is running then
    tell application "Screen Sharing" to activate
end if
```
